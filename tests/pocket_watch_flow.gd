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
	assert(Clock.phase_label(720.0) == "Midday")
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
	g.tick_world(600.0)
	assert(g.state.clock_minutes == before, "Reading the watch must pause time")
	g._close()
	g.tick_world(12.0)
	assert(is_equal_approx(g.state.clock_minutes, before + 1.0), "Watch must reflect normal wandering time")
	g._pocket_watch()
	assert("5:08 PM" in _text(g), "Watch did not update after wandering")
	print("POCKET WATCH PASS: Tab affordance, carried item, day/time/phase display, paused menu, live wandering update")
	quit()
