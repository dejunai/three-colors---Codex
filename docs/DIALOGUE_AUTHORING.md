# Dialogue authoring reference

Updated by Codex, 2026-09-11. This documents the current development parser and live Chapter One runtime, including cross-NPC inquiries, `filed()`, and optional instrumental voices. It does not change the frozen Web build. The design bible remains authoritative for story content.

Start with [the annotated template](../dialogue/background_npc_template.dialogue). It is a cookbook, not a proposed character: delete unused examples, replace all example identifiers, and supply the actual account. Its `{generated}` NPC header deliberately excludes it from the live catalog. Braces are placeholders for a human to replace, not variables.

## Brief for another writer or assistant

Supply this reference, the template, relevant bible passages, and the connected NPC files. Ask for one `.dialogue` file per NPC plus a short dependency list naming the NPC/topic/evidence IDs it reads or creates. Identify which statements are observations, claims, or refusals; do not turn a witness's speculation into established fact. Preserve existing IDs when revising published content. Use existing syntax only; propose required code support separately. Test both intended and resistant approaches, revisits, clothing, and prerequisites in the game before calling the dialogue integrated.

## File structure and every directive

Use UTF-8 text, two spaces per nesting level, and no tabs. Keep directives uppercase and IDs lowercase_snake_case. Comments occupy their own lines beginning with `#`; inline comments are not supported. All file headers precede the first `TOPIC`.

| Header | Meaning |
| --- | --- |
| `NPC: example_witness` | Stable identity for visits, notes, and topic completion. |
| `LOCATION: museum` | Existing location/slot identifier; does not create a building. |
| `SCHEDULE: morning=museum, midday=museum, evening=closed, night=closed` | Existing placement destinations by phase; see limitations below. |
| `INCLUDE: shared_rebuffs.dialogue` | Optional, repeatable. Relative paths resolve under `res://dialogue/`; full `res://` paths also work. |

Included topics are appended only when their ID is absent locally. Local topics win, including `default`; included headers and schedules do not replace the receiving NPC's headers. Completion belongs to the receiving NPC. Never use circular/self includes: there is no cycle guard. Give a shared file a placeholder NPC header such as `{shared}` to keep it from becoming a resident. Do not reference nonexistent files.

`TOPIC: stable_topic_id` starts a block at the left margin. Put all metadata at two spaces **before any dialogue or effects**:

| Metadata | Meaning |
| --- | --- |
| `GATE: expression` | Availability; omitted means `never`. |
| `LABEL: "Menu text"` | Optional; otherwise a capitalized version of the topic ID. |
| `TAG: npc_unique_scene_id` | Optional additional completion identity and timing key. Prefer globally unique tags. |
| `TIME: 12.5` | In-game minutes charged on first completion. Use finite, nonnegative numbers; `0` is valid. |

Multiple `TOPIC: default` blocks are allowed. The first eligible, nonempty one is the automatic greeting, never a menu entry. Put specific variants before the fallback and give them different TAGs. Other topic IDs must be unique within that NPC. Sharing a topic ID across different NPCs intentionally supports `topic_count()`.

| Step | Meaning |
| --- | --- |
| `VOICE: trombone_cautious_medium_v1` | Optional delivery cue for the immediately following spoken line. The identifier must exist in `assets/audio/instrument_voices/manifest.json`. |
| `ANY SPEAKER NAME: "Text"` | A spoken card with that literal label. No name lookup or interpolation. |
| `[A short stage direction.]` | An unspoken beat card; keep the brackets on one physical line. |
| `CHOICE: "Walter's line"` | Outside a FORK, linear Walter speech followed by its indented continuation. |
| `FORK:` | Its indented CHOICE children become selectable options. Each option's continuation is indented another level. Nested FORKs work; parent text resumes afterward. |
| `NOTEBOOK: stable_note_id \| "Account"` | Persists prose under NPC ID plus note ID. First write wins. |
| `NOTEBOOK: "Account"` | Supported legacy form; derives identity from the text, so edits can produce another note. Prefer explicit IDs. |
| `EVIDENCE: stable_evidence_id` | Records a linkable observation. Use source-faithful NOTEBOOK prose immediately before a new observation. |

