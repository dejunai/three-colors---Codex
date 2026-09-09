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
	assert(not R.commit_through(first, D, 1), "partial playback must not complete topic")
	assert(D.facts.is_empty(), "later notebook effect must wait for its dialogue")
	assert(R.commit_through(first, D, first.cards.size()))
	assert(not R.commit_through(first, D, first.cards.size()), "completion event must fire once")
	S.estate_complete = true
	S.coat = "Plain wool coat"
	var later = R.enter(gardener, ctx, D)
	R.commit_through(later, D, later.cards.size())
	assert(D.facts.has("gardener.eight_sheets") and D.facts.has("gardener.service_door"), "both gardener clues must survive")
	var restored = load("res://scripts/shared/dialogue_state.gd").new()
	assert(restored.restore(D.pack()))
	assert(restored.facts == D.facts, "committed dialogue state must round-trip")
	var odell = R.enter(R.load_npc("res://dialogue/odell.dialogue"), ctx, D)
	assert(R.resume(odell, 0).is_empty(), "cannot choose before consuming the prompt")
	R.commit_through(odell, D, odell.cards.size())
	assert(R.resume(odell, -1).is_empty() and R.resume(odell, 99).is_empty())
	var branch = R.resume(odell, 0)
	assert(branch.cards.size() == 1 and branch.cards[0][1] == "I understand it. I don't accept it.")
	assert(D.visit_count("odell") == 1 and not D.topic_done("odell", "default"))
	assert(R.resume(odell, 1).is_empty(), "stale fork cannot be answered twice")
	assert(R.commit_through(branch, D, branch.cards.size()))
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
	R.commit_through(a, D, a.cards.size())
	var b = R.resume(a, 0)
	assert(b.cards == [["WALTER CORWIN", "Outer"], ["N", "Outer reply"]])
	R.commit_through(b, D, b.cards.size())
	var c = R.resume(b, 0)
	assert(c.cards == [["WALTER CORWIN", "Inner"], ["N", "Inner reply"], ["N", "Outer tail"], ["N", "Final tail"]])
	assert(not D.facts.has("nested.inner"))
	assert(not R.commit_through(c, D, 2))
	assert(D.facts.has("nested.inner") and not D.topic_done("nested", "default"))
	assert(R.commit_through(c, D, 4))
	assert(D.visit_count("nested") == 1)
	print("DIALOGUE PLAYBACK PASS: distinct gardener notes, deferred effects/completion, state round-trip, single-visit fork resume, invalid/stale choices, nested continuation")
	quit(0)
