extends RefCounted

# Game-facing half of the dialogue system: builds the GATE-evaluation
# context from live game state, loads/caches parsed .dialogue files, picks
# an NPC's current default line and menu, and renders a chosen topic into
# the compatible card-array shape story.gd/town_story.gd already use.
# Beat cards remain [speaker, text]; dialogue lines are [speaker, text, voice].
# Missing NPC cues receive a conspicuous warning and a neutral same-instrument
# fallback. The Chapter One renderer treats the third element as optional, so
# legacy cards and other chapters remain unchanged. See
# tests/dialogue_lang_flow.gd for a full standalone proof, and the note at
# the bottom of this file for what remains to integrate it live.
const Lang = preload("res://scripts/shared/dialogue_lang.gd")
const DayClock = preload("res://scripts/shared/day_clock.gd")
const VOICE_MANIFEST_PATH = "res://assets/audio/instrument_voices/manifest.json"
const DEFAULT_VOICE = "trombone_neutral_medium_v1"
const SILENT_SPEAKERS = ["WALTER CORWIN", "WALTER'S NOTEBOOK", "THE KITCHEN WING YARD", "THE COVERING LETTER", "THE DAY BOOK", "THE GAZETTE — CORRECTION", "OUTSIDE THE SHUTTERED SHOP", "A CLEAN READ", "THE SMOKING LOUNGE"]

static var _cache: Dictionary = {}
static var _voice_ids: Dictionary = {}

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
	var source = file.get_as_text()
	var parsed = Lang.parse(source)
	_validate_voice_cues(source, parsed.errors)
	var known: Dictionary = {}
	for topic in parsed.topics: known[topic.id] = true
	for include_value in parsed.get("includes", []):
		var include_path = include_value if include_value.begins_with("res://") else "res://dialogue/" + include_value
		var included = load_npc(include_path)
		for topic in included.topics:
			if not known.has(topic.id):
				parsed.topics.append(topic)
				known[topic.id] = true
	# Cookbook/shared files use braced placeholder identities and are never live
	# residents. Do not turn their deliberately incomplete examples into warnings.
	if not String(parsed.get("npc", "")).begins_with("{"):
		_supply_default_voice_cues(parsed, path)
	for error in parsed.errors:
		push_error("dialogue parse error (%s:%d): %s" % [path, error.line, error.message])
	_cache[path] = parsed
	return parsed

static func _supply_default_voice_cues(definition:Dictionary, path:String="<dialogue>") -> void:
	var instruments:Dictionary = {}
	for topic in definition.get("topics", []): _collect_speaker_instruments(topic.get("steps", []), instruments)
	for topic in definition.get("topics", []): _fill_missing_voice_cues(topic.get("steps", []), instruments, path)

static func _collect_speaker_instruments(steps:Array, instruments:Dictionary) -> void:
	for step in steps:
		if String(step.get("kind", "")) == "line":
			var speaker=String(step.get("speaker", ""))
			var cue=String(step.get("voice", ""))
			if not cue.is_empty() and not instruments.has(speaker): instruments[speaker]=cue.get_slice("_",0)
		elif String(step.get("kind", "")) == "fork":
			for option in step.get("options", []): _collect_speaker_instruments(option.get("steps", []),instruments)

static func _fill_missing_voice_cues(steps:Array, instruments:Dictionary, path:String) -> void:
	for step in steps:
		if String(step.get("kind", "")) == "line":
			var speaker=String(step.get("speaker", ""))
			if bool(step.get("player",false)) or speaker in SILENT_SPEAKERS or not String(step.get("voice", "")).is_empty(): continue
			var fallback="%s_neutral_medium_v1" % String(instruments.get(speaker,"trombone"))
			if not _known_voice_ids().has(fallback): fallback=DEFAULT_VOICE
			step["voice"]=fallback
			push_warning("Missing VOICE cue in %s for %s; using %s" % [path,speaker,fallback])
		elif String(step.get("kind", "")) == "fork":
			for option in step.get("options", []): _fill_missing_voice_cues(option.get("steps", []),instruments,path)

static func _validate_voice_cues(source: String, errors: Array) -> void:
	var ids = _known_voice_ids()
	var lines = source.split("\n")
	for index in range(lines.size()):
		var line = String(lines[index]).strip_edges()
		if not line.begins_with("VOICE:"): continue
		var cue = line.substr(6).strip_edges()
		# dialogue_lang.gd reports malformed identifiers. This pass verifies
		# well-formed names against the actual shipped asset manifest.
		if cue.is_valid_identifier() and not ids.has(cue):
			errors.append({"line": index + 1, "message": "Unknown VOICE cue '%s' (not in instrument voice manifest)" % cue})

static func _known_voice_ids() -> Dictionary:
	if not _voice_ids.is_empty(): return _voice_ids
	if not FileAccess.file_exists(VOICE_MANIFEST_PATH):
		push_error("Missing instrument voice manifest: %s" % VOICE_MANIFEST_PATH)
		return _voice_ids
	var manifest = JSON.parse_string(FileAccess.get_file_as_string(VOICE_MANIFEST_PATH))
	if not manifest is Dictionary:
		push_error("Malformed instrument voice manifest: %s" % VOICE_MANIFEST_PATH)
		return _voice_ids
	for clip in manifest.get("clips", []):
		if not clip is Dictionary: continue
		var filename = String(clip.get("filename", ""))
		if filename.ends_with(".wav"):
			_voice_ids[filename.trim_suffix(".wav")] = true
	return _voice_ids

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
# History is authoritative when present. The latest-snapshot fallback is only
# for accepted older saves without history. Intake remains mandatory, and IDs
# remain exact: having filed a related observation is not filing this record.
static func has_filed_evidence(state, id: String) -> bool:
	if state == null: return false
	var snapshot: Dictionary
	if state is Dictionary: snapshot = state
	elif state is Object and state.has_method("pack"): snapshot = state.pack()
	else: return false
	if not bool(snapshot.get("intake_done", false)): return false
	var report = snapshot.get("report_evidence", [])
	if report is Array and report.has(id): return true
	var history = snapshot.get("supplement_history", [])
	if not history is Array: return false
	if not history.is_empty():
		for supplement in history:
			if not supplement is Dictionary: continue
			var received = supplement.get("evidence", [])
			if received is Array and received.has(id): return true
		return false
	var legacy = snapshot.get("supplement_evidence", [])
	return bool(snapshot.get("supplement_filed", false)) and legacy is Array and legacy.has(id)

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
			var label = topic.label if not topic.label.is_empty() else topic.id.capitalize()
			if _menu_topic_recorded(def, topic, ctx): label += "  · recorded"
			entries.append({"id": topic.id, "label": label})
	return {"default_topic": default_topic, "entries": entries}

static func _menu_topic_recorded(def: Dictionary, topic: Dictionary, ctx: Dictionary) -> bool:
	var check = ctx.get("functions", {}).get("topic_done", Callable())
	if not check is Callable or not check.is_valid(): return false
	if bool(check.call([String(def.get("npc", "")), String(topic.get("id", ""))])): return true
	var tag = String(topic.get("tag", ""))
	return not tag.is_empty() and bool(check.call([String(def.get("npc", "")), tag]))

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
			"line": result.cards.append([step.speaker, step.text, step.get("voice", "")])
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
