# Dialogue authoring system — implementation and QA

September 9, 2026. A custom flat-file dialogue format and interpreter, built instead of adopting a
general-purpose Godot dialogue plugin, because the gating this project needs — location, time of
day, and cross-NPC tallies ("ask four to six people about X before the historian will mention it")
— all reads from systems this project already owns (`case_state.gd`, `day_clock.gd`,
`scripts/chapters/town_places.gd`). A plugin's own graph format would have fought those systems
instead of reading them directly.

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
- `NOTEBOOK: "text"` — writes free text straight into the record; no separate facts table to keep in
  sync with the dialogue.
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
  card-array shape `story.gd`/`town_story.gd` already use, so `dialogue_sequence.gd`/
  `chapter_interface.gd` need no changes to consume it. `enter()` takes an optional `choices` array
  so a `default` topic that halts on a `FORK` (Odell's branching response) can be resumed on a
  later interaction, not just via `play_topic()` — note this still counts as a fresh visit, so an
  NPC whose default topic can fork should not also gate anything else on its exact `visit_count`.
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

- Not wired into `chapter_one.gd`'s real `_interact()`/`_town_interaction()` dispatch. The existing
  hand-coded menus (`_witness_menu()`, `_barman_menu()`, `_behan_menu()`) remain authoritative in
  play; these files and tests only prove the new system in isolation.
- `dialogue_state.gd` is not yet part of `case_state.gd`'s save payload (`pack()`/`restore()`).
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
