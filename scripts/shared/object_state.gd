extends RefCounted

# Generic object-authored gating state — deliberately separate from
# case_state.gd, mirroring dialogue_state.gd's rationale: new OBJECT ids and
# GATE conditions are invented by content authors in flat files with no
# engine code change, so the counters they imply (examine_count,
# object_count, arbitrary facts) must not require a case_state.gd schema
# bump every time a new one is authored.
#
# OUTCOME commitments and FLAG reads are deliberately NOT duplicated here —
# object_runtime.gd reads/writes those through the case's shared
# dialogue_state instance instead, so a decision_id or flag set from a
# TOPIC and one set from an OBJECT are always the same fact.
const VERSION = 1
var examine_counts: Dictionary = {}    # "location.object_id" -> int, once per enter()
var object_sources: Dictionary = {}    # object_id_or_tag -> Array[String] distinct locations that completed it
var completed_objects: Dictionary = {} # location -> Array[String] object ids/tags completed at least once
var facts: Dictionary = {}             # "location.note_id" -> free text (legacy notes use text hash)
var evidence: Array[String] = []       # Pending observations; a chapter adapter mirrors these into case_state.evidence.

func examine(location: String, object_id: String) -> void:
	var key = location + "." + object_id
	examine_counts[key] = int(examine_counts.get(key, 0)) + 1

func examine_count(location: String, object_id: String) -> int:
	return int(examine_counts.get(location + "." + object_id, 0))

func complete_object(location: String, object_id: String) -> void:
	var done: Array = completed_objects.get(location, [])
	if done.has(object_id): return
	done.append(object_id)
	completed_objects[location] = done
	var sources: Array = object_sources.get(object_id, [])
	if not sources.has(location):
		sources.append(location)
		object_sources[object_id] = sources

func object_count(object_id: String) -> int:
	return object_sources.get(object_id, []).size()

func object_done(location: String, object_id: String) -> bool:
	return completed_objects.get(location, []).has(object_id)

func record_fact(id: String, text: String) -> void:
	if not facts.has(id): facts[id] = text

func discover(id: String) -> void:
	if not evidence.has(id): evidence.append(id)

func pack() -> Dictionary:
	return {"version": VERSION, "examine_counts": examine_counts, "object_sources": object_sources,
		"completed_objects": completed_objects, "facts": facts, "evidence": evidence}

func restore(d: Dictionary) -> bool:
	if int(d.get("version", 0)) != VERSION: return false
	for key in ["examine_counts", "object_sources", "completed_objects", "facts"]:
		if not d.get(key, {}) is Dictionary: return false
	if not d.get("evidence", []) is Array: return false
	for id in d.get("evidence", []):
		if not id is String: return false
	for key in ["object_sources", "completed_objects"]:
		for values in d.get(key, {}).values():
			if not values is Array: return false
			for value in values:
				if not value is String: return false
	for value in d.get("examine_counts", {}).values():
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0: return false
	for value in d.get("facts", {}).values():
		if not value is String: return false
	evidence.assign(d.get("evidence", []))
	examine_counts = d.get("examine_counts", {}).duplicate(true)
	object_sources = d.get("object_sources", {}).duplicate(true)
	completed_objects = d.get("completed_objects", {}).duplicate(true)
	facts = d.get("facts", {}).duplicate(true)
	return true
