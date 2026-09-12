# Dialogue authoring system — implementation and QA

**Current status:** the interpreter is now connected to live Chapter 1. See
[DIALOGUE_LIVE_PASS.md](DIALOGUE_LIVE_PASS.md) for numeric TIME, schema-9 saves,
resident placement, verification and provenance. Earlier future-work sections
below are retained as implementation history, not current status.

**Current-language addendum — September 12, 2026:** The live corpus now contains 35 concrete NPC definitions and 217 nonempty topics. `VOICE:` carries validated instrumental cue IDs; omitted NPC cues warn and receive a neutral fallback. Multiple eligible `default` topics may use positive relative `WEIGHT:` values, with immediate-repeat avoidance; unpriced defaults cost zero minutes while other unpriced topics retain the three-minute fallback. Consequential fork branches may use `OUTCOME: decision_id = value_id`; the chosen value commits only after complete playback, is immutable and saved, automatically retires its source topic, and is readable through `outcome()` / `outcome_is()`. Existing forks without outcomes remain replayable. `docs/DIALOGUE_AUTHORING.md` is the canonical complete syntax reference.

September 9, 2026. A custom flat-file dialogue format and interpreter, built instead of adopting a
general-purpose Godot dialogue plugin, because the gating this project needs — location, time of
day, and cross-NPC tallies ("ask four to six people about X before the historian will mention it")
— all reads from systems this project already owns (`case_state.gd`, `day_clock.gd`,
`scripts/chapters/town_places.gd`). A plugin's own graph format would have fought those systems
instead of reading them directly.

## Provenance

Original authoring system and content conversion: Claude Sonnet 5 in VS Code,
as reported by Dejunai; baseline commits `0da8d2e` and `59b6d51`.
September 9, 2026 follow-up: Codex reviewed that implementation, reproduced the
gardener notebook collision and Odell fork replay/extra visit, then implemented
the fixes below at Dejunai's request. This extends the original work; it does not
replace its authorship. Dialogue wording and story gates are unchanged.

## Grammar

A `.dialogue` file is `NPC:` / `LOCATION:` (or `SCHEDULE:` for template/background NPCs), followed
by `TOPIC: id` blocks. Each topic has:

- `GATE: <expr>` — `never`, `always`, or a boolean expression of function calls (`visit_count(npc)`,
  `topic_count(topic_id)`, `spoken_to(npc)`, `evidence(id)`, `flag(name)`, `topic_done(npc,topic_id)`)
  and fields (`coat`, `day`, `phase`, `estate_complete`), combined with `AND`/`OR`/`NOT` and
  `< <= > >= = !=`. `=`/`!=` match case-insensitively by substring containment, so `coat = plain`
  matches the stored `"Plain wool coat"` without the author needing the exact string.
- `LABEL: "..."` — optional menu button text; defaults to the topic id, capitalized.
- `SPEAKER: "text"` lines, which may continue across indented lines (merged with a space) or use
  literal `\n`/`\n\n` inline to reproduce the source material's own paragraph breaks on one
  physical line.
- `[bracketed text]` on its own line — a stage-direction beat, not spoken dialogue.
- `CHOICE: "text"` — the player's own line; always linear, never branches by itself.
- `FORK:` — a block of sibling `CHOICE:` entries that *are* mutually exclusive; rendering halts and
  returns the options for the caller to prompt, then resumes exactly where it left off once given a
  choice index.
- `NOTEBOOK: stable_note_id | "text"` — queues free text for the record at that
  playback position. IDs must be unique across all topics/branches of an NPC;
  preserve them when editing or moving text. The stored key is `npc.stable_note_id`.
  Legacy `NOTEBOOK: "text"` remains supported with a text-hash key, but wording
  edits change that fallback identity. All current authored effects now have IDs.
- `#` full-line comments. A topic with no dialogue lines (just `GATE:`/comments) is a documentation
  stub and never surfaces in play.

The topic id `default` is reserved for an NPC's automatic opening line: multiple `TOPIC: default`
blocks may exist with different GATEs, and the first one (file order) whose GATE is true wins,
never appearing in a menu. Every other topic id is a revisitable menu entry whenever its GATE is
true — whether an NPC presents as a single auto-spoken line or a menu falls out for free from
whether more than one of its topics can be GATE-true at once; there is no separate "is this a menu"
flag to author.

