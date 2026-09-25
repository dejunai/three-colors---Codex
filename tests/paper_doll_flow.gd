extends SceneTree

func _initialize() -> void: call_deferred("run")

func _text(g:Node) -> String:
	var result = ""
	for label in g.content.find_children("*", "Label", true, false): result += label.text + "\n"
	return result

func _slot(g:Node,name:String) -> Button:
	return g.content.find_child(name,true,false) as Button

func _button(g:Node,text:String) -> Button:
	for button in g.content.find_children("*","Button",true,false):
		if button.text == text: return button
	return null

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g.state.coat = "Police coat"
	g.state.ammo = 4
	g._case_file()

	var doll = g.content.find_child("WalterPaperDoll",true,false)
	assert(doll != null, "Personal Effects must contain the paper doll")
	assert(doll.coat == "Police coat" and doll.badge_visible and doll.ammo == 4)
	for name in ["CoatSlot","BadgeSlot","NotebookSlot","RevolverSlot","FlaskSlot","BootsSlot"]:
		assert(_slot(g,name) != null, "Missing paper-doll slot: %s" % name)
	var leave = _button(g,"Return to the grounds")
	assert(leave != null and leave.get_parent().name == "EffectsActions", "The grounds button must sit with the other actions, not below the full panel")

	_slot(g,"CoatSlot").pressed.emit()
	assert(g.state.coat == "Plain wool coat", "The paper-doll coat control must reuse the live coat state")
	doll = g.content.find_child("WalterPaperDoll",true,false)
	assert(doll.coat == "Plain wool coat" and not doll.badge_visible)

	_slot(g,"BadgeSlot").pressed.emit()
	assert("pocketed" in _text(g) and "inside" in _text(g), "Plain coat badge inspection must report badge pocketed inside coat before retreat")
	g._close()

	_slot(g,"RevolverSlot").pressed.emit()
	assert("4 of 6 rounds remain" in _text(g))
	g._close()
	assert(g.page == "case" and g.content.find_child("WalterPaperDoll",true,false) != null, "Closing an equipment inspection must return to Personal Effects")
	_slot(g,"BootsSlot").pressed.emit()
	assert("resoled twice" in _text(g))
	g._close()
	_slot(g,"NotebookSlot").pressed.emit()
	assert(g.page == "notebook")
	g._close()
	assert(g.page == "case" and g.content.find_child("WalterPaperDoll",true,false) != null, "Closing the notebook opened from the doll must return to the doll")

	g.state.coat = "Plain wool coat"
	g.state.dialogue_state.set_flag("badge_lost",true)
	g.state.flask_spilled = true
	g._case_file()
	doll = g.content.find_child("WalterPaperDoll",true,false)
	assert(doll.badge_lost and not doll.badge_visible and doll.flask_spilled)
	_slot(g,"BadgeSlot").pressed.emit()
	assert("Lost below the estate" in _text(g), "Plain coat badge inspection must say lost afterward")
	g._close()
	_slot(g,"FlaskSlot").pressed.emit()
	assert("Lost in the dark below" in _text(g))
	g._close()
	assert(g.page == "case" and g.content.find_child("WalterPaperDoll",true,false) != null)

	# The same screens opened directly retain their ordinary game return.
	g._close()
	assert(g.page == "play")
	g._journal()
	g._close()
	assert(g.page == "play", "A directly-opened case file must still close to the game")

	print("PAPER DOLL PASS: compact grounds action; contextual return from equipment, notebook and case UI; direct UI still closes to game; state-driven equipment slots")
	quit()
