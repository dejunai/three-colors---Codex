# How to migrate activator objects into flat `.object` files

Written 2026-09-14. Companion to `docs/OBJECT_AUTHORING.md` (the grammar reference) and
`docs/DIALOGUE_AUTHORING.md` (the sibling system this mirrors). This is the practical,
step-by-step recipe for moving an existing hand-coded world hotspot — an "activator
object" — out of `estate.gd`/`town.gd`/`tunnel.gd` + `story.gd`/`town_story.gd` +
`chapter_one.gd`'s hardcoded dispatch, and into a real `objects/*.object` file backed by
`object_lang.gd`/`object_runtime.gd`/`object_state.gd`.

Do this **one hotspot at a time**, run the tests after each one, and commit. Do not try
to migrate a whole location in one pass — the generic fallback in `chapter_one.gd`
(`_interact()`'s `Story.SCENES[key]` lookup) is shared plumbing for every un-migrated id
in that location; breaking it early breaks everything not yet migrated.

## 1. What counts as an "activator object" here

Not every id dispatched through `Story.SCENES`/`TownStory.SCENES` is an object. Some are
NPC stand-ins that predate (or duplicate) the dialogue system and belong in a
`.dialogue` file instead, not a `.object` file. The reliable test already exists in the
code: the `kind` argument chapter_one.gd passes to `_cards()`. `"examine"` means "this is
a physical thing Walter looks at," `"dialogue"` means "this is someone talking."

Current inventory, read directly from the dispatch sites:

| Location | Examine-mode ids (true objects, migrate here) | Dispatch site |
| --- | --- | --- |
| estate | `wounds`, `eight`, `knife`, `watch`, `gas`, `register`, `shoes` | `chapter_one.gd::_interact()`, the generic `Story.SCENES[key]` fallback, ~line 406 |
| town | `gazette`, `lodging`, `exemption` | `chapter_one.gd::_town_observation()`, ~line 770 |
| tunnel | `tunnel_record` (multi-card, `"examine"` kind) | `chapter_one.gd::_tunnel_interaction()` |

`tunnel_edge` looks similar but isn't: it calls `state.discover(...)` then
`chapter_one_archive.gd::_fact()` directly, which jumps straight to the "review a
previously recorded fact" panel instead of playing a card sequence first. That's a
different, simpler shortcut pattern, not the same "examine cards, then record" flow the
other ids use — leave it as-is rather than forcing it into an `OBJECT:` block.

**Leave everything else alone for now.** `boy`, `assistant`, `gardener`, `odell`,
`crew`, `club_talk`/`club_devotion`/`pantry_lead`, `old_woman`, `lay_lead`,
`service_work`, `behan_name`, etc. are `"dialogue"`-kind — they're witnesses, and some
(`odell`, `old_woman`, `lay_lead`, `service_work`, `behan_name`) already have a live
`.dialogue` file or a `scripted_dialogue` route sitting alongside their legacy
`Story.SCENES` entry. Migrating those is a **dialogue**-system task (arguably finishing
work `dialogue_runtime.gd` already started), not this object migration.

Tunnel's remaining ids (`tunnel_notes`, `tunnel_descent`, `drowned_remains`,
`cultist_encounter`, `tunnel_exit`) are bespoke game logic (combat, flask state,
staggered timers, travel branching) — they are not static examine content and do not
belong in the flat grammar at all. Don't force them in.

## 2. Prerequisite: the adapter (do this once, before any hotspot)

`ObjectRuntime` is currently only called by its own tests — nothing in the live game
invokes `is_available()`/`enter()`/`commit_through()` yet. You need a small adapter,
the object-system equivalent of `chapter_one_dialogue.gd`. Create
`scripts/chapters/chapter_one_objects.gd`:

```gdscript
extends RefCounted

# Chapter adapter: maps the shared object-system effects onto the existing case
# record, mirroring chapter_one_dialogue.gd's own _sync() pattern. Authored
# GATE/TAG/TIME/EVIDENCE/TAKE stay in .object files; this owns presentation only.
const Runtime = preload("res://scripts/shared/object_runtime.gd")

func definition(location: String) -> Dictionary:
	return Runtime.load_location("res://objects/" + location + ".object")

func available(g: Node, location: String, object_id: String) -> bool:
	return Runtime.is_available(definition(location), object_id, Runtime.make_context(g.state))

# Call this from wherever the location currently checks `points.has(id)`/erases a
# point (e.g. estate.gd's sync_staging()) instead of the ad hoc state check.
func sync_points(g: Node, location: String, ids: Array) -> void:
	var def = definition(location)
	var ctx = Runtime.make_context(g.state)
	for id in ids:
		if not Runtime.is_available(def, id, ctx): g.estate.points.erase(id)

# Call this from _interact() instead of falling through to Story.SCENES[key].
func interact(g: Node, location: String, object_id: String) -> bool:
	var def = definition(location)
	var ctx = Runtime.make_context(g.state)
	if not Runtime.is_available(def, object_id, ctx): return false
	var result = Runtime.enter(def, object_id, ctx, g.state)
	if result.session.is_empty(): return false
	g.card_kind = "examine"
	_play(g, result)
	return true

func _play(g: Node, result: Dictionary) -> void:
	g.dialogue.start(result.cards, g._draw_card, func():
		Runtime.commit_through(result, g.state, result.cards.size())
		_sync(g)
		if result.fork != null:
			# TODO once a real FORK-bearing object ships: render result.fork.options
			# as buttons, call Runtime.resume(result, choice), then _play(g, resumed).
			g._close()
			return
		g._close()
		g._toast("Recorded in Walter's case file.  [ Tab ]",4)
		g._save_game())

func _sync(g: Node) -> void:
	# Same rationale as chapter_one_dialogue.gd's _sync(): object_runtime.gd writes
	# to object_state's own pending tallies (testable without engine references),
	# so the adapter promotes them into the real case record here.
	for id in g.state.object_state.evidence:
		if g.facts.has(id): g.state.discover(id)
	for text in g.state.object_state.facts.values(): g.state.record(text)
```

Then wire it into `chapter_one.gd`:

```gdscript
var objects = preload("res://scripts/chapters/chapter_one_objects.gd").new()
```

(next to the existing `var scripted_dialogue = ...` / `var staging = ...` declarations),
and in `_interact()`, add a call **before** the generic `Story.SCENES[key]` fallback —
right alongside the existing `staging.interact(...)`/`scripted_dialogue.interact(...)`
lines:

```gdscript
func _interact(id:String) -> void:
	if staging.interact(self,id): return
	if scripted_dialogue.interact(self,id): return
	if objects.interact(self,"estate",id): return   # <- add this
	if _tunnel_interaction(id): return
	if _town_interaction(id): return
```

Only pass `"estate"` for ids you've actually migrated for that location — see step 4.
Don't route every id through `objects.interact()` yet; it'll just return `false` for
anything without a matching `.object` file, which is safe, but there's no reason to
call it for ids you haven't authored.

## 3. Per-hotspot recipe

For each id you're migrating:

1. **Find the hotspot registration.** Search the location's `.gd` file (`estate.gd`,
   `town.gd`, `tunnel.gd`) for `target("<id>", "<title>", <pos>)` or
   `tabletop_target(...)`. Note the title string — it becomes `LABEL:`. **Leave the
   `target()` call exactly where it is** — position/placement stays in GDScript, per
   the object system's design (see `docs/OBJECT_AUTHORING.md`, "Placement and
   visibility").

2. **Find the content.** Look up `id` in `Story.FACTS`/`Story.SCENES` (estate),
   `TownStory.FACTS`/`TownStory.SCENES` (town), or the equivalent tunnel constant.
   - `FACTS[id]` is `[title, body, source]` — `body` becomes case-file evidence prose.
   - `SCENES[id]` is an array of `[speaker, text]` pairs — each becomes a step.