## Files

- `scripts/shared/dialogue_lang.gd` — the grammar and GATE-expression parser/evaluator. Pure text
  in, structured data out; no engine/game references, so it is unit-testable in isolation.
- `scripts/shared/dialogue_runtime.gd` — the game-facing half: builds the GATE context from live
  `case_state`/`dialogue_state`, loads and caches parsed files, resolves an NPC's current default
  line and menu (`enter()`, `menu()`), and renders a chosen topic into the same `[speaker, text]`
  card-array shape `story.gd`/`town_story.gd` already use. Playback integration
  must call `commit_through()` and use `resume()` at forks, as described below.
  The old optional `choices` array API has been removed; it replayed the prefix
  and incorrectly counted another visit.
- `scripts/shared/dialogue_state.gd` — a persistent store deliberately separate from
  `case_state.gd`: `visit_counts`, `topic_sources` (the cross-NPC tally), `visited_topics`, `facts`,
  and `flags`. New TOPIC ids and GATE conditions are invented by content authors with no engine code
  change, so the counters they imply must never require a `case_state.gd` schema bump.

## Content

Four files prove the grammar itself (`tests/dialogue_lang_flow.gd`): `dialogue/father_behan.dialogue`
(permanent `GATE: never` exclusion, an always-visible three-topic menu, linear `CHOICE` + inline
`NOTEBOOK`), `dialogue/odell.dialogue` (a `FORK` that halts and resumes, and the cross-NPC
`topic_count` tally shared with Behan's `bullets` topic), `dialogue/steward.dialogue` (mutually
exclusive `default` resolution driven purely by `GATE`), and
`dialogue/background_npc_template.dialogue` (parses `SCHEDULE:`/`{placeholder}` syntax for the
~50 background residents; substitution is intentionally unimplemented — see Explicit placeholders).
`club_five`/`club_invitation` in `father_behan.dialogue` are real lines pulled from
`town_story.gd`'s `behan`/`behan_invitation`; its third topic, `bullets`, remains a deliberately
invented GATE-tally demo, not real content, but the real third topic — `behan_name`, the club's
naming — is now also present, gated on `topic_done(father_behan, club_invitation)` so it replaces
the invitation topic in the menu exactly as `_behan_menu()` does, never showing both at once.
`odell.dialogue` similarly now carries both: its original invented `bullets` FORK-tally demo, and a
new `default` topic reverse-engineered from `story.gd`'s `SCENES.odell` and `_odell_response()` — a
genuine two-way player choice via a real `FORK`, each branch persisting its own real statement text,
gated on `topic_done(odell, default)` so it resolves to nothing once answered.

Six further files reverse-engineer already-shipped NPCs verbatim (`tests/dialogue_content_flow.gd`),
proving the grammar holds real content and real GATE conditions, not just illustrative fixtures:

- `dialogue/gatehouse_boy.dialogue` — the three mutually exclusive `boy`/`boy_repeat`/`boy_return`
  states from `story.gd`, now three `GATE`-ordered `default` topics.
- `dialogue/coroners_assistant.dialogue` — the assistant's testimony, including its two bonus
  `discover()`s (`testimony`, `eight`) as `NOTEBOOK` effects.
- `dialogue/groundskeeper.dialogue` — the estate's Observer beat (the kitchen-wing crew), unchanged
  from `story.gd`, always available with no Perception gate.
- `dialogue/gardener.dialogue` — the base scene and the estate-complete/plain-coat later scene, as
  two `GATE`-ordered `default` topics.
- `dialogue/old_woman.dialogue` — the one-shot, disappearing-actor scene, gated on
  `NOT evidence(old_woman)` rather than any actor-lifecycle mechanism.
- `dialogue/mrs_almy.dialogue` — the coat-gated first-visit intro plus the full revisitable witness
  menu (`identify`, `lay_lead`, `service_work`, `almy_ledger`, `almy_trust`), including
  `almy_trust`'s disappear-once-answered gate via `topic_done`.

