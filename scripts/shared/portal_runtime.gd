extends RefCounted

# Game-facing half of the portal system: builds the GATE-evaluation context
# from live game state, loads/caches parsed .portal files, resolves which
# gated variant of a travel point currently applies, and renders it into the
# same [speaker, text] card shape the dialogue/object runtimes already
# produce (no per-line voice field — portal narration stays unvoiced).
# Deliberately a sibling of object_runtime.gd, not built on top of it: a
# portal's defining content is where it leads, not what it says, so its step
# vocabulary adds GO and treats it as a FORK-like circuit breaker rather than
# a deferred effect.
#
# Cross-system sharing is intentional, not accidental: OUTCOME and FLAG both
# read/write through the case's single dialogue_state instance, so a
# decision or flag set from a TOPIC, an OBJECT, or a PORTAL are always the
# same fact. EVIDENCE/FILED reuse dialogue_runtime.gd's existing case-evidence
# helpers for the same reason — they describe case_state, not any one NPC.
const Lang = preload("res://scripts/shared/portal_lang.gd")
const DialogueRuntime = preload("res://scripts/shared/dialogue_runtime.gd")
const DayClock = preload("res://scripts/shared/day_clock.gd")

static var _cache: Dictionary = {}

static func clear_cache() -> void:
	_cache.clear()

static func load_location(path: String) -> Dictionary:
	if _cache.has(path): return _cache[path]
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Missing portal file: %s" % path)
		var empty = {"location": "", "includes": [], "portals": [], "errors": []}
		_cache[path] = empty
		return empty
	var parsed = Lang.parse(file.get_as_text())
	var local_ids: Dictionary = {}
	for portal in parsed.portals: local_ids[portal.id] = true
	for include_value in parsed.get("includes", []):
		var include_path = include_value if include_value.begins_with("res://") else "res://portals/" + include_value
		var included = load_location(include_path)
		for portal in included.portals:
			# Every repeated block for a non-shadowed id is appended, not just the
			# first — repeated PORTAL ids are the core state-cascade mechanism, so
			# truncating to one variant would silently break an included cascade.
			if not local_ids.has(portal.id): parsed.portals.append(portal)
	for error in parsed.errors:
		push_error("portal parse error (%s:%d): %s" % [path, error.line, error.message])
	_cache[path] = parsed
	return parsed

static func make_context(state) -> Dictionary:
	return {
		"functions": {
			"portal_done": func(args): return state.portal_state.portal_done(args[0], args[1]) if args.size() > 1 else false,
			"portal_count": func(args): return state.portal_state.portal_count(args[0]) if args.size() > 0 else 0,
			"attempt_count": func(args): return state.portal_state.attempt_count(args[0], args[1]) if args.size() > 1 else 0,
			"taken": func(args): return state.has_item(args[0]) if args.size() > 0 else false,
			"spoken_to": func(args): return state.dialogue_state.visit_count(args[0]) > 0 if args.size() > 0 else false,
			"topic_done": func(args): return state.dialogue_state.topic_done(args[0], args[1]) if args.size() > 1 else false,
			"npc_done": func(args): return state.dialogue_state.topic_done(args[0], "default") if args.size() > 0 else false,
			# Distinct from spoken_to(): state.visited only records a FULLY completed
			# interaction (see chapter_one_dialogue.gd::_segment_done()), while
			# spoken_to() is true the instant a conversation merely begins. Several
			# existing portal checks (e.g. service_entrance) rely on the stricter,
			# already-completed sense, so both stay available rather than picking one.
			"visited": func(args): return state.visited.has(args[0]) if args.size() > 0 else false,
			"evidence": func(args): return DialogueRuntime.has_evidence(state, args[0]) if args.size() > 0 else false,
			"filed": func(args): return DialogueRuntime.has_filed_evidence(state, args[0]) if args.size() > 0 else false,
			"flag": func(args): return state.dialogue_state.flag(args[0]) if args.size() > 0 else false,
			"outcome": func(args): return state.dialogue_state.has_outcome(args[0]) if args.size() > 0 else false,
			"outcome_is": func(args): return state.dialogue_state.outcome_is(args[0], args[1]) if args.size() > 1 else false,
		},
		"fields": {
			"coat": func(): return state.coat,
			"day": func(): return state.day,
			"phase": func(): return DayClock.phase(state.clock_minutes),
			"estate_complete": func(): return state.estate_complete,
			"steward_ready": func(): return state.steward_ready(),
			"rose_bodies_removed": func(): return state.rose_bodies_removed,
			"birch_bodies_removed": func(): return state.birch_bodies_removed,
			"lounge_exited": func(): return state.lounge_exited,
			"report": func(): return state.report,
			# Boolean form of `report`, added so gates can write
			# `GATE: report_filed` / `GATE: NOT report_filed` instead of
			# comparing against a literal "" — the substring-containment
			# semantics of `=`/`!=` (see _evaluate_cmp()) are correct either
			# way, but an empty-string comparison reads as ambiguous and has
			# repeatedly been misdiagnosed as a bug on sight. Prefer this
			# field for any new boolean-shaped gate; `report` itself stays
			# for authors who need the actual filed text.
			"report_filed": func(): return not state.report.is_empty(),
		}
	}

