extends RefCounted

# Generic dialogue-authored gating state — deliberately separate from
# case_state.gd. New TOPIC ids and GATE conditions are invented by content
# authors in flat files with no engine code change, so the counters they
# imply (visit_count, topic_count, arbitrary flags) must not require a
# case_state.gd schema bump every time a new one is authored. Facts written
# via NOTEBOOK effects are inline text, not ids into a separate table, so
# this store carries their text directly rather than referencing story.gd.
const VERSION = 1
var visit_counts: Dictionary = {}   # npc_id -> int, once per enter()
var topic_sources: Dictionary = {}  # topic_id -> Array[String] distinct npc_ids that completed it
var visited_topics: Dictionary = {} # npc_id -> Array[String] topic_ids completed at least once
var facts: Dictionary = {}          # NPC + authored note id -> free text (legacy notes use text hash)
var evidence: Array[String] = [] # Existing case FACTS identifiers, separate from prose statements.
var flags: Dictionary = {}          # arbitrary named booleans for future SET-style effects

func visit(npc: String) -> void:
	visit_counts[npc] = int(visit_counts.get(npc, 0)) + 1

func visit_count(npc: String) -> int:
	return int(visit_counts.get(npc, 0))

func complete_topic(npc: String, topic_id: String) -> void:
	var done: Array = visited_topics.get(npc, [])
	if done.has(topic_id): return
	done.append(topic_id)
	visited_topics[npc] = done
	var sources: Array = topic_sources.get(topic_id, [])
	if not sources.has(npc):
		sources.append(npc)
		topic_sources[topic_id] = sources

func topic_count(topic_id: String) -> int:
	return topic_sources.get(topic_id, []).size()

func topic_done(npc: String, topic_id: String) -> bool:
	return visited_topics.get(npc, []).has(topic_id)

func record_fact(id: String, text: String) -> void:
	if not facts.has(id): facts[id] = text

func discover(id: String) -> void:
	if not evidence.has(id): evidence.append(id)

func flag(name: String) -> bool:
	return bool(flags.get(name, false))

func set_flag(name: String, value: bool) -> void:
	flags[name] = value

func pack() -> Dictionary:
	return {"version": VERSION, "visit_counts": visit_counts, "topic_sources": topic_sources,
		"visited_topics": visited_topics, "facts": facts, "flags": flags, "evidence": evidence}

func restore(d: Dictionary) -> bool:
	if int(d.get("version", 0)) != VERSION: return false
	for key in ["visit_counts", "topic_sources", "visited_topics", "facts", "flags"]:
		if not d.get(key, {}) is Dictionary: return false
	if not d.get("evidence", []) is Array: return false
	for id in d.get("evidence", []):
		if not id is String: return false
	for key in ["topic_sources", "visited_topics"]:
		for values in d.get(key, {}).values():
			if not values is Array: return false
			for value in values:
				if not value is String: return false
	for value in d.get("visit_counts", {}).values():
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) < 0: return false
	for value in d.get("facts", {}).values():
		if not value is String: return false
	for value in d.get("flags", {}).values():
		if not value is bool: return false
	evidence.assign(d.get("evidence", []))
	visit_counts = d.get("visit_counts", {}).duplicate(true)
	topic_sources = d.get("topic_sources", {}).duplicate(true)
	visited_topics = d.get("visited_topics", {}).duplicate(true)
	facts = d.get("facts", {}).duplicate(true)
	flags = d.get("flags", {}).duplicate(true)
	return true
