extends SceneTree

const Lang = preload("res://scripts/shared/dialogue_lang.gd")
const Runtime = preload("res://scripts/shared/dialogue_runtime.gd")
const Catalog = preload("res://scripts/chapters/dialogue_catalog.gd")
const Archive = preload("res://scripts/chapters/chapter_one_archive.gd")
const CaseState = preload("res://case_state.gd")

func _initialize() -> void:
	call_deferred("run_audit")

func run_audit() -> void:
	var state = CaseState.new()
	var cat = Catalog.new()
	cat.scan()
	
	print("--- AUDITING DIALOGUE FILES ---")
	print("Total definitions scanned: ", cat.definitions.size())
	
	# Collect all evidence produced in dialogue and game
	var all_evidence_emitted = {}
	var all_topics_by_npc = {}
	var all_tags_by_npc = {}
	var all_shared_ids = {} # id -> array of npcs
	
	for npc_id in cat.definitions:
		var def = cat.definitions[npc_id]
		all_topics_by_npc[npc_id] = {}
		all_tags_by_npc[npc_id] = {}
		for topic in def.topics:
			all_topics_by_npc[npc_id][topic.id] = topic
			if not all_shared_ids.has(topic.id):
				all_shared_ids[topic.id] = []
			all_shared_ids[topic.id].append(npc_id)
			
			var tag = topic.get("tag", "")
			if not tag.is_empty():
				all_tags_by_npc[npc_id][tag] = topic.id
				if not all_shared_ids.has(tag):
					all_shared_ids[tag] = []
				all_shared_ids[tag].append(npc_id)
				
			for step in topic.steps:
				if step.kind == "evidence":
					if not all_evidence_emitted.has(step.id):
						all_evidence_emitted[step.id] = []
					all_evidence_emitted[step.id].append(npc_id + ":" + topic.id)
				elif step.kind == "fork":
					for opt in step.options:
						for s in opt.steps:
							if s.kind == "evidence":
								if not all_evidence_emitted.has(s.id):
									all_evidence_emitted[s.id] = []
								all_evidence_emitted[s.id].append(npc_id + ":" + topic.id)
								
	# Game facts
	var game_facts = {}
	# Story facts
	var story_script = load("res://story.gd")
	if story_script:
		var st = story_script.new()
		if "FACTS" in st:
			for f in st.FACTS:
				game_facts[f] = true
	# Archive links
	var arc = Archive.new()
	for l in arc.LINKS:
		var parts = l.split("|")
		game_facts[parts[0]] = true
		game_facts[parts[1]] = true
		
	print("Known game facts: ", game_facts.size())
	print("Known dialogue evidence emitted: ", all_evidence_emitted.size())
	
	# AST Walker
	var errors = []
	var warnings = []
	
	for npc_id in cat.definitions:
		var def = cat.definitions[npc_id]
		for topic in def.topics:
			_check_ast(def, topic, topic.gate, all_topics_by_npc, all_tags_by_npc, all_shared_ids, all_evidence_emitted, game_facts, errors, warnings)

	print("\n=== AUDIT RESULTS ===")
	print("ERRORS (Logic breaks / broken references): ", errors.size())
	for e in errors:
		print("  [ERROR] ", e)
		
	print("\nWARNINGS (Potential gaps / anomalies): ", warnings.size())
	for w in warnings:
		print("  [WARN]  ", w)
		
	quit()

func _check_ast(def: Dictionary, topic: Dictionary, ast: Dictionary, all_topics: Dictionary, all_tags: Dictionary, all_shared: Dictionary, all_ev: Dictionary, game_facts: Dictionary, errors: Array, warnings: Array) -> void:
	if ast.is_empty():
		return
	match String(ast.get("op", "")):
		"lit":
			pass
		"and", "or":
			_check_ast(def, topic, ast.get("left", {}), all_topics, all_tags, all_shared, all_ev, game_facts, errors, warnings)
			_check_ast(def, topic, ast.get("right", {}), all_topics, all_tags, all_shared, all_ev, game_facts, errors, warnings)
		"not":
			_check_ast(def, topic, ast.get("expr", {}), all_topics, all_tags, all_shared, all_ev, game_facts, errors, warnings)
		"cmp":
			_check_cmp(def, topic, ast, all_topics, all_tags, all_shared, all_ev, game_facts, errors, warnings)

