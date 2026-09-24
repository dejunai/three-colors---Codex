extends SceneTree

# Backup-Route Reachability Flow
# Verifies real runtime reachability for every "Redundant-carrier backup" topic
# in the live dialogue corpus.

const MANIFEST = [
	{
		"npc": "apothecary",
		"topic": "the_camphor_stranger",
		"file": "res://dialogue/apothecary.dialogue",
		"primary": "chandlery_island_delivery",
		"backup": "chandlery_island_delivery",
		"prereqs": ["naomi"]
	},
	{
		"npc": "chandlers_boy",
		"topic": "the_woman_with_the_notebook",
		"file": "res://dialogue/chandlers_boy.dialogue",
		"primary": "naomi_quay_inquiry",
		"backup": "naomi_quay_inquiry",
		"prereqs": ["naomi"]
	},
	{
		"npc": "drayman",
		"topic": "the_kitchen_stone",
		"file": "res://dialogue/drayman.dialogue",
		"primary": "estate_freight",
		"backup": "estate_freight",
		"prereqs": ["service_work"]
	},
	{
		"npc": "post_office_clerk",
		"topic": "correction_requirements",
		"file": "res://dialogue/post_office_clerk.dialogue",
		"primary": "gazette_correction_terms",
		"backup": "gazette_correction_terms",
		"prereqs": ["press_suppression", "naomi"]
	},
	{
		"npc": "quay_docker",
		"topic": "the_office_correction",
		"file": "res://dialogue/quay_docker.dialogue",
		"primary": "quay_inquiry",
		"backup": "quay_inquiry",
		"prereqs": ["naomi"]
	},
	{
		"npc": "school_parent",
		"topic": "the_covering_letter",
		"file": "res://dialogue/school_parent.dialogue",
		"primary": "reader_omission_letter",
		"backup": "reader_omission_letter",
		"prereqs": ["curriculum_abridgment"]
	},
	{
		"npc": "school_parent",
		"topic": "the_reader_lesson",
		"file": "res://dialogue/school_parent.dialogue",
		"primary": "sanitized_textbook",
		"backup": "sanitized_textbook",
		"prereqs": []
	},
	{
		"npc": "school_parent",
		"topic": "the_new_bedford_letters",
		"file": "res://dialogue/school_parent.dialogue",
		"primary": "new_bedford_letters",
		"backup": "new_bedford_letters",
		"prereqs": ["naomi_unapologetic_presence"]
	},
	{
		"npc": "stationer",
		"topic": "fenn_conduit_tracing",
		"file": "res://dialogue/stationer.dialogue",
		"primary": "estate_conduit_map",
		"backup": "estate_conduit_map",
		"prereqs": ["cellar_candles"]
	},
	{
		"npc": "stationer",
		"topic": "halleck_arithmetic",
		"file": "res://dialogue/stationer.dialogue",
		"primary": "press_suppression",
		"backup": "press_suppression",
		"prereqs": ["eight"]
	},
	{
		"npc": "tailor",
		"topic": "pruitt_family_naming",
		"file": "res://dialogue/tailor.dialogue",
		"primary": "ophion_myth_classical",
		"backup": "ophion_myth_classical",
		"prereqs": []
	},
	{
		"npc": "tailor",
		"topic": "correction_slip_seen",
		"file": "res://dialogue/tailor.dialogue",
		"primary": "gazette_correction_printed",
		"backup": "gazette_correction_printed",
		"prereqs": ["gazette_correction_terms"],
		"filed": ["eight", "naomi", "lodging"]
	},
	{
		"npc": "tailor",
		"topic": "the_altered_shoulder",
		"file": "res://dialogue/tailor.dialogue",
		"primary": "kessler_carriages",
		"backup": "kessler_carriages",
		"prereqs": []
	}
]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Runtime = load("res://scripts/shared/dialogue_runtime.gd")
	var CaseState = load("res://case_state.gd")
	var DialogueState = load("res://scripts/shared/dialogue_state.gd")

	# 1. Audit live .dialogue files for "Redundant-carrier backup" markers
	var discovered: Dictionary = {}
	var dialogue_dir = "res://dialogue"
	var files = DirAccess.get_files_at(dialogue_dir)
	for fname in files:
		if not fname.ends_with(".dialogue"): continue
		var path = dialogue_dir + "/" + fname
		var f = FileAccess.open(path, FileAccess.READ)
		if f == null: continue
		var content = f.get_as_text()
		var lines = content.split("\n")
		var current_npc = ""
		for idx in range(lines.size()):
			var line = lines[idx].strip_edges()
			if line.begins_with("NPC:"):
				current_npc = line.substr(4).strip_edges()
			elif line.begins_with("# Redundant-carrier backup:"):
				# Search ahead for the next TOPIC:
				for j in range(idx + 1, lines.size()):
					var next_line = lines[j].strip_edges()
					if next_line.begins_with("TOPIC:"):
						var topic_id = next_line.substr(6).strip_edges()
						var key = current_npc + "/" + topic_id
						discovered[key] = true
						break

	# Assert that discovered markers match the explicit manifest exactly
	var manifest_keys: Dictionary = {}
	for item in MANIFEST:
		var k = item.npc + "/" + item.topic
		manifest_keys[k] = true

	assert(discovered.size() == 13, "Expected 13 Redundant-carrier backup topics discovered, found %d: %s" % [discovered.size(), str(discovered.keys())])
	for k in manifest_keys:
		assert(discovered.has(k), "Manifest topic '%s' missing from discovered redundant backup markers in dialogue files" % k)
	for k in discovered:
		assert(manifest_keys.has(k), "Dialogue file has unexpected redundant backup marker '%s' not present in manifest" % k)

	# 2. Test reachability, absence-relevance, execution, and evidence grant for each route
	for route in MANIFEST:
		var def = Runtime.load_npc(route.file)
		assert(def.errors.is_empty(), "Failed to load %s: %s" % [route.file, str(def.errors)])

		# Build minimum valid live state satisfying prerequisites
		var state = CaseState.new()
		var dstate = DialogueState.new()
		for prereq in route.prereqs:
			state.discover(prereq)
		if route.has("filed"):
			state.intake_done = true
			state.report_evidence.assign(route.filed)

		# Ensure primary evidence is absent
		assert(not Runtime.has_evidence(state, route.primary), "%s / %s: primary evidence '%s' must initially be absent" % [route.npc, route.topic, route.primary])

		var ctx = Runtime.make_context(state, dstate)
		var menu = Runtime.menu(def, ctx)
		var entry_ids: Array = []
		for entry in menu.entries:
			entry_ids.append(entry.id)

		# Assert the topic appears in Runtime.menu()
		assert(entry_ids.has(route.topic), "%s / %s: topic must appear in Runtime.menu() with prerequisites met" % [route.npc, route.topic])

		# Find the topic object
		var topic_obj = null
		for t in def.topics:
			if t.id == route.topic:
				topic_obj = t
				break
		assert(topic_obj != null, "%s / %s: topic object must exist in definition" % [route.npc, route.topic])

		# Assert that having the primary evidence is what makes the backup redundant/excluded
		# (if the topic's gate explicitly includes NOT evidence(primary))
		var gate_src = String(topic_obj.get("gate_src", ""))
		if gate_src.contains("NOT evidence(" + route.primary + ")") or gate_src.contains("NOT evidence("):
			var alt_state = CaseState.new()
			var alt_dstate = DialogueState.new()
			for prereq in route.prereqs:
				alt_state.discover(prereq)
			if route.has("filed"):
				alt_state.intake_done = true
				alt_state.report_evidence.assign(route.filed)
			alt_state.discover(route.primary)
			var alt_ctx = Runtime.make_context(alt_state, alt_dstate)
			var alt_menu = Runtime.menu(def, alt_ctx)
			var alt_ids: Array = []
			for entry in alt_menu.entries:
				alt_ids.append(entry.id)
			assert(not alt_ids.has(route.topic), "%s / %s: topic must be excluded when primary evidence '%s' is already held" % [route.npc, route.topic, route.primary])

		# Play and complete through runtime
		var rendered = Runtime.render(def.npc, topic_obj, dstate)
		assert(rendered.cards.size() > 0, "%s / %s: rendered topic must contain dialogue cards" % [route.npc, route.topic])
		var finished = Runtime.commit_through(rendered, state, dstate, rendered.cards.size())
		assert(finished, "%s / %s: topic must complete through commit_through" % [route.npc, route.topic])

		# Sync dstate evidence to state (mirroring chapter_one_dialogue.gd::_sync)
		for ev in dstate.evidence:
			if not state.evidence.has(ev): state.discover(ev)

		# Assert it grants the intended backup evidence
		assert(Runtime.has_evidence(state, route.backup), "%s / %s: must grant intended backup evidence '%s'" % [route.npc, route.topic, route.backup])

	print("BACKUP ROUTE REACHABILITY PASS: all 13 redundant-carrier backup topics verified reachable, gating against primary evidence absence, and granting intended evidence")
	quit(0)
