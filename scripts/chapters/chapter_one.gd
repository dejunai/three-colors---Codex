extends Node3D

const CaseState = preload("res://case_state.gd")
const Story = preload("res://story.gd")
const Estate = preload("res://estate.gd")
const Town = preload("res://town.gd")
const TownStory = preload("res://town_story.gd")
const Tunnel = preload("res://tunnel.gd")
const TunnelStory = preload("res://tunnel_story.gd")
const INK = Color("111615")
const PAPER = Color("d6d2bd")
const MUTED = Color("a6aa9b")

var interface: CanvasLayer
var presentation: CanvasLayer
var archive=preload("res://scripts/chapters/chapter_one_archive.gd").new()
var rig: Node3D
var state = CaseState.new()
var estate: Node3D
var player: CharacterBody3D:
	get: return rig.player
var model: Node3D:
	get: return rig.model
var camera: Camera3D:
	get: return rig.camera
var film: ShaderMaterial:
	get: return presentation.material if presentation else null
var ui: Control:
	get: return interface.ui
var modal: Control:
	get: return interface.modal
var content: VBoxContainer:
	get: return interface.content
var prompt: Label:
	get: return interface.prompt
var location_label: Label:
	get: return interface.location_label
var toast_label: Label:
	get: return interface.toast_label
var marker: MeshInstance3D
var yaw: float:
	get: return rig.yaw
	set(value): rig.yaw=value
var pitch: float:
	get: return rig.pitch
	set(value): rig.pitch=value
var distance: float:
	get: return rig.distance
	set(value): rig.distance=value
var aperture: float:
	get: return presentation.aperture
	set(value): presentation.aperture=value
var aperture_target: float:
	get: return presentation.aperture_target
	set(value): presentation.aperture_target=value
var focused = ""
var page = "title"
var dialogue=preload("res://scripts/shared/dialogue_sequence.gd").new()
var toast_time = 0.0
var location_time = 0.0
var autosave_time = 0.0
var comfort_time: float = 0.0
var last_region = ""
var return_page = "title"
var settings_schema=preload("res://scripts/shared/accessibility_settings.gd").new()
var save_store=preload("res://scripts/shared/save_store.gd").new()
var settings = settings_schema.DEFAULTS.duplicate(true)
var test_mode = false
var capture_mode = ""
var serif: SystemFont:
	get: return interface.serif
var sans: SystemFont:
	get: return interface.sans
var facts = {}
var movement_bounds: Rect2:
	get: return rig.movement_bounds
	set(value): rig.movement_bounds=value
var resume_after_dialogue = false
var tunnel_checkpoint: Dictionary = {}
var tunnel_dead = false
var hazard_caption: Label:
	get: return interface.hazard_caption
var cough_player: AudioStreamPlayer
var last_hazard_phase = ""

func start(player_rig:Node3D) -> void:
	rig=player_rig
	test_mode = OS.get_cmdline_user_args().has("--qa") or OS.get_cmdline_user_args().has("--qa-town") or OS.get_cmdline_user_args().has("--qa-loop") or OS.get_cmdline_user_args().has("--qa-phase2")
	facts = Story.FACTS.duplicate(true)
	facts.merge(TownStory.FACTS)
	facts.merge(TunnelStory.FACTS)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_mode = arg.trim_prefix("--capture=")
	_load_settings()
	estate = Estate.new()
	estate.name = "OphionEstate"
	add_child(estate)
	_build_player()
	_build_ui()
	_title()
	if OS.get_cmdline_user_args().has("--qa"): call_deferred("_qa")
	if OS.get_cmdline_user_args().has("--qa-town"): call_deferred("_qa_town")
	if OS.get_cmdline_user_args().has("--qa-loop"): call_deferred("_qa_loop")
	if OS.get_cmdline_user_args().has("--qa-phase2"): call_deferred("_qa_phase2")
	if not capture_mode.is_empty(): call_deferred("_capture")



func _build_player() -> void:
	var avatar=estate.person(Vector3.ZERO,"424b43")
	var badge=estate.box(avatar,Vector3(-0.16,1.48,-0.18),Vector3(0.07,0.10,0.025),"c3c4b3")
	badge.name="Badge"
	rig.build_player(avatar,state.position)
	marker = MeshInstance3D.new()
	var mesh = TorusMesh.new()
	mesh.inner_radius=0.11
	mesh.outer_radius=0.15
	marker.mesh=mesh
	var material=StandardMaterial3D.new()
	material.albedo_color=PAPER
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override=material
	marker.visible=false
	add_child(marker)

func _build_ui() -> void:
	interface=preload("res://scripts/shared/chapter_interface.gd").new()
	interface.settings=settings
	add_child(interface)
	presentation=preload("res://scripts/shared/film_presentation.gd").new()
	presentation.shader=preload("res://film.gdshader")
	add_child(presentation)
	_build_cough()
	_apply_settings()

func _label(text:String,size:int=24,literary:bool=true) -> Label:
	return interface._label(text,size,literary)

func _style(bg:Color,border:Color=Color("626d5b")) -> StyleBoxFlat:
	return interface._style(bg,border)

func _button(text:String,callback:Callable,parent:Node=null) -> Button:
	return interface._button(text,callback,parent)

func _panel(kind:String,heading:String,kicker:String="",wide:bool=false) -> void:
	page=kind
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	marker.visible=false
	interface._panel(kind,heading,kicker,wide)

func _paragraph(text:String,size:int=23) -> void:
	interface._paragraph(text,size)

func _focus_first() -> void:
	interface._focus_first()

func _close() -> void:
	interface.close()
	page="play"
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func _title() -> void:
	_panel("title","No Exit Wound","THREE COLORS OF MADNESS  /  CHAPTER ONE")
	_paragraph("Widow's Bight, 1923",24)
	_paragraph("Eight people are dead at the Ophion estate.\nThe town is prepared to account for six.",28)
	_paragraph("The estate, Pickman Street, and the service passage\nThird-person 3D prototype",16)
	if not _available_save_path().is_empty(): _button("Continue investigation",_load_game)
	_button("Begin at the estate",_new_game)
	_button("Accessibility & controls",func(): return_page="title"; _settings())
	_button("Quit",func(): get_tree().quit())
	_focus_first()

