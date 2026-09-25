# Telemetry mid-session stall — root cause and repair evidence

Date: 2026-09-23
Status: repaired, deployed, and verified in production

## Confirmed production pattern

Production D1 session `04703c63-db0d-41e8-85b5-1b04b2e01a2b` contains exactly 32 unique events. Its first row is id 2636 and its last row is id 3160, so those 32 unique events consumed 525 autoincrement ids. That is the cumulative retransmission signature: successful requests repeatedly contained the already accepted prefix, while D1's unique event key suppressed duplicate rows but SQLite still consumed ids for the ignored insert attempts. The final unique event is the Day 2 `town -> room` transition reported in the stall.

The game client sent its entire pending buffer on every ordinary upload. Because it did not retire the accepted prefix, event 33 produced a 33-event request. The Worker contract accepts at most 32 and rejected that and every larger retry atomically with HTTP 400. This explains both the precise stopping point and why later events, including the ending and debrief, could never recover the session.

## Controlled browser reproduction

An isolated Godot 4.7.2 Web export posted one valid `session_start` from `http://localhost:5173` to the production Worker while Chrome DevTools Protocol captured both sides.

- Browser Network observed the CORS preflight and POST reach the Worker and return HTTP 204.
- Godot's `HTTPRequest.request_completed` callback reported `result=6`, `response_code=0`, empty headers, and zero body bytes.
- The production D1 row proved the request itself had succeeded even though Godot classified it as a connection failure.

The same isolated Web export was then pointed at a local endpoint that returned HTTP 200 with `{"accepted":1}`. Godot reported `result=0`, `response_code=200`, the JSON response headers, and 14 body bytes. This confirms the non-empty 200 acknowledgement repairs the Web callback rather than merely changing server presentation.

## Repair

- `cloudflare/three-colors-worker/src/index.js` now returns HTTP 200 and `{"accepted": n}` after both D1 and R2 writes succeed. CORS preflight remains HTTP 204 because it is handled by the browser rather than Godot's `HTTPRequest` callback.
- `scripts/shared/playthrough_log.gd` caps every ordinary batch at 32 events, matching the Worker contract. A valid acknowledgement removes exactly the in-flight prefix and immediately drains the next capped batch.
- The logger now requires both `HTTPRequest.RESULT_SUCCESS` and a 2xx response before retiring events.
- `tests/playthrough_log_flow.gd` covers the 40-pending-event case, exact 32-event retirement, retained failures, and subsequent remainder.
- `cloudflare/three-colors-worker/test.mjs` covers the HTTP 200 acknowledgement count, acceptance at exactly 32, and atomic rejection at 33.
- `tests/run_all_qa.py` now includes the telemetry suite so this transport contract is part of aggregate QA.

Focused verification passed locally:

- `tests/playthrough_log_flow.gd`
- `cloudflare/three-colors-worker/test.mjs`

## Production verification

After deployment, session `a2cd8722-54bf-4f38-afc7-2a91d4a18010` recorded 36 unique events in 36 consecutive D1 row ids, 4593 through 4628. It also recorded both `debrief` and `session_end`. The consecutive ids show that acknowledged prefixes are being retired rather than retransmitted, and the session crossing 32 events confirms that the former hard stall is gone.

This closes the telemetry mid-session stall. Future Web publishing checks should retain the HTTP 200 acknowledgement and run at least one session beyond 32 events.
