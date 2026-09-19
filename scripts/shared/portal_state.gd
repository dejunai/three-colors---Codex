extends RefCounted

# Generic portal-authored gating state — mirrors object_state.gd's rationale
# (deliberately separate from case_state.gd, so new PORTAL ids/GATEs never
# need a schema bump). OUTCOME commitments and FLAG reads are NOT duplicated
# here — portal_runtime.gd reads/writes those through the case's shared
# dialogue_state instance instead, same as the object system, so a decision
# or flag set from a TOPIC, an OBJECT, or a PORTAL is always the same fact.
const VERSION = 1
var attempt_counts: Dictionary = {}    # "location.portal_id" -> int, once per enter()
var portal_sources: Dictionary = {}    # portal_id_or_tag -> Array[String] distinct locations that completed it
var completed_portals: Dictionary = {} # location -> Array[String] portal ids/tags completed at least once
var facts: Dictionary = {}             # "location.note_id" -> free text (legacy notes use text hash)
var evidence: Array[String] = []       # Pending observations; a chapter adapter mirrors these into case_state.evidence.

func attempt(location: String, portal_id: String) -> void:
	var key = location + "." + portal_id
	attempt_counts[key] = int(attempt_counts.get(key, 0)) + 1

func attempt_count(location: String, portal_id: String) -> int:
	return int(attempt_counts.get(location + "." + portal_id, 0))

func complete_portal(location: String, portal_id: String) -> void:
	var done: Array = completed_portals.get(location, [])
	if done.has(portal_id): return
	done.append(portal_id)
	completed_portals[location] = done
	var sources: Array = portal_sources.get(portal_id, [])
	if not sources.has(location):
		sources.append(location)
		portal_sources[portal_id] = sources

func portal_count(portal_id: String) -> int:
	return portal_sources.get(portal_id, []).size()

func portal_done(location: String, portal_id: String) -> bool:
	return completed_portals.get(location, []).has(portal_id)

func record_fact(id: String, text: String) -> void:
	if not facts.has(id): facts[id] = text

func discover(id: String) -> void:
	if not evidence.has(id): evidence.append(id)

func pack() -> Dictionary:
	return {"version": VERSION, "attempt_counts": attempt_counts, "portal_sources": portal_sources,
		"completed_portals": completed_portals, "facts": facts, "evidence": evidence}

func restore(d: Dictionary) -> bool:
	if int(d.get("version", 0)) != VERSION: return false
	for key in ["attempt_counts", "portal_sources", "completed_portals", "facts"]:
		if not d.get(key, {}) is Dictionary: return false
	if not d.get("evidence", []) is Array: return false
	for id in d.get("evidence", []):
		if not id is String: return false
	for key in ["portal_sources", "completed_portals"]:
		for values in d.get(key, {}).values():
			if not values is Array: return false
			for value in values:
				if not value is String: return false
	for value in d.get("attempt_counts", {}).values():
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0: return false
	for value in d.get("facts", {}).values():
		if not value is String: return false
	evidence.assign(d.get("evidence", []))
	attempt_counts = d.get("attempt_counts", {}).duplicate(true)
	portal_sources = d.get("portal_sources", {}).duplicate(true)
	completed_portals = d.get("completed_portals", {}).duplicate(true)
	facts = d.get("facts", {}).duplicate(true)
	return true
