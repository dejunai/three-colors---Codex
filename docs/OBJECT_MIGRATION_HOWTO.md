# How to migrate activator objects into flat `.object` files

Written 2026-09-14. Companion to `docs/OBJECT_AUTHORING.md` (the grammar reference) and
`docs/DIALOGUE_AUTHORING.md` (the sibling system this mirrors). This is the practical,
step-by-step recipe for moving an existing hand-coded world hotspot — an "activator
object" — out of `estate.gd`/`town.gd`/`tunnel.gd` + `story.gd`/`town_story.gd` +
`chapter_one.gd`'s hardcoded dispatch, and into a real `objects/*.object` file backed by
`object_lang.gd`/`object_runtime.gd`/`object_state.gd`.

**Status as of this update: estate's 7 ids, town's 3 ids, and tunnel's 1 id are migrated and live**
(`objects/estate.object`, `objects/town.object`, `objects/tunnel.object`, wired through
`scripts/chapters/chapter_one_objects.gd`). Sections 2 and 4 below are now a record of
how that happened, not a to-do — read them to understand the pattern before touching
tunnel or any new location. Known gaps found during review, since fixed: FORK/OUTCOME
now actually presents choices live (§2); an unresolved-but-clickable hotspot fails loud
instead of silently doing nothing (§2, `docs/OBJECT_AUTHORING.md`'s "Fail-loud" section);
`LABEL:` now really drives the hover text, for all three locations (§2/§4); `INCLUDE`d
files no longer drop repeated cascade variants; `LOCATION`/`OBJECT`/`TAG`/`EVIDENCE`/
`NOTEBOOK` ids and `TIME` are now validated at parse time. Since fixed: unknown GATE
fields/functions now fail loud (`object_lang.gd::_evaluate_cmp()` `push_error()`s and
returns false for both, matching `portal_lang.gd`) rather than silently parsing. Still
open: visibility is one-way only (§4) — see `docs/OBJECT_AUTHORING.md`'s "Validation and
provenance" for the current list.

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

## 2. The adapter (already built)

`ObjectRuntime` doesn't call itself — something has to invoke
`is_available()`/`enter()`/`commit_through()`/`resume()`. That's
`scripts/chapters/chapter_one_objects.gd`, the object-system equivalent of
`chapter_one_dialogue.gd`. It's one shared, location-agnostic adapter (not one file per
location) — every call takes a `location` string parameter, so estate/town/tunnel (and
any future location) all go through the same code. Current content, for reference:

```gdscript
extends RefCounted

# Chapter adapter: maps the shared object-system effects onto the existing case
# record, mirroring chapter_one_dialogue.gd's own _sync() pattern. Authored
# GATE/TAG/TIME/EVIDENCE/TAKE stay in .object files; this owns presentation only.
#
# Effects (NOTEBOOK/EVIDENCE/TAKE) commit only once the whole displayed segment
# finishes, not per acknowledged card — this matches every other _cards()-driven
# examine flow in this codebase, not a shortcut unique to objects. There is no
# snapshot/restore for a mid-object save, same as those other flows; only the
# dialogue system has that.
const Runtime = preload("res://scripts/shared/object_runtime.gd")

func definition(location: String) -> Dictionary:
	return Runtime.load_location("res://objects/" + location + ".object")

func available(g: Node, location: String, object_id: String) -> bool:
	return Runtime.is_available(definition(location), object_id, Runtime.make_context(g.state))

# Also refreshes the hotspot's hover text from the currently-eligible block's
# LABEL — placement (target()'s position) stays in GDScript, but content picks
# the text shown for it.
func sync_points(g: Node, location: String, ids: Array) -> void:
	var def = definition(location)
	var ctx = Runtime.make_context(g.state)
	for id in ids:
		if not g.estate or not g.estate.points.has(id): continue
		if Runtime.is_available(def, id, ctx):
			g.estate.points[id]["title"] = Runtime.label_for(def, id, ctx)
		else:
			g.estate.points.erase(id)

# Fail-loud guard: _interact(id) only ever runs for an id currently sitting in
# estate.points (a hotspot the scene already believes is there). If this id
# belongs to the object system at all (known_ids) but is not currently available,
# sync_points() should already have erased it — reaching here anyway means the
# GATE and the hotspot's visibility have gone out of sync, this system's analogue
# of dialogue's "silently unresponsive NPC" bug. Surface it loudly instead of
# falling through to stale/dead content. See docs/OBJECT_AUTHORING.md's
# "Fail-loud" section for the full rationale.
func interact(g: Node, location: String, object_id: String) -> bool:
	var def = definition(location)
	if not Runtime.known_ids(def).has(object_id): return false
	var ctx = Runtime.make_context(g.state)
	if not Runtime.is_available(def, object_id, ctx):
		_fail_loud(g, location, object_id)
		return true
	var result = Runtime.enter(def, object_id, ctx, g.state)
	if result.session.is_empty(): return false
	g.scripted_dialogue.clear()
	g.card_kind = "examine"
	var label = Runtime.label_for(def, object_id, ctx)
	_play(g, result, object_id, label)
	return true

func _play(g: Node, result: Dictionary, object_id: String, label: String) -> void:
	g.dialogue.start(result.cards, g._draw_card, func():
		Runtime.commit_through(result, g.state, result.cards.size())
		_sync(g, object_id)
		if result.fork != null:
			_present_fork(g, result, object_id, label)
			return
		g._close()
		g._toast("Recorded in Walter's case file.  [ Tab ]", 4)
		g._save_game())

func _present_fork(g: Node, result: Dictionary, object_id: String, label: String) -> void:
	g._panel("witness", label, "WALTER'S CHOICE", false, "examine")
	for index in result.fork.options.size():
		var choice_label = String(result.fork.options[index])
		g._button('"' + choice_label + '"', func(): _choose(g, result, index, object_id, label))
	g._focus_first()

func _choose(g: Node, result: Dictionary, index: int, object_id: String, label: String) -> void:
	var resumed = Runtime.resume(result, index)
	if resumed.is_empty(): return
	_play(g, resumed, object_id, label)

func _fail_loud(g: Node, location: String, object_id: String) -> void:
	push_error("Object hotspot '%s.%s' was clickable but no authored state currently applies to it — GATE and hotspot visibility have gone out of sync." % [location, object_id])
	g._panel("case", "EOF ERROR — PLEASE ALERT THE DEVELOPERS", "OBJECT UNRESOLVED")
	g._paragraph("This hotspot was reachable, but nothing currently authored for it applies.\n\nLocation: %s\nObject: %s" % [location, object_id], 20)
	g._button("Close", g._close)
	g._focus_first()

func _sync(g: Node, object_id: String = "") -> void:
	if not object_id.is_empty() and not g.state.visited.has(object_id):
		g.state.visited.append(object_id)
	for id in g.state.object_state.evidence:
		if g.facts.has(id): g.state.discover(id)
	for text in g.state.object_state.facts.values(): g.state.record(text)
```

