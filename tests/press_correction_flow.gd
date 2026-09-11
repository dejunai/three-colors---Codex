extends SceneTree
const C=preload("res://case_state.gd")
const R=preload("res://scripts/shared/dialogue_runtime.gd")
func _initialize() -> void: call_deferred("run")
func available(st,topic:String) -> bool:
	var def=R.load_npc("res://dialogue/gazette_editor.dialogue")
	var menu=R.menu(def,R.make_context(st,st.dialogue_state))
	for entry in menu.entries:
		if entry.id==topic:return true
	return false
func drain(g) -> void:
	var count=0
	while g.page=="dialogue":g._next_card();count+=1;assert(count<100)
func run() -> void:
	# Holding evidence, or preparing an unreceived report, is not receipt.
	var draft=C.new();draft.discover("eight")
	draft.complete_report("Observations filed")
	assert(not R.has_filed_evidence(draft,"eight"))
	draft.receive_report();assert(R.has_filed_evidence(draft,"eight"))
	draft.discover("naomi");assert(not R.has_filed_evidence(draft,"naomi"))
	# Previously received supplements remain valid even after the current snapshot changes.
	draft.file_supplement(false)
	draft.supplement_evidence.clear()
	assert(R.has_filed_evidence(draft,"naomi"))
	draft.supplement_filed=false
	assert(R.has_filed_evidence(draft,"naomi"))
	var restored=C.new();assert(restored.restore(draft.pack()))
	assert(R.has_filed_evidence(restored,"naomi"))
	var scene=load("res://main.tscn").instantiate();root.add_child(scene)
	await process_frame
	var g=scene.chapter;g.test_mode=true
	for send_county in [false,true]:
		g.state=C.new();g.state.started=true;g.state.estate_complete=true
		g.state.discover("eight");g.state.visited.append("eight")
		g.state.complete_report("Full inquest requested" if send_county else "Observations filed",g._current_sources())
		g.state.receive_report()
		var original_report=g.state.report_evidence.duplicate()
		var original_county=g.state.county_evidence.duplicate()
		g.state.discover("naomi");g.state.discover("press_suppression")
		g._travel("business",Vector3(3,0.1,16),0,false)
		assert(not available(g.state,"print_correction"))
		g.scripted_dialogue.play_topic(g,"gazette_editor","correction_terms");drain(g)
		assert(g.state.evidence.has("gazette_correction_terms"))
		assert(available(g.state,"correction_pending"))
		assert(g._open_lead().contains("meal ledger"))
		assert(g._objective().contains("meal ledger"))
		g._file_supplement(send_county);drain(g)
		# Learning the ledger after submitting does not retroactively put it in the copy.
		g.state.discover("lodging")
		assert(not available(g.state,"print_correction"))
		assert(g._open_lead().contains("supplement"))
		g.scripted_dialogue.play_topic(g,"gazette_editor","print_correction")
		assert(not g.state.evidence.has("gazette_correction_printed"))
		g._file_supplement(send_county);drain(g)
		assert(available(g.state,"print_correction"))
		assert(not available(g.state,"correction_pending"))
		assert(g._open_lead().contains("Gazette editor"))
		var reports_before=g.state.supplement_history.duplicate(true)
		var time_before=g.state.clock_minutes
		g.scripted_dialogue.play_topic(g,"gazette_editor","print_correction")
		g._next_card()
		assert(not g.state.evidence.has("gazette_correction_printed"),"Reading the first line does not print the slip")
		assert(g._save_game());g._load_game()
		g=scene.chapter
		drain(g)
		var loaded_state=g.state
		assert(loaded_state.evidence.has("gazette_correction_printed"))
		assert(loaded_state.clock_minutes==time_before+8)
		assert(loaded_state.report_evidence==original_report)
		assert(loaded_state.county_evidence==original_county)
		assert(loaded_state.supplement_history==reports_before)
		assert(loaded_state.links.is_empty(),"Printing requires no manual linking")
		assert(not available(loaded_state,"print_correction"))
		assert(not available(loaded_state,"the_omitted_two"))
		g.scripted_dialogue.play_topic(g,"gazette_editor","print_correction")
		assert(g.state.clock_minutes==time_before+8)
		# The morning edition remains its original account; a distinct later slip is added.
		g._travel("room",Vector3(0,0.1,3),0,false)
		g._town_observation("gazette")
		assert(g.dialogue.cards.size()==g.TownStory.SCENES.gazette.size()+1)
		assert(g.dialogue.cards[0]==g.TownStory.SCENES.gazette[0])
		assert(g.dialogue.cards[-1][0]=="THE CORRECTION SLIP")
		drain(g)
		assert(not g.archive._try_link(g,"gazette","gazette_correction_printed").is_empty())
		g._travel("boardinghouse",Vector3(1.7,0.1,-2),0,false)
		g.scripted_dialogue.play_topic(g,"almy","show_printed_correction");drain(g)
		assert(g.state.dialogue_state.topic_done("almy","show_printed_correction"))
	print("PRESS CORRECTION PASS: received-source gates, later discovery needs supplement, both filing paths, live mid-print save, one-time timing, original copies preserved, newspaper slip and Almy response")
	quit()
