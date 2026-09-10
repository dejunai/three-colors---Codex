extends RefCounted

# Chapter adapter owns presentation and maps shared interpreter effects to the
# existing case record. Authored GATE/TAG/TIME/EVIDENCE remain in .dialogue files.
const Runtime = preload("res://scripts/shared/dialogue_runtime.gd")
const DialogueState = preload("res://scripts/shared/dialogue_state.gd")
var FILES = {"boy":"gatehouse_boy", "assistant":"coroners_assistant", "crew":"groundskeeper", "gardener":"gardener", "odell":"odell", "almy":"mrs_almy", "behan":"father_behan", "barman":"steward", "old_woman":"old_woman"}
var TITLES = {"boy":"The gatehouse boys", "assistant":"The coroner's assistant", "crew":"The groundskeeper", "gardener":"The gardener", "odell":"Captain Odell", "almy":"Mrs. Almy", "behan":"Father Behan", "barman":"The club's steward", "old_woman":"The woman outside Kessler's shop"}
var catalog = preload("res://scripts/chapters/dialogue_catalog.gd").new()
var extra_actors: Array[String] = []
var figures: Dictionary = {}
var population_world_id = 0
var population_phase = ""
var active: Dictionary = {}
var segment: Dictionary = {}
var offset = 0

func setup(g: Node) -> void:
	catalog.scan()
	for npc in catalog.paths:
		if FILES.values().has(catalog.paths[npc]): continue
		FILES[npc] = catalog.paths[npc]
		TITLES[npc] = catalog.titles[npc]
		extra_actors.append(npc)
	catalog.add_facts(g.facts)

func populate(g: Node) -> void:
	var phase = Runtime.DayClock.phase(g.state.clock_minutes)
	if population_world_id == g.estate.get_instance_id() and population_phase == phase: return
	population_world_id = g.estate.get_instance_id()
	population_phase = phase
	for actor in figures:
		if is_instance_valid(figures[actor]): figures[actor].queue_free()
	figures.clear()
	for actor in extra_actors:
		g.estate.points.erase(actor)
		var spot = catalog.slot(actor,g.state)
		if spot.is_empty() or spot[0] != g.state.world: continue
		var figure = g.estate.person(spot[1], "55624f", true, "a17643" if actor=="harbor_observer" else "")
		figures[actor] = figure
		g.estate.target(actor,"Speak with " + TITLES[actor],spot[1])
		if g.state.world == "stationer": g.estate.points.erase("local_resident")

func definition(actor: String) -> Dictionary:
	return Runtime.load_npc("res://dialogue/" + FILES[actor] + ".dialogue")

func clear() -> void:
	active = {}
	segment = {}

func allowed(g: Node, actor: String) -> bool:
	if not FILES.has(actor): return false
	if extra_actors.has(actor):
		var spot = catalog.slot(actor,g.state)
		return not spot.is_empty() and spot[0] == g.state.world
	if actor == "barman": return g.state.world == "lounge" and g.state.visited.has("almy")
	if actor in ["odell", "assistant"]: return g.state.world == "estate" and not g.state.estate_complete
	if actor == "crew": return g.state.world == "estate" and g.state.lounge_exited
	if actor == "old_woman": return g.state.world == "town" and not g.state.evidence.has("old_woman")
	return definition(actor).location == g.state.world

func interact(g: Node, actor: String) -> bool:
	if not FILES.has(actor): return false
	if not allowed(g, actor): return true
	if not active.is_empty(): return true
	var def = definition(actor)
	# Steward visit_count reflects staged days, not repeated attempts at the bar.
	if actor == "barman": g.state.dialogue_state.visit_counts[def.npc] = g.state.steward_visits
	var result = Runtime.enter(def, Runtime.make_context(g.state, g.state.dialogue_state), g.state.dialogue_state)
	if actor == "barman": g.state.dialogue_state.visit_counts[def.npc] = g.state.steward_visits
	if result.session.is_empty():
		show_menu(g, actor)
		return true
	var selected = Runtime.menu(def, Runtime.make_context(g.state, g.state.dialogue_state)).default_topic
	_begin(g, actor, def.topics.find(selected), result)
	return true

func show_menu(g: Node, actor: String) -> void:
	if not allowed(g, actor): g._close(); return
	var def = definition(actor)
	var entries = Runtime.menu(def, Runtime.make_context(g.state, g.state.dialogue_state)).entries
	if entries.is_empty() and actor != "odell": g._close(); return
	g._panel("witness", TITLES[actor], "ASK, LISTEN, RECORD")
	if actor == "odell": g._paragraph("Walter's answer is already in his notebook. Odell has nothing further to add.")
	for entry in entries:
		g._button(entry.label, func(): play_topic(g, actor, entry.id))
	g._button("Leave the conversation", g._close)
	g._focus_first()

func play_topic(g: Node, actor: String, topic_id: String) -> void:
	if not allowed(g, actor) or not active.is_empty(): return
	var def = definition(actor)
	var ctx = Runtime.make_context(g.state, g.state.dialogue_state)
	for index in def.topics.size():
		var topic = def.topics[index]
		if topic.id == topic_id and not topic.steps.is_empty() and Runtime.Lang.evaluate(topic.gate, ctx):
			_begin(g, actor, index, Runtime.render(def.npc, topic, g.state.dialogue_state))
			return
	show_menu(g, actor)