func _new_game() -> void:
	tunnel_checkpoint.clear()
	tunnel_dead = false
	comfort_time = 0
	state = CaseState.new()
	if not estate is Estate or estate.get_script() != Estate: _travel("estate",state.position,0,false)
	player.position = state.position
	yaw = 0
	_refresh_outfit()
	aperture = 0.51
	aperture_target = 0.51
	last_region = ""
	_update_camera(1)
	_cards(Story.INTROS,func():
		state.started = true
		_close()
		_toast("WASD move · Mouse look · E examine · Tab case file · Esc pause",10)
		_save_game()
	)

func _cards(cards:Array,after:Callable) -> void:
	dialogue.start(cards,_draw_card,func(): _close(); after.call())

func _draw_card(card:Array,index:int) -> void:
	_panel("dialogue",str(card[0]),"NO EXIT WOUND  /  %02d" % (index+1))
	_paragraph(str(card[1]),27)
	var space = Control.new()
	space.custom_minimum_size.y = 30
	content.add_child(space)
	_button("Continue",_next_card)
	for child in content.get_children():
		if child is Label: child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_first()

func _next_card() -> void:
	dialogue.next()

func tick_world(delta:float) -> void:
	state.minutes += delta/60
	_find_focus()
	if state.world == "tunnel":
		estate.reveal(state.perception())
		if estate.advance(delta,player.position):
			_show_tunnel_death()
			return
	if state.world == "estate" and player.position.z < 6:
		aperture_target = 1.2
		if not state.visited.has("garden"):
			state.visited.append("garden")
			_save_game()
	var region = _region_name()
	if region != last_region:
		last_region = region
		location_label.text = region+"\n—  "+("BEFORE DAWN" if state.world == "estate" else ("THE SERVICE PASSAGE" if state.world=="tunnel" else "PICKMAN STREET"))+"  —"
		location_time = 4
	autosave_time += delta
	if autosave_time > 20:
		autosave_time = 0
		_save_game()

func _process(delta:float) -> void:
	if page == "play": comfort_time = maxf(0,comfort_time-delta)
	var unease = minf(1.0,float(state.evidence.size())/12.0)
	hazard_caption.visible = state.world == "tunnel" and page == "play"
	if state.world == "tunnel" and estate is Tunnel:
		unease = maxf(unease,clampf((6.0-player.position.z)/30.0,0,1))
		estate.presentation(unease,comfort_time > 0)
		hazard_caption.text = estate.cue()
		var current_phase = estate.phase()
		if page == "play" and current_phase == "warning" and last_hazard_phase != current_phase:
			cough_player.play()
		last_hazard_phase = current_phase
	if is_instance_valid(cough_player): cough_player.stream_paused = page != "play"
	presentation.advance(delta,unease,comfort_time > 0,settings)
	toast_time = maxf(0,toast_time-delta)
	toast_label.modulate.a = minf(1,toast_time)
	location_time = maxf(0,location_time-delta)
	location_label.modulate.a = minf(1,location_time)

func _update_camera(delta:float) -> void:
	rig._update_camera(delta)

func handle_input(event:InputEvent) -> void:
	if page == "play":
		if event.is_action_pressed("use") and not focused.is_empty(): _interact(focused)
		elif event.is_action_pressed("case"): _case_file()
		elif event.is_action_pressed("journal"): _journal()
		elif event.is_action_pressed("pause_game"): _pause()
	elif event.is_action_pressed("pause_game"):
		if page == "dialogue": return
		if page == "settings":
			if return_page == "title": _title()
			else: _pause()
		elif page in ["case","journal","pause","report","fact","witness","board"]: _close()
	elif event.is_action_pressed("case") and page in ["case","journal","fact"]: _close()

func _find_focus() -> void:
	focused = ""
	var best = 3.0
	for id in estate.points:
		if id == "report" and not state.visited.has("odell"): continue
		if id == "exit" and state.report.is_empty(): continue
		var p:Vector3 = estate.points[id].pos
		var d = Vector2(p.x-player.position.x,p.z-player.position.z).length()
		if d < best:
			var origin = player.position+Vector3.UP*1.1
			var query = PhysicsRayQueryParameters3D.create(origin,p+Vector3.UP*1.1,1)
			if get_world_3d().direct_space_state.intersect_ray(query).is_empty():
				best=d
				focused=id
	prompt.text = "" if focused.is_empty() else "[ E ]  "+str(estate.points[focused].title)
	marker.visible = not focused.is_empty() and bool(settings.hints)
	if marker.visible: marker.position = estate.points[focused].pos+Vector3(0,0.06,0)

func _interact(id:String) -> void:
	if _tunnel_interaction(id): return
	if _town_interaction(id): return
	if id == "report":
		_report_screen()
		return
	if id == "exit":
		if state.report.is_empty(): return
		_finish()
		return
	if id == "barman":
		if state.visited.has("barman"):
			_barman_menu()
		else:
			var intro = "barman_plain" if state.coat == "Plain wool coat" else "barman_badge"
			_cards(Story.SCENES[intro],func():
				state.visited.append("barman")
				_save_game()
				_barman_menu())
		return
	var key = "gardener_plain" if id == "gardener" and state.coat == "Plain wool coat" else id
	if not Story.SCENES.has(key): return
	_cards(Story.SCENES[key],func():
		if not state.visited.has(id): state.visited.append(id)
		if Story.FACTS.has(id): state.discover(id)
		if id == "assistant":
			state.discover("testimony")
			state.discover("eight")
		if key == "gardener_plain": state.record("The gardener saw the woman at the service door. Ask the steward.")
		elif id == "gardener": state.record("The gardener requested eight sheets. Six arrived first.")
		if id == "odell":
			state.discover("eight")
			_save_game()
			_odell_response()
		else:
			_save_game()
			_toast("Recorded in Walter's case file.  [ Tab ]",4)
	)

