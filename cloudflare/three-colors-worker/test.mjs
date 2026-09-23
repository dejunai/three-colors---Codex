import worker from "./src/index.js";

const writes = [];
const rows = [];
const env = {
  BUCKET_ONE: { put: async (key, body, options) => writes.push({ key, body, options }) },
  DB: {
    prepare: (sql) => ({ bind: (...values) => ({ sql, values }) }),
    batch: async (statements) => { rows.push(...statements); },
  },
};
const valid = {
  events: [{
    session_id: "12345678-1234-4123-8123-123456789abc",
    event: "district_transition",
    timestamp: "2026-09-13T12:00:00Z",
    from_world: "estate",
    to_world: "town",
    real_seconds_elapsed: 12.5,
    game_minutes_elapsed: 30,
  }],
};

const post = (body, contentType = "application/json") => new Request("https://example.test", {
  method: "POST",
  headers: { "Content-Type": contentType, "Origin": "https://dejunai.github.io" },
  body: JSON.stringify(body),
});

let result = await worker.fetch(post(valid), env);
if (result.status !== 200 || writes.length !== 1 || rows.length !== 1) throw new Error("valid batch was not dual-written");
if ((await result.json()).accepted !== 1) throw new Error("valid batch was not acknowledged with its accepted count");
const stored = JSON.parse(writes[0].body);
if (stored.events[0].from_world !== "estate") throw new Error("stored payload changed");
if (!/^[0-9a-f]{64}$/.test(rows[0].values[0]) || rows[0].values[1] !== valid.events[0].session_id) throw new Error("D1 row key or identity is invalid");

result = await worker.fetch(post({ events: [{ ...valid.events[0], user_agent: "forbidden" }] }), env);
if (result.status !== 400 || writes.length !== 1) throw new Error("unknown identifying field was accepted");

const debrief = { events: [{
  session_id: "12345678-1234-4123-8123-123456789abc",
  event: "debrief",
  timestamp: "2026-09-13T12:01:00Z",
  town_feel: "alive",
  time_natural: "yes",
}] };
result = await worker.fetch(post(debrief), env);
if (result.status !== 200 || writes.length !== 2 || rows.length !== 2) throw new Error("valid debrief was not dual-written");
if (rows[1].values[12] !== "alive" || rows[1].values[13] !== "yes") throw new Error("debrief fields were not mapped to D1");
result = await worker.fetch(post({ events: [{ ...debrief.events[0], town_feel: "free text" }] }), env);
if (result.status !== 400 || writes.length !== 2) throw new Error("invalid debrief choice was accepted");

const conversation = { events: [{
  session_id: "12345678-1234-4123-8123-123456789abc",
  event: "conversation",
  timestamp: "2026-09-13T12:02:00Z",
  npc_id: "mrs_almy",
  topic_id: "crew_omission",
  coat_state: "plain",
  world: "town",
  day: 1,
  phase: "noon",
}] };
result = await worker.fetch(post(conversation), env);
if (result.status !== 200 || writes.length !== 3 || rows.length !== 3) throw new Error("valid conversation was not dual-written");
if (rows[2].values[17] !== "mrs_almy" || rows[2].values[19] !== "plain") throw new Error("conversation fields were not mapped to D1");
result = await worker.fetch(post({ events: [{ ...conversation.events[0], coat_state: "raincoat" }] }), env);
if (result.status !== 400 || writes.length !== 3) throw new Error("invalid coat state was accepted");

const sessionEnd = { events: [{
  session_id: "12345678-1234-4123-8123-123456789abc",
  event: "session_end",
  timestamp: "2026-09-13T12:03:00Z",
  total_real_seconds: 2612,
  final_day: 3,
  ended_via: "completed",
  dev_brisk_used: true,
}] };
result = await worker.fetch(post(sessionEnd), env);
if (result.status !== 200 || writes.length !== 4 || rows.length !== 4) throw new Error("valid session end was not dual-written");
if (rows[3].values[22] !== 1) throw new Error("developer brisk usage was not mapped to D1");
result = await worker.fetch(post({ events: [{ ...sessionEnd.events[0], dev_brisk_used: "yes" }] }), env);
if (result.status !== 400 || writes.length !== 4) throw new Error("non-boolean developer brisk usage was accepted");

const beaconEnd = { events: [{ ...sessionEnd.events[0], timestamp: "2026-09-13T12:04:00Z" }] };
result = await worker.fetch(post(beaconEnd, "text/plain;charset=UTF-8"), env);
if (result.status !== 200 || writes.length !== 5 || rows.length !== 5) throw new Error("Beacon text/plain batch was not accepted");
result = await worker.fetch(post(beaconEnd, "text/html"), env);
if (result.status !== 415 || writes.length !== 5) throw new Error("unsupported content type was accepted");
result = await worker.fetch(new Request("https://example.test", {
  method: "POST",
  headers: { "Content-Type": "text/plain;charset=UTF-8", "Origin": "https://attacker.example" },
  body: JSON.stringify(beaconEnd),
}), env);
if (result.status !== 403 || writes.length !== 5 || rows.length !== 5) throw new Error("Beacon from an unapproved browser origin was accepted");

result = await worker.fetch(new Request("https://example.test", {
  method: "OPTIONS",
  headers: { "Origin": "https://html-classic.itch.zone" },
}), env);
if (result.status !== 204 || result.headers.get("Access-Control-Allow-Origin") !== "https://html-classic.itch.zone") throw new Error("itch.io preflight failed");

const writesBeforeLimitCheck = writes.length;
const rowsBeforeLimitCheck = rows.length;
const maximumBatch = { events: Array.from({ length: 32 }, () => ({ ...valid.events[0] })) };
result = await worker.fetch(post(maximumBatch), env);
if (result.status !== 200 || (await result.json()).accepted !== 32) throw new Error("maximum 32-event batch was not accepted");
if (writes.length !== writesBeforeLimitCheck + 1 || rows.length !== rowsBeforeLimitCheck + 32) throw new Error("maximum batch was not dual-written");
result = await worker.fetch(post({ events: [...maximumBatch.events, valid.events[0]] }), env);
if (result.status !== 400 || writes.length !== writesBeforeLimitCheck + 1 || rows.length !== rowsBeforeLimitCheck + 32) throw new Error("oversized batch was not rejected atomically");

console.log("WORKER PASS: 200 acknowledgement body, 32-event transport contract, strict schema, conversation context, developer-brisk session context, Beacon final delivery, idempotent D1 + R2 dual write, privacy rejection, and CORS preflight");