Quoted speech and notes may continue across physical lines until the closing straight double quote; those lines join with spaces. Use literal `\n` for a line break, `\n\n` for a paragraph, and `\"` for a quoted word inside text. Do not assume other escape sequences are supported. Blank lines and whole-line comments are skipped. A speaker named `WALTER'S NOTEBOOK` is just a spoken-card label; it does not save a note.

`VOICE` is a wordless imitation-of-speech performance, not dialogue content or evidence. It does not persist in case state. Put it directly before the spoken line it accompanies; a dangling cue or a cue immediately before `FORK:` is an authoring error. Inside a fork choice, place it in that choice's indented continuation directly before the reply. Unmarked lines stay silent. Walter, narration, objects, notebook text, and system cards deliberately remain unvoiced. The sound stops when the player advances. Players can reduce or mute these cues independently under **Instrument voices** in Accessibility & controls.

**Delivery cues must never encode truth value.** Choose instrument, mood, length, and take for a character's manner and emotional delivery, never to signal whether the line is true, mistaken, evasive, or deceptive. Do not establish a reliable cue pattern that could turn instrumental voices into a lie detector. The player must judge claims from words, conduct, documents, physical evidence, and consequences.

Run `python tools/seed_instrument_voices.py dialogue` after adding NPC dialogue. It fills only uncued NPC lines, preserves hand-authored cues, assigns one instrument per character, and chooses a deterministic mood, length, and take. Review its choices as delivery direction; rerunning it does not replace manual edits. The live-content test fails when a new NPC line remains unvoiced or a character changes instruments.

CHOICE currently always labels the player **WALTER CORWIN**, including in FORKs. It is not yet a chapter-independent protagonist system. GATE/TAG/TIME/LABEL are topic metadata, not per-choice controls. For different availability, write separate gated topics. There are no `SET`, `GOTO`, `JUMP`, `CALL`, `WAIT`, `END`, `GIVE`, `REMOVE`, or `LINK` commands. An unknown colon-prefixed command can be treated as a speaker, so parsing successfully does not prove invented syntax works.

## Complete GATE vocabulary

Use `always`, `never`, `NOT`, `AND`, `OR`, parentheses, and `<`, `<=`, `>`, `>=`, `=`, `!=`. Boolean keywords are case-insensitive; field and function names are case-sensitive. NOT binds before AND, then OR; use parentheses to make intent clear. Use simple identifiers or quoted string arguments/values. No arithmetic, nested function calls, `==`, `&&`, `||`, or standalone `!`.

| Function | What it reads |
| --- | --- |
| `visit_count(npc_id)` | Interactions begun; the current visit is counted before greeting selection. |
| `spoken_to(npc_id)` | Whether any interaction began, even without completing a substantive topic. |
| `topic_done(npc_id, topic_or_tag)` | Whether that NPC's topic or TAG completed. |
| `topic_count(shared_topic_or_tag)` | Number of distinct NPCs completing that identity; repeats with one NPC add nothing. |
| `evidence(evidence_id)` | Current recorded evidence, with the small existing alias map in the runtime. |
| `filed(evidence_id)` | Evidence in received records after intake. Supplement history is authoritative when present; older saves without history may use the filed supplement snapshot. Possession alone is insufficient. No alias expansion. |
| `flag(flag_id)` | Boolean set by game code; unknown flags are false. Dialogue has no command to set one. |

| Field | Values/meaning |
| --- | --- |
| `coat` | Stored clothing description; `coat = plain` is the customary plain-coat test. |
| `day` | Day number. |
| `phase` | `morning`, **`noon`**, `evening`, `night`. |
| `estate_complete` | Existing estate investigation completion state. |
| `steward_ready` | Existing story predicate: Almy visited, Day 3, sufficient steward visits, and plain coat. |

These are the full exposed runtime fields/functions. Clock minutes, Perception, and arbitrary case-state members are not gate fields. Unknown names are not extensions. Check the actual dependency ID before using a gate.

`=` and `!=` use case-insensitive **substring containment in either direction**, including for numbers converted to text. They are not strict equality. This lets `coat = plain` match `Plain wool coat`; it also means `day = 3` could match 13. Relational comparisons are numeric. For exact integer day 3 use `day >= 3 AND day <= 3`.

