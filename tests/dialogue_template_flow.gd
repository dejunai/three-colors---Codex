extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Lang = load("res://scripts/shared/dialogue_lang.gd")
	var Runtime = load("res://scripts/shared/dialogue_runtime.gd")
	var DState = load("res://scripts/shared/dialogue_state.gd")
	var Case = load("res://case_state.gd")
	var source = FileAccess.get_file_as_string("res://dialogue/background_npc_template.dialogue")
	var template = Lang.parse(source)
	assert(template.errors.is_empty(), str(template.errors))
	assert(template.npc.contains("{"), "Cookbook must remain excluded from live NPC discovery")
	assert(template.schedule.has("morning") and template.schedule.has("midday") and template.schedule.has("evening"))
	var def = Lang.parse(source.replace("NPC: {generated}", "NPC: example_witness"))
	var state = Case.new()
	var ds = DState.new()
	var ctx = Runtime.make_context(state, ds)
	assert(Runtime.menu(def, ctx).default_topic.tag == "example_witness_greeting")
	state.coat = "Plain wool coat"
	ds.visit("example_witness")
	ds.visit("example_witness")
	assert(Runtime.menu(def, ctx).default_topic.tag == "example_witness_plain_return")
	# Execute every cookbook body, including every path through nested forks.
	for topic in def.topics:
		if topic.steps.is_empty(): continue
		for route in [[0, 0], [0, 1], [1]]:
			var fresh = DState.new()
			var result = Runtime.render(def.npc, topic, fresh)
			var depth = 0
			while true:
				Runtime.commit_through(result, null, fresh, result.cards.size())
				if result.fork == null: break
				assert(depth < route.size(), "Unexpected additional fork")
				result = Runtime.resume(result, route[depth])
				depth += 1
			assert(fresh.topic_done(def.npc, topic.id), topic.id)
			if topic.id == "example_approach":
				assert(result.cards.back()[1] == "The witness folds the newspaper again.")
				var expected = "example_pressure_rebuff" if route[0] == 1 else ("example_window_account" if route[1] == 0 else "example_face_unseen")
				assert(fresh.evidence == [expected], "Only selected branch evidence should persist")
	var before = state.clock_minutes
	var account = Runtime.play_topic(def, ds, "example_account")
	Runtime.commit_through(account, state, ds, account.cards.size())
	assert(is_equal_approx(state.clock_minutes - before, 12.5), "Decimal TIME must work")
	assert(ds.facts.has("example_witness.example_account_note"))
	assert(ds.evidence.has("example_door_account"))
	for entry in Runtime.menu(def, ctx).entries:
		assert(entry.id != "example_account" and entry.id != "example_disabled" and entry.id != "example_unwritten")
	var repeated = Runtime.play_topic(def, ds, "example_account")
	Runtime.commit_through(repeated, state, ds, repeated.cards.size())
	assert(is_equal_approx(state.clock_minutes - before, 12.5), "Replay must not charge again")
	print("PASS: dialogue template parses; all fork paths, defaults, notes, evidence, gates and timing verified")
	quit(0)
