# Object authoring reference

Written by Copilot, 2026-09-14, as the sibling system to `docs/DIALOGUE_AUTHORING.md`. This documents the flat-file OBJECT format and its game-facing runtime for world hotspots — examine points and carryable items — as a deliberate parallel to the dialogue system, not a subclass of it. Updated the same day once `estate.object`, `town.object`, and `tunnel.object` went live: `chapter_one_objects.gd` (the adapter, mirroring `chapter_one_dialogue.gd`) is wired into `chapter_one.gd`'s `_interact()`/`_town_interaction()`/`_town_observation()`/`_tunnel_interaction()` and into every `estate.sync_staging(state)` call site. See `docs/OBJECT_MIGRATION_HOWTO.md` for the full migrated inventory and what's intentionally left alone. The design bible remains authoritative for story content.

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
| `spoken_to(npc_id)` | Whether any interaction with that NPC began — shared with dialogue, reads `dialogue_state.visit_count()` directly. |
| `topic_done(npc_id, topic_id_or_tag)` | Whether that NPC's topic id or TAG completed — shared with dialogue, reads `dialogue_state.topic_done()` directly. |
| `outcome(decision_id)` / `outcome_is(decision_id, value_id)` | Whether/which value committed for a decision, **shared with dialogue** through the same `dialogue_state.outcomes` store. A decision can be started by an OBJECT and later read by a TOPIC, or vice versa. |

