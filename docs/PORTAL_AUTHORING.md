# Portal authoring reference

Written 2026-09-14, as the second sibling to `docs/DIALOGUE_AUTHORING.md` (the first being `docs/OBJECT_AUTHORING.md`). This documents the flat-file PORTAL format and its game-facing runtime for travel points — hotspots that send Walter somewhere else, like `estate.gd`'s service entrance — as a deliberate parallel to the dialogue and object systems, not a subclass of either. `chapter_one_portals.gd` (the adapter, mirroring `chapter_one_objects.gd`) is wired into `chapter_one.gd`'s `_interact()`. The design bible remains authoritative for story content.

Start with [the annotated template](../portals/background_portal_template.portal). It is a cookbook, not a proposed location: delete unused examples, replace all example identifiers, and supply the actual content. Its `{generated}` location header deliberately excludes it from any future live catalog. Braces are placeholders for a human to replace, not variables.

## Why a third sibling, not an extension of dialogue or objects

A travel point is not an NPC (no schedule, no topic menu) and it is not an examine-only object either (its defining content is *where it leads*, not what it says). Because of that:

- There is no `NPC:`/`SCHEDULE:`/`WEIGHT:`/`VOICE:`/`TAKE:`, same exclusions objects already make.
- **Like `OBJECT` ids, a `PORTAL` id is expected to repeat.** Multiple `PORTAL: service_entrance` blocks may exist with different `GATE`s; the first block (file order) whose `GATE` is currently true wins. A locked state simply has no `GO` step — Walter reads or hears something and does not move; an unlocked state's `GO` step is what actually sends him somewhere.
- There is a new `GO: destination | x,y,z | yaw | flags` step — the one thing only a portal does.

The GATE mini-language is byte-for-byte the same grammar as dialogue's/objects' so one authoring skill covers all three formats; only the function/field vocabulary differs where it must.

## File structure and every directive

Use UTF-8 text, two spaces per nesting level, and no tabs. Keep directives uppercase and ids lowercase_snake_case. Comments occupy their own lines beginning with `#`; inline comments are not supported. The `LOCATION:`/`INCLUDE:` header precedes the first `PORTAL`.

| Header | Meaning |
| --- | --- |
| `LOCATION: estate` | Identity used for completion/timing keys and cross-location tallies. Does not create a scene by itself; matches an existing `state.world` value. |
| `INCLUDE: shared_portal_rebuffs.portal` | Optional, repeatable. Relative paths resolve under `res://portals/`; full `res://` paths also work. Included portals are appended only when their id is absent locally; every repeated block for a non-shadowed id is appended (not just the first), so an included cascade survives intact. There is no cycle guard — do not self-include. |

`PORTAL: stable_portal_id` starts a block at the left margin. Put all metadata at two spaces **before any steps**:

| Metadata | Meaning |
| --- | --- |
| `GATE: expression` | Availability; omitted means `never`. |
| `LABEL: "Menu/hover text"` | Optional; otherwise a capitalized version of the portal id. |
| `TAG: estate_service_entrance` | Optional additional completion identity and timing key, same purpose as dialogue's/objects'. |
| `TIME: 12.5` | Optional override, finite and nonnegative; `0` is valid. Explicit `TIME` overrides automatic travel time and is charged on every completed `GO`. Omitted `TIME` delegates to `_travel()`, which charges 30 minutes when origin and destination belong to different hubs and zero within the same hub; `nosave` suppresses automatic charging unless `elapsed` is also present. Portals without a `GO` (e.g. locked doors or paperwork refusals) do not charge clock time. |

| Step | Meaning |
| --- | --- |
| `ANY SPEAKER NAME: "Text"` | A card with that literal label — usually `WALTER CORWIN` for his own narration. No name lookup or interpolation. |
| `[A short stage direction.]` | An unspoken beat card; keep the brackets on one physical line. |
| `CHOICE: "Walter's line"` | Outside a FORK, linear Walter speech followed by its indented continuation. Rarely needed for a travel point, kept for grammar parity. |
| `FORK:` | Its indented CHOICE children become selectable options, resolved through `PortalRuntime.resume()`. Rarely needed; kept for parity. |
| `NOTEBOOK: stable_note_id \| "Account"` | Persists prose under `location.note_id`. First write wins. |
| `EVIDENCE: stable_evidence_id` | Records a linkable observation, same case-wide evidence catalog dialogue/objects write to. |
| `OUTCOME: decision_id = value_id` | Commits one immutable branch result when the entire chosen path finishes (only valid inside a FORK choice), identical semantics to dialogue's/objects'. |
| `GO: destination \| x,y,z \| yaw \| flags` | The one new step. See below. |

