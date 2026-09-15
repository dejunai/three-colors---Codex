extends RefCounted

# Chapter adapter: maps the shared portal-system effects onto real travel,
# mirroring chapter_one_objects.gd's shape (itself mirroring
# chapter_one_dialogue.gd). Authored GATE/TAG/TIME/EVIDENCE/GO stay in
# .portal files; this owns presentation and actually calls _travel().
#
# Effects (NOTEBOOK/EVIDENCE) commit once their segment finishes, matching
# every other _cards()-driven flow in this codebase — same rationale as
# chapter_one_objects.gd. GO is not an effect: it is a circuit breaker (like
# FORK) the adapter must act on directly, since only chapter_one.gd can
# actually call _travel().
const Runtime = preload("res://scripts/shared/portal_runtime.gd")

# Most locations have no .portal file at all — that is the normal case, not
# an authoring mistake, so callers check this first rather than letting
# Runtime.load_location() push_error() on a routine, expected absence.
func _exists(location: String) -> bool:
	return FileAccess.file_exists("res://portals/" + location + ".portal")

func definition(location: String) -> Dictionary:
	return Runtime.load_location("res://portals/" + location + ".portal")

func available(g: Node, location: String, portal_id: String) -> bool:
	if not _exists(location): return false
	return Runtime.is_available(definition(location), portal_id, Runtime.make_context(g.state))

# Refreshes a hotspot's hover text from the currently-eligible block's LABEL,
# same convention as chapter_one_objects.gd::sync_points(). Call this
# wherever a location's `points` get (re)built for the current state.
func sync_points(g: Node, location: String, ids: Array) -> void:
	if not _exists(location): return
	var def = definition(location)
	var ctx = Runtime.make_context(g.state)
	for id in ids:
		if not g.estate or not g.estate.points.has(id): continue
		if Runtime.is_available(def, id, ctx):
			g.estate.points[id]["title"] = Runtime.label_for(def, id, ctx)
		else:
			g.estate.points.erase(id)

# Fail-loud guard: identical rationale to chapter_one_objects.gd's — a
# hotspot the player can click always came from estate.points, so a known
# portal id that resolves to nothing eligible here means visibility and GATE
# have gone out of sync, not that the portal is legitimately absent.
func interact(g: Node, location: String, portal_id: String) -> bool:
	if not _exists(location): return false
	var def = definition(location)
	if not Runtime.known_ids(def).has(portal_id): return false
	var ctx = Runtime.make_context(g.state)
	if not Runtime.is_available(def, portal_id, ctx):
		_fail_loud(g, location, portal_id)
		return true
	var result = Runtime.enter(def, portal_id, ctx, g.state)
	if result.session.is_empty(): return false
	g.scripted_dialogue.clear()
	g.card_kind = "examine"
	_play(g, result)
	return true

func _play(g: Node, result: Dictionary) -> void:
	g.dialogue.start(result.cards, g._draw_card, func(): _advance(g, result))

func _advance(g: Node, result: Dictionary) -> void:
	Runtime.commit_through(result, g.state, result.cards.size())
	_sync(g)
	if result.go != null:
		_perform_go(g, result)
		return
	if result.fork != null:
		_present_fork(g, result)
		return
	g._close()
	g._save_game()

