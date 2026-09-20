# Perplexity Chapter One Review: Actionable Follow-Up

Perplexity ran a document-based analysis of the Chapter One route (Design Bible, TDD, README, ARCHITECTURE, object/portal grammar references, the Dialogue Authoring Reference, and the current glass-break material) on 2026-09-20. Its findings were cross-checked against the actual source in this repo, not just the docs, before anything below was accepted as a real task. Several of its High priority player-facing risks turned out to already be handled in the shipped code; those are recorded at the bottom as verified and closed rather than left open. What follows are the findings that survived verification.

## Confirmed, actionable

- [ ] Object-grammar unknown-name silent failure (real bug-shaped gap). dialogue_lang.gd's _evaluate_cmp calls push_error(Unknown dialogue gate field/function ...) when a GATE references a name that doesn't resolve. object_lang.gd's equivalent _evaluate_cmp has no such check; an unknown field or function in an .object GATE just falls through to false with zero warning, silently making a branch permanently unreachable. Fix: add the same push_error path to object_lang.gd, matching dialogue's behavior, or document why the asymmetry is intentional if it turns out to be.

- [ ] day = N and other numeric GATEs use substring matching, not numeric equality. Confirmed in both dialogue_lang.gd:485 and the mirrored block in object_lang.gd: left.contains(right) or right.contains(left) for = and !=. day = 3 would match a resolved value of 13 (string 13 contains 3). No practical impact yet since the slice tops out at day 3, but it's a footgun for future content. Fix: add a linter/validation pass that warns on = or != against known-numeric fields (day, steward_visits, etc.), or give numeric fields a dedicated numeric-equality comparison path instead of falling through to string substring logic.

- [ ] No include-cycle guard in dialogue_runtime.gd load_npc. Traced the function: _cache[path] is only written after includes are fully resolved, not before recursion starts. A genuine A INCLUDE B, B INCLUDE A cycle would recurse forever before the cache could break it: unbounded recursion / stack overflow, not a clean parse error. No such cycle exists in current content as far as traced, but nothing prevents one being authored later. Fix: track an in-progress path set per top-level load_npc call and raise a normal parse error on re-entry, the same way object_lang.gd should for unknown names above.

## Optional / lower priority

- [ ] midday vs noon vocabulary split: document more visibly. Schedules are authored with midday; GATE: clauses must use noon (the actual runtime phase value). dialogue_catalog.gd already translates between them correctly for scheduling (midday if phase == noon else phase), so this isn't a live bug, but a GATE: phase = midday typo would silently never match (known field, mismatched value, no error). Worth a parser-level warning if a GATE clause uses the raw string midday, since that's never valid on that side.

- [ ] Conversation-vs-travel time tuning. Confirmed the numbers Perplexity cited: district travel costs a flat DayClock.advance(state, 30.0) minutes (chapter_one.gd:744) while individual dialogue defaults to a much smaller TIME cost. Whether this needs rebalancing is a playtest-feel question, not a bug; flagging for the next cold-playtest pass rather than queuing a code change now.


## Verified and already handled (no action needed)

These were Perplexity's High priority player-facing risks. Traced against the actual running code; all three already do what the report recommended.

- Sleep-gate ambiguity: using the bed before glass_broken already shows an explicit panel (There's still work to do) followed by the exact current objective text (chapter_one_staging.gd). Not silent.
- Plain-coat discovery: the steward says, in-fiction, every single time the player approaches in the wrong coat on Day 3: I asked you to leave your badge behind (steward.dialogue line 15). This is a stronger signal than a document-only review would assume.
- Pantry-lead clarity: _objective() already returns The steward pointed to the old pantry door, off the smoking lounge the moment the lead is recorded (chapter_one.gd); essentially what the report asked for, already shipped.

## Not actioned

- The report's proposed cold-path playtest matrix (five runs: minimal, curious, resistant, schedule-adversarial, save/load) is a good idea for a future pass but wasn't run this session; flagging here so it isn't lost, not because it was rejected.
- Developer error exposed in release (fail-loud EOF/error cards reaching a published build) and web/native parity were not verified against the actual web export this session; worth a look before the next public push but not chased down here.
