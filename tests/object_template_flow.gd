extends SceneTree

# Standalone check for the object cookbook, runnable directly:
#   godot --headless --path . --script res://tests/object_template_flow.gd
# Mirrors tests/dialogue_template_flow.gd's shape, adapted to the object
# system's own stateful cascade/FORK/TAKE/cross-location features.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Lang = load("res://scripts/shared/object_lang.gd")
	var Runtime = load("res://scripts/shared/object_runtime.gd")
	var CaseState = load("res://case_state.gd")
	var source = FileAccess.get_file_as_string("res://objects/background_object_template.object")
	var template = Lang.parse(source)
	assert(template.errors.is_empty(), str(template.errors))
	assert(template.location.contains("{"), "Cookbook must remain excluded from live location discovery")

	var def = Lang.parse(source.replace("LOCATION: {generated}", "LOCATION: example_location"))
	assert(def.errors.is_empty(), str(def.errors))
	var state = CaseState.new()
	var ctx = Runtime.make_context(state)

	# --- example_ledger: GATE cascade between first-look and already-examined ---
	assert(Runtime.is_available(def, "example_ledger", ctx), "the first-look block must be available before completion")
	var first_look = Runtime.enter(def, "example_ledger", ctx, state)
	assert(first_look.cards.back()[1] == "Six names, every final Thursday, for two years.")
	Runtime.commit_through(first_look, state, first_look.cards.size())
	assert(state.object_state.facts.has("example_location.example_ledger_note"), "NOTEBOOK must key its fact by location.note_id")
	assert(state.object_state.evidence.has("example_ledger_account"))
	assert(is_equal_approx(state.clock_minutes, 365.0), "explicit TIME: 5 must charge once")
	var second_look = Runtime.enter(def, "example_ledger", Runtime.make_context(state), state)
	assert(second_look.cards[0][1] == "The ledger says nothing new on a second look.", "GATE cascade must now pick the already-examined block")
	Runtime.commit_through(second_look, state, second_look.cards.size())
	assert(is_equal_approx(state.clock_minutes, 365.0), "an unpriced repeat block must stay free")

	# --- example_knife: FORK + OUTCOME + TAKE, each branch proven on a fresh case ---
	var taken_state = CaseState.new()
	var opened = Runtime.enter(def, "example_knife", Runtime.make_context(taken_state), taken_state)
	Runtime.commit_through(opened, taken_state, opened.cards.size())
	assert(opened.fork != null, "the FORK must halt rendering until a choice is supplied")
	var bagged = Runtime.resume(opened, 0)
	Runtime.commit_through(bagged, taken_state, bagged.cards.size())
	assert(taken_state.has_item("example_clean_knife"), "TAKE on the chosen branch must reach case_state.inventory")
	assert(taken_state.object_state.evidence.has("example_clean_knife"))
	assert(taken_state.dialogue_state.outcome_is("example_knife_response", "taken"))

	var left_state = CaseState.new()
	var opened_left = Runtime.enter(def, "example_knife", Runtime.make_context(left_state), left_state)
	Runtime.commit_through(opened_left, left_state, opened_left.cards.size())
	var left = Runtime.resume(opened_left, 1)
	Runtime.commit_through(left, left_state, left.cards.size())
	assert(not left_state.has_item("example_clean_knife"), "the unchosen branch's TAKE must never apply")
	assert(left_state.dialogue_state.outcome_is("example_knife_response", "left"))

	# --- example_locked_drawer: gated on taken(), proven against both prior states ---
	assert(not Runtime.is_available(def, "example_locked_drawer", Runtime.make_context(left_state)), "the drawer must stay locked without the knife")
	assert(Runtime.is_available(def, "example_locked_drawer", Runtime.make_context(taken_state)), "taking the knife must unlock the drawer")
	var drawer = Runtime.enter(def, "example_locked_drawer", Runtime.make_context(taken_state), taken_state)
	Runtime.commit_through(drawer, taken_state, drawer.cards.size())
	assert(taken_state.object_state.object_done("example_location", "example_locked_drawer"))

	# --- example_shared_signage / example_pattern_noticed: object_count() across locations ---
	var shared_state = CaseState.new()
	for loc in ["location_alpha", "location_beta", "location_gamma"]:
		var loc_def = Lang.parse(source.replace("LOCATION: {generated}", "LOCATION: %s" % loc))
		assert(not Runtime.is_available(loc_def, "example_pattern_noticed", Runtime.make_context(shared_state)), "pattern must stay unnoticed before three sources")
		var read = Runtime.enter(loc_def, "example_shared_signage", Runtime.make_context(shared_state), shared_state)
		Runtime.commit_through(read, shared_state, read.cards.size())
	assert(shared_state.object_state.object_count("example_shared_signage") == 3, "three distinct locations must have completed the shared tag")
	var last_def = Lang.parse(source.replace("LOCATION: {generated}", "LOCATION: location_gamma"))
	assert(Runtime.is_available(last_def, "example_pattern_noticed", Runtime.make_context(shared_state)), "three distinct sources must unlock the pattern remark")

	# --- example_disabled / example_unwritten must never surface ---
	assert(not Runtime.is_available(def, "example_disabled", ctx), "GATE: never must keep a block permanently unavailable")
	assert(not Runtime.is_available(def, "example_unwritten", ctx), "a block with no steps must never surface, same as dialogue's empty topics")

	print("PASS: object template parses; GATE cascade, FORK/OUTCOME, TAKE, locked drawer, and cross-location object_count verified")
	quit(0)
