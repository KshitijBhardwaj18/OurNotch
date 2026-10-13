import { DurableObject } from "cloudflare:workers";

// The doorbell between a couple's two Macs. Only the word "ring" passes through: the Mac that rang saved
// something to iCloud, and the other Mac reads it from there, encrypted, as before. A room's name is a hash
// of the couple's shared key, so Cloudflare never learns who is in it.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
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
