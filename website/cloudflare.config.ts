import { bindings, defineConfig, defineWorker } from "cf/config";

export default defineConfig({
  worker: defineWorker({
    name: "ournotch-website",
    entrypoint: "vinext/server/fetch-handler",
    compatibilityDate: "2026-09-28",
    compatibilityFlags: ["nodejs_compat"],
    assets: { notFoundHandling: "none" },
    // Cloudflare points these at the Worker and handles HTTPS once the domain's DNS is on Cloudflare.
    domains: ["ournotch.app", "www.ournotch.app"],
    env: {
      ASSETS: bindings.assets(),
    },
  }),
});
