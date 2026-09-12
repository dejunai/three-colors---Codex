extends RefCounted

# Temporary pacing bridge. Replace the montage with enacted investigation later.
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
	if id in ["odell","assistant"] and g.state.estate_complete:
		return true # Cleared bodies and departed staff cannot be interacted with remotely.
	if id == "crew":
		return g.state.world != "estate" or not g.state.lounge_exited
	match id:
		"service_entrance":
			if g.state.world == "estate" and g.state.visited.has("almy"):
				g._travel("lounge",Vector3(0,0.1,6))
			return true
		"lounge_exit":
			if g.state.world == "lounge":
				g.state.lounge_exited = true
				g._travel("estate",Vector3(-10,0.1,-17),PI)
			return true
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
	if g.state.steward_visits == 0 or not g.state.intake_done or not g.state.evidence.has("naomi"):
		g._panel("case","There’s still work to do.","CORWIN'S ROOM")
		g._paragraph(g._objective(),22)
		g._button("Get up",g._close)
		g._focus_first()
		return
	if g.state.day < 3:
		g.state.day = 2
		g.state.clock_minutes = 360.0
		g.state.montage_index = 0
		g._save_game()
		draw_montage(g)
	elif g.state.steward_visits < 3:
		g._panel("case","The steward is expecting me.","CORWIN'S ROOM")
		g._paragraph("Come back tomorrow, and don't bring your badge.")
		g._button("Get up",g._close)
		g._focus_first()
	else:
		g._cards(g.TownStory.SCENES.close_day,func(): g.state.finished=true; g._save_game(); g._town_complete())

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
