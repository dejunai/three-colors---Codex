const EVENT_FIELDS = {
  session_start: [],
  first_objective: [],
  district_transition: ["from_world", "to_world", "real_seconds_elapsed", "game_minutes_elapsed"],
  phase_change: ["day", "new_phase", "npcs_spoken_to_this_phase"],
  day3_bed_reached: ["real_seconds_since_day3_start"],
  session_end: ["total_real_seconds", "final_day", "ended_via"],
};

const STANDARD_FIELDS = ["session_id", "event", "timestamp"];
const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const MAX_BODY_BYTES = 64 * 1024;
const MAX_EVENTS = 32;

function corsHeaders(request) {
  const origin = request.headers.get("Origin") || "";
  const allowed = origin === "https://dejunai.github.io"
    || origin.endsWith(".itch.io")
    || origin.endsWith(".itch.zone")
    || origin.endsWith(".hwcdn.net")
    || origin === "http://localhost:5173"
    || origin === "http://127.0.0.1:5173";
  return {
    "Access-Control-Allow-Origin": allowed ? origin : "https://dejunai.github.io",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

function response(request, status, message) {
  return new Response(message, { status, headers: corsHeaders(request) });
}

function cleanEvent(raw) {
  if (!raw || typeof raw !== "object" || Array.isArray(raw)) throw new Error("event must be an object");
  const eventName = raw.event;
  if (!Object.hasOwn(EVENT_FIELDS, eventName)) throw new Error("unknown event");
  if (typeof raw.session_id !== "string" || !UUID_V4.test(raw.session_id)) throw new Error("invalid session id");
  if (typeof raw.timestamp !== "string" || !Number.isFinite(Date.parse(raw.timestamp))) throw new Error("invalid timestamp");
  const allowed = new Set([...STANDARD_FIELDS, ...EVENT_FIELDS[eventName]]);
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
  if (Object.hasOwn(raw, "new_phase") && !["morning", "noon", "evening", "night"].includes(raw.new_phase)) throw new Error("invalid phase");
  if (Object.hasOwn(raw, "ended_via") && !["closed", "completed"].includes(raw.ended_via)) throw new Error("invalid ending");
  return Object.fromEntries([...allowed].filter((key) => Object.hasOwn(raw, key)).map((key) => [key, raw[key]]));
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") return response(request, 204, null);
    if (request.method !== "POST") return response(request, 405, "Method not allowed");
    if (!request.headers.get("Content-Type")?.toLowerCase().startsWith("application/json")) {
      return response(request, 415, "JSON required");
    }
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

    const now = new Date();
    const date = now.toISOString().slice(0, 10);
    const key = `events/${date}/${crypto.randomUUID()}.json`;
    await env.BUCKET_ONE.put(key, JSON.stringify({ events }), {
      httpMetadata: { contentType: "application/json" },
    });
    return response(request, 204, null);
  },
};