func _begin(g: Node, actor: String, index: int, result: Dictionary) -> void:
	active = {"actor":actor, "topic_index":index, "choices":[], "consumed":0,
		"signature": JSON.stringify(definition(actor).topics[index]).sha256_text()}
	segment = result
	_display(g)
	g._save_game()

func _sync(g: Node) -> void:
	for id in g.state.dialogue_state.evidence:
		if g.facts.has(id): g.state.discover(id)
	for text in g.state.dialogue_state.facts.values(): g.state.record(text)
	if is_instance_valid(g.estate) and g.estate.has_method("sync_actors"): g.estate.sync_actors(g.state)
	elif g.state.world == "town" and g.state.evidence.has("old_woman") and g.estate.has_method("dismiss_old_woman"): g.estate.dismiss_old_woman()

func _acknowledge(g: Node, count: int) -> bool:
	active.consumed = count
	var complete = Runtime.commit_through(segment, g.state, g.state.dialogue_state, count)
	_sync(g)
	return complete

func _display(g: Node) -> void:
	offset = int(active.consumed)
	# Restore already-consumed effects without charging timing or another visit.
	_acknowledge(g, offset)
	if offset == segment.cards.size(): _segment_done(g); return
	g.dialogue.start(segment.cards.slice(offset), g._draw_card, func(): _segment_done(g))

func next(g: Node) -> void:
	if active.is_empty() or g.page != "dialogue": return
	_acknowledge(g, offset + g.dialogue.index + 1)
	g.dialogue.next()
	g._save_game()

func _segment_done(g: Node) -> void:
	if active.is_empty(): return
	var actor = String(active.actor)
	if segment.fork != null:
		# Odell's count is already heard before Walter gives his answer.
		if actor == "odell" and not g.state.visited.has(actor): g.state.visited.append(actor)
		g._panel("witness", TITLES[actor], "WALTER'S ANSWER")
		var current = segment
		for index in segment.fork.options.size():
			var label = String(segment.fork.options[index])
			g._button('"' + label + '"' if not label.begins_with("Say nothing") else label, func(): _choose(g, current, index))
		g._focus_first()
		return
	var tag = String(segment.session.tag)
	if not g.state.visited.has(actor): g.state.visited.append(actor)
	if actor == "barman":
		if tag == "steward_first" and g.state.steward_visits == 0: g.state.steward_visits = 1
		elif tag == "steward_open": g.state.steward_visits = 3
		g.state.dialogue_state.visit_counts["steward"] = g.state.steward_visits
	if tag in ["almy_trust", "behan_invitation", "lay_lead", "service_work", "behan_name", "old_woman", "club_talk", "club_devotion", "pantry_lead"]:
		if not g.state.inquiry_topics.has(tag): g.state.inquiry_topics.append(tag)
	if is_instance_valid(g.daylight): g.daylight.update_clock(g.state.clock_minutes, g.player.position)
	clear()
	_sync(g)
	populate(g)
	if (actor in ["almy", "behan", "barman"] or extra_actors.has(actor)) and tag != "almy_ledger": show_menu(g, actor)
	else: g._close()
	if tag == "almy_ledger": g._toast("The meal ledger is on the sideboard to your right.",5)
	g._save_game()

func _choose(g: Node, current: Dictionary, index: int) -> void:
	if active.is_empty() or current != segment: return
	var label = String(segment.fork.options[index])
	var result = Runtime.resume(segment, index)
	if result.is_empty(): return
	active.choices.append(index)
	active.consumed = 0
	segment = result
	# Choosing Walter's line consumes that line; don't ask Continue for his own choice.
	if not segment.cards.is_empty() and segment.cards[0] == ["WALTER CORWIN", label]:
		_acknowledge(g, 1)
	_display(g)
	g._save_game()

func snapshot() -> Dictionary:
	return active.duplicate(true)

# Rebuild from authored data and choice history, not executable data in a save.
# Prior segments are replayed only into scratch state, never shown or recounted.
func restore(g: Node, data: Variant) -> bool:
	clear()
	if not data is Dictionary or data.is_empty(): return false
	if not data.get("actor", "") is String or not FILES.has(data.actor): return false
	if not data.get("choices", []) is Array: return false
	for key in ["topic_index", "consumed"]:
		if not (data.get(key) is int or data.get(key) is float): return false
		if not is_finite(float(data[key])) or float(data[key]) != floor(float(data[key])): return false
	var def = definition(data.actor)
	var index = int(data.topic_index)
	if index < 0 or index >= def.topics.size(): return false
	if data.get("signature", "") != JSON.stringify(def.topics[index]).sha256_text(): return false
	var scratch = DialogueState.new()
	var result = Runtime.render(def.npc, def.topics[index], scratch)
	for choice in data.choices:
		if not (choice is int or choice is float) or not is_finite(float(choice)) or float(choice) != floor(float(choice)): return false
		Runtime.commit_through(result, null, scratch, result.cards.size())
		result = Runtime.resume(result, int(choice))
		if result.is_empty(): return false
	if int(data.consumed) < 0 or int(data.consumed) > result.cards.size(): return false
	active = data.duplicate(true)
	segment = result
	_display(g)
	return true