func _odell_response() -> void:
	var spoken="Walter told Odell to his face that six was not the whole count. Odell did not answer."
	var silent="Walter wrote EIGHT in his own file, in a hand larger than his usual notation, and said nothing further to the captain."
	# Existing saves already encode the answer in the permanent statement record.
	if state.statements.has(spoken) or state.statements.has(silent):
		_panel("witness","Already answered","THE TERRACE / WALTER'S NOTEBOOK")
		_paragraph("Walter's answer is already in his notebook. Odell has nothing further to add.")
		_button("Leave the captain",_close)
		_focus_first()
		return
	_panel("witness","A filing matter","THE TERRACE  /  WALTER'S ANSWER")
	_paragraph("Odell has already turned back toward the sheeted tables. Walter can let the matter rest here, or say what he actually thinks before it does.",22)
	_button("\"I understand it. I don't accept it.\"",func():
		state.record("Walter told Odell to his face that six was not the whole count. Odell did not answer.")
		_save_game()
		_close()
		_toast("Recorded in Walter's case file.  [ Tab ]",4))
	_button("Say nothing. Write it down instead.",func():
		state.record("Walter wrote EIGHT in his own file, in a hand larger than his usual notation, and said nothing further to the captain.")
		_save_game()
		_close()
		_toast("Recorded in Walter's case file.  [ Tab ]",4))
	_focus_first()

func _barman_menu() -> void:
	_panel("witness","The club's barman","THE PORTICO  /  ASK, LISTEN, RECORD")
	_paragraph("He keeps his voice low and his eyes on the glasses he's drying. He has already decided how much of this he's willing to say.",22)
	_button("Ask what the members used to talk about"+("  · recorded" if state.evidence.has("club_talk") else ""),func(): _estate_observation("club_talk",true))
	if state.evidence.has("club_talk"):
		_button("Ask what Kessler used to say"+("  · recorded" if state.evidence.has("club_devotion") else ""),func(): _estate_observation("club_devotion",true))
	if state.evidence.has("club_devotion"):
		_button("Ask about the old pantry door"+("  · recorded" if state.evidence.has("pantry_lead") else ""),func(): _estate_observation("pantry_lead",true))
	_button("Leave him to his glasses",_close)
	_focus_first()

func _estate_observation(id:String,return_to_barman:bool=false) -> void:
	_cards(Story.SCENES[id],func():
		state.discover(id)
		if estate and estate.has_method("sync_actors"): estate.sync_actors(state)
		if not state.inquiry_topics.has(id): state.inquiry_topics.append(id)
		_save_game()
		if return_to_barman: _barman_menu()
		else: _close(); _toast("Recorded in Walter's case file.  [ Tab ]",4)
	)

func _objective() -> String:
	if state.world == "tunnel":
		return "Return to the service stair with the measurements." if state.evidence.has("lower_foundation") else "Compare the lower support with the service plan. The outer service walk remains open."
	if state.estate_complete or state.world != "estate":
		if not state.intake_done: return "Submit your estate report at the precinct intake counter on Pickman Street."
		if not state.evidence.has("naomi"): return "Speak to Mrs. Almy at her boardinghouse on Pickman Street. Ask who the woman was."
		if state.finished: return "The first town inquiry is recorded. You can revisit witnesses, file a supplement, or review Walter's board."
		return "Continue questioning Mrs. Almy or file a dated supplement at the precinct. Set the notebook on your desk above the cobbler's when ready to end the day."
	if not state.visited.has("garden") and not state.visited.has("odell"): return "Follow the drive to the rose garden. The gatehouse boy can direct you."
	if not state.visited.has("odell"): return "Examine the grounds and consult Captain Odell on the terrace, beyond the fountain."
	if state.report.is_empty(): return "Write your preliminary report at the field desk beside the captain. You may continue examining first."
	return "Return down the drive to the estate gates, or continue examining the grounds before leaving."

func _case_file() -> void:
	archive._case_file(self)

func _flask() -> void:
	archive._flask(self)

func _journal() -> void:
	archive._journal(self)

func _fact(id:String) -> void:
	archive._fact(self,id)

func _report_screen() -> void:
	archive._report_screen(self)

func _write_report(mode:String,scene:String) -> void:
	state.complete_report(mode,_current_sources())
	_save_game()
	_cards(Story.SCENES[scene],func(): _close(); _toast("Report prepared. Return to the estate gates when ready.",6))

func _finish() -> void:
	state.estate_complete = true
	_save_game()
	_cards(TownStory.ARRIVAL,func(): _travel("town",Vector3(0,0.1,17)))

func _pause() -> void:
	_save_game()
	_panel("pause","An unfinished case","PAUSED")
	_paragraph(_objective(),24)
	_button("Return to the grounds",_close)
	_button("Case file",_journal)
	_button("Accessibility & controls",func(): return_page="pause"; _settings())
	_button("Save and return to title",_title)
	_button("Save and quit",func(): _save_game(); get_tree().quit())
	_focus_first()

func _settings() -> void:
	_panel("settings","Accessibility & controls","AVAILABLE BEFORE PLAY",true)
	_paragraph("WASD / arrows: move · Mouse: look · Q / R: orbit camera\nWheel: camera distance · Shift: walk briskly · E / F: interact\nTab / I: personal effects · J: case file · Esc: pause · F11: fullscreen\nMenus: Tab to focus · Enter / Space to select · Mouse also supported",18)
	_paragraph("Clue text and intertitles remain outside all film effects.\nThe service passage uses a provisional cough cue with a protected caption. No spoken dialogue is omitted.",18)
	for item in [["distortion","Distortion intensity",0.0,1.0,0.05],["grain","Film grain",0.0,0.06,0.005],["contrast","Scene contrast",0.8,1.4,0.05],["text_scale","Text size",0.9,1.3,0.1],["sensitivity","Mouse sensitivity",0.001,0.006,0.0005]]:
		var key:String = item[0]
		var row = HBoxContainer.new()
		content.add_child(row)
		var label = _label(str(item[1]),18,false)
		label.custom_minimum_size.x = 270
		row.add_child(label)
		var slider = HSlider.new()
		slider.min_value=item[2]
		slider.max_value=item[3]
		slider.step=item[4]
		slider.value=settings[key]
		slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(slider)
		slider.value_changed.connect(func(value): settings[key]=value; _apply_settings(); _save_settings())
	for item in [["reduced_flicker","Reduce flicker (static grain)"],["hints","Show nearby interaction marker"],["invert_y","Invert vertical mouse look"]]:
		var key:String=item[0]
		var toggle=CheckButton.new()
		toggle.text=item[1]
		toggle.button_pressed=settings[key]
		toggle.add_theme_font_size_override("font_size",18)
		content.add_child(toggle)
		toggle.toggled.connect(func(value): settings[key]=value; _apply_settings(); _save_settings())
	_button("Apply & return",func():
		if return_page == "title": _title()
		else: _pause())
	_focus_first()