There are no `SET`, `GOTO`, `JUMP`, `CALL`, `WAIT`, `END`, `GIVE`, `REMOVE`, `LINK`, `WEIGHT`, `TAKE`, or `VOICE` directives in this format either. An unknown colon-prefixed line is treated as a speaker line, so parsing successfully does not prove invented syntax works.

### `GO`

```text
GO: destination | x,y,z | yaw | flags
```

- `destination` — a location id, a simple identifier matching an existing `state.world` value. Required.
- `x,y,z` — the spawn position, comma-separated numbers. Required.
- `yaw` — optional, radians, default `0.0`.
- `flags` — optional, comma-separated: `nosave` mirrors `_travel()`'s own `save` parameter (inverted — the transition does not persist as a real arrival, and suppresses automatic charging unless `elapsed` is also present), `elapsed` mirrors its `elapsed_travel` parameter (still charge automatic travel time despite `nosave`). Note that an explicit `TIME:` on the portal overrides automatic travel time completely.

`GO` is **not** a card and **not** a deferred effect like `EVIDENCE`/`NOTEBOOK`. Reaching it halts step processing immediately and hands control back to the caller — exactly like `FORK`, just with no choice to make. `chapter_one_portals.gd` is the only thing that actually calls `_travel()`; the runtime itself never touches the scene tree. Content authored **after** a `GO`renders once the caller has performed the travel and resumed (via `PortalRuntime.after_go()`) — arrival narration "from the new place," not before it. A block with no `GO` at all never moves the player; that is exactly how a locked door stays locked.

## Complete GATE vocabulary

Boolean grammar is identical to dialogue/objects: `always`, `never`, `NOT`, `AND`, `OR`, parentheses, and `<`, `<=`, `>`, `>=`, `=`, `!=`.

| Function | What it reads |
| --- | --- |
| `portal_done(location_id, portal_id_or_tag)` | Whether that location's portal id or TAG completed. Location-scoped, like `object_done`. |
| `portal_count(shared_portal_id_or_tag)` | Number of distinct locations completing that identity; repeats within one location add nothing. |
| `attempt_count(location_id, portal_id)` | Interactions begun with that hotspot; the current interaction is counted before availability is evaluated (same off-by-one convention as `examine_count()`/`visit_count()` — the first `enter()` call already reports `1`, not `0`). |
| `taken(item_id)` | Whether that item is currently in `case_state.gd`'s inventory — shared with the object system. |
| `spoken_to(npc_id)` | Whether any interaction with that NPC began — shared with dialogue, reads `dialogue_state.visit_count()` directly (this system has no NPC of its own to ask). |
| `visited(id)` | Whether `case_state.gd`'s `visited` array contains that id — a stricter, already-completed sense than `spoken_to()` (`visited` is only appended once a dialogue segment fully finishes; `spoken_to` is true the instant one merely begins). Use whichever matches the original behavior you're migrating. |
| `evidence(evidence_id)` / `filed(evidence_id)` | Case-wide evidence, identical to dialogue's/objects'. |
| `flag(flag_id)` | Boolean set by game code, **shared with dialogue and objects**. |
| `topic_done(npc_id, topic_id_or_tag)` | Whether that NPC's topic id or TAG completed — shared with dialogue, reads `dialogue_state.topic_done()` directly. |
| `outcome(decision_id)` / `outcome_is(decision_id, value_id)` | Whether/which value committed for a decision, **shared with dialogue and objects** through the same `dialogue_state.outcomes` store. |

| Field | Values/meaning |
| --- | --- |
| `coat`, `day`, `phase`, `estate_complete`, `steward_ready`, `rose_bodies_removed`, `birch_bodies_removed`, `lounge_exited`, `report` | Identical to the object system's field list — same `case_state.gd`/`DayClock` reads (`report` returns the filed report string or `""`). |
| `report_filed` | Boolean convenience (`true`/`false` form of `report`, shared across `.portal`, `.object`, and `.dialogue`): write `GATE: report_filed` / `GATE: NOT report_filed` for a plain locked/unlocked gate instead of comparing `report` against `""` — both are evaluated correctly by `_evaluate_cmp()`, but the empty-string comparison has repeatedly read as a suspected bug on inspection; prefer this field for any new boolean-shaped gate and reserve `report` for authors who need the actual filed text. |