static func is_available(def: Dictionary, portal_id: String, ctx: Dictionary) -> bool:
	return select(def, portal_id, ctx) != null

# Public: the adapter also uses this to drive a hotspot's hover LABEL, since
# placement (target()'s position) lives in GDScript but content picks the text.
static func select(def: Dictionary, portal_id: String, ctx: Dictionary):
	for portal in def.portals:
		if portal.id != portal_id or portal.steps.is_empty(): continue
		if Lang.evaluate(portal.gate, ctx): return portal
	return null

# Every distinct id this file authors at least one populated block for,
# regardless of current GATE state — lets the adapter tell "not ours" apart
# from "ours, but nothing eligible right now" (fail-loud guard).
static func known_ids(def: Dictionary) -> Dictionary:
	var ids: Dictionary = {}
	for portal in def.portals:
		if not portal.steps.is_empty(): ids[portal.id] = true
	return ids

static func label_for(def: Dictionary, portal_id: String, ctx: Dictionary) -> String:
	var portal = select(def, portal_id, ctx)
	if portal == null: return ""
	var label = String(portal.get("label", ""))
	return label if not label.is_empty() else portal_id.capitalize()

static func _empty_result() -> Dictionary:
	return {"cards": [], "fork": null, "go": null, "effects": [], "session": {}, "acknowledged": -1, "finished": false, "resumed": false}

# A fresh interaction counts one attempt. Resuming a halted FORK/GO continues
# the same session through resume()/after_go(); never call enter() again mid-session.
static func enter(def: Dictionary, portal_id: String, ctx: Dictionary, state) -> Dictionary:
	var location = String(def.get("location", ""))
	state.portal_state.attempt(location, portal_id)
	var selected = select(def, portal_id, ctx)
	if selected == null: return _empty_result()
	return render(location, selected, state)

# Preparation is side-effect free. The caller acknowledges displayed cards
# with commit_through(), then passes this result to resume()/after_go().
static func render(location: String, portal: Dictionary, state) -> Dictionary:
	var locked_outcomes: Dictionary = {}
	for key in portal.get("outcome_keys", []):
		if state.dialogue_state.has_outcome(String(key)):
			locked_outcomes[String(key)] = String(state.dialogue_state.outcomes[String(key)])
	var session = {"location": location, "portal": portal.id,
		"stack": [{"steps": portal.steps, "i": 0}], "pending": [],
		"pending_outcomes": {}, "locked_outcomes": locked_outcomes,
		"tag": portal.get("tag", ""), "timing": portal.get("timing", "")}
	return _next_segment(session)

