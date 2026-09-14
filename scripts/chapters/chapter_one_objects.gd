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
		if not Runtime.is_available(def, id, ctx):
			if g.estate and g.estate.points.has(id):
				g.estate.points.erase(id)

# Call this from _interact() instead of falling through to Story.SCENES[key].
func interact(g: Node, location: String, object_id: String) -> bool:
	var def = definition(location)
	var ctx = Runtime.make_context(g.state)
	if not Runtime.is_available(def, object_id, ctx): return false
	var result = Runtime.enter(def, object_id, ctx, g.state)
	if result.session.is_empty(): return false
	g.scripted_dialogue.clear()
	g.card_kind = "examine"
	_play(g, result, location, object_id)
	return true

func _play(g: Node, result: Dictionary, location: String = "", object_id: String = "") -> void:
	g.dialogue.start(result.cards, g._draw_card, func():
		Runtime.commit_through(result, g.state, result.cards.size())
		_sync(g, object_id)
		if result.fork != null:
			# TODO once a real FORK-bearing object ships: render result.fork.options
			# as buttons, call Runtime.resume(result, choice), then _play(g, resumed).
			g._close()
			return
		g._close()
		g._toast("Recorded in Walter's case file.  [ Tab ]", 4)
		g._save_game())

func _sync(g: Node, object_id: String = "") -> void:
	# Same rationale as chapter_one_dialogue.gd's _sync(): object_runtime.gd writes
	# to object_state's own pending tallies (testable without engine references),
	# so the adapter promotes them into the real case record here.
	if not object_id.is_empty() and not g.state.visited.has(object_id):
		g.state.visited.append(object_id)
	for id in g.state.object_state.evidence:
		if g.facts.has(id): g.state.discover(id)
	for text in g.state.object_state.facts.values(): g.state.record(text)