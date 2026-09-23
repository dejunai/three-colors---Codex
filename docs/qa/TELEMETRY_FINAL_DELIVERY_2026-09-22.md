# Telemetry final-delivery audit — 2026-09-22

## Verified live findings

Direct D1 queries found 35 non-synthetic sessions at audit time. Only two sessions had ever delivered `day3_bed_reached`, the marker fired when the glass sequence begins. Both also delivered `debrief`. The author separately confirmed reaching the visible localhost debrief more than six times; the absence of those markers and surveys from D1 is therefore evidence of browser delivery loss, not evidence that those runs stopped before the ending.

Session `ae190c59-a9f3-49de-9528-8386fd5d5b2c` used the allowed origin `http://localhost:5173`. Its final recorded actions were Day 3 morning, a conversation with `pickman_resident_04`, and a `town -> estate` transition. It never emitted `day3_bed_reached`. Its earlier events prove that the allowed localhost origin passed CORS. Its missing ending events, combined with the author's confirmed completion of the visible debrief, establish that the browser stopped delivering telemetry near the ending; no continuation appeared under another session id in the reported completion window.

Session `59429204-cd53-4ea2-bf9a-b3905e9b464a` has `page_origin = NULL` throughout, which identifies the successful 43-minute run as native desktop telemetry rather than a browser served from any local port. CORS did not participate in that success.

One itch.io session, `731a32f2-bc5a-442b-9968-377d989e022d`, recorded `day3_bed_reached` and `debrief` but no `session_end`. This is the observed final-delivery defect addressed here.

## Source-traced cause

The second survey answer previously called `playthrough_log.debrief()`, which immediately started an `HTTPRequest`, then called `_town_complete()`, which immediately called `playthrough_log.end()`. The logger permits only one request at a time. While the debrief request was busy, `session_end` remained only in the in-memory buffer and depended on the first request's completion signal to start a second request. Browser navigation or quitting in that interval could preserve `debrief` while losing `session_end`, exactly matching session `731a32f2…`.

There was also no browser `pagehide`, `beforeunload`, or Beacon handling. `NOTIFICATION_WM_CLOSE_REQUEST` was the only close hook; it is not a dependable browser page-teardown delivery mechanism.

A separate source path could skip the survey: glass break sets `state.finished = true` before the survey, and loading that save previously routed straight to `_town_complete()`. That path is now distinguished with the persisted `debrief_completed` dialogue-state flag.

## Changes

- `debrief` and completed `session_end` are constructed together and submitted as one atomic final batch. The batch also retransmits up to 24 recent pending events, recovering a glass marker stranded behind a failed or still-running request; D1's deterministic event keys safely deduplicate repeats.
- Web completion uses `navigator.sendBeacon` with a validated `text/plain` JSON body; the Worker accepts that content type but applies the identical event allowlist and validation. Because `text/plain` is a simple browser request, the Worker also rejects any present `Origin` outside the distribution allowlist before reading or storing the body; originless native clients remain supported.
- A retained `pagehide` callback sends an anonymous `ended_via: closed` event by Beacon for genuine page exits. BFCache page hides are ignored because the game can resume from them. The pause menu's explicit Save-and-Quit and Save-and-Return actions now call the same ending hook; loading again in the same process reactivates the retained session id.
- A save made after glass break but before the survey reopens the survey on load; a completed survey sets `debrief_completed` and does not repeat.

## Verification

- Focused `playthrough_log_flow.gd`, `break_flow.gd`, and `debrief_flow.gd` runs passed under the standard Godot 4.7.2 console build.
- All 35 suites in `tests/run_all_qa.py` passed cleanly.
- The Worker unit test passed its strict-schema, Beacon `text/plain`, D1/R2, idempotency, privacy, and CORS checks.
- A real Chrome page served from `http://127.0.0.1:5173` queued `navigator.sendBeacon`; the local Wrangler Worker accepted it and the exact `session_end` row was read back from local D1. This verifies browser-to-Worker delivery without writing a synthetic event to production.

The unrelated Godot/WASM client timestamp offset remains outside this change.