It's already wired into `chapter_one.gd`:

```gdscript
var objects=preload("res://scripts/chapters/chapter_one_objects.gd").new()
```

and called from `_interact()` (before the generic `Story.SCENES[key]` fallback),
`_town_interaction()`/`_town_observation()`, `_tunnel_interaction()`, and every place
`chapter_one.gd::_travel()` rebuilds the world's `points` (an `if`/`elif`/`else` on
`destination` that calls `objects.sync_points()` for `"estate"`, `"tunnel"`, or
`"town"` respectively) plus `_write_report()`/`_finish()`/`_refresh_outfit()`'s
estate-only sync calls. For a brand-new location, follow that same shape: one
`objects.interact(self, "<location>", id)` line ahead of the old fallback, one
`objects.sync_points(self, "<location>", [...ids...])` line wherever that location's
`points` get (re)built.

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

7. **Remove the old `SCENES` entry only — leave `FACTS` alone.** Delete `id` from
   `Story.SCENES`/`TownStory.SCENES` (or the tunnel equivalent) once you've confirmed
   the migrated version works; it's dead code once `objects.interact()` intercepts the
   id first. **Do not delete the matching `FACTS` entry.** The adapter's `_sync()` only
   mirrors newly-discovered evidence into `case_state.evidence` when `g.facts.has(id)`
   is true, and `g.facts` is still assembled from `Story.FACTS`/`TownStory.FACTS`/
   `TunnelStory.FACTS` (`chapter_one.gd::start()`). Deleting a migrated id's `FACTS`
   entry silently stops that evidence from ever reaching the playable case file. Leave
   `FACTS` in place until the object format grows its own evidence title/body/source
   metadata and registers it without going through `g.facts` at all. Also trim the id
   out of the `"examine" if id in [...]` list in `chapter_one.gd` once its `SCENES`
   entry is gone, so the list stays an accurate "not yet migrated" inventory.

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

Two things worth knowing about this example, so you don't get surprised elsewhere:
- **This is why `rose_bodies_removed`/`birch_bodies_removed`/`lounge_exited` are now in
  the exposed GATE field list** (`docs/OBJECT_AUTHORING.md`'s vocabulary table) —
  migrating `wounds` needed the first one, and the other two followed for the ids that
  came after it. `object_runtime.gd::make_context()`'s `"fields"` dict (and, for
  symmetry, `dialogue_runtime.gd`'s) is scoped to what content actually needs, not
  every `case_state.gd` field — expect to add more there the same way as new ids need
  new state to gate on.
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
`estate.gd` for it. At the time `wounds` was migrated, every `estate.sync_staging(state)`
call site in `chapter_one.gd` got a second line right after it:
```gdscript
estate.sync_staging(state)
if state.world == "estate": objects.sync_points(self, "estate", ["wounds","watch","knife"])
```
That single-location shape is now superseded: `_travel()` (the one place that rebuilds
`points` from scratch for whichever destination is entered) was later generalized to an
`if`/`elif`/`else` covering `"estate"`/`"tunnel"`/every other (town-family) destination,
so the same LABEL-refresh/erase logic runs for all three live locations, not just
estate — see §2's current adapter listing and its wiring paragraph for the accurate
present-day shape. The `_write_report()`/`_finish()`/`_refresh_outfit()` call sites
stayed estate-only, since none of their triggers are relevant to town/tunnel content.
The corresponding `if st.rose_bodies_removed: for id in [...]: points.erase(id)` block
was deleted from `sync_staging()` itself once `sync_points()` replaced it.

**Once confirmed working**, delete `"wounds"` from `Story.SCENES` only (leave
`Story.FACTS["wounds"]` in place — see step 7) and trim it out of the
`["wounds","eight","knife","watch","gas","register","shoes"]` list at `chapter_one.gd`'s
old dispatch site as each id migrates; once that list is empty, delete the whole
fallback branch (but `g.facts`'s three-way `FACTS` merge stays regardless).

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
