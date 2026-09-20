# Pacing and cross-file consistency audit — 2026-09-20

Requested by Dejunai: read the design docs, the major `/docs` files, the `/dialogue` `/object` `/portal` flat files and the scripts, and explain why the playable slice — originally scoped at roughly 30 minutes — is now measuring 45–60 minutes with playtesters, plus flag any other gaps/inconsistencies. Performed against live HEAD `252e3442e31f0d6f24defdce3e92b76fc13d9049` (clean working tree), cross-checked by actually running the project's own Godot test suites, not just reading prose.

## Bottom line on the 30 → 45–60 minute question

**Per Dejunai: 30 minutes was always a target, not a ceiling — exceeding it because players engaged more than expected is a good sign, not a regression.** The analysis below supports that reading: the overage tracks real content growth and real engagement, not scope creep or a pacing defect nobody noticed.

**There is also no broken promise here — there's a retired number nobody replaced.** "30 minutes" was never a target for *this* slice. It was the target for a single-day, single-location opening (estate → precinct → Almy) written into `docs/qa/DAY_ONE_PACING_REVIEW.md` on 9 September, when the corpus was roughly 29 NPCs / 135 topics and Chapter One had no Day 2, no Day 3, no waterfront, no contiguous town exterior, and no service-passage/glass-break ending. That review's own words: *"Do not add districts, art, another investigation system, or enough mandatory reading to manufacture thirty minutes."* It was a design constraint on the opening beat, not a runtime promise for the whole build.

Since then the slice's scope roughly tripled by every measure that exists on disk:

| | 9 Sep (pacing review baseline) | 12 Sep (TDD v21) | Now (live, 20 Sep) |
|---|---|---|---|
| NPCs | ~29 | 35 | **71** |
| Dialogue topics | ~135 | 217 | **449** |
| Voiced instrument lines | — | 455 | **723** |
| Enacted days | 1 (Day 1 only; Day 2 was a montage) | 1 | **3** |
| Districts | estate + Pickman St. | + business/upper/lower | + **waterfront**, fully walkable contiguous exterior |
| Ending | none (slice just stopped) | none | **steward pantry lead → service passage → tunnel stealth/combat → glass-shattering break** |

None of that growth is a defect — it's exactly what `README.md` and `docs/PLAYTEST.md` now say out loud: *"human playtime is measured through cold playtests and anonymous telemetry rather than promised as a fixed duration."* `README.md` line 11 explicitly retires the last hard numbers that ever existed (the original opener's "3.1–3.6/6.6–7.8 minute" pacing-probe figures) as describing *only* that original opener, not the present three-day slice. The team already stopped promising a duration — but nothing ever stated a *new* one, which is why "30 minutes" is still the number sitting in your head. That's the actual gap: not a broken target, a retired one with no replacement written down anywhere.

Given the Design Bible's own stated target for the *complete* Chapter One is 5–7 hours (`design/0) ... Design Bible v17.md`, "Runtime"), a 45–60 minute slice that stops well short of the fatal ending (per `DOC_SYNC_INCONSISTENCIES.md` item 2, the slice deliberately stops at the ontological crack, before "the entity, Constance's voice and Walter's death") is proportionate, not bloated. If anything it's on the short side of where a ~15% content-complete fragment of a 5–7 hour chapter would land.

## The mechanical amplifier, already diagnosed, still open

Separate from content volume, there's a real, previously-identified pacing bug that would make *any* size of slice feel longer than intended, and it's still unresolved:

- `scripts/shared/day_clock.gd`: `TRAVEL_MINUTES = 30.0` — every district crossing costs a flat 30 in-world minutes, regardless of distance.
- Dialogue's own default cost is `DEFAULT_MINUTES = 3.0` (most `TIME:` overrides in the corpus run 5–9; see distribution below) — roughly **10x cheaper** than one district crossing.
- A passive real-time tick (`chapter_one.gd::tick_world()` → `DayClock.advance(state, delta*DayClock.WANDER_RATE)`, `WANDER_RATE = 5.0/60.0`) advances the game clock 5 minutes per real minute just from being in the free-roam world, independent of anything the player does.