func _apply_settings() -> void:
	if presentation: presentation.apply_settings(settings)
	if interface: interface.apply_settings()

func _save_path() -> String:
	return "user://opening_qa.json" if test_mode else "user://opening_save.json"

func _available_save_path() -> String:
	# The original editor run and the portable launcher may use different APPDATA roots.
	# Read the newer candidate; write only to the active user directory. Never alter the source save.
	var candidates=[ProjectSettings.globalize_path(_save_path())]
	if not test_mode and capture_mode.is_empty():
		var folder="Godot/app_userdata/"+str(ProjectSettings.get_setting("application/config/name"))+"/opening_save.json"
		candidates.append(OS.get_environment("USERPROFILE").path_join("AppData/Roaming").path_join(folder))
		candidates.append(ProjectSettings.globalize_path("res://.runtime-data").path_join(folder))
	return save_store.newest(candidates)

func _save_game() -> bool:
	if not state.started or not capture_mode.is_empty(): return false
	var d = _session_snapshot()
	d["tunnel_checkpoint"] = tunnel_checkpoint.duplicate(true)
	d["tunnel_dead"] = tunnel_dead
	if save_store.write(_save_path(),d)!=OK:
		_toast("Save could not be completed. Your session remains playable.",5)
		return false
	return true

func _load_game() -> void:
	var d=save_store.read(_available_save_path())
	if d.is_empty() or not state.restore(d): _toast("The save could not be read. Begin a new investigation.",5); return
	tunnel_checkpoint=_normalize_snapshot(d.get("tunnel_checkpoint",{}))
	_restore_session(d)
	tunnel_dead=bool(d.get("tunnel_dead",false))
	if tunnel_dead: _show_tunnel_death(false)
	elif state.finished and state.world != "tunnel": _town_complete()
	else: _close()

func _save_settings() -> void:
	if test_mode or not capture_mode.is_empty(): return
	save_store.write("user://accessibility_settings.json",settings_schema.encode(settings))

func _load_settings() -> void:
	if test_mode: return
	var payload=save_store.read("user://accessibility_settings.json")
	if payload.is_empty(): payload=save_store.read("user://opening_settings.json")
	settings=settings_schema.decode(payload)

func _toast(text:String,duration:float = 4) -> void:
	toast_label.text=text
	toast_time=duration

func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and page == "play" and not test_mode and capture_mode.is_empty(): _pause()

func _capture() -> void:
	await load("res://tests/capture_views.gd").new().run(self)

func _qa() -> void:
	await load("res://tests/opening_flow.gd").new().run(self)

func _walk_to(destination:Vector3) -> void:
	await load("res://tests/walk_driver.gd").new().walk_to(self,destination)

func _travel(destination:String,spawn:Vector3,view_yaw:float=0.0,save:bool=true) -> void:
	if is_instance_valid(estate):
		remove_child(estate)
		estate.queue_free()
	if destination == "estate": estate=Estate.new()
	elif destination == "tunnel": estate=Tunnel.new()
	else:
		estate=Town.new()
		estate.location=destination
	add_child(estate)
	if estate and estate.has_method("sync_actors"):
		estate.sync_actors(state)
	elif destination=="town" and state.evidence.has("old_woman") and estate.has_method("dismiss_old_woman"):
		estate.dismiss_old_woman()
	if destination == "tunnel":
		estate.reveal(state.perception())
		last_hazard_phase = ""
	else:
		cough_player.stop()
	state.world=destination
	player.position=spawn
	player.velocity=Vector3.ZERO
	yaw=view_yaw
	pitch=0.38 if destination in ["estate","town"] else 0.48
	distance=6.3 if destination in ["estate","town"] else 4.8
	movement_bounds=Rect2(-31,-18.4,62,60.4) if destination=="estate" else (Rect2(-29,-6,58,28) if destination=="town" else Rect2(-8.45,-7.4,16.9,15.1))
	if destination == "tunnel":
		movement_bounds=Rect2(-8.6,-33,14.2,42)
		distance=5.3
		pitch=0.58
	if destination != "estate":
		aperture=1.2
		aperture_target=1.2
	last_region=""
	focused=""
	if destination=="room": estate.update_board(state.evidence)
	_update_camera(1)
	_close()
	if save: _save_game()

func _region_name() -> String:
	match state.world:
		"tunnel": return "BENEATH THE KITCHEN WING"
		"town": return "WIDOW'S BIGHT"
		"precinct": return "PRECINCT 4"
		"boardinghouse": return "MRS. ALMY'S PARLOR"
		"room": return "CORWIN'S ROOM"
	if player.position.x > 18: return "THE BIRCH GROVE"
	if player.position.x < -10 and player.position.z < -14: return "THE KITCHEN WING YARD"
	return "THE TERRACE" if player.position.z < -10 else ("THE ROSE GARDEN" if player.position.z < 6 else "THE OPHION ESTATE")

