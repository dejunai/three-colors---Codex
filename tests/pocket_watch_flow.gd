extends SceneTree

const Clock = preload("res://scripts/shared/day_clock.gd")

func _initialize() -> void: call_deferred("run")

func _text(g: Node) -> String:
	var result = ""
	for label in g.content.find_children("*", "Label", true, false): result += label.text + "\n"
	return result

func _has_button(g: Node, caption: String) -> bool:
	for button in g.content.find_children("*", "Button", true, false):
		if button.text == caption: return true
	return false

func run() -> void:
	assert(Clock.display_time(360.0) == "6:00 AM")
	assert(Clock.display_time(719.99) == "11:59 AM")
	assert(Clock.display_time(720.0) == "12:00 PM")
	assert(Clock.display_time(1027.5) == "5:07 PM")
	assert(Clock.display_time(1200.0) == "8:00 PM")
	assert(Clock.display_time(1440.0) == "MIDNIGHT")
	assert(Clock.phase_label(720.0) == "Midday")
	assert(Clock.watch_aperture(360.0) == "sun")
	assert(Clock.watch_aperture(1079.99) == "sun")
	assert(Clock.watch_aperture(1080.0) == "moon")
	assert(Clock.watch_aperture(1440.0) == "moon")
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.state = g.CaseState.new()
	g.state.started = true
	g.state.day = 2
	g.state.clock_minutes = 1027.5
	g._case_file()
	assert(_has_button(g, "Check the pocket watch"), "Pocket watch missing from Tab menu")
	assert("pocket watch" in _text(g).to_lower(), "Pocket watch missing from carried items")
	var before = g.state.clock_minutes
	g._pocket_watch()
	var watch_text = _text(g)
	assert("DAY 2" in watch_text and "5:07 PM" in watch_text and "EVENING" in watch_text)
	var face = g.content.find_child("PocketWatchFace", true, false)
	assert(face != null and is_equal_approx(face.minutes, 1027.5) and face.aperture_state == "sun", "Analogue face must reflect the live clock and daylight aperture")
	g.tick_world(600.0)
	assert(g.state.clock_minutes == before, "Reading the watch must pause time")
	g._close()
	g.tick_world(12.0)
	assert(is_equal_approx(g.state.clock_minutes, before + 1.0), "Watch must reflect normal wandering time")
	g._pocket_watch()
	assert("5:08 PM" in _text(g), "Watch did not update after wandering")
	g._close()
	g.state.clock_minutes = 1080.0
	g._pocket_watch()
	face = g.content.find_child("PocketWatchFace", true, false)
	assert(face.aperture_state == "moon", "Moon plate must click in at 6 PM")
	g._close()
	g.state.clock_minutes = 1439.5
	Clock.advance(g.state, 30.0)
	assert(g.state.clock_minutes == Clock.MIDNIGHT)
	g._pocket_watch()
	face = g.content.find_child("PocketWatchFace", true, false)
	assert("MIDNIGHT" in _text(g) and face.aperture_state == "moon")
	print("POCKET WATCH PASS: analogue face, Tab affordance, exact text, 6 AM/6 PM aperture, paused menu, live update, midnight clamp")
	quit()
