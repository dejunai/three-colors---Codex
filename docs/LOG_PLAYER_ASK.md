# THREE COLORS OF MADNESS — Anonymous playthrough telemetry — build brief for Codex

## CONTEXT
This is a Godot 4.7 project (GL Compatibility renderer), Web export (HTML5) as the tester-distribution build — no installer, by design, which is also exactly why this is needed: there is currently no way to see what an external tester actually did during a session. The TDD (`docs/design/7) Three Colors of Madness - TDD v21.md`, Part Four, "Playthrough telemetry") has the full design discussion and reasoning behind every choice below; where this brief is thinner than that section, the TDD is the fuller record, not a contradiction.

**Hard constraint, non-negotiable:** no personal data of any kind. No player name, no account, no device fingerprint, no browser fingerprinting, no IP address collected *in the log payload*, no analytics SDK, no third-party tracking script. The only identifier is a random per-playthrough session id (a v4 UUID or equivalent, generated client-side at New Game). If any implementation choice below would require collecting more than that, stop and flag it rather than proceeding.

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
5. **`watch_checked`** — fired when the player uses the Tab-menu pocket watch (TDD Part Six, Stage 5 — not built yet as of this writing). Fields: `day`, `phase`, `game_minutes`. **This event is a no-op until the pocket watch exists; add the log call when that feature is built, not before.**
6. **`day3_bed_reached`** — fired when `sleep()` (or wherever Day 3's "turn in for the night" resolves — see `target("sleep", ...)` in `town.gd`'s `_corwin_room()`) succeeds on Day 3 specifically. Fields: `real_seconds_since_day3_start` (wall-clock from the `phase_change` event that first set `day == 3`).
7. **`session_end`** — fired on quit/tab-close if catchable (`NOTIFICATION_WM_CLOSE_REQUEST` or equivalent), and also at any existing "the end" screen. Fields: `total_real_seconds`, `final_day`, `ended_via` (`"closed"` vs `"completed"` vs whatever states are distinguishable).

**Deliberately not a new event type:** "did a player miss a scheduled NPC, and what did they try next" does not need live detection. `district_transition` events already carry world + game-clock time, and `dialogue_catalog.gd`'s `slot()` is a pure, deterministic function of `(npc, phase)` — so whether any given NPC was reachable at any logged moment can be reconstructed later by replaying `slot()` against the log, offline. Do not add a "player missed someone" detection mechanic to satisfy this — that would be new gameplay-adjacent logic for a question the existing data can already answer analytically.

**Also deliberately out of scope for this task:** the two subjective questions in the TDD ("does the town feel alive vs. too large," "does time feel tied to investigation vs. walking") are not loggable events — they need a short exit question to testers, separate from this telemetry system. Not part of this ask; the author will handle that separately (a simple end-of-session prompt, or an external form).

## TASK 3 — Upload
- Transport is decided: automatic upload, not a manual "download and send" flow.
- Fire an `HTTPRequest` POST (JSON body) at each event above, or batched every few events / on each `district_transition` — whichever is simpler to implement reliably; either is fine as long as a closed tab doesn't lose the whole session's data. If a request fails (offline, endpoint unreachable), don't block or retry aggressively — drop it or retry once on the next event, but never stall gameplay on network state.
- **Endpoint hosting is open — the author has a Cloudflare account and several other webserver accounts, so pick whatever's least effort to stand up and maintain, and confirm the choice before building against it.** Reasonable options, roughly in order of expected setup effort:
  1. A Cloudflare Worker, receiving the POST and writing to KV, D1, or R2. No server to patch, generous free tier, and — relevant to the privacy constraint above — Workers request logging is not persisted by default (unlike a conventional web server's access log), which narrows the IP-at-the-infrastructure-level exposure without extra configuration.
  2. A small endpoint on one of the author's existing webserver accounts (a short PHP or Node script appending JSON lines to a file, or inserting into a database) — viable if any of those accounts already has an easy path to a script + persistent storage, but note that ordinary web server software typically logs the caller's IP in its own access logs by default; if this path is chosen, either disable access logging for that endpoint specifically or accept that tradeoff explicitly.
  3. Anything else already familiar to Codex that meets the same bar (no server maintenance burden, no persistent IP logging by default, reachable over plain HTTPS from a Web-exported Godot build with no CORS surprises).
- Whichever is chosen, confirm CORS is configured correctly for a Web-exported Godot build calling it from an arbitrary hosting origin (itch.io, a personal domain, wherever the Web build ends up served from) before treating this as done.
- Store the endpoint URL as an easily swappable value (an exported variable or a config constant), not hardcoded in multiple places — the author may want to point this at a different account later without a code change.

## ACCEPTANCE / VERIFICATION
Per this project's existing standard, don't just self-report — check source and, where possible, run it:
- Confirm by direct source read that no field anywhere in the log payload or the request itself carries player-identifying data (name, account, device id, IP collected/forwarded intentionally, fingerprinting of any kind) — the only identifier is the random session id.
- Confirm a new session id is generated on New Game and the same id persists across save/load within one playthrough.
- Confirm each event's fields actually populate correctly against a real playthrough (a `district_transition` between two real locations shows sane `real_seconds_elapsed`/`game_minutes_elapsed`, a `phase_change` shows a plausible NPC count, etc.) — don't just confirm the request fires, confirm the payload contents are correct.
- Confirm closing the tab mid-session does not lose previously-flushed events (only whatever hadn't yet been sent should be lost).
- Confirm this adds no player-visible UI, no toast, no interruption — it should be entirely invisible during play.
- Confirm the endpoint choice and CORS configuration actually work from a real Web export, not just localhost.
- Report back whichever hosting option was chosen and why, and hand the author whatever access/dashboard they need to actually read the collected logs afterward.

## OUT OF SCOPE (do not touch)
- The two subjective exit-survey questions — not telemetry, handled separately by the author.
- Any live "you just missed someone" detection or messaging — this is answered by offline analysis of `district_transition` events against `dialogue_catalog.gd`'s existing `slot()`, not new gameplay logic.
- The Tab-menu pocket watch itself (TDD Part Six, Stage 5) — build `watch_checked`'s log call when that feature lands, don't build the watch as part of this task.
- Anything resembling analytics beyond the fields listed above (no session replay, no heatmaps, no third-party analytics SDK of any kind).
