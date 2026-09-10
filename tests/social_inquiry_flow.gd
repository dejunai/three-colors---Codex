extends SceneTree
const R=preload("res://scripts/shared/dialogue_runtime.gd")
const C=preload("res://case_state.gd")
const SOURCES=["county_clerk","gazette_editor","post_office_clerk","stationer","tailor","miss_wexley"]
func _initialize() -> void: call_deferred("run")
func available(st, npc:String, topic:String) -> bool:
	var menu=R.menu(R.load_npc("res://dialogue/"+npc+".dialogue"),R.make_context(st,st.dialogue_state))
	for entry in menu.entries:
		if entry.id==topic: return true
	return false
func finish(st,npc:String,topic:String) -> void:
	var result=R.play_topic_by_path("res://dialogue/"+npc+".dialogue",st,st.dialogue_state,topic)
	assert(not result.session.is_empty())
	R.commit_through(result,st,st.dialogue_state,result.cards.size())
	assert(result.fork==null)
	for id in st.dialogue_state.evidence: st.discover(id)
func drain(g) -> void:
	var guard=0
	while g.page=="dialogue":
		g._next_card();guard+=1;assert(guard<100)
func labels(g) -> String:
	var text=""
	for label in g.content.find_children("*","Label",true,false): text+=label.text+"\n"
	return text
func run() -> void:
	var st=C.new()
	st.discover("lay_lead");st.discover("naomi")
	assert(not available(st,"schoolteacher","the_slain_boy"))
	assert(available(st,"schoolteacher","personal_questions"))
	assert(not available(st,"stationer","crew_omission"))
	finish(st,"local_historian","crew_omission_official")
	assert(st.dialogue_state.topic_count("crew_omission")==0)
	var def=R.load_npc("res://dialogue/stationer.dialogue")
	var pending=R.play_topic(def,st.dialogue_state,"crew_omission")
	R.commit_through(pending,st,st.dialogue_state,1)
	assert(st.dialogue_state.topic_count("crew_omission")==0,"Partial conversation cannot count")
	for i in 6: finish(st,"stationer","crew_omission")
	assert(st.dialogue_state.topic_count("crew_omission")==1,"One witness cannot supply multiple refusals")
	assert(not available(st,"local_historian","crew_omission_followup"))
	# Every possible set of four witnesses works; the fifth and sixth are optional.
	var combinations=0
	for mask in range(64):
		var selected=[]
		for i in 6:
			if mask & (1<<i): selected.append(SOURCES[i])
		if selected.size()!=4: continue
		var trial=C.new();trial.discover("lay_lead")
		finish(trial,"local_historian","crew_omission_official")
		for i in 4:
			finish(trial,selected[i],"crew_omission")
			assert(available(trial,"local_historian","crew_omission_followup")== (i==3))
		var restored=C.new();assert(restored.restore(trial.pack().duplicate(true)))
		assert(available(restored,"local_historian","crew_omission_followup"))
		finish(restored,"local_historian","crew_omission_followup")
		assert(available(restored,"schoolteacher","reader_letter"))
		assert(not available(restored,"schoolteacher","the_slain_boy"))
		finish(restored,"schoolteacher","reader_letter")
		restored.discover("naomi")
		assert(available(restored,"schoolteacher","the_slain_boy"))
		assert(not available(restored,"schoolteacher","personal_questions"))
		combinations+=1
	assert(combinations==15)
	# Actual scene: save/load in a refusal, finish the chain, and draw the new link.
	var scene=load("res://main.tscn").instantiate();root.add_child(scene)
	await process_frame
	var g=scene.chapter;g.test_mode=true;g.state=st;g.state.started=true
	g._travel("post_office",Vector3(4,0.1,0),0,false)
	g.scripted_dialogue.play_topic(g,"post_office_clerk","crew_omission")
	g._next_card();assert(g._save_game());g._load_game();drain(g)
	assert(g.state.dialogue_state.topic_count("crew_omission")==2)
	finish(g.state,"tailor","crew_omission");finish(g.state,"county_clerk","crew_omission")
	g._travel("museum",Vector3(2,0.1,-2),0,false)
	g.scripted_dialogue.play_topic(g,"local_historian","crew_omission_followup");drain(g)
	assert(g.state.evidence.has("curriculum_abridgment"))
	g._travel("schoolhouse",Vector3(0,0.1,-2),0,false)
	g.scripted_dialogue.play_topic(g,"schoolteacher","reader_letter");drain(g)
	assert(g.state.evidence.has("reader_omission_letter"))
	assert(not g.archive._try_link(g,"curriculum_abridgment","reader_omission_letter").is_empty())
	assert(g.state.has_link("reader_omission"))
	# The first steward visit's promised book has a later, earned payoff.
	var staff=C.new();staff.visited.append("almy");staff.discover("service_work")
	assert(not available(staff,"steward","day_book"))
	staff.day=3;staff.steward_visits=2
	assert(not available(staff,"steward","day_book"))
	staff.coat="Plain wool coat"
	assert(available(staff,"steward","day_book"))
	finish(staff,"steward","day_book")
	assert(staff.evidence.has("estate_day_book"))
	# Nine ordinary observations may increase Perception, never reveal a missing cause.
	g.state=C.new()
	for id in ["wounds","eight","knife","watch","gas","register","shoes","testimony","intake"]: g.state.discover(id)
	assert(g.state.perception()==5)
	g._board();var board=labels(g)
	assert(board.contains("CAUSE UNRESOLVED"))
	assert(not board.contains("SUMMONED PRESENCE") and not board.contains("UNDERSEA PASSAGE"))
	g.state.discover("naomi");g.state.discover("lay_lead")
	g.archive._link_result(g,"naomi","lay_lead")
	assert(not labels(g).contains("satchel") and labels(g).contains("has not examined"))
	g.state.discover("lower_foundation");g._board()
	assert(labels(g).contains("THE MEASURED PASSAGE"))
	var before=g.state.pack().duplicate(true);g._notebook()
	assert(labels(g).contains("CAUSE UNRESOLVED") and g.state.pack()==before)
	print("SOCIAL INQUIRY PASS: 15 four-witness combinations; no repeat/partial farming; saved live refusal; historian to teacher; corroboration; evidence-honest board and notebook")
	quit()
