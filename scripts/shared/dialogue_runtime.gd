extends RefCounted

# Game-facing half of the dialogue system: builds the GATE-evaluation
# context from live game state, loads/caches parsed .dialogue files, picks
# an NPC's current default line and menu, and renders a chosen topic into
# the same [speaker, text] card-array shape story.gd/town_story.gd already
# use, so dialogue_sequence.gd/chapter_interface.gd need no changes to
# consume it. Live presentation is owned by ChapterOneDialogue; see
# tests/dialogue_lang_flow.gd for a full standalone proof, and the note at
# the bottom of this file for what remains to integrate it live.
const Lang = preload("res://scripts/shared/dialogue_lang.gd")
const DayClock = preload("res://scripts/shared/day_clock.gd")

static var _cache: Dictionary = {}

static func clear_cache() -> void:
	_cache.clear()

static func load_npc(path: String) -> Dictionary:
	if _cache.has(path): return _cache[path]
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing dialogue file: %s" % path)
		var empty = {"npc": "", "location": "", "schedule": {}, "includes": [], "topics": [], "errors": []}
		_cache[path] = empty
		return empty
	var parsed = Lang.parse(file.get_as_text())
	var known: Dictionary = {}
	for topic in parsed.topics: known[topic.id] = true
	for include_value in parsed.get("includes", []):
		var include_path = include_value if include_value.begins_with("res://") else "res://dialogue/" + include_value
		var included = load_npc(include_path)
		for topic in included.topics:
			if not known.has(topic.id):
				parsed.topics.append(topic)
				known[topic.id] = true
	for error in parsed.errors:
		push_error("dialogue parse error (%s:%d): %s" % [path, error.line, error.message])
	_cache[path] = parsed
	return parsed

static func make_context(state, dstate) -> Dictionary:
	return {
		"functions": {
			"visit_count": func(args): return dstate.visit_count(args[0]) if args.size() > 0 else 0,
			"topic_count": func(args): return dstate.topic_count(args[0]) if args.size() > 0 else 0,
			"spoken_to": func(args): return dstate.visit_count(args[0]) > 0 if args.size() > 0 else false,
			"evidence": func(args): return has_evidence(state, args[0]) if args.size() > 0 else false,
			"filed": func(args): return has_filed_evidence(state, args[0]) if args.size() > 0 else false,
			"flag": func(args): return dstate.flag(args[0]) if args.size() > 0 else false,
			"topic_done": func(args): return dstate.topic_done(args[0], args[1]) if args.size() > 1 else false,
		},
		"fields": {
			"coat": func(): return state.coat,
			"day": func(): return state.day,
			"phase": func(): return DayClock.phase(state.clock_minutes),
			"estate_complete": func(): return state.estate_complete,
			"steward_ready": func(): return state.steward_ready(),
		}

	}

# Draft gate vocabulary mapped to the already-authored observations. These
# aliases read existing records; they do not grant extra evidence or Perception.
# Read received snapshots, never the player's current unsubmitted observations.
# This gate changes no copy and grants no evidence or Perception.
static func has_filed_evidence(state, id: String) -> bool:
	if state == null: return false
	var report = state.get("report_evidence", []) if state is Dictionary else state.report_evidence
	var intake_done = state.get("intake_done", false) if state is Dictionary else state.intake_done
	if bool(intake_done) and report is Array and report.has(id): return true
	var history = state.get("supplement_history", []) if state is Dictionary else state.supplement_history
	if history is Array:
		for supplement in history:
			var filed = []
			if supplement is Dictionary:
				filed = supplement.get("evidence", [])
			elif supplement is Object:
				filed = supplement.get("evidence")
			if filed is Array and filed.has(id): return true
	return false

static func has_evidence(state, id: String) -> bool:
	if state.evidence.has(id): return true
	var aliases = {"ophion_name":["behan_name","ophion_myth_classical"], "kessler_standing":["kessler_carriages"]}
	for source in aliases.get(id, []):
		if state.evidence.has(source): return true
	return false

# Finds the winning `default` topic (first true GATE, file order) and every
# other topic currently GATE-true, as menu entries. Does not render or
# apply effects — prepare with play_topic(), then acknowledge playback.
static func menu(def: Dictionary, ctx: Dictionary) -> Dictionary:
	var default_topic = null
	var entries: Array = []
	for topic in def.topics:
		if topic.steps.is_empty(): continue
		if not Lang.evaluate(topic.gate, ctx): continue
		if topic.id == "default":
			if default_topic == null: default_topic = topic
		else:
			entries.append({"id": topic.id, "label": topic.label if not topic.label.is_empty() else topic.id.capitalize()})
	return {"default_topic": default_topic, "entries": entries}

# A fresh interaction counts one visit. A FORK continues this same session
# through resume(); never call enter() again to answer a pending choice.
static func enter(def: Dictionary, ctx: Dictionary, dstate) -> Dictionary:
	dstate.visit(def.npc)
	var selection = menu(def, ctx)
	var result = _empty_result()
	if selection.default_topic != null:
		result = render(def.npc, selection.default_topic, dstate)
	result["entries"] = selection.entries
	return result

