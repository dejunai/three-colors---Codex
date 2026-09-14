extends SceneTree

# Standalone check for the portal cookbook, runnable directly:
#   godot --headless --path . --script res://tests/portal_template_flow.gd
# Mirrors tests/object_template_flow.gd's shape, adapted to GO/after_go.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Lang = load("res://scripts/shared/portal_lang.gd")
	var Runtime = load("res://scripts/shared/portal_runtime.gd")
	var CaseState = load("res://case_state.gd")
	var source = FileAccess.get_file_as_string("res://portals/background_portal_template.portal")
	var template = Lang.parse(source)
	assert(template.errors.is_empty(), str(template.errors))
	assert(template.location.contains("{"), "Cookbook must remain excluded from live location discovery")

	var def = Lang.parse(source.replace("LOCATION: {generated}", "LOCATION: example_location"))
	assert(def.errors.is_empty(), str(def.errors))
	var state = CaseState.new()
	var ctx = Runtime.make_context(state)

	# --- example_door: locked (no GO) vs unlocked (GO), GATE cascade ---
	assert(Runtime.is_available(def, "example_door", ctx), "the locked block must be available before speaking to the witness")
	var locked = Runtime.enter(def, "example_door", ctx, state)
	assert(locked.go == null, "the locked block must never travel")
	Runtime.commit_through(locked, state, locked.cards.size())
	state.dialogue_state.visit("example_witness")
	var unlocked = Runtime.enter(def, "example_door", Runtime.make_context(state), state)
	assert(unlocked.go != null and unlocked.go.destination == "example_location", "GATE cascade must now select the unlocked, GO-bearing block")

	# --- example_encounter_exit: immediate GO with nosave/elapsed flags ---
	var exit_result = Runtime.enter(def, "example_encounter_exit", Runtime.make_context(state), state)
	assert(exit_result.go.flags == ["nosave", "elapsed"], "GO flags must parse in author order")
	assert(exit_result.cards.is_empty(), "an immediate GO with no preceding steps renders no cards")

	# --- example_arrival: content authored after GO renders via after_go() ---
	state.discover("example_measurement")
	var arrival = Runtime.enter(def, "example_arrival", Runtime.make_context(state), state)
	assert(arrival.go != null and arrival.cards.is_empty())
	Runtime.commit_through(arrival, state, arrival.cards.size())
	var after_arrival = Runtime.after_go(arrival)
	assert(after_arrival.cards.size() == 2, "arrival narration must render once the caller resumes past GO")
	Runtime.commit_through(after_arrival, state, after_arrival.cards.size())
	assert(state.portal_state.portal_done("example_location", "example_arrival"), "completing the post-GO continuation must mark the portal done")

	# --- example_toll_gate: NOTEBOOK before GO commits immediately; GATE cascade on portal_done ---
	var toll_state = CaseState.new()
	assert(Runtime.is_available(def, "example_toll_gate", Runtime.make_context(toll_state)), "the untaxed block must be available first")
	var first_crossing = Runtime.enter(def, "example_toll_gate", Runtime.make_context(toll_state), toll_state)
	assert(first_crossing.go != null and first_crossing.cards.is_empty())
	Runtime.commit_through(first_crossing, toll_state, first_crossing.cards.size())
	assert(toll_state.portal_state.facts.has("example_location.example_toll_note"), "NOTEBOOK before GO must still commit")
	var after_first_crossing = Runtime.after_go(first_crossing)
	Runtime.commit_through(after_first_crossing, toll_state, after_first_crossing.cards.size())
	assert(toll_state.portal_state.portal_done("example_location", "example_toll_gate"), "the toll crossing must complete once GO resolves")
	var second_crossing = Runtime.enter(def, "example_toll_gate", Runtime.make_context(toll_state), toll_state)
	assert(second_crossing.go != null, "the already-paid block must still offer GO")
	assert(Runtime.select(def, "example_toll_gate", Runtime.make_context(toll_state)).label == "Cross again", "GATE cascade must now select the already-paid block's own label")

	# --- example_shared_checkpoint: portal_count() across locations ---
	var shared_state = CaseState.new()
	for loc in ["location_alpha", "location_beta", "location_gamma"]:
		var loc_def = Lang.parse(source.replace("LOCATION: {generated}", "LOCATION: %s" % loc))
		var crossing = Runtime.enter(loc_def, "example_shared_checkpoint", Runtime.make_context(shared_state), shared_state)
		Runtime.commit_through(crossing, shared_state, crossing.cards.size())
		var after_crossing = Runtime.after_go(crossing)
		Runtime.commit_through(after_crossing, shared_state, after_crossing.cards.size())
	assert(shared_state.portal_state.portal_count("example_shared_checkpoint") == 3, "three distinct locations completing the same portal id must grow the tally")

	# --- example_disabled / example_unwritten must never surface ---
	assert(not Runtime.is_available(def, "example_disabled", ctx), "GATE: never must keep a block permanently unavailable")
	assert(not Runtime.is_available(def, "example_unwritten", ctx), "a block with no steps must never surface, same as objects' empty blocks")

	print("PASS: portal template parses; GATE cascade, GO/after_go continuation, TIME/NOTEBOOK-before-GO, and portal_done all verified")
	quit(0)