func _town_interaction(id:String) -> bool:
	match id:
		"street_precinct": _travel("precinct",Vector3(0,0.1,6)); return true
		"street_almy": _travel("boardinghouse",Vector3(0,0.1,6)); return true
		"street_room": _travel("room",Vector3(0,0.1,6)); return true
		"street_estate": _travel("estate",Vector3(0,0.1,35)); return true
		"interior_exit":
			var exits={"precinct":Vector3(-18,0.1,-4.5),"boardinghouse":Vector3(-1,0.1,-4.5),"room":Vector3(18,0.1,-4.5)}
			_travel("town",exits.get(state.world,Vector3(0,0.1,17)),PI)
			return true
		"intake": _intake(); return true
		"supplement": _supplement(); return true
		"survey_drawer": _survey_drawer(); return true
		"almy":
			if state.visited.has("almy"):
				_witness_menu()
			else:
				var scene="almy_plain" if state.coat=="Plain wool coat" else "almy_badge"
				_cards(TownStory.SCENES[scene],func():
					state.visited.append("almy")
					_save_game()
					_witness_menu())
			return true
		"behan":
			if state.visited.has("behan"):
				_behan_menu()
			else:
				_cards(TownStory.SCENES.behan,func():
					state.visited.append("behan")
					state.record("Father Behan discussed the six men's characters freely and himself not at all.")
					_save_game()
					_behan_menu())
			return true
		"board": _board(); return true
		"day_close":
			if not state.intake_done or not state.evidence.has("naomi"):
				_panel("case","Work still to do","WALTER'S DESK")
				_paragraph(_objective())
				_button("Take the notebook",_close)
				_focus_first()
			else:
				_cards(TownStory.SCENES.close_day,func(): state.finished=true; _save_game(); _town_complete())
			return true
	if TownStory.FACTS.has(id) and TownStory.SCENES.has(id):
		if id=="lodging" and not state.evidence.has("naomi"):
			_panel("case","A private ledger","MRS. ALMY'S PARLOR")
			_paragraph("Ask Mrs. Almy whose entry you are looking for before copying her book.")
			_button("Put it down",_close)
			_focus_first()
		else: _town_observation(id)
		return true
	return false

func _town_observation(id:String,return_target:Variant=null) -> void:
	if id=="old_woman" and state.evidence.has(id): return
	_cards(TownStory.SCENES[id],func():
		state.discover(id)
		if estate and estate.has_method("sync_actors"):
			estate.sync_actors(state)
		elif id=="old_woman" and state.world=="town" and estate.has_method("dismiss_old_woman"):
			estate.dismiss_old_woman()
		if not state.inquiry_topics.has(id): state.inquiry_topics.append(id)
		_save_game()
		if return_target is Callable and return_target.is_valid():
			return_target.call()
		elif return_target is bool and return_target:
			_witness_menu()
		else:
			_close()
			_toast("Source recorded in Walter's notebook.  [ J ]",4))

func _survey_drawer(index_open:bool=false) -> void:
	_panel("case","The survey drawer","PRECINCT 4  /  MUNICIPAL RECORDS")
	if state.evidence.has("municipal_foundation"):
		_paragraph("Walter's transcription remains in the notebook. The sheet stays in the drawer.")
		_button("Read the comparison",func(): _fact("municipal_foundation"))
	elif not state.evidence.has("lower_foundation"):
		_paragraph("Foundation sheets, street surveys, drainage plans. Without a measured discrepancy to compare, Walter has no particular entry to copy.")
	elif state.evidence.has("county_foundation_request") or index_open:
		_paragraph("KITCHEN WING / FOUNDATION\n\nThe municipal sheet stops at the same support as the service plan. Walter lays his measurement beside it. The passage he walked continues beyond the limits on both pages.\n\nNeither drawing says who extended it, or when.",24)
		_button("Copy the reference and comparison into my notebook",func():
			state.discover("municipal_foundation")
			_save_game()
			_close()
			_toast("Municipal source recorded. The sheet stays in the drawer.  [ J ]",5))
	else:
		_paragraph("No reply has named a sheet. Walter can work through the property index himself.\n\nUnder the estate address: drainage, boundaries, kitchen-wing foundation.")
		_button("Follow the kitchen-wing entry",func(): _survey_drawer(true))
	_button("Close the drawer",_close)
	_focus_first()

func _intake() -> void:
	if state.intake_done:
		_panel("case","Received as written","PRECINCT 4  /  INCOMING REPORT")
		_paragraph("%s\n%d observations in the estate report.\n\nThe received copy remains unchanged." % [state.report,state.report_evidence.size()],24)
		if state.county_evidence.size()>0: _paragraph("The first county copy contains %d observations." % state.county_evidence.size(),20)
		if state.tunnel_complete and _county_has_comparison():
			_button("Read the county examiner's foundation request",func():
				state.discover("county_foundation_request")
				_save_game()
				_fact("county_foundation_request"))
		_button("File a dated supplement",_supplement)
		_button("Leave the counter",_close)
		_focus_first()
		return
	var cards=TownStory.SCENES.intake.duplicate(true)
	if state.report_evidence.has("wounds") and state.report_evidence.has("gas"): cards.append_array(TownStory.SCENES.intake_rich)
	elif state.report_evidence.size()<=1: cards.append_array(TownStory.SCENES.intake_thin)
	if state.report=="Full inquest requested": cards.append_array(TownStory.SCENES.intake_county)
	_cards(cards,func():
		state.receive_report()
		state.discover("intake")
		_save_game()
		_close()
		_toast("Report received. Mrs. Almy keeps the boardinghouse on Pickman Street.",6))