static func play_topic(def: Dictionary, dstate, topic_id: String) -> Dictionary:
	for topic in def.topics:
		if topic.id == topic_id: return render(def.npc, topic, dstate)
	return _empty_result()

static func _empty_result() -> Dictionary:
	return {"cards": [], "fork": null, "effects": [], "session": {}, "acknowledged": -1, "finished": false, "resumed": false}

# Preparation is side-effect free. The caller acknowledges displayed cards
# with commit_through(), then passes this result to resume() after a choice.
# Sessions are transient playback cursors, not save payloads.
static func render(npc: String, topic: Dictionary, _dstate) -> Dictionary:
	var session = {"npc": npc, "topic": topic.id,
		"stack": [{"steps": topic.steps, "i": 0}], "pending": [],
		"tag": topic.get("tag", ""), "timing": topic.get("timing", "")}
	return _next_segment(session)

static func _next_segment(session: Dictionary) -> Dictionary:
	var result = _empty_result()
	result.session = session
	var stack: Array = session.stack
	while not stack.is_empty():
		var frame = stack[stack.size() - 1]
		if frame.i >= frame.steps.size():
			stack.pop_back()
			continue
		var step = frame.steps[frame.i]
		frame.i += 1
		match String(step.kind):
			"line": result.cards.append([step.speaker, step.text])
			"beat": result.cards.append(["", step.text])
			"evidence":
				result.effects.append({"kind": "evidence", "id": step.id, "after_cards": result.cards.size(), "applied": false})
			"notebook":
				var note_id = String(step.get("id", ""))
				# Legacy unlabelled notes remain supported without ordinal collisions.
				# Authors should supply an explicit id to survive future wording edits.
				if note_id.is_empty(): note_id = "text_" + String(step.text).sha256_text()
				result.effects.append({"id": session.npc + "." + note_id,
					"text": step.text, "after_cards": result.cards.size(), "applied": false})
			"fork":
				session.pending = step.options
				result.fork = {"options": step.options.map(func(o): return o.label)}
				return result
	return result

# Call only after the first count cards of this segment have been consumed.
# Returns true exactly once when the whole topic finishes: on that first
# completion (and only then — repeats and "nothing more to say" replays
# never re-fire this), TIME: minutes are charged to the day clock via
# DayClock.advance(), giving each topic its own cost instead of a blanket
# per-interaction charge. A topic with no TIME: (or a non-numeric one)
# falls back to DEFAULT_MINUTES rather than silently costing nothing.
const DEFAULT_MINUTES = 3.0
static func commit_through(result: Dictionary, state, dstate, count: int) -> bool:
	if result.session.is_empty() or result.resumed or result.finished: return false
	if count < result.acknowledged or count > result.cards.size(): return false
	result.acknowledged = count
	for effect in result.effects:
		if not effect.applied and effect.after_cards <= count:
			if effect.get("kind", "notebook") == "evidence": dstate.discover(effect.id)
			else: dstate.record_fact(effect.id, effect.text)
			effect.applied = true
	if count == result.cards.size() and result.fork == null:
		# gardener_plain/gardener (etc.) share the reserved "default" topic id but
		# are genuinely separate scenes distinguished only by TAG — charge time per
		# TAG when one is authored, so the second variant isn't wrongly "already done".
		var time_key = result.session.tag if not result.session.tag.is_empty() else result.session.topic
		var first_completion = not dstate.topic_done(result.session.npc, time_key)
		if state != null and not result.session.tag.is_empty() and state.timed_conversations.has(time_key): first_completion = false
		dstate.complete_topic(result.session.npc, result.session.topic)
		if not result.session.tag.is_empty(): dstate.complete_topic(result.session.npc, result.session.tag)
		if first_completion and state != null:
			var raw_minutes = String(result.session.timing)
			DayClock.advance(state, float(raw_minutes) if raw_minutes.is_valid_float() else DEFAULT_MINUTES)
			if not result.session.tag.is_empty() and not state.timed_conversations.has(time_key): state.timed_conversations.append(time_key)
		result.finished = true
		return true
	return false

# Continue the saved stack, including nested forks and the parent tail.
# Invalid/stale choices leave the pending segment untouched and return {}.
static func resume(result: Dictionary, choice: int) -> Dictionary:
	if result.resumed or result.fork == null or result.acknowledged != result.cards.size(): return {}
	var options: Array = result.session.pending
	if choice < 0 or choice >= options.size(): return {}
	result.resumed = true
	result.session.pending = []
	result.session.stack.append({"steps": options[choice].steps, "i": 0})
	return _next_segment(result.session)

static func enter_by_path(path: String, state, dstate) -> Dictionary:
	return enter(load_npc(path), make_context(state, dstate), dstate)

static func play_topic_by_path(path: String, _state, dstate, topic_id: String) -> Dictionary:
	return play_topic(load_npc(path), dstate, topic_id)

# ChapterOneDialogue handles live menus, branching, effect mirroring and resumable saves.
# Numeric TIME costs are committed here exactly once, not by the legacy card timer.
