# Object authoring reference

Written by Copilot, 2026-09-14, as the sibling system to `docs/DIALOGUE_AUTHORING.md`. This documents the flat-file OBJECT format and its game-facing runtime for world hotspots — examine points and carryable items — as a deliberate parallel to the dialogue system, not a subclass of it. It is infrastructure only as of this writing: the parser, state store, runtime, template, and tests exist and pass standalone, but no scene (`estate.gd`, `town.gd`, `tunnel.gd`) or `chapter_one.gd` has been wired to call it yet. The design bible remains authoritative for story content.

Start with [the annotated template](../objects/background_object_template.object). It is a cookbook, not a proposed location: delete unused examples, replace all example identifiers, and supply the actual content. Its `{generated}` location header deliberately excludes it from any future live catalog. Braces are placeholders for a human to replace, not variables.

## Why a sibling system, not an extension of dialogue

World objects are not NPCs. An NPC conversation has a menu of many topics with a distinguished automatic opener (`TOPIC: default`) and a schedule that moves it around the map. A world hotspot is a single fixed thing: interacting with it plays whichever one of its authored states currently applies, full stop — there is no menu to build and no separate "is this the opener" concept. Because of that:

- There is no `NPC:`/`SCHEDULE:` header, and no `WEIGHT:` (objects have no random chatter pool to draw from).
- There is no `VOICE:`. Examined objects are Walter's own narration and stay unvoiced, exactly like dialogue's beats, notebook text, and system cards.
- **Unlike `TOPIC` ids in dialogue, an `OBJECT` id is expected to repeat.** Multiple `OBJECT: knife` blocks may exist with different `GATE`s; the first block (file order) whose `GATE` is currently true wins — exactly dialogue's repeatable `TOPIC: default` cascade, just applied to every object id instead of only the reserved one. Write the most specific/gated state first and the always-eligible fallback last.
- There is a new `TAKE:` step for carryable items, since not every examined thing is inventory (a witness's account of a knife is not the knife).

The GATE mini-language itself is intentionally identical in syntax to dialogue's (`NOT`/`AND`/`OR`, parentheses, `< <= > >= = !=`) so one authoring skill covers both formats — only the function/field vocabulary differs where it must.

## File structure and every directive

Use UTF-8 text, two spaces per nesting level, and no tabs. Keep directives uppercase and ids lowercase_snake_case. Comments occupy their own lines beginning with `#`; inline comments are not supported. The `LOCATION:`/`INCLUDE:` header precedes the first `OBJECT`.

| Header | Meaning |
| --- | --- |
| `LOCATION: estate` | Identity used for completion/timing keys and cross-location tallies. Does not create a scene by itself. |
| `INCLUDE: shared_object_rebuffs.object` | Optional, repeatable. Relative paths resolve under `res://objects/`; full `res://` paths also work. Included objects are appended only when their id is absent locally, same rule as dialogue's `INCLUDE`. There is no cycle guard — do not self-include. |

`OBJECT: stable_object_id` starts a block at the left margin. Put all metadata at two spaces **before any steps**:

| Metadata | Meaning |
| --- | --- |
| `GATE: expression` | Availability; omitted means `never`. |
| `LABEL: "Menu/hover text"` | Optional; otherwise a capitalized version of the object id. |
| `TAG: estate_knife_take` | Optional additional completion identity and timing key, same purpose as dialogue's `TAG`. |
| `TIME: 12.5` | In-game minutes charged on first completion. Finite, nonnegative; `0` is valid. **Omitted is free (0 minutes)** — there is no dialogue-style default/other split, because no object id is distinguished as a "greeting." |

| Step | Meaning |
| --- | --- |
| `ANY SPEAKER NAME: "Text"` | A card with that literal label — usually `WALTER CORWIN` for his own narration, but a witness/observer label works too. No name lookup or interpolation. |
| `[A short stage direction.]` | An unspoken beat card; keep the brackets on one physical line. |
| `CHOICE: "Walter's line"` | Outside a FORK, linear Walter speech followed by its indented continuation. Always labelled `WALTER CORWIN`, same as dialogue. |
| `FORK:` | Its indented CHOICE children become selectable options. Each option's continuation is indented another level. Nested FORKs work; parent content resumes afterward. |
| `NOTEBOOK: stable_note_id \| "Account"` | Persists prose under `location.note_id`. First write wins. |
| `EVIDENCE: stable_evidence_id` | Records a linkable observation, same case-wide evidence catalog dialogue writes to. |
| `TAKE: item_id` | Adds `item_id` to `case_state.gd`'s `inventory`. Distinct from `EVIDENCE`: use both together when a physical item is also a recordable observation. |
| `OUTCOME: decision_id = value_id` | Commits one immutable branch result when the entire chosen path finishes, identical semantics to dialogue's `OUTCOME`. |

Quoted speech/notes may continue across physical lines until the closing straight double quote; those lines join with spaces. Use literal `\n` for a line break, `\n\n` for a paragraph, and `\"` for a quoted word. Blank lines and whole-line comments are skipped.

There are no `SET`, `GOTO`, `JUMP`, `CALL`, `WAIT`, `END`, `GIVE`, `REMOVE`, `LINK`, `WEIGHT`, or `VOICE` directives in this format. An unknown colon-prefixed line is treated as a speaker line, so parsing successfully does not prove invented syntax works.

## Complete GATE vocabulary

Boolean grammar is identical to dialogue: `always`, `never`, `NOT`, `AND`, `OR`, parentheses, and `<`, `<=`, `>`, `>=`, `=`, `!=`. `=`/`!=` are case-insensitive substring containment in either direction (same caveats as dialogue: `day = 3` can match `13`). Relational comparisons are numeric.

| Function | What it reads |
| --- | --- |
| `object_done(location_id, object_id_or_tag)` | Whether that location's object id or TAG completed. Location-scoped, unlike dialogue's `topic_done` which is NPC-scoped — pass the exact `LOCATION:` value. |
| `object_count(shared_object_id_or_tag)` | Number of distinct locations completing that identity; repeats within one location add nothing. Mirrors dialogue's `topic_count`. |
| `examine_count(location_id, object_id)` | Interactions begun with that hotspot; the current interaction is counted before availability is evaluated (same off-by-one convention as dialogue's `visit_count` — the first `enter()` call already reports `1`, not `0`). |
| `taken(item_id)` | Whether that item is currently in `case_state.gd`'s inventory. |
| `evidence(evidence_id)` | Case-wide evidence, identical to dialogue's `evidence()` (same alias map, since both read `dialogue_runtime.gd::has_evidence`). |
| `filed(evidence_id)` | Case-wide filed/received evidence, identical to dialogue's `filed()`. |
| `flag(flag_id)` | Boolean set by game code, **shared with dialogue** — both systems read/write through the same `case_state.dialogue_state` flag store. |
| `outcome(decision_id)` / `outcome_is(decision_id, value_id)` | Whether/which value committed for a decision, **shared with dialogue** through the same `dialogue_state.outcomes` store. A decision can be started by an OBJECT and later read by a TOPIC, or vice versa. |

| Field | Values/meaning |
| --- | --- |
| `coat` | Same stored clothing description dialogue reads. |
| `day` | Day number. |
| `phase` | `morning`, `noon`, `evening`, `night` — same `DayClock.phase()` dialogue uses. |
| `estate_complete` | Existing estate investigation completion state. |
| `steward_ready` | Existing story predicate, identical to dialogue's. |

These are the full exposed vocabulary. As of this writing, `dialogue_runtime.gd::make_context()` was also given `object_done`, `object_count`, and `taken` entries so a dialogue `GATE` can react to the object system symmetrically (e.g. an NPC who notices a taken item). Check the actual dependency id before using a gate; unknown names are not extensions.

## Completion, consequences, evidence, and time

Semantics mirror dialogue exactly: notes/evidence/inventory apply as the player acknowledges the preceding cards (`commit_through`); an object's own completion (and its TAG's) is recorded only after the chosen branch and final continuation finish; a cancelled interaction earns nothing. A completed object remains available if its `GATE` stays true — for a once-only state, gate the *next* block on `NOT object_done(location, this_id)` (see the template's `example_ledger` pair).

`OUTCOME` behaves identically to dialogue's: the selected value commits only when the player finishes the entire chosen path, is immutable, survives save/load, and a replay of a resolved FORK shows only the committed branch. Because outcomes share dialogue's store, do not reuse a `decision_id` across an OBJECT and a TOPIC unless they are genuinely the same decision.

`TAKE` writes directly to `case_state.gd`'s `inventory` the moment its card is acknowledged (during `commit_through`, not gated behind full-object completion the way evidence/notebook nominally are timed) — pair it with `GATE: NOT object_done(...)` on the object so a taken item's hotspot naturally stops offering itself once its containing block has completed. This system does not itself hide or remove the world node; see "Placement and visibility" below.

`TIME` is charged once per location+id (or TAG, if authored). An explicitly authored numeric `TIME` always wins, including `TIME: 0`. Omitted TIME costs 0 minutes — there is no dialogue-style "greeting is free, everything else falls back to 3" split, since no object id is distinguished as an opener.

Keep object, TAG, note, and evidence identities stable through prose edits: saves depend on them. Evidence written by an OBJECT still needs an authored entry in `chapter_one_archive.gd`'s LINKS table to become a valid linkable pair, same rule as dialogue.

## Placement and visibility (current scope)

Positions stay in GDScript, not in `.object` files — the existing per-scene pattern (`estate.gd`'s `target(id, title, pos)` hotspots, `points` dict, and manual `sync_staging()` visibility toggling) is unchanged by this system. What this system replaces is the *content and logic* behind an id: instead of a hardcoded `Story.SCENES`/`Story.FACTS` lookup and ad hoc `state.xyz` checks in `chapter_one.gd`, scene code is expected to:

1. Call `ObjectRuntime.is_available(def, object_id, ctx)` wherever it currently decides whether to keep a hotspot/mesh visible (replacing hand-written conditionals like `if st.rose_bodies_removed: points.erase(id)`).
2. Call `ObjectRuntime.enter(def, object_id, ctx, state)` when the player actually interacts, and render/commit exactly as `chapter_one_dialogue.gd` already does for NPC topics.

Neither of these is wired into `estate.gd`/`town.gd`/`tunnel.gd`/`chapter_one.gd` yet — that integration, and porting the existing hardcoded `Story.SCENES` content into real `objects/*.object` files, is future work, not part of this pass.

## Validation and provenance

`tests/object_lang_flow.gd` is the standalone grammar proof (mirrors `tests/dialogue_lang_flow.gd`); `tests/object_template_flow.gd` exercises the cookbook end-to-end, including the GATE cascade, FORK/OUTCOME, TAKE→inventory, and cross-location `object_count()` (mirrors `tests/dialogue_template_flow.gd`). Run with the project's Godot console executable:

```text
godot --headless --path . --script res://tests/object_lang_flow.gd
godot --headless --path . --script res://tests/object_template_flow.gd
```

Implementation sources: [parser](../scripts/shared/object_lang.gd), [runtime](../scripts/shared/object_runtime.gd), [object state](../scripts/shared/object_state.gd). `case_state.gd` is schema version 10 as of this pass (adds `inventory` and `object_state`, both additive/backward-compatible). See `docs/DIALOGUE_AUTHORING.md` for the sibling NPC-facing format and the shared GATE grammar's full rationale.
