var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// src/index.js
var EVENT_FIELDS = {
  session_start: [],
  first_objective: [],
  district_transition: ["from_world", "to_world", "real_seconds_elapsed", "game_minutes_elapsed"],
  phase_change: ["day", "new_phase", "npcs_spoken_to_this_phase"],
  conversation: ["npc_id", "topic_id", "coat_state", "world", "day", "phase"],
  day3_bed_reached: ["real_seconds_since_day3_start"],
  debrief: ["town_feel", "time_natural"],
  session_end: ["total_real_seconds", "final_day", "ended_via", "dev_brisk_used"]
};
var STANDARD_FIELDS = ["session_id", "event", "timestamp"];
var UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
var MAX_BODY_BYTES = 64 * 1024;
var MAX_EVENTS = 32;
var INSERT_EVENT = `INSERT OR IGNORE INTO game_events (
  event_key, session_id, event, timestamp,
  from_world, to_world, real_seconds_elapsed, game_minutes_elapsed,
  day, new_phase, npcs_spoken_to_this_phase,
  real_seconds_since_day3_start, town_feel, time_natural,
  total_real_seconds, final_day, ended_via,
  npc_id, topic_id, coat_state, world, phase,
  dev_brisk_used, page_origin, received_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;
function isAllowedOrigin(origin) {
  return !origin || origin === "https://dejunai.github.io" || origin.endsWith(".itch.io") || origin.endsWith(".itch.zone") || origin.endsWith(".hwcdn.net") || origin === "http://localhost:5173" || origin === "http://127.0.0.1:5173";
}
__name(isAllowedOrigin, "isAllowedOrigin");
function corsHeaders(request) {
  const origin = request.headers.get("Origin") || "";
  return {
    "Access-Control-Allow-Origin": isAllowedOrigin(origin) && origin ? origin : "https://dejunai.github.io",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin"
  };
}
__name(corsHeaders, "corsHeaders");
function response(request, status, message) {
  return new Response(message, { status, headers: corsHeaders(request) });
}
__name(response, "response");
function cleanEvent(raw) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) throw new Error("event must be an object");
  const eventName = raw.event;
  if (!Object.hasOwn(EVENT_FIELDS, eventName)) throw new Error("unknown event");
  if (typeof raw.session_id !== "string" || !UUID_V4.test(raw.session_id)) throw new Error("invalid session id");
  if (typeof raw.timestamp !== "string" || !Number.isFinite(Date.parse(raw.timestamp))) throw new Error("invalid timestamp");
  const allowed = /* @__PURE__ */ new Set([...STANDARD_FIELDS, ...EVENT_FIELDS[eventName]]);
  for (const key of Object.keys(raw)) {
    if (!allowed.has(key)) throw new Error("unknown field");
  }
  for (const key of EVENT_FIELDS[eventName]) {
    if (!Object.hasOwn(raw, key)) throw new Error("missing field");
  }
  for (const key of ["real_seconds_elapsed", "game_minutes_elapsed", "real_seconds_since_day3_start", "total_real_seconds"]) {
    if (Object.hasOwn(raw, key) && (typeof raw[key] !== "number" || !Number.isFinite(raw[key]) || raw[key] < 0)) throw new Error("invalid duration");
  }
  for (const key of ["day", "final_day", "npcs_spoken_to_this_phase"]) {
    if (Object.hasOwn(raw, key) && (!Number.isInteger(raw[key]) || raw[key] < 0)) throw new Error("invalid count");
  }
  for (const key of ["from_world", "to_world"]) {
    if (Object.hasOwn(raw, key) && (typeof raw[key] !== "string" || !/^[a-z0-9_]{1,32}$/.test(raw[key]))) throw new Error("invalid world");
  }
  for (const key of ["npc_id", "topic_id", "world"]) {
    if (Object.hasOwn(raw, key) && (typeof raw[key] !== "string" || !/^[a-z0-9_]{1,64}$/.test(raw[key]))) throw new Error("invalid identifier");
  }
  if (Object.hasOwn(raw, "coat_state") && !["police", "plain"].includes(raw.coat_state)) throw new Error("invalid coat_state");
  if (Object.hasOwn(raw, "phase") && !["morning", "noon", "evening", "night"].includes(raw.phase)) throw new Error("invalid phase");
  if (Object.hasOwn(raw, "new_phase") && !["morning", "noon", "evening", "night"].includes(raw.new_phase)) throw new Error("invalid phase");
  if (Object.hasOwn(raw, "ended_via") && !["closed", "completed"].includes(raw.ended_via)) throw new Error("invalid ending");
  if (Object.hasOwn(raw, "town_feel") && !["alive", "confusing", "too_large", "easy", "skipped"].includes(raw.town_feel)) throw new Error("invalid town_feel");
  if (Object.hasOwn(raw, "time_natural") && !["yes", "no", "skipped"].includes(raw.time_natural)) throw new Error("invalid time_natural");
  if (Object.hasOwn(raw, "dev_brisk_used") && typeof raw.dev_brisk_used !== "boolean") throw new Error("invalid dev_brisk_used");
  return Object.fromEntries([...allowed].filter((key) => Object.hasOwn(raw, key)).map((key) => [key, raw[key]]));
}
__name(cleanEvent, "cleanEvent");
async function eventKey(event) {
  const bytes = new TextEncoder().encode(JSON.stringify(event));
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}
__name(eventKey, "eventKey");
async function d1Statements(env, events, origin, receivedAt) {
  return Promise.all(events.map(async (event) => env.DB.prepare(INSERT_EVENT).bind(
    await eventKey(event),
    event.session_id,
    event.event,
    event.timestamp,
    event.from_world ?? null,
    event.to_world ?? null,
    event.real_seconds_elapsed ?? null,
    event.game_minutes_elapsed ?? null,
    event.day ?? null,
    event.new_phase ?? null,
    event.npcs_spoken_to_this_phase ?? null,
    event.real_seconds_since_day3_start ?? null,
    event.town_feel ?? null,
    event.time_natural ?? null,
    event.total_real_seconds ?? null,
    event.final_day ?? null,
    event.ended_via ?? null,
    event.npc_id ?? null,
    event.topic_id ?? null,
    event.coat_state ?? null,
    event.world ?? null,
    event.phase ?? null,
    event.dev_brisk_used == null ? null : event.dev_brisk_used ? 1 : 0,
    origin,
    receivedAt
  )));
}
__name(d1Statements, "d1Statements");
var src_default = {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "";
    if (!isAllowedOrigin(origin)) return response(request, 403, "Origin not allowed");
    if (request.method === "OPTIONS") return response(request, 204, null);
    if (request.method !== "POST") return response(request, 405, "Method not allowed");
    const contentType = request.headers.get("Content-Type")?.toLowerCase() || "";
    const isJson = contentType.startsWith("application/json");
    const isBeacon = contentType.startsWith("text/plain");
    if (!isJson && !isBeacon) return response(request, 415, "JSON required");
    const declaredLength = Number(request.headers.get("Content-Length") || 0);
    if (declaredLength > MAX_BODY_BYTES) return response(request, 413, "Payload too large");
    let payload;
    try {
      const text = await request.text();
      if (new TextEncoder().encode(text).byteLength > MAX_BODY_BYTES) return response(request, 413, "Payload too large");
      payload = JSON.parse(text);
    } catch {
      return response(request, 400, "Invalid JSON");
    }
    if (!payload || Object.keys(payload).length !== 1 || !Array.isArray(payload.events) || payload.events.length < 1 || payload.events.length > MAX_EVENTS) {
      return response(request, 400, "Invalid event batch");
    }
    let events;
    try {
      events = payload.events.map(cleanEvent);
    } catch {
      return response(request, 400, "Invalid event");
    }
    const now = /* @__PURE__ */ new Date();
    const date = now.toISOString().slice(0, 10);
    const key = `events/${date}/${crypto.randomUUID()}.json`;
    const requestOrigin = request.headers.get("Origin") || null;
    const statements = await d1Statements(env, events, requestOrigin, now.toISOString());
    await Promise.all([
      env.DB.batch(statements),
      env.BUCKET_ONE.put(key, JSON.stringify({ events }), {
        httpMetadata: { contentType: "application/json" }
      })
    ]);
    return response(request, 204, null);
  }
};

// ../../../../AppData/Local/Microsoft/WinGet/Packages/OpenJS.NodeJS.LTS_Microsoft.Winget.Source_8wekyb3d8bbwe/node-v24.19.0-win-x64/node_modules/wrangler/templates/middleware/middleware-ensure-req-body-drained.ts
var drainBody = /* @__PURE__ */ __name(async (request, env, _ctx, middlewareCtx) => {
  try {
    return await middlewareCtx.next(request, env);
  } finally {
    try {
      if (request.body !== null && !request.bodyUsed) {
        const reader = request.body.getReader();
        while (!(await reader.read()).done) {
        }
      }
    } catch (e) {
      console.error("Failed to drain the unused request body.", e);
    }
  }
}, "drainBody");
var middleware_ensure_req_body_drained_default = drainBody;

// ../../../../AppData/Local/Microsoft/WinGet/Packages/OpenJS.NodeJS.LTS_Microsoft.Winget.Source_8wekyb3d8bbwe/node-v24.19.0-win-x64/node_modules/wrangler/templates/middleware/middleware-miniflare3-json-error.ts
function reduceError(e) {
  return {
    name: e?.name,
    message: e?.message ?? String(e),
    stack: e?.stack,
    cause: e?.cause === void 0 ? void 0 : reduceError(e.cause)
  };
}
__name(reduceError, "reduceError");
var jsonError = /* @__PURE__ */ __name(async (request, env, _ctx, middlewareCtx) => {
  try {
    return await middlewareCtx.next(request, env);
  } catch (e) {
    const error = reduceError(e);
    const body = JSON.stringify(error);
    const headers = {
      "Content-Type": "application/json",
      "MF-Experimental-Error-Stack": "true"
    };
    const encoded = encodeURIComponent(body);
    if (encoded.length <= 8192) {
      headers["MF-Experimental-Error-Stack-Payload"] = encoded;
    }
    return new Response(body, { status: 500, headers });
  }
}, "jsonError");
var middleware_miniflare3_json_error_default = jsonError;

// .wrangler/tmp/bundle-sgwQ0G/middleware-insertion-facade.js
var __INTERNAL_WRANGLER_MIDDLEWARE__ = [
  middleware_ensure_req_body_drained_default,
  middleware_miniflare3_json_error_default
];
var middleware_insertion_facade_default = src_default;

// ../../../../AppData/Local/Microsoft/WinGet/Packages/OpenJS.NodeJS.LTS_Microsoft.Winget.Source_8wekyb3d8bbwe/node-v24.19.0-win-x64/node_modules/wrangler/templates/middleware/common.ts
var __facade_middleware__ = [];
function __facade_register__(...args) {
  __facade_middleware__.push(...args.flat());
}
__name(__facade_register__, "__facade_register__");
function __facade_invokeChain__(request, env, ctx, dispatch, middlewareChain) {
  const [head, ...tail] = middlewareChain;
  const middlewareCtx = {
    dispatch,
    next(newRequest, newEnv) {
      return __facade_invokeChain__(newRequest, newEnv, ctx, dispatch, tail);
    }
  };
  return head(request, env, ctx, middlewareCtx);
}
__name(__facade_invokeChain__, "__facade_invokeChain__");
function __facade_invoke__(request, env, ctx, dispatch, finalMiddleware) {
  return __facade_invokeChain__(request, env, ctx, dispatch, [
    ...__facade_middleware__,
    finalMiddleware
  ]);
}
__name(__facade_invoke__, "__facade_invoke__");

// .wrangler/tmp/bundle-sgwQ0G/middleware-loader.entry.ts
var __Facade_ScheduledController__ = class ___Facade_ScheduledController__ {
  constructor(scheduledTime, cron, noRetry) {
    this.scheduledTime = scheduledTime;
    this.cron = cron;
    this.#noRetry = noRetry;
  }
  scheduledTime;
  cron;
  static {
    __name(this, "__Facade_ScheduledController__");
  }
  #noRetry;
  noRetry() {
    if (!(this instanceof ___Facade_ScheduledController__)) {
      throw new TypeError("Illegal invocation");
    }
    this.#noRetry();
  }
};
function wrapExportedHandler(worker) {
  if (__INTERNAL_WRANGLER_MIDDLEWARE__ === void 0 || __INTERNAL_WRANGLER_MIDDLEWARE__.length === 0) {
    return worker;
  }
  for (const middleware of __INTERNAL_WRANGLER_MIDDLEWARE__) {
    __facade_register__(middleware);
  }
  const fetchDispatcher = /* @__PURE__ */ __name(function(request, env, ctx) {
    if (worker.fetch === void 0) {
      throw new Error("Handler does not export a fetch() function.");
    }
    return worker.fetch(request, env, ctx);
  }, "fetchDispatcher");
  return {
    ...worker,
    fetch(request, env, ctx) {
      const dispatcher = /* @__PURE__ */ __name(function(type, init) {
        if (type === "scheduled" && worker.scheduled !== void 0) {
          const controller = new __Facade_ScheduledController__(
            Date.now(),
            init.cron ?? "",
            () => {
            }
          );
          return worker.scheduled(controller, env, ctx);
        }
      }, "dispatcher");
      return __facade_invoke__(request, env, ctx, dispatcher, fetchDispatcher);
    }
  };
}
__name(wrapExportedHandler, "wrapExportedHandler");
function wrapWorkerEntrypoint(klass) {
  if (__INTERNAL_WRANGLER_MIDDLEWARE__ === void 0 || __INTERNAL_WRANGLER_MIDDLEWARE__.length === 0) {
    return klass;
  }
  for (const middleware of __INTERNAL_WRANGLER_MIDDLEWARE__) {
    __facade_register__(middleware);
  }
  return class extends klass {
    #fetchDispatcher = /* @__PURE__ */ __name((request, env, ctx) => {
      this.env = env;
      this.ctx = ctx;
      if (super.fetch === void 0) {
        throw new Error("Entrypoint class does not define a fetch() function.");
      }
      return super.fetch(request);
    }, "#fetchDispatcher");
    #dispatcher = /* @__PURE__ */ __name((type, init) => {
      if (type === "scheduled" && super.scheduled !== void 0) {
        const controller = new __Facade_ScheduledController__(
          Date.now(),
          init.cron ?? "",
          () => {
          }
        );
        return super.scheduled(controller);
      }
    }, "#dispatcher");
    fetch(request) {
      return __facade_invoke__(
        request,
        this.env,
        this.ctx,
        this.#dispatcher,
        this.#fetchDispatcher
      );
    }
  };
}
__name(wrapWorkerEntrypoint, "wrapWorkerEntrypoint");
var WRAPPED_ENTRY;
if (typeof middleware_insertion_facade_default === "object") {
  WRAPPED_ENTRY = wrapExportedHandler(middleware_insertion_facade_default);
} else if (typeof middleware_insertion_facade_default === "function") {
  WRAPPED_ENTRY = wrapWorkerEntrypoint(middleware_insertion_facade_default);
}
var middleware_loader_entry_default = WRAPPED_ENTRY;
export {
  __INTERNAL_WRANGLER_MIDDLEWARE__,
  middleware_loader_entry_default as default
};
//# sourceMappingURL=index.js.map