static func _outcome_values(steps: Array) -> Dictionary:
	var found: Dictionary = {}
	for step in steps:
		match String(step.get("kind", "")):
			"outcome":
				var id = String(step.id)
				if not found.has(id): found[id] = []
				if not found[id].has(String(step.value)): found[id].append(String(step.value))
			"fork":
				for option in step.options:
					var nested = _outcome_values(option.steps)
					for id in nested:
						if not found.has(id): found[id] = []
						for value in nested[id]:
							if not found[id].has(value): found[id].append(value)
	return found

static func _locked_fork_options(options: Array, locked: Dictionary) -> Array:
	if locked.is_empty(): return options
	var authored: Array = []
	var relevant: Array[String] = []
	for option in options:
		var values = _outcome_values(option.steps)
		authored.append(values)
		for id in locked:
			if values.has(id) and not relevant.has(String(id)): relevant.append(String(id))
	if relevant.is_empty(): return options
	var matching: Array = []
	for index in options.size():
		var accepts = true
		for id in relevant:
			if not authored[index].has(id) or not authored[index][id].has(String(locked[id])):
				accepts = false
				break
		if accepts: matching.append(options[index])
	return matching if not matching.is_empty() else options

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
				if note_id.is_empty(): note_id = "text_" + String(step.text).sha256_text()
				result.effects.append({"kind": "notebook", "id": session.location + "." + note_id,
					"text": step.text, "after_cards": result.cards.size(), "applied": false})
			"outcome": session.pending_outcomes[String(step.id)] = String(step.value)
			"go":
				result.go = {"destination": step.destination, "spawn": step.spawn, "yaw": step.yaw, "flags": step.flags}
				return result
			"fork":
				var options = _locked_fork_options(step.options, session.get("locked_outcomes", {}))
				session.pending = options
				result.fork = {"options": options.map(func(o): return o.label)}
				return result
	return result

# Call only after the first count cards of this segment have been consumed.
# Returns true exactly once when the whole portal finishes (reaching the true
# end with no pending FORK/GO).
static func commit_through(result: Dictionary, state, count: int) -> bool:
	if result.session.is_empty() or result.resumed or result.finished: return false
	if count < result.acknowledged or count > result.cards.size(): return false
	result.acknowledged = count
	for effect in result.effects:
		if not effect.applied and effect.after_cards <= count:
			match String(effect.get("kind", "notebook")):
				"evidence": state.portal_state.discover(effect.id)
				_: state.portal_state.record_fact(effect.id, effect.text)
			effect.applied = true
	if count == result.cards.size() and result.fork == null and result.go == null:
		var time_key = result.session.tag if not result.session.tag.is_empty() else result.session.portal
		state.portal_state.complete_portal(result.session.location, result.session.portal)
		if not result.session.tag.is_empty(): state.portal_state.complete_portal(result.session.location, result.session.tag)
		for outcome_id in result.session.pending_outcomes:
			state.dialogue_state.set_outcome(String(outcome_id), String(result.session.pending_outcomes[outcome_id]))
		result.finished = true
		return true
	return false

# Continue the saved stack after a FORK choice, including nested forks and
# the parent tail. Invalid/stale choices leave the pending segment untouched.
static func resume(result: Dictionary, choice: int) -> Dictionary:
	if result.resumed or result.fork == null or result.acknowledged != result.cards.size(): return {}
	var options: Array = result.session.pending
	if choice < 0 or choice >= options.size(): return {}
	result.resumed = true
	result.session.pending = []
	result.session.stack.append({"steps": options[choice].steps, "i": 0})
	return _next_segment(result.session)

# Continue the saved stack after a GO the caller has already performed (the
# actual travel is the adapter's job — see chapter_one_portals.gd). Unlike a
# FORK there is no choice to make, so this just resumes the same stack from
# wherever the GO step left it (e.g. arrival narration authored after it).
static func after_go(result: Dictionary) -> Dictionary:
	if result.resumed or result.go == null or result.acknowledged != result.cards.size(): return {}
	result.resumed = true
	return _next_segment(result.session)

static func enter_by_path(path: String, portal_id: String, state) -> Dictionary:
	var def = load_location(path)
	return enter(def, portal_id, make_context(state), state)
