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
	if settings_button==null:
		push_error("Accessibility & controls button not found")
		quit(1)
		return
	settings_button.pressed.emit()
	await process_frame
	if g.page != "settings":
		push_error("Expected page to be settings, got " + str(g.page))
		quit(1)
		return
	if g.prologue.root.visible:
		push_error("Title must not cover settings")
		quit(1)
		return
	var voice_slider:HSlider
	for slider in g.content.find_children("*","HSlider",true,false):
		if is_equal_approx(slider.value,float(g.settings.instrument_voice_volume)): voice_slider=slider
	if voice_slider == null:
		push_error("Instrument voice volume must be reachable before play")
		quit(1)
		return
	var return_button:Button
	for button in g.content.find_children("*","Button",true,false):
		if button.text=="Apply & return": return_button=button
	if return_button == null:
		push_error("Apply & return button not found")
		quit(1)
		return
	return_button.pressed.emit()
	await process_frame
	if not (g.page=="title" and g.prologue.root.visible):
		push_error("Expected return to title with visible prologue")
		quit(1)
		return
	print("TITLE SETTINGS PASS: mouse entry, visible voice slider, return to title")
	quit()
