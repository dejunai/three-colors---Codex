extends SceneTree

# Standalone check for the portal authoring format, runnable directly:
#   godot --headless --path . --script res://tests/portal_lang_flow.gd
# Mirrors tests/object_lang_flow.gd's coverage style, exercising
# scripts/shared/portal_lang.gd and scripts/shared/portal_runtime.gd in
# isolation via inline fixture sources (no .portal files on disk needed).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var Lang = load("res://scripts/shared/portal_lang.gd")
	var Runtime = load("res://scripts/shared/portal_runtime.gd")
	var CaseState = load("res://case_state.gd")

	# --- header parsing and basic errors ---
	var bad = Lang.parse("MADE_UP: x\nPORTAL: thing\n  GATE: always\n  GO: town | 0,0.1,0\n")
	assert(bad.errors.size() == 1, "an unknown header must be reported")

	# --- GATE cascade: locked (no GO) vs unlocked (GO), same id repeats ---
	var door_src = "LOCATION: estate\nPORTAL: service_entrance\n  GATE: NOT spoken_to(almy)\n  LABEL: \"Try the door\"\n  [A heavy door, bolted from the far side.]\n  WALTER CORWIN: \"Locked.\"\nPORTAL: service_entrance\n  GATE: spoken_to(almy)\n  LABEL: \"Enter\"\n  GO: lounge | 0,0.1,6 | 0\n"
	var door_def = Lang.parse(door_src)
	assert(door_def.errors.is_empty(), "door fixture must parse without errors: %s" % str(door_def.errors))
	assert(door_def.portals.size() == 2, "both PORTAL: service_entrance blocks must parse, ids are allowed to repeat")
	var state = CaseState.new()
	var ctx = Runtime.make_context(state)
	assert(Runtime.is_available(door_def, "service_entrance", ctx), "the locked block must be available before almy is spoken to")
	var locked = Runtime.enter(door_def, "service_entrance", ctx, state)
	assert(locked.go == null, "a block with no GO step must never travel")
	assert(locked.cards[0][1] == "A heavy door, bolted from the far side.", "locked beat must render")
	Runtime.commit_through(locked, state, locked.cards.size())
	assert(state.portal_state.portal_done("estate", "service_entrance"), "completing the locked block still marks the id done")
	state.dialogue_state.visit("almy")
	var unlocked = Runtime.enter(door_def, "service_entrance", Runtime.make_context(state), state)
	assert(unlocked.go != null, "GATE cascade must now select the unlocked block")
	assert(unlocked.go.destination == "lounge" and unlocked.go.spawn == [0.0, 0.1, 6.0], "GO must expose destination and spawn")
	assert(unlocked.cards.is_empty(), "an immediate GO with no preceding steps must render no cards")

	# --- never permanently excludes, regardless of state ---
	var never_src = "LOCATION: estate\nPORTAL: sealed\n  GATE: never\n  GO: town | 0,0.1,0\n"
	var never_def = Lang.parse(never_src)
	assert(not Runtime.is_available(never_def, "sealed", Runtime.make_context(CaseState.new())), "GATE: never must never be available")

	# --- attempt_count is incremented before availability is evaluated ---
	var count_src = "LOCATION: museum\nPORTAL: gate\n  GATE: always\n  GO: town | 0,0.1,0\n"
	var count_def = Lang.parse(count_src)
	var count_state = CaseState.new()
	assert(count_state.portal_state.attempt_count("museum", "gate") == 0, "attempt_count starts at zero")
	Runtime.enter(count_def, "gate", Runtime.make_context(count_state), count_state)
	assert(count_state.portal_state.attempt_count("museum", "gate") == 1, "the first enter() must already report count 1, not 0")

	# --- GO as a circuit breaker: content after GO renders only via after_go() ---
	var arrival_src = "LOCATION: tunnel\nPORTAL: tunnel_exit\n  GATE: always\n  GO: precinct | 0,0.1,5 | 0 | nosave,elapsed\n  [Back at the precinct.]\n  WALTER CORWIN: \"That's everything for now.\"\n"
	var arrival_def = Lang.parse(arrival_src)
	assert(arrival_def.errors.is_empty(), "arrival fixture must parse without errors: %s" % str(arrival_def.errors))
	var arrival_state = CaseState.new()
	var exit_result = Runtime.enter(arrival_def, "tunnel_exit", Runtime.make_context(arrival_state), arrival_state)
	assert(exit_result.go.destination == "precinct" and exit_result.go.flags == ["nosave", "elapsed"], "GO flags must parse in order")
	assert(exit_result.cards.is_empty(), "no cards precede this GO")
	Runtime.commit_through(exit_result, arrival_state, exit_result.cards.size())
	assert(not arrival_state.portal_state.portal_done("tunnel", "tunnel_exit"), "reaching an unresolved GO must not mark the portal complete yet")
	var resumed = Runtime.after_go(exit_result)
	assert(resumed.cards.size() == 2, "content authored after GO must render once the caller resumes via after_go()")
	assert(resumed.cards[0][1] == "Back at the precinct.")
	Runtime.commit_through(resumed, arrival_state, resumed.cards.size())
	assert(arrival_state.portal_state.portal_done("tunnel", "tunnel_exit"), "completing the post-GO continuation must mark the portal done")

	# --- known_ids()/fail-loud distinction, same rationale as objects ---
	var known = Runtime.known_ids(door_def)
	assert(known.has("service_entrance") and not known.has("nonexistent_id"), "known_ids must list every authored id, not just currently-eligible ones")

	# --- TAG/TIME/EVIDENCE/NOTEBOOK validation mirrors object_lang.gd ---
	var bad_ids = Lang.parse("LOCATION: x\nPORTAL: y\n  GATE: always\n  EVIDENCE: not a valid id\n")
	assert(bad_ids.errors.size() == 1, "EVIDENCE must require a simple identifier")
	var bad_time = Lang.parse("LOCATION: x\nPORTAL: y\n  GATE: always\n  TIME: -5\n  GO: z | 0,0,0\n")
	assert(bad_time.errors.size() == 1, "TIME must be a finite number >= 0")
	var bad_go = Lang.parse("LOCATION: x\nPORTAL: y\n  GATE: always\n  GO: z | not,three,numbers\n")
	assert(bad_go.errors.size() == 1, "GO must reject a malformed spawn")
	var bad_flag = Lang.parse("LOCATION: x\nPORTAL: y\n  GATE: always\n  GO: z | 0,0,0 | 0 | nosvae\n")
	assert(bad_flag.errors.size() == 1, "GO must reject an unrecognized flag such as a nosave typo")
	var good_flags = Lang.parse("LOCATION: x\nPORTAL: y\n  GATE: always\n  GO: z | 0,0,0 | 0 | nosave,elapsed\n")
	assert(good_flags.errors.is_empty(), "nosave and elapsed must remain accepted: %s" % str(good_flags.errors))

	# --- default TIME is empty when omitted ---
	var default_time_src = "LOCATION: x\nPORTAL: y\n  GATE: always\n  GO: z | 0,0,0\n"
	var default_time_def = Lang.parse(default_time_src)
	assert(default_time_def.errors.is_empty(), str(default_time_def.errors))
	assert(default_time_def.portals[0].timing.is_empty(), "omitted TIME must default to empty")

	# --- report and report_filed boolean evaluation ---
	var rep_state = CaseState.new()
	var rep_ctx = Runtime.make_context(rep_state)
	assert(not Lang.evaluate(Lang._parse_gate("report_filed"), rep_ctx), "report_filed must evaluate false before report is completed")
	assert(Lang.evaluate(Lang._parse_gate("NOT report_filed"), rep_ctx), "NOT report_filed must evaluate true before report is completed")
	assert(Lang.evaluate(Lang._parse_gate("report = ''"), rep_ctx), "report = '' must be true when report is empty")
	rep_state.complete_report("Observations filed")
	var filed_ctx = Runtime.make_context(rep_state)
	assert(Lang.evaluate(Lang._parse_gate("report_filed"), filed_ctx), "report_filed must evaluate true after report is completed")
	assert(not Lang.evaluate(Lang._parse_gate("NOT report_filed"), filed_ctx), "NOT report_filed must evaluate false after report is completed")
	assert(Lang.evaluate(Lang._parse_gate("report = 'Observations filed'"), filed_ctx), "report mode string must still match for textual reads")
	assert(not Lang.evaluate(Lang._parse_gate("report = ''"), filed_ctx), "report = '' must be false when report is non-empty")

	# --- cross-system parity: object_done, visit_count, topic_count, intake_done ---
	assert(not Lang.evaluate(Lang._parse_gate("object_done(estate, knife)"), filed_ctx), "object_done must evaluate correctly in portal runtime")
	assert(not Lang.evaluate(Lang._parse_gate("visit_count(odell) >= 1"), filed_ctx), "visit_count must evaluate correctly in portal runtime")
	assert(not Lang.evaluate(Lang._parse_gate("topic_count(crew_omission) >= 1"), filed_ctx), "topic_count must evaluate correctly in portal runtime")
	assert(not Lang.evaluate(Lang._parse_gate("intake_done"), filed_ctx), "intake_done must evaluate correctly in portal runtime")

	print("PASS: portal grammar parses; GATE cascade, GO/after_go continuation, attempt_count, known_ids, omitted TIME empty, report_filed, and validation verified")
	quit(0)
