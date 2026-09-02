export interface Env {
  NEXUS_API_KEY?: string;
  NEXUS_JOBS?: Queue;
  NEXUS_CACHE?: R2Bucket;
}

const MAX_BODY_BYTES = 65536;

function routeTask(task: string): string {
  const t = task.toLowerCase();
  if (/gpu|ml|embedding|audio-batch|spectrogram|large-data/.test(t)) return "gpu-cloud";
  if (/build|test|lint|repo|npm|compile|inventory/.test(t)) return "github-actions-or-codespace";
  if (/scrape|browser-automation|crawl/.test(t)) return "remote-browser";
  return "local-or-lan-worker";
}

function authorized(request: Request, env: Env): boolean {
  const configured = env.NEXUS_API_KEY ?? "";
  const supplied = request.headers.get("X-Nexus-Key") ?? "";
  return configured.length >= 32 && supplied === configured;
}

function json(value: unknown, status = 200): Response {
  return Response.json(value, {
    status,
    headers: { "Cache-Control": "no-store" }
  });
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    if (url.pathname === "/health" && request.method === "GET") {
      return json({ ok: true, service: "nexus-router", version: 2 });
    }

    if (!authorized(request, env)) return json({ error: "unauthorized" }, 401);

    if (url.pathname === "/route" && request.method === "GET") {
      const task = (url.searchParams.get("task") ?? "").slice(0, 256);
      return json({ task, route: routeTask(task) });
    }

    if (url.pathname === "/submit" && request.method === "POST") {
      if (!env.NEXUS_JOBS) return json({ ok: false, error: "queue-not-bound" }, 503);
      const declared = Number(request.headers.get("Content-Length") ?? 0);
      if (declared > MAX_BODY_BYTES) return json({ error: "payload-too-large" }, 413);

      const raw = await request.text();
      if (new TextEncoder().encode(raw).byteLength > MAX_BODY_BYTES) {
        return json({ error: "payload-too-large" }, 413);
      }

      let body: Record<string, unknown>;
      try {
        body = JSON.parse(raw || "{}") as Record<string, unknown>;
      } catch {
        return json({ error: "invalid-json" }, 400);
      }

      const task = String(body.task ?? "").slice(0, 256);
      const job = {
        id: crypto.randomUUID(),
        task,
        route: routeTask(task),
        createdAt: new Date().toISOString(),
        payload: body.payload ?? null
      };
      await env.NEXUS_JOBS.send(job);
      return json({ ok: true, job }, 202);
    }

    return json({ error: "not-found" }, 404);
  }
};
