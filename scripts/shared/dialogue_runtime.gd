extends RefCounted

# Game-facing half of the dialogue system: builds the GATE-evaluation
# context from live game state, loads/caches parsed .dialogue files, picks
# an NPC's current default line and menu, and renders a chosen topic into
# the same [speaker, text] card-array shape story.gd/town_story.gd already
# use, so dialogue_sequence.gd/chapter_interface.gd need no changes to
# consume it. Not wired into chapter_one.gd's _interact() yet — see
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
			"evidence": func(args): return state.evidence.has(args[0]) if args.size() > 0 else false,
			"flag": func(args): return dstate.flag(args[0]) if args.size() > 0 else false,
			"topic_done": func(args): return dstate.topic_done(args[0], args[1]) if args.size() > 1 else false,
		},
		"fields": {
			"coat": func(): return state.coat,
			"day": func(): return state.day,
			"phase": func(): return DayClock.phase(state.clock_minutes),
			"estate_complete": func(): return state.estate_complete,
		}
	}

# Finds the winning `default` topic (first true GATE, file order) and every
# other topic currently GATE-true, as menu entries. Does not render or
# apply effects — call play_topic() with the chosen id for that.
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

# The single entry point for "the player interacts with this NPC": counts
# the visit, then resolves and renders the default line if one applies.
# `choices` lets a caller resume a default topic that halted on a FORK on a
# prior enter() (e.g. Odell's branching response) — note this still counts
# as a fresh visit, so an NPC whose default topic can fork should not also
# gate anything else on its exact visit_count.
static func enter(def: Dictionary, ctx: Dictionary, dstate, choices: Array = []) -> Dictionary:
	dstate.visit(def.npc)
	var result = menu(def, ctx)
	var rendered = {"cards": [], "fork": null}
	if result.default_topic != null:
		rendered = render(def.npc, result.default_topic, dstate, choices)
	return {"cards": rendered.cards, "fork": rendered.fork, "entries": result.entries}

static func play_topic(def: Dictionary, dstate, topic_id: String, choices: Array = []) -> Dictionary:
	for topic in def.topics:
		if topic.id == topic_id: return render(def.npc, topic, dstate, choices)
	return {"cards": [], "fork": null}

# Walks a topic's steps into a flat card list, applying NOTEBOOK effects as
# it goes. A FORK step not yet resolved by `choices` halts the walk and
# returns its options for the caller to prompt; re-calling with `choices`
# extended by the player's pick resumes exactly where it left off. Marks
# the topic complete (for topic_count's cross-NPC tally) only once the walk
# reaches the end with no pending fork.
static func render(npc: String, topic: Dictionary, dstate, choices: Array = []) -> Dictionary:
	var cards: Array = []
	var fork_index = 0
	var notebook_seq = 0
	var stack: Array = [{"steps": topic.steps, "i": 0}]
	var pending = null
	while not stack.is_empty():
		var frame = stack[stack.size() - 1]
		if frame.i >= frame.steps.size():
			stack.pop_back()
			continue
		var step = frame.steps[frame.i]
		frame.i += 1
		match String(step.kind):
			"line": cards.append([step.speaker, step.text])
			"beat": cards.append(["", step.text])
			"notebook":
				notebook_seq += 1
				dstate.record_fact("%s.%s.%d" % [npc, topic.id, notebook_seq], step.text)
			"fork":
				if fork_index < choices.size():
					var chosen = step.options[choices[fork_index]]
					fork_index += 1
					stack.append({"steps": chosen.steps, "i": 0})
				else:
					pending = {"options": step.options.map(func(o): return o.label)}
					stack.clear()
	if pending != null: return {"cards": cards, "fork": pending}
	dstate.complete_topic(npc, topic.id)
	return {"cards": cards, "fork": null}

static func enter_by_path(path: String, state, dstate, choices: Array = []) -> Dictionary:
	return enter(load_npc(path), make_context(state, dstate), dstate, choices)

static func play_topic_by_path(path: String, state, dstate, topic_id: String, choices: Array = []) -> Dictionary:
	return play_topic(load_npc(path), dstate, topic_id, choices)

# Not yet done, left for the live-integration pass:
#  - chapter_one.gd's _interact()/_cards() need a branch that consults this
#    module for NPCs authored in the new format, and DayClock.conversation_key()
#    needs an explicit key (it currently detects a conversation by exact
#    array-equality against Story.SCENES, which dynamically rendered cards
#    will never match) instead of array-sniffing.
#  - a real "pick one of N" UI widget for FORK, since dialogue_sequence.gd
#    only auto-advances linearly today.
#  - dialogue_state.gd is not yet part of the save payload (case_state.gd's
#    pack()/restore()); it needs a slot there once real content ships.
#  - SCHEDULE/{template} placeholder substitution for the ~50 background
#    residents is intentionally unimplemented — this pass only proves the
#    parser tolerates the syntax.
