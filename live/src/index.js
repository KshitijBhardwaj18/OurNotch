import { DurableObject } from "cloudflare:workers";
import { inviteEmail } from "./invite.js";

// The doorbell between a couple's two Macs. Only the word "ring" passes through: the Mac that rang saved
// something to iCloud, and the other Mac reads it from there, encrypted, as before. A room's name is a hash
// of the couple's shared key, so Cloudflare never learns who is in it.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/v1/invite") return sendInvite(request, env);
    if (url.pathname === "/v1/invite/preview") return previewInvite(url);
    const room = url.pathname.match(/^\/v1\/room\/([0-9a-f]{64})$/)?.[1];
    if (!room) return new Response("not found", { status: 404 });
    if (env.LIVE !== "on") return new Response("off", { status: 503 });
    if (request.headers.get("Upgrade") !== "websocket") return new Response("websocket only", { status: 426 });
    const me = url.searchParams.get("me");
    if (me !== "inviter" && me !== "joiner") return new Response("who are you?", { status: 400 });
    return env.ROOMS.get(env.ROOMS.idFromName(room)).fetch(request);
  },
};

// One per couple. Uses hibernation: an idle room costs nothing while its two sockets stay open.
export class Room extends DurableObject {
  fetch(request) {
    const me = new URL(request.url).searchParams.get("me");
    // A Mac that reconnects (after sleep or a dropped network) replaces its old socket, so a room holds two at most.
    for (const old of this.ctx.getWebSockets(me)) old.close(1000, "replaced");
    const [client, server] = Object.values(new WebSocketPair());
    this.ctx.acceptWebSocket(server, [me]);
    this.announce();
    return new Response(null, { status: 101, webSocket: client });
  }

  // ponytail: no rate limit; a buggy Mac could ring nonstop. Add one if the request count ever shows it.
  webSocketMessage(ws, message) {
    if (message !== "ring") return;
    for (const other of this.open()) if (other !== ws) other.send("ring");
  }

  webSocketClose(ws) {
    this.announce(ws);
  }

  webSocketError(ws) {
    this.announce(ws);
  }

  // Tells each Mac how many of the couple are here, so it knows whether a ring would be heard.
  announce(gone) {
    const open = this.open().filter((ws) => ws !== gone);
    const here = new Set(open.map((ws) => this.ctx.getTags(ws)[0])).size;
    for (const ws of open) ws.send(`here ${here}`);
  }

  open() {
    return this.ctx.getWebSockets().filter((ws) => ws.readyState === WebSocket.OPEN);
  }
}

// MARK: Invite email

const CODE = /^[A-HJ-NP-Z2-9]{6}$/; // PairingService.codeAlphabet
const EMAIL = /^[^\s@<>,;"]+@[^\s@<>,;"]+\.[^\s@<>,;"]+$/;
const LANGS = ["en", "fr", "de"];
const DOWNLOAD = { beta: "https://downloads.ournotch.app/beta/OurNotch.dmg", sold: "https://ournotch.app/download" };

// The sender's name as typed in the app: plain text, short, on one line.
const cleanName = (s) => (typeof s === "string" ? s.replace(/[\u0000-\u001f<>"]/g, "").trim().slice(0, 30) : "");

// Sends the invite from hello@ournotch.app through Resend. Each Mac (IP) may send a few an hour and all of
// them together a few hundred a day, so this can't be used to spam people from our address.
// ponytail: limits by IP, not by a real invite; checking the code against CloudKit would close the gap.
async function sendInvite(request, env) {
  if (request.method !== "POST") return new Response("post only", { status: 405 });
  if (!env.RESEND_API_KEY) return Response.json({ error: "not set up" }, { status: 503 });
  const body = await request.json().catch(() => ({}));
  const name = cleanName(body.name);
  const to = typeof body.to === "string" ? body.to.trim() : "";
  if (!name || !CODE.test(body.code ?? "") || to.length > 254 || !EMAIL.test(to)) {
    return Response.json({ error: "bad request" }, { status: 400 });
  }
  const ip = request.headers.get("cf-connecting-ip") ?? "unknown";
  const mine = await env.LIMITS.get(env.LIMITS.idFromName(`ip:${ip}`)).take(5, 60 * 60);
  const everyone = mine && (await env.LIMITS.get(env.LIMITS.idFromName("all")).take(300, 24 * 60 * 60));
  if (!everyone) return Response.json({ error: "too many" }, { status: 429 });

  const lang = LANGS.includes(body.lang) ? body.lang : "en";
  const email = inviteEmail({ name, code: body.code, lang, download: body.beta === true ? DOWNLOAD.beta : DOWNLOAD.sold });
  const sent = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: { Authorization: `Bearer ${env.RESEND_API_KEY}`, "Content-Type": "application/json" },
    body: JSON.stringify({ from: `${name} via OurNotch <hello@ournotch.app>`, to: [to], ...email }),
  });
  if (!sent.ok) {
    console.error("resend failed", sent.status, await sent.text());
    return Response.json({ error: "send failed" }, { status: 502 });
  }
  return Response.json({ sent: true });
}

// The email in a browser, with sample (or given) values; sends nothing.
function previewInvite(url) {
  const q = url.searchParams;
  const code = CODE.test(q.get("code") ?? "") ? q.get("code") : "K7M2QX";
  const lang = LANGS.includes(q.get("lang")) ? q.get("lang") : "en";
  const { html } = inviteEmail({ name: cleanName(q.get("name")) || "kshitij", code, lang, download: DOWNLOAD.sold });
  return new Response(html, { headers: { "Content-Type": "text/html; charset=utf-8" } });
}

// A fixed-window counter, one per key ("ip:1.2.3.4", "all").
export class Limit extends DurableObject {
  async take(max, seconds) {
    const now = Date.now();
    let w = (await this.ctx.storage.get("w")) ?? { start: now, count: 0 };
    if (now - w.start > seconds * 1000) w = { start: now, count: 0 };
    if (w.count >= max) return false;
    w.count += 1;
    await this.ctx.storage.put("w", w);
    return true;
  }
}
