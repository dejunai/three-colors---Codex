extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g=scene.chapter
	g.test_mode=true
	for lead in [false,true]:
		g.scripted_dialogue.clear()
		g.state=g.CaseState.new()
		g.state.visited.append("almy")
		g.state.intake_done=true
		g.state.discover("naomi")
		if lead: g.state.discover("service_work")
		g._travel("lounge",Vector3.ZERO,0,false)
		g.scripted_dialogue.interact(g,"barman")
		assert(g.scripted_dialogue.segment.session.tag==("steward_first_lead" if lead else "steward_first"))
		var incomplete=g.CaseState.new()
		assert(incomplete.restore(g.state.pack().duplicate(true)))
		assert(incomplete.steward_visits==0,"Opening a conversation is not completing it")
		while g.page=="dialogue": g._next_card()
		assert(g.state.steward_visits==1)
		assert(g.state.dialogue_state.visit_count("steward")==1)
		# Reproduce the broken counter from existing saves after completion.
		var broken=g.state.pack().duplicate(true)
		broken.steward_visits=0
		broken.dialogue_state.visit_counts["steward"]=0
		var restored=g.CaseState.new()
		assert(restored.restore(broken))
		assert(restored.steward_visits==1 and restored.dialogue_state.visit_count("steward")==1)
		assert(restored.evidence==g.state.evidence and restored.day==1)
		g.state=restored
		g.staging.sleep(g)
		assert(g.page=="montage" and g.state.day==2)
		while g.page=="montage":
			for button in g.content.find_children("*","Button",true,false):
				if button.text=="Continue":
					button.pressed.emit()
					break
		assert(g.state.day==3 and g.state.steward_visits==2)
		var later=g.CaseState.new()
		assert(later.restore(g.state.pack().duplicate(true)))
		assert(later.steward_visits==2)
	print("STEWARD SLEEP PASS: both first conversations, incomplete conversation, save repair, montage and day-three visit count")
	quit()
