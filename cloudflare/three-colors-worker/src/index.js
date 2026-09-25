const EVENT_FIELDS = {
  session_start: [],
  first_objective: [],
  district_transition: ["from_world", "to_world", "real_seconds_elapsed", "game_minutes_elapsed"],
  phase_change: ["day", "new_phase", "npcs_spoken_to_this_phase"],
  conversation: ["npc_id", "topic_id", "coat_state", "world", "day", "phase"],
  day3_bed_reached: ["real_seconds_since_day3_start"],
  debrief: ["town_feel", "time_natural"],
  session_end: ["total_real_seconds", "final_day", "ended_via", "dev_brisk_used"],
};

const STANDARD_FIELDS = ["session_id", "event", "timestamp"];
const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/;
const MAX_BODY_BYTES = 64 * 1024;
const MAX_EVENTS = 32;
const INSERT_EVENT = `INSERT OR IGNORE INTO game_events (
  event_key, session_id, event, timestamp,
  from_world, to_world, real_seconds_elapsed, game_minutes_elapsed,
  day, new_phase, npcs_spoken_to_this_phase,
  real_seconds_since_day3_start, town_feel, time_natural,
  total_real_seconds, final_day, ended_via,
  npc_id, topic_id, coat_state, world, phase,
  dev_brisk_used, page_origin, received_at
) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`;

function isAllowedOrigin(origin) {
  return !origin
    || origin === "https://dejunai.github.io"
    || origin.endsWith(".itch.io")
    || origin.endsWith(".itch.zone")
    || origin.endsWith(".hwcdn.net")
    || origin === "http://localhost:5173"
    || origin === "http://127.0.0.1:5173";
}

function corsHeaders(request) {
  const origin = request.headers.get("Origin") || "";
  return {
    "Access-Control-Allow-Origin": isAllowedOrigin(origin) && origin ? origin : "https://dejunai.github.io",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400",
    "Vary": "Origin",
  };
}

function response(request, status, message) {
  return new Response(message, { status, headers: corsHeaders(request) });
}

function acceptedResponse(request, accepted) {
  return new Response(JSON.stringify({ accepted }), {
    status: 200,
    headers: { ...corsHeaders(request), "Content-Type": "application/json" },
  });
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

async function eventKey(event) {
  const bytes = new TextEncoder().encode(JSON.stringify(event));
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function d1Statements(env, events, origin, receivedAt) {
  return Promise.all(events.map(async (event) => env.DB.prepare(INSERT_EVENT).bind(
    await eventKey(event), event.session_id, event.event, event.timestamp,
    event.from_world ?? null, event.to_world ?? null,
    event.real_seconds_elapsed ?? null, event.game_minutes_elapsed ?? null,
    event.day ?? null, event.new_phase ?? null, event.npcs_spoken_to_this_phase ?? null,
    event.real_seconds_since_day3_start ?? null,
    event.town_feel ?? null, event.time_natural ?? null,
    event.total_real_seconds ?? null, event.final_day ?? null, event.ended_via ?? null,
    event.npc_id ?? null, event.topic_id ?? null, event.coat_state ?? null,
    event.world ?? null, event.phase ?? null,
    event.dev_brisk_used == null ? null : (event.dev_brisk_used ? 1 : 0),
    origin, receivedAt,
  )));
}

export default {
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

    const now = new Date();
    const date = now.toISOString().slice(0, 10);
    const key = `events/${date}/${crypto.randomUUID()}.json`;
    const requestOrigin = request.headers.get("Origin") || null;
    const statements = await d1Statements(env, events, requestOrigin, now.toISOString());
    await Promise.all([
      env.DB.batch(statements),
      env.BUCKET_ONE.put(key, JSON.stringify({ events }), {
        httpMetadata: { contentType: "application/json" },
      }),
    ]);
    return acceptedResponse(request, events.length);
  },
};