3. **Find the availability rule.** This is scattered today: check
   `chapter_one_staging.gd::interact()`'s early-return list (e.g.
   `if id in ["wounds","watch","knife"] and g.state.rose_bodies_removed: return true`)
   and the location's `sync_staging()` (e.g. `if st.rose_bodies_removed: for id in
   ["wounds","watch","knife"]: points.erase(id)`). Translate that condition directly
   into `GATE:`. A once-only object also needs `NOT object_done(location, id)` in its
   GATE so it doesn't re-offer itself after completion, unless the original was always
   re-examinable.

4. **Write the OBJECT block** in `objects/<location>.object` (create the file with a
   `LOCATION: <location>` header if it doesn't exist yet):

   ```text
   OBJECT: <id>
     GATE: <translated availability> AND NOT object_done(<location>, <id>)
     LABEL: "<title from target()>"
     [<first SCENES card's text, as a beat if its speaker was a location/object label>]
     <SPEAKER>: "<any card whose speaker is a person, e.g. WALTER CORWIN or an NPC name>"
     NOTEBOOK: <id>_note | "<FACTS[id][1], the body text>"
     EVIDENCE: <id>
   ```

   A card whose speaker is a place/object label (e.g. `"THE ROSE GARDEN"`,
   `"EXAMINE · JUDGE WEXFORD"`) reads as a beat (`[...]`) in the new grammar just as
   easily as a spoken line with that literal label — either is valid; prefer a beat
   when the original text is scene-setting narration rather than something with a
   speaking "voice." A card literally labelled `"WALTER'S NOTEBOOK"` is flavor, not a
   real note — see `docs/DIALOGUE_AUTHORING.md`'s note on that convention, it applies
   here too.

5. **Cut over the dispatch.** In `_interact()` (or `_town_observation()`/
   `_tunnel_interaction()`), make sure `objects.interact(self, "<location>", id)` is
   called before the generic `Story.SCENES` fallback for this id specifically. Since
   `objects.interact()` returns `false` when nothing matches, you can leave the old
   fallback in place until every id in the location is migrated — it's dead code for
   already-migrated ids (never reached, because the object call already returned
   `true`) but harmless.

6. **Cut over visibility.** Replace the hardcoded `sync_staging()` check for this id
   with `objects.sync_points(g, "<location>", ["<id>"])` (or fold several ids into one
   call). Confirm the `GATE` you wrote in step 3 reproduces the same visibility.

7. **Remove the old entries** — delete `id` from `Story.FACTS`/`Story.SCENES` (or the
   town/tunnel equivalent) and from the `"examine" if id in [...]` list in
   `chapter_one.gd`, once you've confirmed the migrated version works. Don't delete
   before confirming; a stale-but-unreachable old entry is harmless, a half-migrated id
   with no content anywhere is a silent dead hotspot.

8. **Test.** At minimum: `godot --headless --path . --script res://tests/object_lang_flow.gd`
   stays green (unaffected, but cheap to confirm), then the relevant `--qa-*` flow for
   that location (`Test opening.cmd` for estate, `Test town.cmd` for town). Walk the
   hotspot manually if you can — GATE cascades are easy to get subtly wrong (see the
   off-by-one note on `examine_count()`/`visit_count()` in `docs/OBJECT_AUTHORING.md`).

## 4. Worked example: estate's `wounds`

**Find the registration** (`estate.gd`):
```gdscript
target("wounds","Examine the six men",Vector3(0,0,0))
```
Leave this line untouched.

**Find the content** (`story.gd`):
```gdscript
"wounds": ["NO EXIT WOUND", "Six men in evening dress. A small wound above the bridge of each nose. No corresponding wound behind the skull. No powder marks on the collars.", "Rose garden · direct examination"],
```
```gdscript
"wounds": [
	["THE ROSE GARDEN", "Six men in evening dress, arranged in a half-circle.\n\nWalter knows five of the faces. Judge Wexford. Dr. Fenn. Corliss, the district attorney. Pruitt. Kessler.\n\nThe sixth means nothing to him."],
	["EXAMINE · JUDGE WEXFORD", "A wound above the bridge of the nose.\nNo powder scorching.\n\nWalter turns the head.\nThere is no exit wound."],
	["WALTER'S NOTEBOOK", "The other five present the same condition.\n\nNo weapon in any visible hand.\nCause and sequence unestablished.\n\nThe observation is exact. It is the explanation that is missing."]],
```

**Find the availability rule** (`estate.gd::sync_staging()`):
```gdscript
if st.rose_bodies_removed:
	for id in ["wounds","watch","knife"]: points.erase(id)
```
So: available whenever the bodies haven't been removed yet.

**Write `objects/estate.object`:**
```text
LOCATION: estate

OBJECT: wounds
  GATE: NOT rose_bodies_removed
  LABEL: "Examine the six men"
  [Six men in evening dress, arranged in a half-circle. Walter knows five of the faces: Judge Wexford. Dr. Fenn. Corliss, the district attorney. Pruitt. Kessler. The sixth means nothing to him.]
  [A wound above the bridge of the nose. No powder scorching. Walter turns the head. There is no exit wound.]
  NOTEBOOK: wounds_note | "The other five present the same condition.\n\nNo weapon in any visible hand.\nCause and sequence unestablished.\n\nThe observation is exact. It is the explanation that is missing."
  EVIDENCE: wounds
```

Two things to flag honestly about this example, so you don't get surprised elsewhere:
- **`rose_bodies_removed` is not in the exposed GATE field list** (`docs/OBJECT_AUTHORING.md`
  only documents `coat`, `day`, `phase`, `estate_complete`, `steward_ready`). You'll need
  to add a `"rose_bodies_removed": func(): return state.rose_bodies_removed,` entry to
  `object_runtime.gd::make_context()`'s `"fields"` dict (and, for symmetry, to
  `dialogue_runtime.gd`'s too, the way this session already added `object_done`/
  `object_count`/`taken` to it). Expect to do this for a handful of other state fields
  as you migrate more ids (`birch_bodies_removed`, `lounge_exited`, etc.) — the exposed
  vocabulary was scoped to what dialogue content needed at the time, not to every field
  the object migration will want.
