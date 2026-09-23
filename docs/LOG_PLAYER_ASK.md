# THREE COLORS OF MADNESS — Anonymous playthrough telemetry — build brief for Codex

## CONTEXT
This is a Godot 4.7 project (GL Compatibility renderer), with Web export as the tester-distribution build. The current TDD is `docs/design/07) Three Colors of Madness — TDD v43.md`; this build brief preserves the original telemetry request while the current-implementation section below records what actually shipped.

**Hard constraint, non-negotiable:** no personal data of any kind. No player name, no account, no device fingerprint, no browser fingerprinting, no IP address collected *in the log payload*, no analytics SDK, no third-party tracking script. The only identifier is a random per-playthrough session id (a v4 UUID or equivalent, generated client-side at New Game). If any implementation choice below would require collecting more than that, stop and flag it rather than proceeding.

## CURRENT IMPLEMENTATION — 2026-09-19

This file began as a build brief. The implementation now differs from its historical task text in these authoritative ways:

- The deployed Worker **dual-writes**: each validated event is inserted into D1 (`three-colors-db`) and each accepted request batch is archived to R2 (`three-colors-logs`). D1 is the queryable store; R2 is the raw verification archive. Deterministic event hashes make D1 retries idempotent.
- The live allowlist is `session_start`, `first_objective`, `district_transition`, `phase_change`, `conversation`, `day3_bed_reached`, `debrief`, and `session_end`. A `conversation` is logged only after a complete authored topic segment and carries `npc_id`, `topic_id`, `coat_state`, `world`, `day`, and `phase`.
- `session_end` also carries `dev_brisk_used`, a sticky boolean that becomes true if F3 enables the temporary developer pace at any point in the playthrough. Toggling F3 back off does not clear it, and its value persists across save/load.
- The pocket watch is built in the Tab/personal-effects menu, but `watch_checked` is **not** implemented in `playthrough_log.gd` or accepted by the Worker.
- Durations are emitted as rounded integer seconds/minutes. The Worker rejects negative or non-numeric values.
- The debrief now follows the glass-shattering ending beat. `day3_bed_reached` retains its historical event name but fires when that final break begins.
- The endpoint remains `https://three-colors-worker.dejunai.workers.dev`; its source of truth is `cloudflare/three-colors-worker/src/index.js`, and the database schema is `cloudflare/three-colors-worker/schema.sql` plus its checked-in upgrades.

Everything below preserves the original request and its evolution. Where it conflicts with this section, this section and the live source win.

## STATUS — this brief is now a historical record, not an open ask
Everything below shipped and was subsequently extended. Two things landed differently than the first draft:
- **Hosting is Cloudflare Worker + D1 + R2.** R2 was deployed first; D1 was added later as the queryable event store while R2 remained the raw batch archive.
- **The two subjective questions, originally OUT OF SCOPE for this task (see below), are now built** as a `debrief` event — see TASK 4, added after this brief's original scope was delivered. They are not free text; they're single-tap choices, matching the rest of this codebase's UI, which has never used a text-entry widget.

## GOAL
Add lightweight, anonymous logging that answers real pacing/design questions by measurement instead of by the author's own feel — the exact motivation for the recent Shift-brisk-speed fix (`main.gd`), which corrected the author's *own* playtesting speed but did nothing to tell us what an actual first-time tester experiences. Log a defined set of events per playthrough, tagged with a random session id, and upload them automatically to a small collection endpoint so the data reaches the author without any manual step from the tester.