`docs/design/07) ... TDD v43.md` (Part Four) already calls this "open, diagnosed, no solution chosen," and today's `docs/qa/PERPLEXITY_REVIEW_TODO.md` re-confirms the same numbers and explicitly defers it: *"flagging for the next cold-playtest pass rather than queuing a code change now."* You now have that cold-playtest data (the 45–60 minute figures). That's the signal this item was waiting on — it's reasonable to treat it as ready to act on rather than defer again.

Note this is a **game-clock** effect, not directly a **real-world-minutes** effect — but it matters here because it's what makes districts feel far apart and discourages backtracking, which pushes players toward exhausting each district fully before leaving (more dialogue read per visit) rather than making short efficient trips. That behavioral pressure is a plausible contributor to real playtime beyond pure content volume, though nothing in the repo yet correlates it against the actual D1 telemetry (`real_seconds_elapsed` per `district_transition` — see Follow-up below).

## Live verification run this pass

Ran the maintained suite fresh against current HEAD rather than trusting dated docs:

- `python tests/run_all_qa.py` — **all 13 aggregate suites pass clean**, including `break_flow` (full steward → glass-break path).
- Also ran individually, all clean: `dialogue_catalog_flow` (71 NPCs / 449 topics, confirmed live), `test_placement_audit` (62 NPCs, 0 coordinate collisions), `speakeasy_flow` (including the bar-eavesdropping scene that was broken as of the 19th), `pocket_watch_flow`, `playthrough_log_flow`, `debrief_flow`, **and `town_expansion_flow`**.

Your "rock solid" assessment from the speedrun holds up against the automated suite too — nothing is currently broken.

## One stale doc claim found

`docs/qa/TDD_PENDING_NOTES.md`'s prose still lists `tests/town_expansion_flow.gd` under "Still open, carried forward" (needing a fix to stop special-casing the `lower` hub's dead `route_lower` lookup). That's no longer true: `git log` shows the fix landed 16 September (`1bf452c`, "town tests seperated"), and the suite passes clean right now. The file's own banner already warns "no longer a current issue list, retain only as provenance" — so this isn't a trap for anyone following the banner's instruction — but it's exactly the kind of literal claim `docs/DOC_SYNC_INCONSISTENCIES.md`'s 19 September audit was built to catch, and it didn't catch this one because it only diffed the Bible/TDD against source, not the holding-pen file. Low stakes, easy fix: either delete the stale bullet or fold a one-line "resolved 9/16" note into it.

## Flat-file grammar cross-check

Cross-referenced every `GATE:` field/function used in `objects/*.object` and `portals/*.portal` against the actual supported vocabulary in `object_runtime.gd::make_context()` and `portal_runtime.gd::make_context()`. Everything resolves — no orphaned or unknown identifiers in the live content files. This corroborates today's Perplexity-review fixes (unknown-name `push_error`, exact numeric equality for `day = N`, include-cycle guard) rather than finding something new past them — the flat-file layer is clean as of right now.

## What's *not* answered by anything on disk

- No document states a current total-playtime target for the three-day/waterfront/ending slice as it now stands — worth writing one down explicitly (even a range) once you're ready to stop treating "no fixed duration" as sufficient, if only so the next person (or your own memory in six months) doesn't reach for "30 minutes" again.
- Nothing in the repo reconciles the real playtester telemetry (your 45–60 minute figures) against `district_transition`/`conversation` D1 rows — `cloudflare/three-colors-worker/queries.sql` has the starter aggregate queries but no saved output. Worth a `wrangler d1 execute` pass to see how much of the real-time total is travel vs. conversation vs. the tunnel encounter specifically — that would settle whether the travel/conversation scale mismatch above is worth fixing now or is a minor contributor next to sheer content volume.

## Recommendation

Don't cut content to chase "30 minutes" — that number was scoped to a fragment of what currently exists and the team already (correctly) stopped promising a fixed duration. Two concrete next steps, both cheap: (1) pick a direction on the travel/conversation time-cost mismatch now that real telemetry backs the decision, per the TDD's own deferred item; (2) write down a replacement duration statement (or an explicit "we don't promise one, here's the observed range") somewhere durable — `README.md` or `docs/PLAYTEST.md` — so 45–60 minutes becomes the documented reality instead of a surprise against a retired number.