- This example has no `TIME:` — matches current behavior exactly. `DayClock.advance()`
  is never called for these examine cards today (confirmed: `conversation_key()` only
  charges time for ids explicitly listed in `day_clock.gd`'s `ESTATE_TALKS`/
  `TOWN_TALKS`, and none of the seven estate examine ids are in that list), and an
  omitted `TIME:` in the new grammar is also free. No behavior change.

**Cut over** in `chapter_one.gd::_interact()`:
```gdscript
func _interact(id:String) -> void:
	if staging.interact(self,id): return
	if scripted_dialogue.interact(self,id): return
	if objects.interact(self,"estate",id): return
	if _tunnel_interaction(id): return
	if _town_interaction(id): return
```

**Cut over visibility.** `estate.gd::sync_staging(st)` only ever receives `state`, not
the `chapter_one.gd` instance that owns `objects` — don't reach outward from
`estate.gd` for it. Instead, since every call site already looks like
`estate.sync_staging(state)` from inside `chapter_one.gd` (four call sites, e.g.
`scripts/chapters/chapter_one.gd:486`), add the object sync as a second line right
after each one:
```gdscript
estate.sync_staging(state)
if state.world == "estate": objects.sync_points(self, "estate", ["wounds","watch","knife"])
```
and delete the corresponding `if st.rose_bodies_removed: for id in [...]: points.erase(id)`
block from `sync_staging()` itself once this replaces it.

**Once confirmed working**, delete `"wounds"` from `Story.FACTS`, `Story.SCENES`, and
from the `["wounds","eight","knife","watch","gas","register","shoes"]` list at
`chapter_one.gd`'s old dispatch site (trim the list down as each id migrates; once it's
empty, delete the whole fallback branch).

## 5. Suggested order

1. Estate's seven ids first — most uniform, all through one dispatcher, one
   `sync_staging()` to touch, and this doc's worked example covers one already.
2. Town's three ids next (`gazette`, `lodging`, `exemption`) — same shape, different
   adapter entry point (`_town_observation()` instead of the generic fallback). Note
   `lodging`'s extra pre-check (`if id=="lodging" and not state.evidence.has("naomi")`,
   which shows a redirect panel instead of the observation): you can either leave that
   check in `_town_interaction()` ahead of the `objects.interact()` call, or fold it
   into `GATE: evidence(naomi) AND ...` in the `.object` file and drop the special-cased
   panel — the grammar supports it either way, your call.
3. Leave tunnel's bespoke ids alone (see §1) unless/until there's a concrete reason to
   force them into this grammar.

## 6. Don't forget

- New `EVIDENCE:` ids still need an entry in `chapter_one_archive.gd`'s `LINKS` table
  to become linkable on the board — unchanged by this migration, same rule dialogue
  content already follows.
- `Runtime.load_location()` caches by path (`ObjectRuntime.clear_cache()` exists for
  tests/hot-reload); if you edit a `.object` file while iterating in a running session,
  you may need that cache cleared to see changes.
- Re-run `tests/object_lang_flow.gd` and `tests/object_template_flow.gd` after any
  `object_lang.gd`/`object_runtime.gd` change (e.g. adding a new GATE field) — they're
  fast and standalone, no reason to skip them.
