extends SceneTree

# Standalone check for the object authoring format, runnable directly:
#   godot --headless --path . --script res://tests/object_lang_flow.gd
# Mirrors tests/dialogue_lang_flow.gd's coverage style, but exercises
# scripts/shared/object_lang.gd and scripts/shared/object_runtime.gd
# in isolation via inline fixture sources (no .object files on disk needed).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Lang = load("res://scripts/shared/object_lang.gd")
	var Runtime = load("res://scripts/shared/object_runtime.gd")
	var CaseState = load("res://case_state.gd")

	# --- header parsing and basic errors ---
	var bad = Lang.parse("MADE_UP: x\nOBJECT: thing\n  GATE: always\n  WALTER CORWIN: \"Hi.\"\n")
	assert(bad.errors.size() == 1, "an unknown header must be reported")

	# --- GATE cascade: same id repeats, first eligible (file order) wins ---
	var knife_src = "LOCATION: estate\nOBJECT: knife\n  GATE: NOT object_done(estate, knife)\n  TAG: knife_first\n  TIME: 5\n  [Wiped too clean.]\n  WALTER CORWIN: \"First look.\"\n  EVIDENCE: clean_knife\nOBJECT: knife\n  GATE: object_done(estate, knife)\n  WALTER CORWIN: \"Nothing new now.\"\n"
	var knife_def = Lang.parse(knife_src)
	assert(knife_def.errors.is_empty(), "knife fixture must parse without errors: %s" % str(knife_def.errors))
	assert(knife_def.objects.size() == 2, "both OBJECT: knife blocks must parse, ids are allowed to repeat")
	var state = CaseState.new()
	var ctx = Runtime.make_context(state)
	assert(Runtime.is_available(knife_def, "knife", ctx), "the first-look block must be available before completion")
	var first_look = Runtime.enter(knife_def, "knife", ctx, state)
	assert(first_look.cards[0][1] == "Wiped too clean.", "first-look beat must render before the line")
	assert(first_look.cards[1] == ["WALTER CORWIN", "First look."], "first-look line must render")
	Runtime.commit_through(first_look, state, first_look.cards.size())
	assert(state.object_state.object_done("estate", "knife"), "completing the block must mark the object id done")
	assert(state.object_state.facts.is_empty(), "no NOTEBOOK was authored in this fixture")
	assert(state.object_state.evidence.has("clean_knife"), "EVIDENCE must be tallied on object_state, mirroring dialogue_state")
	var second_look = Runtime.enter(knife_def, "knife", Runtime.make_context(state), state)
	assert(second_look.cards[0][1] == "Nothing new now.", "GATE cascade must now select the second block")

	# --- known_ids(): distinguishes "not ours" from "ours, but unavailable" —
	# the fail-loud guard in chapter_one_objects.gd depends on this distinction
	# so a correctly-absent hotspot (never clickable) never trips a false alarm.
	var known = Runtime.known_ids(knife_def)
	assert(known.has("knife") and not known.has("nonexistent_id"), "known_ids must list every authored id, not just currently-eligible ones")
	var broken_src = "LOCATION: estate\nOBJECT: drawer\n  GATE: never\n  WALTER CORWIN: \"Unreachable.\"\n"
	var broken_def = Lang.parse(broken_src)
	assert(Runtime.known_ids(broken_def).has("drawer") and not Runtime.is_available(broken_def, "drawer", Runtime.make_context(CaseState.new())), "an authored-but-currently-ineligible id must still be 'known' even though it is not available")

	# --- never permanently excludes, regardless of state ---
	var never_src = "LOCATION: estate\nOBJECT: sealed\n  GATE: never\n  WALTER CORWIN: \"Unreachable.\"\n"
	var never_def = Lang.parse(never_src)
	assert(not Runtime.is_available(never_def, "sealed", Runtime.make_context(CaseState.new())), "GATE: never must never be available")

	# --- examine_count is incremented before availability is evaluated (matches visit_count's off-by-one) ---
	var count_src = "LOCATION: museum\nOBJECT: case\n  GATE: always\n  WALTER CORWIN: \"A case.\"\n"
	var count_def = Lang.parse(count_src)
	var count_state = CaseState.new()
	assert(count_state.object_state.examine_count("museum", "case") == 0, "examine_count starts at zero")
	Runtime.enter(count_def, "case", Runtime.make_context(count_state), count_state)
	assert(count_state.object_state.examine_count("museum", "case") == 1, "the first enter() must already report count 1, not 0")
	Runtime.enter(count_def, "case", Runtime.make_context(count_state), count_state)
	assert(count_state.object_state.examine_count("museum", "case") == 2, "each enter() call counts a separate examination")

	# --- FORK halts for an unresolved choice; TAKE only applies on the chosen branch ---
	var fork_src = "LOCATION: estate\nOBJECT: chest\n  GATE: always\n  FORK:\n    CHOICE: \"Take the coin.\"\n      TAKE: old_coin\n      OUTCOME: chest_response = taken\n    CHOICE: \"Leave it.\"\n      OUTCOME: chest_response = left\n"
	var fork_def = Lang.parse(fork_src)
	assert(fork_def.errors.is_empty(), "fork fixture must parse without errors: %s" % str(fork_def.errors))
	var fork_state = CaseState.new()
	var fork_ctx = Runtime.make_context(fork_state)
	var opened = Runtime.enter(fork_def, "chest", fork_ctx, fork_state)
	Runtime.commit_through(opened, fork_state, opened.cards.size())
	assert(opened.fork != null, "the FORK must halt rendering until a choice is supplied")
	assert(opened.fork.options == ["Take the coin.", "Leave it."], "fork options must be exposed in author order")
	assert(not fork_state.has_item("old_coin"), "an unresolved fork must not apply either branch's effects")
	var resumed = Runtime.resume(opened, 0)
	Runtime.commit_through(resumed, fork_state, resumed.cards.size())
	assert(fork_state.has_item("old_coin"), "TAKE on the chosen branch must add the item to case_state.inventory")
	assert(fork_state.dialogue_state.outcome_is("chest_response", "taken"), "OUTCOME must commit through the shared dialogue_state store")

	# --- OUTCOME lock: replay shows only the committed branch ---
	var replay = Runtime.enter(fork_def, "chest", Runtime.make_context(fork_state), fork_state)
	assert(replay.fork.options == ["Take the coin."], "replay must expose only the previously committed branch")

	# --- object_count(): distinct LOCATIONs completing a shared id/tag ---
	var signage_src_a = "LOCATION: pickman_street\nOBJECT: notice\n  GATE: always\n  TAG: shared_notice\n  WALTER CORWIN: \"A notice.\"\n"
	var signage_src_b = "LOCATION: harbor_road\nOBJECT: notice\n  GATE: always\n  TAG: shared_notice\n  WALTER CORWIN: \"The same notice.\"\n"
	var signage_a = Lang.parse(signage_src_a)
	var signage_b = Lang.parse(signage_src_b)
	var signage_state = CaseState.new()
	assert(signage_state.object_state.object_count("shared_notice") == 0, "shared tag not yet completed anywhere")
	var read_a = Runtime.enter(signage_a, "notice", Runtime.make_context(signage_state), signage_state)
	Runtime.commit_through(read_a, signage_state, read_a.cards.size())
	assert(signage_state.object_state.object_count("shared_notice") == 1, "one distinct location has completed the shared tag")
	var read_b = Runtime.enter(signage_b, "notice", Runtime.make_context(signage_state), signage_state)
	Runtime.commit_through(read_b, signage_state, read_b.cards.size())
	assert(signage_state.object_state.object_count("shared_notice") == 2, "a second distinct location must grow the tally")
	var read_a_again = Runtime.enter(signage_a, "notice", Runtime.make_context(signage_state), signage_state)
	Runtime.commit_through(read_a_again, signage_state, read_a_again.cards.size())
	assert(signage_state.object_state.object_count("shared_notice") == 2, "re-completing the same location must not double-count")

	# --- taken()/flag()/outcome() are shared with the dialogue system ---
	assert(Lang.evaluate(Lang._parse_gate("taken(old_coin)"), Runtime.make_context(fork_state)), "taken() must read case_state.inventory")
	var DialogueRuntime = load("res://scripts/shared/dialogue_runtime.gd")
	var dctx = DialogueRuntime.make_context(fork_state, fork_state.dialogue_state)
	assert(dctx.functions.taken.call(["old_coin"]), "dialogue_runtime's make_context must expose the same taken() fact")
	assert(dctx.functions.outcome_is.call(["chest_response", "taken"]), "dialogue GATEs must read an OBJECT's committed OUTCOME")

	# --- TIME: omitted is free; explicit numeric (including 0) always wins ---
	var timing_src = "LOCATION: estate\nOBJECT: free_look\n  GATE: always\n  WALTER CORWIN: \"No charge.\"\nOBJECT: priced_look\n  GATE: always\n  TIME: 5\n  WALTER CORWIN: \"Costs time.\"\nOBJECT: zero_look\n  GATE: always\n  TIME: 0\n  WALTER CORWIN: \"Explicitly free.\"\n"
	var timing_def = Lang.parse(timing_src)
	var timing_state = CaseState.new()
	var clock_before = timing_state.clock_minutes
	var free_result = Runtime.enter(timing_def, "free_look", Runtime.make_context(timing_state), timing_state)
	Runtime.commit_through(free_result, timing_state, free_result.cards.size())
	assert(timing_state.clock_minutes == clock_before, "an omitted TIME must cost zero minutes")
	var priced_result = Runtime.enter(timing_def, "priced_look", Runtime.make_context(timing_state), timing_state)
	Runtime.commit_through(priced_result, timing_state, priced_result.cards.size())
	assert(is_equal_approx(timing_state.clock_minutes - clock_before, 5.0), "an explicit TIME must charge that many minutes")

	# --- authoring errors: OUTCOME outside FORK, malformed TAKE id ---
	var stray_outcome = Lang.parse("LOCATION: x\nOBJECT: y\n  GATE: always\n  OUTCOME: a = b\n")
	assert(stray_outcome.errors.size() == 1, "OUTCOME outside a FORK choice must be an error")
	var bad_take = Lang.parse("LOCATION: x\nOBJECT: y\n  GATE: always\n  TAKE: not a valid id\n")
	assert(bad_take.errors.size() == 1, "TAKE must require a simple identifier")

	print("PASS: object grammar parses; GATE cascade, FORK/OUTCOME, TAKE/inventory, object_count, timing, and dialogue-shared facts verified")
	quit(0)