Reverse-engineering surfaced one real distinction worth naming: several source scenes show a
"WALTER'S NOTEBOOK"-titled card that is pure flavor, never mirrored by an actual `discover()`/
`record()` call. Those became plain speaker lines (rendered, not persisted). Only text that the
source code actually writes into `case_state` became a `NOTEBOOK:` effect. `tests/dialogue_content_flow.gd`
asserts both halves of this directly (a flavor card renders but never lands in `dialogue_state.facts`).

## Grammar fixes made during reverse-engineering

- `_quoted()` now unescapes literal `\n` (in addition to the existing `\"`), so one physical line can
  hold a source paragraph break (`"...ambitions.\n\nI'll discuss..."`) exactly, instead of relying on
  space-joined continuation lines, which collapse multi-line breaks to a single space.
- `_evaluate_cmp()` used `String(resolved)` to stringify a GATE function's return value; `String()` is
  a narrow GDScript type constructor that throws `Invalid call. Nonexistent 'String' constructor.` for
  a plain `bool` (e.g. `spoken_to(npc) = true`). Changed to `str()`, which stringifies any Variant.
  This bug hung every headless test run silently: a failed `assert()` aborts only the function it's
  in, so `quit()` was never reached and the process just idled forever — indistinguishable from an
  infinite loop until the output was captured to a file and read directly.
- `visit_count(npc)` increments *before* the GATE is evaluated (visiting itself is unconditional), so
  "this is the Nth visit" is `>= N`, not `> N`, and "this is strictly before the Nth visit" is
  `< N+1`, not `< N`. Both `gatehouse_boy.dialogue` (`>= 2` for "this is a repeat") and
  `mrs_almy.dialogue` (`< 2` for "this is the first visit only") depend on this.
- `dialogue_runtime.gd`'s `make_context()` gained `topic_done(npc, topic_id)` and the `estate_complete`
  field; both already existed in `dialogue_state.gd`/`case_state.gd` but were not yet exposed to GATEs.

## Verification

`tests/dialogue_lang_flow.gd` and `tests/dialogue_content_flow.gd` both pass headless (the latter
now also covers the real Odell/behan_name additions above):
`godot --headless --path . --script res://tests/dialogue_lang_flow.gd` and the same for
`dialogue_content_flow.gd`. No `.cmd` launcher yet. A GUI-subsystem Godot exe on Windows exits
cleanly without `--headless` but silently swallows `print()` output; the sibling `*_console.exe`
must be used if stdout needs to be read from a non-headless run.

## Explicit placeholders and future work

- **Superseded:** live wiring into `chapter_one.gd` and `dialogue_state.gd` joining the save payload
  both happened in the September 9, 2026 live-integration pass — see `docs/qa/DIALOGUE_LIVE_PASS.md`
  and `docs/ARCHITECTURE.md`'s "Live dialogue integration" section, not this file, for their current
  state. This file now documents only the grammar/interpreter itself as it stood before that pass.
- `case_state.gd` distinguishes `evidence` (ids resolved against a separate `FACTS` table) from
  `statements` (free text); `dialogue_state.gd` currently collapses both into one `facts` dict of
  free text. Fine for proving the grammar; real integration needs to decide whether to keep that
  distinction or simplify `case_state.gd`'s schema to match.
- No GATE writes back to `case_state`/`dialogue_state` on its own — `evidence()`/`coat`/`day` read
  live state, but nothing calls `state.discover()`/`state.record()` automatically after a topic
  completes. `tests/dialogue_content_flow.gd` calls `state.discover()` manually to stand in for
  whatever the eventual integration does.
- The first four (grammar-fixture) files use space-joined physical-line continuation for their
  longer quotes, which loses the source's `\n\n` paragraph breaks — a minor cosmetic fidelity gap the
  six reverse-engineered files avoid by using the new `\n` escape throughout.
- `FORK` has no real "pick one of N" UI widget yet; `dialogue_sequence.gd` only auto-advances
  linearly today.
- `SCHEDULE:`/`{placeholder}` substitution for the ~50 background residents is intentionally
  unimplemented — the grammar tolerates the syntax; nothing resolves it to a concrete NPC yet.

## Codex playback correction — September 9, 2026

Three changes address the review findings:

1. Explicit notebook IDs replace NPC/topic/ordinal keys, which collided between
   multiple `default` topics. Both `gardener.eight_sheets` and
   `gardener.service_door` now survive the two encounters. Other authored notes
   also received stable IDs without changing their text.