func _check_cmp(def: Dictionary, topic: Dictionary, ast: Dictionary, all_topics: Dictionary, all_tags: Dictionary, all_shared: Dictionary, all_ev: Dictionary, game_facts: Dictionary, errors: Array, warnings: Array) -> void:
	var name = String(ast.get("name", ""))
	var is_call = bool(ast.get("call", false))
	var args = ast.get("args", [])
	var topic_ref = def.npc + ":" + topic.id
	
	if is_call:
		match name:
			"visit_count":
				var target_npc = args[0] if args.size() > 0 else ""
				if not all_topics.has(target_npc):
					errors.append("%s: visit_count references unknown NPC '%s'" % [topic_ref, target_npc])
			"spoken_to":
				var target_npc = args[0] if args.size() > 0 else ""
				if not all_topics.has(target_npc):
					errors.append("%s: spoken_to references unknown NPC '%s'" % [topic_ref, target_npc])
			"topic_done":
				if args.size() < 2:
					errors.append("%s: topic_done requires 2 args, got %s" % [topic_ref, str(args)])
				else:
					var target_npc = args[0]
					var target_t = args[1]
					if not all_topics.has(target_npc):
						errors.append("%s: topic_done references unknown NPC '%s'" % [topic_ref, target_npc])
					else:
						var has_t = all_topics[target_npc].has(target_t)
						var has_tag = all_tags[target_npc].has(target_t)
						if not (has_t or has_tag):
							errors.append("%s: topic_done references non-existent topic/tag '%s' on NPC '%s'" % [topic_ref, target_t, target_npc])
			"topic_count":
				if args.size() < 1:
					errors.append("%s: topic_count requires 1 arg" % [topic_ref])
				else:
					var target_shared = args[0]
					if not all_shared.has(target_shared):
						errors.append("%s: topic_count references unknown shared ID '%s'" % [topic_ref, target_shared])
					else:
						var count = all_shared[target_shared].size()
						if count < 2:
							warnings.append("%s: topic_count('%s') only used by %d NPC (%s)" % [topic_ref, target_shared, count, str(all_shared[target_shared])])
			"evidence":
				if args.size() < 1:
					errors.append("%s: evidence() requires 1 arg" % [topic_ref])
				else:
					var ev_id = args[0]
					if not all_ev.has(ev_id) and not game_facts.has(ev_id):
						# Check runtime aliases in dialogue_runtime.gd
						if ev_id != "eight" and ev_id != "naomi" and ev_id != "watch" and ev_id != "knife":
							warnings.append("%s: evidence('%s') is never emitted in dialogue or known facts" % [topic_ref, ev_id])
			"filed":
				if args.size() < 1:
					errors.append("%s: filed() requires 1 arg" % [topic_ref])
				else:
					var ev_id = args[0]
					if not all_ev.has(ev_id) and not game_facts.has(ev_id):
						warnings.append("%s: filed('%s') is never emitted in dialogue or known facts" % [topic_ref, ev_id])
			"flag":
				pass
			"outcome", "outcome_is":
				# OUTCOME identifiers are author-defined and validated by the parser.
				pass
			_:
				errors.append("%s: Unknown gate function '%s'" % [topic_ref, name])
	else:
		# Field check
		var valid_fields = ["coat", "day", "phase", "estate_complete", "steward_ready"]
		if not valid_fields.has(name):
			errors.append("%s: Unknown gate field '%s'" % [topic_ref, name])