`dialogue_runtime.gd::make_context()` and `object_runtime.gd::make_context()` were both given matching `portal_done`/`portal_count` entries for the same symmetry the object system already established with dialogue — a decision or milestone from any of the three formats is readable by the other two. Check the actual dependency id before using a gate; unknown names are not extensions.

## Completion, consequences, evidence, and time

Same completion-only semantics as objects: `NOTEBOOK`/`EVIDENCE` commit once the whole displayed segment finishes, not per acknowledged card — matching every other `_cards()`-driven flow in this codebase. There is no snapshot/restore for a mid-portal save.

`OUTCOME` behaves identically to dialogue's/objects': the selected value commits only when the player finishes the entire chosen path, is immutable, survives save/load, and shares the same store — do not reuse a `decision_id` across a PORTAL and a TOPIC/OBJECT unless they are genuinely the same decision.

`TIME` no longer has a flat default when omitted (as of September 23, 2026): an omitted `TIME` delegates entirely to `_travel()`'s own automatic charge (30 minutes crossing between hubs, free within one hub). An authored `TIME` overrides that automatic charge with the authored amount (0 is valid), and the charge fires on *every* completed traversal (`GO`) of a matching block — `portal_done()` is not consulted for charging, so repeat crossings of a timed route cost time again, same as the first; it remains useful only for gating content/labels (e.g. switching a "Pay the toll" label to "Cross again"). Non-traversing portal segments (e.g. locked doors, flavor rejections) do not charge clock time.

Evidence written by a PORTAL still needs an authored entry in `chapter_one_archive.gd`'s LINKS table to become linkable, same rule as dialogue/objects.

## Known limitation: genuinely dynamic post-arrival content

Some existing travel points render content computed from live state at the moment of arrival — the tunnel exit's custody-result card (`chapter_one.gd::_custody_result()`) branches on which supplement was sent and what it contained, not a static string. That cannot be authored as flat prose without a much richer expression language than GATE supports, and forcing it in would be the same mistake dialogue/object authoring already learned not to make with `_source_for()`-style dynamic text. Keep that kind of content as a small, explicitly named adapter-level special case in `chapter_one_portals.gd` (the same principle as `lounge_exit`'s `lounge_exited = true` side effect) rather than inventing a generic "insert dynamic content here" directive.

## Placement, visibility, and fail-loud

Positions stay in GDScript, not in `.portal` files — same as objects, `estate.gd`'s `target(id, title, pos)`/`routes` dict is unchanged. `LABEL:` drives the hover text: `chapter_one_portals.gd::sync_points()` overwrites `points[id]["title"]` from the currently-eligible block's `LABEL` every time it runs, mirroring the object system exactly, including its one-way limitation (a hotspot erased because its `GATE` went false does not come back on its own if the `GATE` later becomes true again).

A hotspot the player can click that resolves to no eligible state — a visibility/GATE desync — fails loudly with a `push_error()` and an on-screen "EOF ERROR — PLEASE ALERT THE DEVELOPERS" panel naming the location and id, instead of silently doing nothing, mirroring the object system's guard exactly (see `docs/OBJECT_AUTHORING.md`'s "Fail-loud" section for the full rationale).

## Validation and provenance

`tests/portal_lang_flow.gd` is the standalone grammar proof (mirrors `tests/object_lang_flow.gd`); `tests/portal_template_flow.gd` exercises the cookbook end-to-end. Run with the project's Godot console executable:

```text
godot --headless --path . --script res://tests/portal_lang_flow.gd
godot --headless --path . --script res://tests/portal_template_flow.gd
```

Implementation sources: [parser](../scripts/shared/portal_lang.gd), [runtime](../scripts/shared/portal_runtime.gd), [portal state](../scripts/shared/portal_state.gd), [chapter adapter](../scripts/chapters/chapter_one_portals.gd). `case_state.gd` is schema version 11 as of this pass (adds `portal_state`, additive/backward-compatible). See `docs/DIALOGUE_AUTHORING.md` and `docs/OBJECT_AUTHORING.md` for the other two formats and the shared GATE grammar's full rationale.