Examples:

```text
GATE: NOT topic_done(example_witness, account)
GATE: topic_done(example_historian, referral) AND coat = plain
GATE: topic_count(crew_omission) >= 4
GATE: filed(eight) AND filed(naomi) AND filed(lodging)
GATE: (day >= 2 AND phase = evening) OR flag(actual_game_flag)
```

Use a shared named TOPIC for spreading questions, with a different TAG for each NPC. Do not count `default` to measure inquiries: greetings also complete it. A gate that reads another NPC's topic needs that exact NPC/topic pair, not its display name or menu label.

## Completion, consequences, evidence, and time

Notes and evidence apply as the player acknowledges the preceding cards. Topic and TAG completion occur only after the chosen branches and final continuation finish. A cancelled or unfinished conversation does not earn completion. A completed topic remains available if its gate stays true. For a once-only decision use `NOT topic_done(this_npc, this_topic)`; otherwise a later replay can choose another branch.

Branch-specific consequences can be represented by distinct EVIDENCE IDs and read later with `evidence()`. Completion alone records that a topic finished, not which option was chosen. New evidence joins the catalog, but valid evidence pairs still require an authored entry in `chapter_one_archive.gd`'s LINKS table. Writing a note does not create a link, file a report, or automatically unlock a consequence elsewhere. New observation descriptions use preceding notebook prose or the topic label when no existing fact supplies a description; inspect the resulting case-file text.

TIME is charged once per NPC and TAG (or TOPIC if TAG is omitted). Existing legacy timed-conversation tags are also consulted, so use globally unique TAGs. Missing or nonnumeric TIME falls back to **3 minutes**; words such as `short` do not define a duration. Replaying a completed topic does not repeatedly advance time. Give new default scenes distinct TAGs if each should have its own time charge.

Keep NPC, topic, TAG, note, and evidence identities stable through prose edits: saves and other files depend on them. A later changed account should get its own note ID because existing notes are not overwritten. Saved mid-conversation playback may return control safely if the underlying content changes rather than resuming an obsolete sequence.

## Scheduling and placement: current limitations

Author schedule keys as **morning, midday, evening, night**. Runtime GATE phase uses **noon**, while schedule lookup uses **midday**. `dawn` currently serves as a fallback when the phase key is missing; it is not a fully normalized morning alias. `dusk` is not recognized. This documentation update does not implement alias normalization.

The additional-resident catalog hides its NPCs at night regardless of their authored night destination; individual night schedules are not enacted yet. `closed` hides a resident. `home` needs a HOME mapping or falls back to LOCATION. A destination must resolve through existing slots, buildings, or hubs in [dialogue_catalog.gd](../scripts/chapters/dialogue_catalog.gd) and [town_places.gd](../scripts/chapters/town_places.gd). Inspect those registries instead of inventing a location string. Phase changes reposition residents; they do not imply a simulated walk. Core story actors retain separate staging rules, and opening hours do not override every story gate.

Current phase boundaries are 06:00 morning, 12:00 noon, 17:00 evening, 20:00 night. A new `.dialogue` file alone does not guarantee a well-positioned avatar: check its actual slot, overlaps, approach directions, and visibility at each phase.

## Validation and provenance

The executable examples are covered by `tests/dialogue_template_flow.gd`; the wider language behavior is covered by `tests/dialogue_lang_flow.gd`. Run with the project's Godot console executable:

```text
godot --headless --path . --script res://tests/dialogue_template_flow.gd
godot --headless --path . --script res://tests/dialogue_lang_flow.gd
```

Also play the intended entry conditions, locked conditions, both fork responses, and revisits. Verify notebook/evidence wording and time charges. Syntax tests cannot establish that an NPC is reachable or a dependency makes narrative sense.

Implementation sources: [parser](../scripts/shared/dialogue_lang.gd), [runtime](../scripts/shared/dialogue_runtime.gd), [dialogue state](../scripts/shared/dialogue_state.gd), and [catalog](../scripts/chapters/dialogue_catalog.gd). Codex expanded the original placeholder template and authored this reference on 2026-09-10 against these sources. No interpreter, scheduling, story-state, or Web-build behavior was changed by this authoring pass.