## TASK 1 — Session id
- On New Game (not on save/load resume of an existing session), generate a random session id and hold it for the lifetime of that playthrough. Loading a save later in the same playthrough keeps the same id; starting a fresh New Game generates a new one.
- The id is opaque and random — not derived from system time, hardware, IP, or anything else that could correlate two different sessions to the same person. A plain `String` UUID v4 is fine.
- The id is never shown to the player and never written anywhere the player could screenshot/share by accident (not in the notebook, not in a save-file field the player's own tooling might inspect and misread as meaningful — a dedicated internal field is fine).

## TASK 2 — Event log, in-memory buffer
Define an event schema (a flat dictionary is fine — this doesn't need a class hierarchy) with at minimum: `session_id`, `event`, a client wall-clock timestamp, and event-specific fields below. Buffer events in memory and flush them per Task 3 rather than uploading one at a time — a browser tab can close mid-session, so flushing incrementally (not only at the very end) matters more than batching efficiency.

Events to log, mapped to the author's actual questions (see TDD Part Four for the original list) and to existing hook points already in the codebase — this is additive logging at points that already exist, not new game logic:

1. **`session_start`** — fired once at New Game. Fields: none beyond the standard ones.
2. **`first_objective`** — fired once, the first time `state.discover()` or `state.record()` is called in a session (both already exist as effect hooks — see `chapter_one.gd`'s `_interact()` callback and `_estate_observation()`). If "first meaningful objective" should mean something more specific than "first fact recorded," flag it back to the author rather than guessing — this definition is a reasonable default, not a TDD-mandated one.
3. **`district_transition`** — fired on every `_travel()` call that changes `state.world`. Fields: `from_world`, `to_world`, `real_seconds_elapsed` (wall-clock since the previous transition), `game_minutes_elapsed` (`state.clock_minutes` delta since the previous transition).
4. **`phase_change`** — fired whenever `DayClock.phase(state.clock_minutes)` changes value. Fields: `day`, `new_phase`, `npcs_spoken_to_this_phase` (count of distinct entries added to `state.visited` since the previous phase change — reset the counter on each phase change, don't reset `state.visited` itself).
5. **`watch_checked`** — proposed for the Tab-menu pocket watch. The watch now exists, but this event remains unimplemented and is not in the Worker allowlist.
6. **`day3_bed_reached`** — fired when `sleep()` (or wherever Day 3's "turn in for the night" resolves — see `target("sleep", ...)` in `town.gd`'s `_corwin_room()`) succeeds on Day 3 specifically. Fields: `real_seconds_since_day3_start` (wall-clock from the `phase_change` event that first set `day == 3`).
7. **`session_end`** — fired on quit/tab-close if catchable (`NOTIFICATION_WM_CLOSE_REQUEST` or equivalent), and also at any existing "the end" screen. Fields: `total_real_seconds`, `final_day`, `ended_via` (`"closed"` vs `"completed"` vs whatever states are distinguishable), and `dev_brisk_used` (sticky for the playthrough once F3 has enabled the developer pace).

**Deliberately not a new event type:** "did a player miss a scheduled NPC, and what did they try next" does not need live detection. `district_transition` events already carry world + game-clock time, and `dialogue_catalog.gd`'s `slot()` is a pure, deterministic function of `(npc, phase)` — so whether any given NPC was reachable at any logged moment can be reconstructed later by replaying `slot()` against the log, offline. Do not add a "player missed someone" detection mechanic to satisfy this — that would be new gameplay-adjacent logic for a question the existing data can already answer analytically.

**Originally out of scope for this task, since built (see TASK 4):** the two subjective questions in the TDD ("does the town feel alive vs. too large," "does time feel tied to investigation vs. walking") were flagged here as not loggable events needing a separate exit-question mechanism. They now are that mechanism's own event — see TASK 4 below.

## TASK 3 — Upload
- Transport is decided: automatic upload, not a manual "download and send" flow.
- Fire an `HTTPRequest` POST (JSON body) at each event above, or batched every few events / on each `district_transition` — whichever is simpler to implement reliably; either is fine as long as a closed tab doesn't lose the whole session's data. If a request fails (offline, endpoint unreachable), don't block or retry aggressively — drop it or retry once on the next event, but never stall gameplay on network state.
- In-game **Save and return to title** and **Save and quit** offer the same optional two-question debrief before leaving, including a one-tap **Skip debrief and …** action. This early survey records a closed session and does not set story completion; browser tab closure remains non-interactive and uses the `pagehide` Beacon fallback.
- **Endpoint hosting: Cloudflare Worker + D1 + R2.** D1 stores allowlisted event rows for SQL aggregation; R2 stores each accepted batch as `events/YYYY-MM-DD/<uuid>.json` for raw verification. Both writes must succeed before the Worker returns HTTP 204. The Worker accepts strict JSON bodies as `application/json` and the same validated schema as `text/plain` solely for Web `sendBeacon` final delivery.
  - Workers request logging is not persisted by default (unlike a conventional web server's access log), which narrows the IP-at-the-infrastructure-level exposure named in the constraint above without extra configuration — no optional logging/analytics add-on is enabled, and the deployed `src/index.js` never copies request headers, IP, or user-agent into R2.
- Whichever is chosen, confirm CORS is configured correctly for a Web-exported Godot build calling it from an arbitrary hosting origin (itch.io, a personal domain, wherever the Web build ends up served from) before treating this as done.
- Store the endpoint URL as an easily swappable value (an exported variable or a config constant), not hardcoded in multiple places — the author may want to point this at a different account later without a code change.

## TASK 4 — Debrief pairing (added after the above shipped; also built)
Telemetry answers "what did they do." It doesn't answer "what did they think they were doing, and how did it feel." Rather than a free-text survey (this codebase has no text-entry widget anywhere, by design — the interaction idiom throughout is `_panel`/`_button`), this is two single-tap optional questions shown once, right after the Day 3 "close_day" narrative cards and before the town is marked finished:

1. A choice among: "Alive, and hard to fully take in" / "Confusing" / "Too large for the time given" / "Easy enough to navigate" / "Skip".
2. Yes / No / Skip to: "Did the passage of time feel natural while investigating?"

Both answers (or `"skipped"`) are logged as one new event:

8. **`debrief`** — fired once, immediately after the Day 3 bed sequence resolves (same moment `day3_bed_reached` fires; `day3_bed_reached` itself was defined in `playthrough_log.gd` from the start but had never actually been wired to a call site until this task — that gap is now closed alongside this one). Fields: `town_feel` (`"alive"` / `"confusing"` / `"too_large"` / `"easy"` / `"skipped"`), `time_natural` (`"yes"` / `"no"` / `"skipped"`).

Implementation landed in `scripts/chapters/chapter_one_staging.gd`'s `sleep()` (the Day-3-success branch) via two new local functions, `_debrief_town_feel()` and `_debrief_time_natural()`, and in `playthrough_log.gd` via a new `debrief(town_feel, time_natural)` method. The Worker's `EVENT_FIELDS` allowlist and field-value validation (`cloudflare/three-colors-worker/src/index.js`) were extended to match and redeployed.

## ACCEPTANCE / VERIFICATION
Per this project's existing standard, don't just self-report — check source and, where possible, run it:
- Confirm by direct source read that no field anywhere in the log payload or the request itself carries player-identifying data (name, account, device id, IP collected/forwarded intentionally, fingerprinting of any kind) — the only identifier is the random session id.
- Confirm a new session id is generated on New Game and the same id persists across save/load within one playthrough.
- Confirm each event's fields actually populate correctly against a real playthrough (a `district_transition` between two real locations shows sane `real_seconds_elapsed`/`game_minutes_elapsed`, a `phase_change` shows a plausible NPC count, etc.) — don't just confirm the request fires, confirm the payload contents are correct.
- Confirm closing the tab mid-session does not lose previously-flushed events (only whatever hadn't yet been sent should be lost).
- Confirm this adds no player-visible UI, no toast, no interruption — it should be entirely invisible during play.
- Confirm the Worker/R2 endpoint and its CORS configuration actually work from a real Web export, not just localhost.
- Query aggregate data through D1 (`wrangler d1 execute three-colors-db --remote ...`) and use R2 objects for raw-batch verification.
- Confirm the `debrief` panel appears exactly once per completed playthrough, offers "Skip" on both questions, and never blocks reaching the town-complete screen even if both are skipped.

## OUT OF SCOPE (do not touch)
- Any live "you just missed someone" detection or messaging — this is answered by offline analysis of `district_transition` events against `dialogue_catalog.gd`'s existing `slot()`, not new gameplay logic.
- The Tab-menu pocket watch itself has since shipped. Only its proposed `watch_checked` telemetry event remains outside the implemented event schema.
- Anything resembling analytics beyond the fields listed above (no session replay, no heatmaps, no third-party analytics SDK of any kind).
