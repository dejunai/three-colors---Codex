extends RefCounted

# Chapter adapter: maps the shared object-system effects onto the existing case
# record, mirroring chapter_one_dialogue.gd's own _sync() pattern. Authored
# GATE/TAG/TIME/EVIDENCE/TAKE stay in .object files; this owns presentation only.
#
# Effects (NOTEBOOK/EVIDENCE/TAKE) commit only once the whole displayed segment
# finishes, not per acknowledged card — this matches every other _cards()-driven
# examine flow in this codebase (the old Story.SCENES fallback, _town_observation,
# etc. all apply their effects in the completion callback too), not a shortcut
# unique to objects. There is no snapshot/restore for a mid-object save, same as
# those other flows; only the dialogue system has that.
const Runtime = preload("res://scripts/shared/object_runtime.gd")

func definition(location: String) -> Dictionary:
	return Runtime.load_location("res://objects/" + location + ".object")

func available(g: Node, location: String, object_id: String) -> bool:
	return Runtime.is_available(definition(location), object_id, Runtime.make_context(g.state))

# Call this from wherever the location currently checks `points.has(id)`/erases a
# point (e.g. estate.gd's sync_staging()) instead of the ad hoc state check. Also
# refreshes the hotspot's hover text from the currently-eligible block's LABEL,
# since placement (target()'s position) stays in GDScript but content picks the
# text shown for it.
func sync_points(g: Node, location: String, ids: Array) -> void:
	var def = definition(location)
	var ctx = Runtime.make_context(g.state)
	for id in ids:
		if not g.estate or not g.estate.points.has(id): continue
		if Runtime.is_available(def, id, ctx):
			g.estate.points[id]["title"] = Runtime.label_for(def, id, ctx)
		else:
			g.estate.points.erase(id)

# Call this from _interact() instead of falling through to Story.SCENES[key].
#
# Fail-loud guard: _interact(id) only ever runs for an id currently sitting in
# estate.points (see chapter_one.gd::_find_focus()/_unhandled_input) — the player
# can only click a hotspot the scene already believes is there. So if this id
# belongs to the object system at all (known_ids) but is not currently available,
# sync_points() should already have erased it; reaching here anyway means the
# GATE that governs visibility and the GATE checked at the moment of interaction
# disagree, or a location forgot to call sync_points() for this id. That is
# exactly this system's analogue of dialogue's "silently unresponsive NPC" bug —
# surface it loudly instead of falling through to stale/dead content.
func interact(g: Node, location: String, object_id: String) -> bool:
	var def = definition(location)
	if not Runtime.known_ids(def).has(object_id): return false
	var ctx = Runtime.make_context(g.state)
	if not Runtime.is_available(def, object_id, ctx):
		_fail_loud(g, location, object_id)
		return true
	var label = Runtime.label_for(def, object_id, ctx)
	if not g.test_mode and location == "estate" and object_id in ["watch", "knife"] and not g.state.object_state.object_done(location, object_id) and g.estate.points.has(object_id) and g.rig.has_method("play_ground_pickup"):
		var point: Vector3 = g.estate.points[object_id].get("pos", g.player.global_position)
		g.rig.play_ground_pickup(point,
			func():
				if object_id == "knife" and is_instance_valid(g.estate.opening_knife): g.estate.opening_knife.hide(),
			func(): _begin(g, def, object_id, label))
		return true
	_begin(g, def, object_id, label)
	return true

func _begin(g: Node, def: Dictionary, object_id: String, label: String) -> void:
	var ctx = Runtime.make_context(g.state)
	var result = Runtime.enter(def, object_id, ctx, g.state)
	if result.session.is_empty(): return
	g.scripted_dialogue.clear()
	g.card_kind = "examine"
	_play(g, result, object_id, label)

func _play(g: Node, result: Dictionary, object_id: String, label: String) -> void:
	g.dialogue.start(result.cards, g._draw_card, func():
		Runtime.commit_through(result, g.state, result.cards.size())
		_sync(g, object_id)
		if result.fork != null:
			_present_fork(g, result, object_id, label)
			return
		if is_instance_valid(g.estate) and g.estate.has_method("sync_staging"):
			g.estate.sync_staging(g.state)
		if g.state.world == "estate":
			sync_points(g, "estate", ["wounds","watch","knife","eight","shoes","gas","register"])
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

# Mirrors dialogue's "EOF Error, please alert developers" guard, adapted to
# this system's shape: dialogue has one guaranteed default slot per NPC to
# append a catch-all to, but an object file authors many independent ids, each
# with its own cascade, and "nothing eligible" is often correct (the hotspot
# is meant to not exist yet) rather than a bug — so this can't be a per-id
# authored fallback without breaking intentional absence. Firing this only
# when a real click reached an unavailable-but-known id sidesteps that: a
# hotspot that's correctly absent is never in estate.points to begin with, so
# this path is never reached for it.
func _fail_loud(g: Node, location: String, object_id: String) -> void:
	push_error("Object hotspot '%s.%s' was clickable but no authored state currently applies to it — GATE and hotspot visibility have gone out of sync." % [location, object_id])
	g._panel("case", "EOF ERROR — PLEASE ALERT THE DEVELOPERS", "OBJECT UNRESOLVED")
	g._paragraph("This hotspot was reachable, but nothing currently authored for it applies.\n\nLocation: %s\nObject: %s" % [location, object_id], 20)
	g._button("Close", g._close)
	g._focus_first()

func _sync(g: Node, object_id: String = "") -> void:
	# Same rationale as chapter_one_dialogue.gd's _sync(): object_runtime.gd writes
	# to object_state's own pending tallies (testable without engine references),
	# so the adapter promotes them into the real case record here.
	if not object_id.is_empty() and not g.state.visited.has(object_id):
		g.state.visited.append(object_id)
	for id in g.state.object_state.evidence:
		if g.facts.has(id): g.state.discover(id)
	for text in g.state.object_state.facts.values(): g.state.record(text)