func _witness_menu() -> void:
	_panel("witness","Mrs. Almy","PICKMAN STREET  /  ASK, LISTEN, RECORD")
	if state.evidence.has("naomi"): _paragraph("Naomi Freeman.\nThe name is now in the notebook.\nThere is more you could ask.",24)
	else: _paragraph("The room is quiet. Mrs. Almy waits for a question she can answer.",24)
	_button("Ask for the woman's name"+("  · recorded" if state.evidence.has("naomi") else ""),func():
		_cards(TownStory.SCENES.identify,func():
			state.discover("naomi")
			_save_game()
			_witness_menu()))
	if state.evidence.has("naomi"):
		_button("Ask what brought Naomi to town"+("  · recorded" if state.evidence.has("lay_lead") else ""),func(): _town_observation("lay_lead",true))
		_button("Ask about work at the estate"+("  · recorded" if state.evidence.has("service_work") else ""),func(): _town_observation("service_work",true))
		_button("Ask to corroborate the visit in her ledger",func():
			_cards([["MRS. ALMY","On the sideboard.\nCopy the entry, if you need it.\nThe book stays here."]],func(): _close(); _toast("The meal ledger is on the sideboard to your right.",5)))
	if state.coat=="Plain wool coat" and not state.inquiry_topics.has("almy_trust"):
		_button("Ask why the coat made a difference",func():
			_cards([["MRS. ALMY","A uniform asks what belongs in a report.\nA man might still ask what happened.\n\nI haven't decided which you are yet."]],func():
				state.inquiry_topics.append("almy_trust")
				state.record("Mrs. Almy distinguished speaking to a uniform from speaking to a man. The name she supplied was the same.")
				_save_game()
				_witness_menu()))
	_button("Thank her and leave the conversation",_close)
	_focus_first()

func _behan_menu() -> void:
	_panel("witness","Father Behan","PICKMAN STREET  /  BEHIND THE RECTORY")
	_paragraph("He answers plainly, the way a man does who stopped being frightened of the truth a long time before Walter arrived.",22)
	if not state.inquiry_topics.has("behan_invitation"):
		_button("Ask why he declined the club's invitations",func():
			_cards(TownStory.SCENES.behan_invitation,func():
				state.inquiry_topics.append("behan_invitation")
				state.record("Father Behan declined two invitations to the club and would not say why.")
				_save_game()
				_behan_menu()))
	else:
		_button("Ask about the meaning of the club's name"+("  · recorded" if state.evidence.has("behan_name") else ""),func():
			_town_observation("behan_name",_behan_menu))
	_button("Thank him and leave",_close)
	_focus_first()

func _supplement() -> void:
	_panel("report","A later page","PRECINCT 4  /  DATED SUPPLEMENT")
	if not state.intake_done:
		_paragraph("Submit the estate report at the main intake counter first. A supplement must have an original to follow.")
		_button("Return to the room",_close)
	elif not state.evidence.has("naomi"):
		_paragraph("There is no identification to add yet. Mrs. Almy may know the woman. Her boardinghouse is on Pickman Street.")
		_button("Continue the inquiry",_close)
	else:
		_paragraph("Naomi Freeman. Identified by Mrs. Almy.\n\nRecord the source and the additional observations in the notebook. Earlier copies remain as sent.",24)
		if state.supplement_filed: _paragraph("%d earlier supplement(s) retained in the record." % state.supplement_history.size(),18)
		_button("File at the precinct",func(): _file_supplement(false))
		_button("File here and send a county copy",func(): _file_supplement(true))
		_button("Keep these observations in my notebook for now",_close)
	_focus_first()

func _file_supplement(county:bool) -> void:
	state.file_supplement(county,_current_sources())
	_save_game()
	var cards=TownStory.SCENES.supplement.duplicate(true)
	if county: cards.append_array(TownStory.SCENES.county_supplement)
	_cards(cards,func(): _close(); _toast("Dated supplement received. Earlier copies retained.",5))

func _board() -> void:
	archive._board(self)

func _town_complete() -> void:
	archive._town_complete(self)

func _qa_town() -> void:
	await load("res://tests/town_flow.gd").new().run(self)

func _refresh_outfit() -> void:
	model.get_node("Coat").material_override=estate.mat("5f6559" if state.coat=="Plain wool coat" else "424b43")
	if model.has_node("Badge"): model.get_node("Badge").visible=state.coat=="Police coat"

func _source_for(id:String) -> String:
	if id=="eight":
		if state.visited.has("eight"): return "Birch grove · Walter's direct observation"
		if state.visited.has("assistant"): return "Coroner's assistant · reported count"
		return "Captain Odell · reported count and scene locations"
	return str(facts[id][2])

func _current_sources() -> Dictionary:
	var sources={}
	for id in state.evidence:
		if facts.has(id): sources[id]=_source_for(id)
	return sources

func _take_pour() -> bool:
	if state.flask <= 0: return false
	state.flask -= 1
	comfort_time = 90
	_save_game()
	return true

func _begin_tunnel() -> void:
	_cards(TunnelStory.ENTRY,func():
		tunnel_dead=false
		_travel("tunnel",Vector3(0,0.1,7),0,false)
		tunnel_checkpoint=_session_snapshot()
		_save_game()
		_toast("Checkpoint saved at the service stair.",5))

func _tunnel_interaction(id:String) -> bool:
	if state.world != "tunnel": return false
	match id:
		"tunnel_notes":
			_panel("fact","The service plan","KITCHEN WING · MAINTENANCE COPY")
			_paragraph("The marked outer walk runs left of the long dividing wall. It rejoins the passage beyond the figure.\n\nThe last support on this plan should stand against earth. Walter can compare it with the masonry below.")
			_paragraph("A wet cough precedes the figure facing the central passage. When it turns to the wall, the crossing is unwatched. Stone screens the side walks.",21)
			if state.perception() >= 4: _paragraph("Walter picks out pale wear marks behind the shorter right-hand screen. A recessed walk, missed at first glance.",21)
			_button("Fold the plan",_close)
			_focus_first()
		"tunnel_edge":
			state.discover("service_recess")
			_save_game()
			_fact("service_recess")
		"tunnel_record":
			_cards([["THE LAST SUPPORT","The plan ends here. The stonework does not.\nWalter measures the distance twice and records both readings."],["THE PASSAGE CONTINUES","A bend carries the passage beyond the reach of his light.\nHe has a measurement to bring back. He turns toward the service stair."]],func():
				state.discover("lower_foundation")
				state.record("Walter measured a passage beyond the recorded foundation; the service plan is the comparison source.")
				_save_game()
				_toast("Measurement recorded. Return to the service stair.",5))
		"tunnel_descent":
			_tunnel_descent()
		"drowned_remains":
			_drowned_encounter()
		"cultist_encounter":
			_cultist_encounter()
		"tunnel_exit":
			if state.evidence.has("lower_foundation"):
				state.tunnel_complete=true
				_travel("precinct",Vector3(0,0.1,5),0,false)
				_cards([["BACK AT THE PRECINCT",_custody_result()],["A LATER PAGE","The lower-foundation measurement is still in Walter's notebook.\nHe can file it as a dated supplement at the side counter. Earlier copies remain as they were received."]],func(): _save_game())
			else:
				_travel("room",Vector3(0,0.1,5),0,false)
				_save_game()
		_:
			return false
	return true

