import worker from "./src/index.js";

const writes = [];
const env = { BUCKET_ONE: { put: async (key, body, options) => writes.push({ key, body, options }) } };
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

const post = (body) => new Request("https://example.test", {
  method: "POST",
  headers: { "Content-Type": "application/json", "Origin": "https://dejunai.github.io" },
  body: JSON.stringify(body),
});

let result = await worker.fetch(post(valid), env);
if (result.status !== 204 || writes.length !== 1) throw new Error("valid batch was not stored");
const stored = JSON.parse(writes[0].body);
if (stored.events[0].from_world !== "estate") throw new Error("stored payload changed");

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
if (result.status !== 204 || writes.length !== 2) throw new Error("valid debrief was not stored");
result = await worker.fetch(post({ events: [{ ...debrief.events[0], town_feel: "free text" }] }), env);
if (result.status !== 400 || writes.length !== 2) throw new Error("invalid debrief choice was accepted");

result = await worker.fetch(new Request("https://example.test", {
  method: "OPTIONS",
  headers: { "Origin": "https://html-classic.itch.zone" },
}), env);
if (result.status !== 204 || result.headers.get("Access-Control-Allow-Origin") !== "https://html-classic.itch.zone") throw new Error("itch.io preflight failed");

console.log("WORKER PASS: strict schema, R2 write, privacy rejection, and CORS preflight");
