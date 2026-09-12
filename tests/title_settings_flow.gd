extends SceneTree

func _initialize() -> void: call_deferred("run")

func _click(button:Button) -> void:
	var point=button.get_global_rect().get_center()
	for pressed in [true,false]:
		var event=InputEventMouseButton.new()
		event.position=point
		event.button_index=MOUSE_BUTTON_LEFT
		event.pressed=pressed
		root.push_input(event)
	await process_frame

func run() -> void:
	var scene=load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g=scene.chapter
	g.test_mode=true
	var settings_button:Button
	for button in g.prologue.root.find_children("*","Button",true,false):
		if button.text=="Accessibility & controls": settings_button=button
	assert(settings_button!=null)
	await _click(settings_button)
	assert(g.page=="settings")
	assert(not g.prologue.root.visible,"Title must not cover settings")
	var voice_slider:HSlider
	for slider in g.content.find_children("*","HSlider",true,false):
		if is_equal_approx(slider.value,float(g.settings.instrument_voice_volume)): voice_slider=slider
	assert(voice_slider!=null,"Instrument voice volume must be reachable before play")
	var return_button:Button
	for button in g.content.find_children("*","Button",true,false):
		if button.text=="Apply & return": return_button=button
	assert(return_button!=null)
	return_button.pressed.emit()
	await process_frame
	assert(g.page=="title" and g.prologue.root.visible)
	print("TITLE SETTINGS PASS: mouse entry, visible voice slider, return to title")
	quit()