func _tunnel_descent() -> void:
	if not state.flask_spilled:
		state.flask_spill_amount = state.flask
		state.flask_spilled = true
		state.flask = 0
		_cards(TunnelStory.FLASK_SPILL,func():
			state.discover("flask_spill")
			state.record("A rock spur tore Walter's flask loose on the descent. What remained inside was lost.")
			_save_game()
			_toast("The flask was torn loose and lost in the dark.",5)
		)
	else:
		_panel("descent","The Deep Corridor","BEYOND THE FOUNDATION")
		_paragraph("The worked masonry gives way to rough-hewn stone descending beneath the seabed. Water seeps through the joints.\n\nCold air carries the faint rhythm of the tide miles overhead.",24)
		if state.ammo > 0:
			_paragraph("Revolver: %d rounds in the cylinder." % state.ammo,18)
		_button("Step back to the foundation support",_close)
		_focus_first()

func _cultist_encounter() -> void:
	_panel("combat","The Transformed Cultist","CENTRAL PASSAGE")
	_paragraph("The dinner jacket hangs in ribbons over elongated collar and limbs. A thin, wet cough rattles from a head turned too far around.\n\nIts eyes catch the light with no human expression.",23)
	if estate is Tunnel and estate.cultist_stagger > 0:
		_paragraph("The creature is staggered (%.1f seconds remaining), folded at the waist. Move past it into the side walk." % estate.cultist_stagger,20)
	if state.ammo > 0:
		_button("Fire service revolver center-mass (%d/6 rounds left)" % state.ammo,func():
			state.ammo -= 1
			if estate is Tunnel:
				estate.cultist_stagger = 4.0
				estate.exposure = 0.0
			_save_game()
			_panel("combat","Revolver Shot","STAGGERED ONLY")
			_paragraph("The shot roars in the stone corridor. No exit wound. The creature folds at the middle and staggers backward, groaning.\n\nIt does not fall. No force can destroy it permanently; the shot buys only a few seconds to run.",23)
			_button("Retreat into the side walk",_close)
			_focus_first()
		)
	if state.evidence.has("knife"):
		var stagger_sec = 1.5 + state.strength() * 1.0
		_button("Drive Kessler's boning knife in low",func():
			if estate is Tunnel:
				estate.cultist_stagger = stagger_sec
				estate.exposure = 0.0
			_save_game()
			_panel("combat","Knife Strike","STRENGTH %d" % state.strength())
			_paragraph("Walter drives the heavy knife in low, levering against the reaching arm. The creature staggers, breaking its grip.\n\nStrength buys %.1f seconds of delay. It will rise again." % stagger_sec,23)
			_button("Retreat into the side walk",_close)
			_focus_first()
		)
	_button("Retreat behind the stone wall",_close)
	_focus_first()

func _drowned_encounter() -> void:
	if state.drowned_dead:
		_panel("fact","Waterlogged Remains","DEEP CORRIDOR")
		_paragraph("The drowned sailor lies permanently still. No movement stirs the sodden wool.",22)
		_button("Leave the remains",_close)
		_focus_first()
		return
	_panel("combat","The Drowned Sailor","SUB-BASEMENT CORRIDOR  /  REMAINS")
	_paragraph("Bloated, pale flesh wrapped in sea-worn wool. It shifts against the stone floor with a low, impersonal groan, turning toward Walter.",23)
	if estate is Tunnel and estate.drowned_stagger > 0:
		_paragraph("The sailor is staggered (%.1f seconds remaining). An opening is available." % estate.drowned_stagger,20)
		_button("Deliver desperate finishing blow",func():
			state.drowned_dead = true
			state.discover("drowned_remains")
			state.record("A drowned sailor put down permanently by a brutal finishing blow. Different rules from the other thing.")
			if estate is Tunnel:
				estate.drowned_sailor.rotation.x = PI * 0.5
				estate.drowned_sailor.position.y = 0.15
				estate.points.erase("drowned_remains")
			_save_game()
			_cards([["FINISHING BLOW","Walter puts his boot into the sailor's skull as it reaches for his ankle. Something gives, definitively.\n\nThe sailor goes completely still. Unlike the cultists, this body carries no curse; brutal force ends it permanently."]],_close)
		)
	if state.ammo > 0:
		_button("Fire service revolver (%d/6 rounds left)" % state.ammo,func():
			state.ammo -= 1
			if estate is Tunnel: estate.drowned_stagger = 4.0
			_save_game()
			_panel("combat","Revolver shot","CENTER MASS")
			_paragraph("The revolver cracks in the close corridor. Center mass. No exit wound.\n\nThe drowned sailor staggers backward into the stone, folded at the waist.",23)
			_button("Deliver desperate finishing blow",func():
				state.drowned_dead = true
				state.discover("drowned_remains")
				state.record("A drowned sailor put down permanently by a brutal finishing blow. Different rules from the other thing.")
				if estate is Tunnel:
					estate.drowned_sailor.rotation.x = PI * 0.5
					estate.drowned_sailor.position.y = 0.15
					estate.points.erase("drowned_remains")
				_save_game()
				_cards([["FINISHING BLOW","Walter puts his boot into the sailor's skull as it reaches for his ankle. Something gives, definitively.\n\nThe sailor goes completely still. Unlike the cultists, this body carries no curse; brutal force ends it permanently."]],_close)
			)
			_button("Step back into cover",_close)
			_focus_first()
		)
	if state.evidence.has("knife"):
		var stagger_duration = 2.0 + state.strength() * 1.5
		_button("Strike with Kessler's boning knife",func():
			if estate is Tunnel: estate.drowned_stagger = stagger_duration
			_save_game()
			_panel("combat","Knife strike","STRENGTH %d" % state.strength())
			_paragraph("Walter drives Kessler's knife in low. The force in his arms and back buys %.1f seconds of the sailor simply not breathing again." % stagger_duration,23)
			_button("Deliver desperate finishing blow",func():
				state.drowned_dead = true
				state.discover("drowned_remains")
				state.record("A drowned sailor put down permanently by a brutal finishing blow. Different rules from the other thing.")
				if estate is Tunnel:
					estate.drowned_sailor.rotation.x = PI * 0.5
					estate.drowned_sailor.position.y = 0.15
					estate.points.erase("drowned_remains")
				_save_game()
				_cards([["FINISHING BLOW","Walter puts his boot into the sailor's skull as it reaches for his ankle. Something gives, definitively.\n\nThe sailor goes completely still. Unlike the cultists, this body carries no curse; brutal force ends it permanently."]],_close)
			)
			_button("Step back into cover",_close)
			_focus_first()
		)
	_button("Retreat behind the stone wall",_close)
	_focus_first()