2. Each prepared result carries a transient stack cursor. `resume(result, index)`
   continues the selected branch and parent tail, including nested forks. It
   neither repeats earlier cards nor reevaluates the opening gate/counts a visit.
   Out-of-range choices and repeated use of an old result return an empty dictionary
   without consuming the pending choice.
3. Preparation no longer writes facts or completes topics. The playback owner calls
   `commit_through(result, case_state, dialogue_state, count)` after consuming the first `count`
   cards of that segment. Effects commit at their authored card boundary. Completion
   returns true exactly once, only after the final segment's last card. On that first
   completion (never on a replay), `TIME:` minutes charge to the day clock via
   `DayClock.advance()` — see "TIME: is minutes, not a key" below. Repeated acknowledgment
   does not repeat effects or completion. Abandoning an unread segment commits nothing;
   already acknowledged effects remain. A leading NOTEBOOK requires acknowledgment
   at count zero, including when a segment contains no cards.

Playback contract:

```gdscript
var segment = Runtime.enter(definition, context, dialogue_state) # one visit
# Display cards in order; after each card is consumed:
var completed = Runtime.commit_through(segment, case_state, dialogue_state, consumed_count)
# Once every card has been consumed, expose segment.fork.options if non-null.
# After the player chooses, use the same result, not another enter():
segment = Runtime.resume(segment, selected_index)
# Display/acknowledge this new segment, repeating for any subsequent forks.
```

Do not acknowledge a segment merely because it was prepared. Zero-card segments
still need an explicit `commit_through(segment, case_state, dialogue_state, 0)` at playback.
Refresh menus using `menu(definition, context)` after completion, since the entries
returned by enter are a snapshot from before playback effects.

Tests updated: the two existing suites now explicitly simulate consuming cards.
New `tests/dialogue_playback_flow.gd` covers both gardener facts, deferred writes,
one-shot completion, committed-state pack/restore, one-visit Odell continuation,
invalid/stale choices, and nested forks with parent tails. All three suites passed
headless with Godot 4.7.2 on September 9, 2026.

The runtime remains isolated from live Chapter 1 dispatch. No branch UI, automatic
case-state evidence mapping, or game-save integration was added in this correction.
Playback cursors are transient and are not packed by DialogueState; mid-conversation
save/resume remains future work. Existing development-only dialogue state snapshots
keep any old fact keys on restore; no released game saves contain this unintegrated
state, and no speculative migration was introduced. The web build was not re-exported
or published by this pass.

## TIME: is minutes, not a key (September 9, 2026)

`TIME:` was originally authored as a string mirroring each topic's own id — parsed
and threaded onto the session, but never read by anything (confirmed by grep: exactly
one reference, the line storing it). It's now a plain number of minutes, sized per
topic instead of `day_clock.gd`'s old blanket 30-minute `CONVERSATION_MINUTES`: a
three-line exchange might cost 3–4, a long forked interrogation 7–10. `commit_through()`
charges it to `state.clock_minutes` via `DayClock.advance()` at the exact moment a
topic's own first completion fires — reusing the existing `topic_done()` check that
already guards `complete_topic()`, not a separate tracking array. Because that check
is per-topic, revisiting an NPC after a topic is already done (a repeat/"nothing more
to say" state, or a different mutually-exclusive `default` variant sharing the same
topic id) never advances time again; a topic with no `TIME:`, or one still holding a
non-numeric legacy value, simply costs nothing (`str.is_valid_float()` guards it).
This also means a `FORK`'s time is charged once, on the branch that actually finishes
the topic, not per branch offered.

All 55 `TIME:` occurrences across the 20 files that had them were converted from their
old string-id values to numbers, sized by each topic's own dialogue length (roughly
3 minutes for a short exchange up to 10 for the longest forked interrogations).
`commit_through()`'s signature grew a leading `state` (case_state) parameter to reach
`DayClock`; every call site in all three test suites and the pass doc's playback
contract above were updated to match. `day_clock.gd`'s `CONVERSATION_COSTS` dict
(previously empty, intended as the per-conversation override point) is now bypassed
entirely for dialogue-system content — real integration will need to decide whether
the old array-sniffed `Story.SCENES` conversations should move to this same per-topic
`TIME:` model instead of the blanket 30-minute default they still use today.
