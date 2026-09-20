extends RefCounted

# Archived pacing bridge retained below for reference and possible captures. Live
# progression now enacts Day 2 and no longer calls draw_montage().
const MONTAGE = [
	["THE SECOND DAY", "Doors opened. Chairs were offered. Walter asked his questions.", 0],
	["AT THE MORGUE", "The coroner turned a page. Walter waited with his notebook open.", 1],
	["THE SECOND EVENING", "Through the service entrance again. The steward had little to add.", 2],
	["THE STEWARD", "Come back tomorrow, and don't bring your badge.", 2]
]

func interact(g:Node,id:String) -> bool:
	if id in ["club_talk","club_devotion","pantry_lead"] and (g.state.world != "lounge" or not g.state.steward_ready()): return true
	if id in ["eight","shoes"] and g.state.birch_bodies_removed: return true
	if id in ["wounds","watch","knife"] and g.state.rose_bodies_removed: return true
	if id in ["odell","assistant","report"] and g.state.estate_complete:
		return true # Cleared bodies, departed staff, and filed preliminary report cannot be interacted with remotely.
	if id == "crew":
		return g.state.world != "estate" or not g.state.lounge_exited
	match id:
		"barman": steward(g); return true
		"day_close":
			# Reviewing the notebook at the desk is a reflective beat, not a way to
			# advance the day — that belongs to the bed alone (id "sleep" below).
			# Previously both ids shared sleep()'s logic, so setting the notebook down
			# silently advanced the day exactly like turning in for the night, with no
			# beat implying Walter actually slept.
			if g.state.world == "room":
				g._panel("case","Walter looks over the day's notes once more.","CORWIN'S ROOM")
				g._paragraph(g._objective(),22)
				g._button("Set it down",g._close)
				g._focus_first()
			return true
		"sleep":
			if g.state.world == "room": sleep(g)
			return true
	return false

func steward(g:Node) -> void:
	g.scripted_dialogue.interact(g,"barman")

func sleep(g:Node) -> void:
	if g.state.finished:
		g._town_complete()
		return
	if g.state.steward_visits == 0 or not g.state.intake_done or not g.state.evidence.has("naomi"):
		g._panel("case","There’s still work to do.","CORWIN'S ROOM")
		g._paragraph(g._objective(),22)
		g._button("Get up",g._close)
		g._focus_first()
		return
	if g.state.day < 2:
		g.state.day = 2
		g.state.clock_minutes = 360.0
		g.state.montage_index = -1
		g._save_game()
		g._panel("case","Turn in for the night.","CORWIN'S ROOM")
		g._paragraph("Walter lies down in the dark room above the cobbler's shop, listening to the harbor wind rattle the sash. With eight deaths in his notebook and an unacknowledged woman turning in his head, he isn't likely to get much sleep tonight, if any at all.",22)
		g._button("Get up",func():
			g._close()
			g._toast("The second day. The investigation continues.",6))
		g._focus_first()
	elif g.state.day == 2 and g.state.steward_visits < 2:
		g._panel("case","The steward has not answered me yet today.","CORWIN'S ROOM")
		g._paragraph("Return to the smoking lounge through the service entrance.")
		g._button("Get up",g._close)
		g._focus_first()
	elif g.state.day == 2:
		g.state.day = 3
		g.state.clock_minutes = 360.0
		g.state.montage_index = -1
		g._save_game()
		g._panel("case","Turn in for the night.","CORWIN'S ROOM")
		g._paragraph("Walter lies back on the narrow mattress and stares at the ceiling plaster until his eyes ache. With tomorrow's appointment at the estate waiting, he isn't likely to get much sleep tonight, if any.",22)
		g._button("Get up",func():
			g._close()
			g._toast("The third day. The steward is expecting you.",6))
		g._focus_first()
	elif g.state.steward_visits < 3:
		g._panel("case","The steward is expecting me.","CORWIN'S ROOM")
		g._paragraph("Come back tomorrow, and don't bring your badge.")
		g._button("Get up",g._close)
		g._focus_first()
	elif not g.state.dialogue_state.flag("glass_broken"):
		# The slice no longer ends at the bed. It ends at the glass (chapter_one_break.gd),
		# reached through the steward's pantry door. Sleeping is refused, in the same
		# placeholder register as the earlier "still work to do" gate, until then.
		g._panel("case","There’s still work to do.","CORWIN'S ROOM")
		g._paragraph(g._objective(),22)
		g._button("Get up",g._close)
		g._focus_first()
	else:
		g.playthrough_log.day3_bed_reached()
		g._cards(g.TownStory.SCENES.close_day,func(): _debrief_town_feel(g))

# Public entry for the slice's final beat: the two optional tester questions, then
# the ending. Kept here so the questions and the telemetry event stay in one place.
func debrief(g:Node) -> void:
	_debrief_town_feel(g)

# Optional, two-question tester debrief shown once, right after the Day 3
# close_day cards and before the town is marked finished. Answers are
# recorded through playthrough_log.debrief() alongside the anonymous
# session id — no free text, single-tap choices only, "Skip" always
# available. See docs/LOG_PLAYER_ASK.md.
func _debrief_town_feel(g:Node) -> void:
	g._panel("case","Before this closes, one thought lingers.","A QUIET MOMENT")
	g._paragraph("Did the town feel—")
	var choose = func(answer:String): _debrief_time_natural(g,answer)
	g._button("Alive, and hard to fully take in",choose.bind("alive"))
	g._button("Confusing",choose.bind("confusing"))
	g._button("Too large for the time given",choose.bind("too_large"))
	g._button("Easy enough to navigate",choose.bind("easy"))
	g._button("Skip",choose.bind("skipped"))
	g._focus_first()

func _debrief_time_natural(g:Node,town_feel:String) -> void:
	g._panel("case","One more thought.","A QUIET MOMENT")
	g._paragraph("Did the passage of time feel natural while investigating?")
	var finish = func(answer:String):
		g.playthrough_log.debrief(town_feel,answer)
		g.state.finished=true
		g._save_game()
		g._town_complete()
	g._button("Yes",finish.bind("yes"))
	g._button("No",finish.bind("no"))
	g._button("Skip",finish.bind("skipped"))
	g._focus_first()

# Archived and intentionally unwired. Keeping this renderer preserves the stills,
# intertitles and old save/capture reference without putting them in live play.
func draw_montage(g:Node) -> void:
	var index = g.state.montage_index
	if index < 0 or index >= MONTAGE.size(): return
	var card = MONTAGE[index]
	g._panel("montage",card[0],"NO EXIT WOUND / DAY TWO")
	var still = preload("res://scripts/chapters/montage_still.gd").new()
	still.scene_index = card[2]
	still.custom_minimum_size = Vector2(0,210)
	still.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	still.mouse_filter = Control.MOUSE_FILTER_IGNORE
	g.content.add_child(still)
	g._paragraph(card[1],26)
	g._button("Continue",func():
		if g.state.montage_index != index: return
		if index + 1 < MONTAGE.size():
			g.state.montage_index += 1
			g._save_game()
			draw_montage(g)
		else:
			g.state.montage_index = -1
			g.state.steward_visits = 2
			g.state.dialogue_state.visit_counts["steward"] = 2
			g.state.day = 3
			g.state.clock_minutes = 360.0
			g._save_game()
			g._close()
			g._toast("The third day. The steward is expecting you.",6))
	g._focus_first()