func _custody_result() -> String:
	var source = state.county_evidence
	var provenance = "The county's original copy"
	for item in state.supplement_history:
		if item.get("county",false):
			source = item.get("evidence",[])
			provenance = "The county's dated supplement"
	if not state.county_dispatched:
		return "No county copy was sent. The clerk has no outside acknowledgement to attach.\nWalter's notebook still carries the observations. He can send a dated supplement now."
	if source.has("wounds") and source.has("gas"):
		return provenance+" records the wounds and intact windows together. The reply asks for the service plan rather than another accident form.\nThe intake clerk holds the examiner's request, with a survey-drawer reference Walter can add to the case."
	return provenance+" records only what Walter had established when it left. The reply requests further observations before examining the proposed accident.\nThe measurements in his notebook have not reached that reader yet."

func _county_has_comparison() -> bool:
	if not state.county_dispatched: return false
	if state.county_evidence.has("wounds") and state.county_evidence.has("gas"): return true
	for item in state.supplement_history:
		if item.get("county",false) and item.get("evidence",[]).has("wounds") and item.get("evidence",[]).has("gas"): return true
	return false

func _session_snapshot() -> Dictionary:
	state.position=player.position
	state.yaw=yaw
	var d=state.pack().duplicate(true)
	d["comfort_time"]=comfort_time
	d["pitch"]=pitch
	d["distance"]=distance
	d["aperture"]=aperture
	d["aperture_target"]=aperture_target
	if state.world=="tunnel" and estate is Tunnel:
		d["hazard_clock"]=estate.clock
		d["hazard_exposure"]=estate.exposure
	return d

func _restore_session(d:Dictionary) -> bool:
	var restored=CaseState.new()
	if not restored.restore(d): return false
	state=restored
	_travel(state.world,state.position,state.yaw,false)
	pitch=float(d.get("pitch",0.38))
	distance=float(d.get("distance",6.3))
	comfort_time=float(d.get("comfort_time",0))
	aperture=float(d.get("aperture",1.2 if state.visited.has("garden") else 0.51))
	aperture_target=float(d.get("aperture_target",aperture))
	if state.world=="tunnel":
		estate.clock=float(d.get("hazard_clock",0))
		estate.exposure=float(d.get("hazard_exposure",0))
		estate.pose()
		last_hazard_phase=estate.phase()
	_refresh_outfit()
	_update_camera(1)
	return true

func _show_tunnel_death(save:bool=true) -> void:
	tunnel_dead=true
	player.velocity=Vector3.ZERO
	_panel("death","Walter died in the passage","RELOAD THE SERVICE-STAIR CHECKPOINT")
	_paragraph("The figure crossed the open floor before he reached cover.")
	_paragraph("Reload restores the investigation, flask, and passage to the checkpoint. Anything learned since remains yours to use.",21)
	_button("Reload checkpoint",_retry_tunnel)
	_button("Return to title",_title)
	_focus_first()
	if save: _save_game()

func _retry_tunnel() -> void:
	if tunnel_checkpoint.is_empty():
		_toast("The checkpoint could not be read. Continue from your saved investigation.",5)
		_title()
		return
	tunnel_dead=false
	_restore_session(tunnel_checkpoint.duplicate(true))
	_close()
	_save_game()

func _build_cough() -> void:
	cough_player=AudioStreamPlayer.new()
	add_child(cough_player)
	# Provisional dry breath/cough texture. The protected caption carries the full cue.
	var stream=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	var bytes=PackedByteArray()
	bytes.resize(11025*2)
	var noise=RandomNumberGenerator.new()
	noise.seed=1923
	var filtered=0.0
	for i in 11025:
		var t=float(i)/22050.0
		filtered=lerpf(filtered,noise.randf_range(-1,1),0.35)
		var envelope=exp(-pow((t-0.10)/0.035,2))+0.65*exp(-pow((t-0.24)/0.06,2))
		bytes.encode_s16(i*2,int(filtered*envelope*11000))
	stream.data=bytes
	cough_player.stream=stream
	cough_player.volume_db=-12

func _qa_loop() -> void:
	await load("res://tests/interaction_loop.gd").new().run(self)

func _qa_phase2() -> void:
	await load("res://tests/phase_two_mechanics.gd").new().run(self)

func _normalize_snapshot(value:Variant) -> Dictionary:
	if not value is Dictionary or value.is_empty(): return {}
	var restored=CaseState.new()
	if not restored.restore(value): return {}
	var normalized=restored.pack().duplicate(true)
	for key in ["comfort_time","pitch","distance","aperture","aperture_target","hazard_clock","hazard_exposure"]:
		if value.has(key): normalized[key]=float(value[key])
	return normalized