# TIME: an omitted TIME defaults to 3 minutes (matching dialogue substantive
# topic defaults), charged once the first time this portal identity ever completes
# (checked via portal_done(), mirroring object_runtime.gd's first_completion guard) —
# every crossing after that is free, matching portal_done()'s own bookkeeping.
# An explicit numeric TIME override (including 0) is respected.
func _perform_go(g: Node, result: Dictionary) -> void:
	var go = result.go
	var portal_id = String(result.session.portal)
	var location = String(result.session.location)
	var tag = String(result.session.tag)
	var spawn = Vector3(go.spawn[0], go.spawn[1], go.spawn[2])
	var flags: Array = go.flags
	var timing = String(result.session.timing)
	_before_travel(g, portal_id, go.destination)
	if timing.is_valid_float():
		var already_completed = g.state.portal_state.portal_done(location, portal_id) or (not tag.is_empty() and g.state.portal_state.portal_done(location, tag))
		if not already_completed:
			# Charge before _travel() so its telemetry reflects the real
			# post-charge clock, matching the automatic-charge path's order.
			Runtime.DayClock.advance(g.state, float(timing))
		g._travel(go.destination, spawn, go.yaw, false, false)
	else:
		g._travel(go.destination, spawn, go.yaw, not flags.has("nosave"), flags.has("elapsed"))
	var extra = _extra_cards(g, portal_id, go.destination)
	var resumed = Runtime.after_go(result)
	if resumed.is_empty():
		g._close()
		g._save_game()
		return
	# Always route through _play()/_advance() even when resumed.cards is
	# empty — dialogue_sequence.gd's start() invokes its completion callback
	# immediately for an empty sequence, which is what actually calls
	# commit_through() on the resumed result. Skipping _play() here (as a
	# prior version did) meant an "immediate GO" with no post-arrival cards
	# (e.g. service_entrance's unlocked block) never completed its portal
	# session at all.
	if not extra.is_empty():
		g.card_kind = "examine"
		g._cards(extra, func(): _play(g, resumed))
	else:
		_play(g, resumed)

# A small, explicitly named escape hatch for the rare travel point whose
# post-arrival content or side effect is genuinely dynamic (computed from
# live state, not static prose) — see docs/PORTAL_AUTHORING.md's "Known
# limitation" section. Keep this list short; anything expressible as static
# prose or a GATE belongs in the .portal file instead.
func _before_travel(g: Node, portal_id: String, destination: String) -> void:
	if portal_id == "exit" and destination == "town":
		g.state.estate_complete = true
		g.state.estate_visits_completed += 1
		g.state.rose_bodies_removed = true
		if is_instance_valid(g.estate) and g.estate.has_method("sync_staging"):
			g.estate.sync_staging(g.state)
		if g.state.world == "estate":
			g.objects.sync_points(g, "estate", ["wounds","watch","knife","eight","shoes"])
	if portal_id == "street_estate" and destination == "estate":
		if g.state.day >= 3 and g.state.estate_visits_completed >= 2:
			g.state.birch_bodies_removed = true
	if portal_id == "tunnel_exit" and destination == "precinct":
		g.state.tunnel_complete = true
	if portal_id == "lounge_exit":
		g.state.lounge_exited = true

func _extra_cards(g: Node, portal_id: String, destination: String) -> Array:
	if portal_id == "exit" and destination == "town":
		return g.TownStory.ARRIVAL
	if portal_id == "tunnel_exit" and destination == "precinct":
		return [["BACK AT THE PRECINCT", g._custody_result()]]
	return []

func _present_fork(g: Node, result: Dictionary) -> void:
	g._panel("witness", "", "WALTER'S CHOICE", false, "examine")
	for index in result.fork.options.size():
		var choice_label = String(result.fork.options[index])
		g._button('"' + choice_label + '"', func(): _choose(g, result, index))
	g._focus_first()

func _choose(g: Node, result: Dictionary, index: int) -> void:
	var resumed = Runtime.resume(result, index)
	if resumed.is_empty(): return
	_play(g, resumed)


func _fail_loud(g: Node, location: String, portal_id: String) -> void:
	push_error("Portal hotspot '%s.%s' was clickable but no authored state currently applies to it — GATE and hotspot visibility have gone out of sync." % [location, portal_id])
	g._panel("case", "EOF ERROR — PLEASE ALERT THE DEVELOPERS", "PORTAL UNRESOLVED")
	g._paragraph("This hotspot was reachable, but nothing currently authored for it applies.\n\nLocation: %s\nPortal: %s" % [location, portal_id], 20)
	g._button("Close", g._close)
	g._focus_first()

func _sync(g: Node) -> void:
	for id in g.state.portal_state.evidence:
		if g.facts.has(id): g.state.discover(id)
	for text in g.state.portal_state.facts.values(): g.state.record(text)