| Field | Values/meaning |
| --- | --- |
| `coat` | Same stored clothing description dialogue reads. |
| `day` | Day number. |
| `phase` | `morning`, `noon`, `evening`, `night` — same `DayClock.phase()` dialogue uses. |
| `estate_complete` | Existing estate investigation completion state. |
| `steward_ready` | Existing story predicate, identical to dialogue's. |
| `rose_bodies_removed` | Existing estate staging milestone (the six club members' bodies cleared). |
| `birch_bodies_removed` | Existing estate staging milestone (the woman and boy cleared). |
| `lounge_exited` | Existing estate staging milestone (Walter has left the smoking lounge once). |
| `report` | Filed preliminary report mode string, or `""` if not yet completed. |
| `report_filed` | Boolean convenience (`true`/`false` form of `report`, shared across `.object`, `.portal`, and `.dialogue`): write `GATE: report_filed` / `GATE: NOT report_filed` for a plain locked/unlocked gate instead of comparing `report` against `""`. |

These are the full exposed vocabulary. As of this writing, `dialogue_runtime.gd::make_context()` was also given `object_done`, `object_count`, and `taken` entries so a dialogue `GATE` can react to the object system symmetrically (e.g. an NPC who notices a taken item). Check the actual dependency id before using a gate; unknown names are not extensions.

## Completion, consequences, evidence, and time

Object effects (`NOTEBOOK`/`EVIDENCE`/`TAKE`) commit only once the whole displayed
segment finishes (`commit_through` is called with the full card count from the
adapter's completion callback), **not** per acknowledged card. This is not a
shortcut unique to objects — it matches every other `_cards()`-driven examine flow
in this codebase (the old `Story.SCENES` fallback, `_town_observation()`, etc. all
apply their effects in a completion callback too). Only the dialogue system commits
incrementally as each card is acknowledged, and only it has a snapshot/restore path
for a mid-conversation save; a game closed or interrupted mid-object loses that
object's progress and must be re-entered from the start, same as any other
non-dialogue card sequence. An object's own *completion* (its TAG's, its TIME
charge, and any OUTCOME) is recorded only after the chosen branch and final
continuation finish. **`NOTEBOOK`/`EVIDENCE`/`TAKE` placed before a `FORK` are a
narrower exception: they commit as soon as their own card is acknowledged, even if
the player never resolves the fork that follows** (pressing Escape at the choice
screen keeps them). This is intentional, not a bug, and matches how `commit_through()`
already applies every effect in file order regardless of what comes after it — the
same is true of dialogue's identical `commit_through()`. It is also safe to retry:
recording the same `EVIDENCE`/`NOTEBOOK` id twice is a no-op (`object_state.gd`'s
`discover()`/`record_fact()` both check first), so walking away and re-entering only
replays those pre-fork effects harmlessly. **Keep any effect that should depend on
the player's actual choice inside the relevant `CHOICE`'s own indented body, never
before the `FORK:` line** — see the template's `example_knife`, where `TAKE`/`EVIDENCE`
only ever appear inside a branch, never ahead of the fork. A completed object remains
available if its `GATE` stays true — for a once-only state, gate the *next* block on
`NOT object_done(location, this_id)` (see the template's `example_ledger` pair).

`OUTCOME` behaves identically to dialogue's: the selected value commits only when the player finishes the entire chosen path, is immutable, survives save/load, and a replay of a resolved FORK shows only the committed branch. Because outcomes share dialogue's store, do not reuse a `decision_id` across an OBJECT and a TOPIC unless they are genuinely the same decision. `chapter_one_objects.gd` presents a live FORK the same way `chapter_one_dialogue.gd` presents one: a button per option once the preceding cards finish, resolved through `ObjectRuntime.resume()`.

`TAKE` writes directly to `case_state.gd`'s `inventory` at the same completion point as `EVIDENCE`/`NOTEBOOK` (see above) — pair it with `GATE: NOT object_done(...)` on the object so a taken item's hotspot naturally stops offering itself once its containing block has completed. This system does not itself hide or remove the world node; see "Placement and visibility" below.

`TIME` is charged once per location+id (or TAG, if authored). An explicitly authored numeric `TIME` always wins, including `TIME: 0`. Omitted TIME costs 0 minutes — there is no dialogue-style "greeting is free, everything else falls back to 3" split, since no object id is distinguished as an opener. `LOCATION`, `OBJECT`, `TAG`, `EVIDENCE`, and `NOTEBOOK` identifiers are all validated as simple lowercase_snake_case at parse time (the cookbook's `{generated}` placeholder is the one deliberate exception), and a non-numeric/negative/non-finite `TIME` is a parse error rather than a silent fallback — a typo'd directive still becomes an unrecognized-line error or a stray speaker card, so double-check the parse errors array, not just that the file loaded.

Keep object, TAG, note, and evidence identities stable through prose edits: saves depend on them. Evidence written by an OBJECT still needs an authored entry in `chapter_one_archive.gd`'s LINKS table to become a valid linkable pair, same rule as dialogue. **Migrating an id out of `Story.FACTS`/`TownStory.FACTS` is not yet safe** — the adapter's `_sync()` only mirrors newly-discovered evidence into `case_state.evidence` when `g.facts.has(id)` is true, and `g.facts` is still built entirely from `Story.FACTS`/`TownStory.FACTS`/`TunnelStory.FACTS`. Delete a migrated id's old `SCENES` entry (it's dead code once the object intercepts it), but leave its `FACTS` entry in place until the object format grows its own evidence title/body/source metadata.

## Fail-loud: an unresolved hotspot is an error, not silence

Mirrors the intent of dialogue's own "an NPC must never go silently unresponsive" guard, but shaped differently on purpose. A `.dialogue` file has one guaranteed default slot per NPC to guard; an `.object` file authors many independent ids, each with its own cascade, and "nothing eligible right now" is frequently *correct* — the hotspot is meant to not exist yet — not a bug. A per-id authored fallback (or a parse-time "every block for this id is unreachable" check) would misfire on that legitimate pattern, since a deliberately-disabled stub (`GATE: never`, same convention as the template's `example_disabled`) is indistinguishable from a typo at parse time.

Instead, `chapter_one_objects.gd::interact()` fires only on an actual click: `ObjectRuntime.known_ids(def)` lists every id the file authors content for regardless of current GATE state, distinct from `is_available()`. A hotspot the player can click always came from `estate.points` (see `chapter_one.gd::_find_focus()`), which a correctly-absent object was never added to — so this path can only be reached by an id whose visibility check and interaction-time check disagree (a scene forgot to call `sync_points()`, or the two got out of sync some other way). When that happens it `push_error()`s and shows an obvious "EOF ERROR — PLEASE ALERT THE DEVELOPERS" panel naming the location and object id, instead of silently falling through to nothing or stale content.

## Placement and visibility (current scope)

Positions stay in GDScript, not in `.object` files — the existing per-scene pattern (`estate.gd`'s `target(id, title, pos)` hotspots and `points` dict is unchanged by this system). `LABEL:` *does* drive the hotspot's hover text: `chapter_one_objects.gd::sync_points()` overwrites `points[id]["title"]` from the currently-eligible block's `LABEL` (falling back to the capitalized id) every time it runs, so the placement call's own title argument is effectively just an initial/unused value once an id is migrated. `chapter_one.gd::_travel()` calls `sync_points()` for all three live locations (estate, town, tunnel) on every arrival, not just estate.

**Visibility is currently one-way.** `sync_points()` erases a hotspot's `points` entry once its `GATE` goes false, but nothing re-adds it if a `GATE` later becomes true again — there is no cached position to restore from once `estate.gd`'s original `target()` call is gone from `points`. Every currently-authored estate/town `GATE` (`rose_bodies_removed`, `birch_bodies_removed`, `evidence(...)`) is one-way by design (bodies removed, evidence learned — never un-happens), so this hasn't caused a visible bug yet, but don't author a `GATE` that's meant to toggle back and forth without first adding reversible hotspot registration.

What this system replaces is the *content and logic* behind an id: instead of a hardcoded `Story.SCENES`/`Story.FACTS` lookup and ad hoc `state.xyz` checks in `chapter_one.gd`, scene code:

1. Calls `ObjectRuntime.is_available(def, object_id, ctx)` (via the adapter's `sync_points()`) wherever it used to decide whether to keep a hotspot visible.
2. Calls `ObjectRuntime.enter(def, object_id, ctx, state)` (via the adapter's `interact()`) when the player actually interacts, and renders/commits/presents FORK choices the same way `chapter_one_dialogue.gd` does for NPC topics.

`estate.object`, `town.object`, and `tunnel.object` are live; see `docs/OBJECT_MIGRATION_HOWTO.md` for the migrated inventory (tunnel's other, bespoke ids are deliberately not migrated) and the per-hotspot recipe used to get here.

## Validation and provenance

`tests/object_lang_flow.gd` is the standalone grammar proof (mirrors `tests/dialogue_lang_flow.gd`); `tests/object_template_flow.gd` exercises the cookbook end-to-end, including the GATE cascade, FORK/OUTCOME, TAKE→inventory, and cross-location `object_count()` (mirrors `tests/dialogue_template_flow.gd`). `tests/object_content_flow.gd` is a live-content audit: it scans every real `objects/*.object` file for parse errors, checks every `EVIDENCE:` id against `Story.FACTS`/`TownStory.FACTS`/`TunnelStory.FACTS` (the same union `g.facts` merges), cross-checks `chapter_one.gd`'s own hardcoded wiring lists against each file's authored ids, and drives one synthetic FORK through the real `chapter_one_objects.gd` adapter inside a live `main.tscn` instance (no shipped object authors a FORK yet, so this seeds a definition straight into `ObjectRuntime`'s path cache rather than waiting for one). Run with the project's Godot console executable:

```text
godot --headless --path . --script res://tests/object_lang_flow.gd
godot --headless --path . --script res://tests/object_template_flow.gd
godot --headless --path . --script res://tests/object_content_flow.gd
```

Implementation sources: [parser](../scripts/shared/object_lang.gd), [runtime](../scripts/shared/object_runtime.gd), [object state](../scripts/shared/object_state.gd), [chapter adapter](../scripts/chapters/chapter_one_objects.gd). `case_state.gd` is schema version 10 as of this pass (adds `inventory` and `object_state`, both additive/backward-compatible). See `docs/DIALOGUE_AUTHORING.md` for the sibling NPC-facing format and the shared GATE grammar's full rationale, and `docs/OBJECT_MIGRATION_HOWTO.md` for the migration recipe and current known limitations. Unknown GATE fields/functions now fail loud (`object_lang.gd::_evaluate_cmp()`, matching `portal_lang.gd`); the one limitation still open is one-way visibility (see "Fail-loud" above).
