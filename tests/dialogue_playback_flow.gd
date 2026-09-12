extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var R = load("res://scripts/shared/dialogue_runtime.gd")
	var L = load("res://scripts/shared/dialogue_lang.gd")
	var S = load("res://case_state.gd").new()
	var D = load("res://scripts/shared/dialogue_state.gd").new()
	var ctx = R.make_context(S, D)
	var gardener = R.load_npc("res://dialogue/gardener.dialogue")
	var first = R.enter(gardener, ctx, D)
	assert(D.facts.is_empty() and not D.topic_done("gardener", "default"), "preparation must not commit progress")
	assert(not R.commit_through(first, S, D, 1), "partial playback must not complete topic")
	assert(D.facts.is_empty(), "later notebook effect must wait for its dialogue")
	assert(S.clock_minutes == 360.0, "the clock must not move before a topic actually finishes")
	assert(R.commit_through(first, S, D, first.cards.size()))
	assert(S.clock_minutes == 363.0, "gardener's TIME: 3 must charge on first completion")
	assert(not R.commit_through(first, S, D, first.cards.size()), "completion event must fire once")
	assert(S.clock_minutes == 363.0, "a repeated completion event must not charge time twice")
	S.estate_complete = true
	S.coat = "Plain wool coat"
	var later = R.enter(gardener, ctx, D)
	R.commit_through(later, S, D, later.cards.size())
	assert(S.clock_minutes == 366.0, "gardener_plain shares the 'default' topic id but is a distinct TAG, so it must still charge its own TIME: 3")
	assert(D.facts.has("gardener.eight_sheets") and D.facts.has("gardener.service_door"), "both gardener clues must survive")
	var restored = load("res://scripts/shared/dialogue_state.gd").new()
	assert(restored.restore(D.pack()))
	assert(restored.facts == D.facts, "committed dialogue state must round-trip")
	var odell = R.enter(R.load_npc("res://dialogue/odell.dialogue"), ctx, D)
	assert(R.resume(odell, 0).is_empty(), "cannot choose before consuming the prompt")
	R.commit_through(odell, S, D, odell.cards.size())
	assert(R.resume(odell, -1).is_empty() and R.resume(odell, 99).is_empty())
	var branch = R.resume(odell, 0)
	assert(branch.cards.size() == 1 and branch.cards[0][1] == "I understand it. I don't accept it.")
	assert(D.visit_count("odell") == 1 and not D.topic_done("odell", "default"))
	assert(R.resume(odell, 1).is_empty(), "stale fork cannot be answered twice")
	assert(R.commit_through(branch, S, D, branch.cards.size()))
	assert(S.clock_minutes == 374.0, "odell's TIME: 8 must charge once the branching topic actually finishes")
	assert(D.topic_done("odell", "default"))
	# Nested forks must return to both parent tails and defer branch notes.
	var fixture = L.parse('''NPC: nested
TOPIC: default
  GATE: always
  N: "Opening"
  FORK:
    CHOICE: "Outer"
      N: "Outer reply"
      FORK:
        CHOICE: "Inner"
          N: "Inner reply"
          NOTEBOOK: inner | "Inner note"
        CHOICE: "Other"
          N: "Other reply"
      N: "Outer tail"
    CHOICE: "Decline"
      N: "Declined"
  N: "Final tail"
''')
	assert(fixture.errors.is_empty())
	var a = R.enter(fixture, ctx, D)
	R.commit_through(a, S, D, a.cards.size())
	var b = R.resume(a, 0)
	assert(b.cards == [["WALTER CORWIN", "Outer", ""], ["N", "Outer reply", ""]])
	R.commit_through(b, S, D, b.cards.size())
	var c = R.resume(b, 0)
	assert(c.cards == [["WALTER CORWIN", "Inner", ""], ["N", "Inner reply", ""], ["N", "Outer tail", ""], ["N", "Final tail", ""]])
	assert(not D.facts.has("nested.inner"))
	assert(not R.commit_through(c, S, D, 2))
	assert(D.facts.has("nested.inner") and not D.topic_done("nested", "default"))
	assert(R.commit_through(c, S, D, 4))
	assert(D.visit_count("nested") == 1)
	# Consequential fork outcomes commit only with the completed chosen path,
	# retire their source topic automatically, persist, and cannot be overwritten.
	var decision = L.parse('''NPC: choice_test
TOPIC: decision
  GATE: always
  FORK:
    CHOICE: "Press him."
      N: "He stiffens."
      OUTCOME: odell_response = pressed
    CHOICE: "Let it pass."
      N: "He relaxes."
      OUTCOME: odell_response = deferred
''')
	assert(decision.errors.is_empty())
	assert(R.menu(decision, R.make_context(S, D)).entries.size() == 1)
	var prompt = R.render("choice_test", decision.topics[0], D)
	R.commit_through(prompt, S, D, prompt.cards.size())
	var chosen = R.resume(prompt, 0)
	assert(not R.commit_through(chosen, S, D, 1) and not D.has_outcome("odell_response"), "Partial branch playback must not commit its outcome")
	assert(R.commit_through(chosen, S, D, chosen.cards.size()))
	assert(D.outcome_is("odell_response", "pressed") and not D.outcome_is("odell_response", "deferred"))
	assert(R.menu(decision, R.make_context(S, D)).entries.is_empty(), "A committed outcome must retire its source fork")
	assert(L.evaluate(L._parse_gate("outcome(odell_response) AND outcome_is(odell_response, pressed)"), R.make_context(S, D)))
	D.set_outcome("odell_response", "deferred")
	assert(D.outcome_is("odell_response", "pressed"), "A committed outcome must be immutable")
	var outcome_restore = load("res://scripts/shared/dialogue_state.gd").new()
	assert(outcome_restore.restore(D.pack()) and outcome_restore.outcome_is("odell_response", "pressed"), "Outcomes must survive save/load")
	var legacy_pack = D.pack()
	legacy_pack.erase("outcomes")
	var legacy_restore = load("res://scripts/shared/dialogue_state.gd").new()
	assert(legacy_restore.restore(legacy_pack) and legacy_restore.outcomes.is_empty(), "Pre-OUTCOME dialogue saves must remain valid")
	print("DIALOGUE PLAYBACK PASS: distinct gardener notes, deferred effects/completion, state round-trip, forks, nested continuation, immutable outcomes and automatic retirement")
	quit(0)
