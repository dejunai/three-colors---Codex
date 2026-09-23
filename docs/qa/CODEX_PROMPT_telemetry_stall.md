## Prompt for Codex — telemetry silently stops mid-session on a real playthrough

### Symptom (confirmed against production D1, not just reported)

Dejunai played a real session start to finish today: new game → Day 1 → Day 2 →
Day 3 → tunnel → the glass-shattering ending beat → the debrief screen →
"Save and quit" → closed the tab.

Querying the production D1 database directly (`wrangler d1 execute
three-colors-db --remote`) for that session (`session_id =
'04703c63-db0d-41e8-85b5-1b04b2e01a2b'`, started 08:30:12 UTC) shows normal
event traffic for the first ~5 minutes — `session_start`, `first_objective`,
several `conversation` and `district_transition` events — right up through a
`district_transition` to `room` at **08:35:18 UTC, still on Day 2**. After
that timestamp there is nothing. No further `conversation` or
`district_transition` events for the rest of what must have been a much
longer session (Day 2 evening through all of Day 3, the tunnel, the ending),
no `debrief` event, and no `session_end` event at all. The session simply
stops appearing in telemetry roughly 5 minutes in, even though the player
kept going for a long time afterward and the game itself worked correctly
(save/quit succeeded, the debrief displayed on screen).

This is not just "the final beacon on quit didn't fire" — ordinary
mid-session events (`district_transition`, `conversation`) also stopped
being recorded from that point on. Whatever broke, broke the whole pipeline
for the rest of the session, not just the teardown path.

### Relevant files

- `scripts/shared/playthrough_log.gd` — the whole telemetry client. Key parts:
  - `_flush()` / `_request_completed()` (around line 291-316): the normal
    (non-Beacon) send path. A failed request is deliberately left in
    `buffer` rather than retried immediately — the comment says "A failure
    remains buffered until the next event. Never retry in a gameplay loop."
    — so it should self-heal the next time any event is logged, *unless*
    something keeps `request_busy` stuck true past `REQUEST_TIMEOUT_MS`
    (5000ms) without the stale-request recovery branch in `_flush()` ever
    running again, or the `HTTPRequest` node itself is in a bad state.
  - `_ensure_request()` (line ~64): creates one `HTTPRequest` child node
    once and reuses it for the life of the session — worth checking whether
    something can leave it in a state where `request.request(...)` keeps
    returning non-OK, or where `request_completed` stops firing at all
    (e.g. if the node got freed/reparented by some other system, or if
    scene/tree changes during the Day 2→Day 3 transition or the tunnel
    sequence affect it).
  - `_send_web_beacon()` (line ~286): the Web-only `navigator.sendBeacon`
    path used by `complete()`, `close_with_debrief()`, and the `pagehide`
    handler for the final event(s). This is supposed to be robust against
    page teardown specifically because sendBeacon queues the request in the
    browser and returns immediately — but if `JavaScriptBridge.eval(...,
    true)` returns `false` (sendBeacon itself refused, e.g. payload/queue
    limits), the code falls back to `_queue_event()` + a normal
    `HTTPRequest`, which *can* lose a race against the tab actually
    closing.
  - `MAX_BUFFER_SIZE = 300`, `MAX_BEACON_BACKLOG = 24` (Worker's cap is 32
    events per request, per the comment) — worth checking whether the
    buffer silently overflowed and `pop_front()`-evicted events without
    that itself breaking anything downstream.
- `scripts/chapters/chapter_one.gd`:
  - `_finish_exit_debrief()` (~line 568) → calls
    `playthrough_log.close_with_debrief(...)` then `continuation.call()`.
  - `_save_and_quit()` (~line 565) → `staging.exit_debrief(self,"quit",
    _quit_after_debrief)`; `_quit_after_debrief()` calls
    `get_tree().quit()` immediately after the debrief flow finishes. This
    is a plausible source of a *final-beacon-only* race, but does not by
    itself explain the ~5-minute-in silence that starts long before quit.
  - `_continue_exit_without_debrief()` (~line 575) →
    `playthrough_log.end(state,"closed")`.
  - `_notification()` `NOTIFICATION_WM_CLOSE_REQUEST` handler (~line 680) →
    also calls `playthrough_log.end(...)`.
  - `_town_complete()` (~line 963) → `playthrough_log.end(...)`.
- `docs/qa/TELEMETRY_FINAL_DELIVERY_2026-09-22.md` — the write-up from the
  prior telemetry pass (dual D1+R2 write, sendBeacon, pagehide/BFCache
  handling). Read this first: it documents the *intended* design this
  session's behavior is violating, and the source-traced cause of whatever
  the previous gap was — useful context for whether this is a regression of
  that fix or a new, different failure mode.
- `cloudflare/three-colors-worker/src/index.js` — the receiving Worker.
  Worth checking server-side too: does it ever reject a batch outright (bad
  event shape, unknown event type, a validation failure on one event
  poisoning the whole batch), and would such a rejection be silent to the
  client (sendBeacon never reports response status; the normal
  `HTTPRequest` path treats non-2xx as `succeeded := false` and leaves
  everything buffered without logging why).

### What to actually do

1. Read `docs/qa/TELEMETRY_FINAL_DELIVERY_2026-09-22.md` first for context on the existing design intent.
2. Reproduce this live: run the Web export locally (`tools/serve_web.py` /
   `tools/serve.js`, per the TDD), open the browser's Network tab and
   Console *before* pressing play, and do a full Day 1→3 playthrough to the
   real ending, through the tunnel and glass-break beat, into the debrief,
   then Save and Quit. Watch specifically for:
   - Whether POST requests to the telemetry endpoint keep appearing
     throughout play, or stop at some point — and if they stop, what the
     browser Console shows at that moment (a thrown JS error, a Godot
     script error, anything).
   - Whether any `HTTPRequest` node timeout/cancel logging appears.
   - Whether the final `close_with_debrief` request/beacon actually leaves
     the browser at all (Network tab), regardless of whether the server
     ends up recording it.
3. Root-cause it from that live evidence — don't guess from reading the
   code alone. If it reproduces, get an exact "this line does X when Y"
   explanation, the same way the rest of this project's fixes have been
   traced (see `AGENTS.md` / the HCL's verification discipline: nothing
   goes into the fix log without being traced to source or reproduced
   live, not just inferred from plausible code reading).
4. Fix it, and add or update a test in `tests/` that would have caught
   this — a long-session or multi-transition telemetry test if one
   doesn't already exist, since the existing telemetry tests
   (`tests/playthrough_log_flow.gd`, run individually — it is **not**
   currently one of the 35 suites in `tests/run_all_qa.py`) apparently
   didn't catch this failure mode.
5. Write up what you find and fix in the same evidence-backed style as
   this project's other HCL entries: what broke, why (traced, not
   assumed), the exact fix, and how it was verified (live repro passing
   afterward, plus the new/updated test passing). Do not write the HCL or
   TDD entry yourself — hand the write-up back and Claude will
   independently verify it against source before it goes in the log, per
   this project's standing rule that no agent's fix is taken on report
   alone.

### One thing NOT to do

Don't assume the `get_tree().quit()` race in `_quit_after_debrief()` is the
whole story and fix only that. It may be *a* bug, but it cannot explain
telemetry going silent for `conversation`/`district_transition` events
starting ~5 minutes into a session that ran much longer than that. Find the
actual point where sending stopped, not just the last handler in the call
chain.
