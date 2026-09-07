extends Node3D

const CaseState = preload("res://case_state.gd")
const Story = preload("res://story.gd")
const Estate = preload("res://estate.gd")
const Town = preload("res://town.gd")
const TownStory = preload("res://town_story.gd")
const INK = Color("111615")
const PAPER = Color("d6d2bd")
const MUTED = Color("a6aa9b")

var state = CaseState.new()
var estate: Node3D
var player: CharacterBody3D
var model: Node3D
var camera: Camera3D
var film: ShaderMaterial
var ui: Control
var modal: Control
var content: VBoxContainer
var prompt: Label
var location_label: Label
var toast_label: Label
var marker: MeshInstance3D
var yaw = 0.0
var pitch = 0.38
var distance = 6.3
var aperture = 0.51
var aperture_target = 0.51
var focused = ""
var page = "title"
var scene_cards: Array = []
var scene_index = 0
var scene_callback: Callable
var animation_time = 0.0
var toast_time = 0.0
var location_time = 0.0
var autosave_time = 0.0
var comfort_time = 0.0
var last_region = ""
var return_page = "title"
var settings = {"grain":0.018,"distortion":0.25,"contrast":1.0,"text_scale":1.0,"sensitivity":0.0026,"camera_speed":1.0,"reduced_flicker":true,"hints":true,"invert_y":false}
var test_mode = false
var capture_mode = ""
var serif: SystemFont
var sans: SystemFont
var facts = {}
var movement_bounds = Rect2(-31,-18.4,62,60.4)
var resume_after_dialogue = false

func _ready() -> void:
	test_mode = OS.get_cmdline_user_args().has("--qa") or OS.get_cmdline_user_args().has("--qa-town")
	facts = Story.FACTS.duplicate(true)
	facts.merge(TownStory.FACTS)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="): capture_mode = arg.trim_prefix("--capture=")
	_setup_inputs()
	_load_settings()
	estate = Estate.new()
	estate.name = "OphionEstate"
	add_child(estate)
	_build_player()
	_build_ui()
	_title()
	if OS.get_cmdline_user_args().has("--qa"): call_deferred("_qa")
	if OS.get_cmdline_user_args().has("--qa-town"): call_deferred("_qa_town")
	if not capture_mode.is_empty(): call_deferred("_capture")

func _setup_inputs() -> void:
	var keys = {"walk_forward":[KEY_W,KEY_UP],"walk_back":[KEY_S,KEY_DOWN],"walk_left":[KEY_A,KEY_LEFT],"walk_right":[KEY_D,KEY_RIGHT],"use":[KEY_E,KEY_F],"case":[KEY_TAB,KEY_I],"journal":[KEY_J],"pause_game":[KEY_ESCAPE],"brisk":[KEY_SHIFT],"camera_left":[KEY_Q],"camera_right":[KEY_R]}
	for action in keys:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in keys[action]:
			var e = InputEventKey.new()
			e.physical_keycode = key
			InputMap.action_add_event(action,e)

func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "WalterCorwin3D"
	player.collision_layer = 2
	player.collision_mask = 1
	player.floor_snap_length = 0.3
	add_child(player)
	var capsule = CapsuleShape3D.new()
	capsule.height = 1.85
	capsule.radius = 0.3
	var collision = CollisionShape3D.new()
	collision.shape = capsule
	collision.position.y = 0.95
	player.add_child(collision)
	model = estate.person(Vector3.ZERO,"424b43")
	model.reparent(player,false)
	model.position = Vector3.ZERO
	var badge=estate.box(model,Vector3(-0.16,1.48,-0.18),Vector3(0.07,0.10,0.025),"c3c4b3")
	badge.name="Badge"
	player.position = state.position
	camera = Camera3D.new()
	camera.name = "ThirdPersonCamera"
	camera.fov = 53
	camera.near = 0.1
	camera.far = 180
	camera.current = true
	add_child(camera)
	_update_camera(1.0)
	var mesh = TorusMesh.new()
	mesh.inner_radius = 0.11
	mesh.outer_radius = 0.15
	marker = MeshInstance3D.new()
	marker.mesh = mesh
	var material = StandardMaterial3D.new()
	material.albedo_color = Color("d9dacb")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	marker.material_override = material
	marker.visible = false
	add_child(marker)

func _build_ui() -> void:
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia","Times New Roman"])
	sans = SystemFont.new()
	sans.font_names = PackedStringArray(["Segoe UI","Arial"])
	var film_layer = CanvasLayer.new()
	film_layer.layer = 20
	add_child(film_layer)
	var screen = ColorRect.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film = ShaderMaterial.new()
	film.shader = preload("res://film.gdshader")
	screen.material = film
	film_layer.add_child(screen)
	var layer = CanvasLayer.new()
	layer.layer = 30
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui)
	prompt = _label("",22,false)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_top = -96
	prompt.offset_bottom = -52
	ui.add_child(prompt)
	location_label = _label("",22,false)
	location_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	location_label.offset_top = 70
	location_label.offset_bottom = 145
	ui.add_child(location_label)
	toast_label = _label("",19,false)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	toast_label.offset_top = -153
	toast_label.offset_bottom = -105
	ui.add_child(toast_label)
	_apply_settings()

func _label(text:String, size:int = 24, literary:bool = true) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font",serif if literary else sans)
	l.add_theme_font_size_override("font_size",int(size*float(settings.text_scale)))
	l.add_theme_color_override("font_color",PAPER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

func _style(bg:Color,border:Color = Color("626d5b")) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func _button(text:String, callback:Callable, parent:Node = null) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size.y = 48
	b.add_theme_font_override("font",sans)
	b.add_theme_font_size_override("font_size",int(18*float(settings.text_scale)))
	b.add_theme_color_override("font_color",PAPER)
	b.add_theme_color_override("font_hover_color",Color.WHITE)
	b.add_theme_stylebox_override("normal",_style(Color("18201b")))
	b.add_theme_stylebox_override("hover",_style(Color("303a2e"),PAPER))
	b.add_theme_stylebox_override("pressed",_style(Color("3d4938"),PAPER))
	b.add_theme_stylebox_override("focus",_style(Color(0,0,0,0),PAPER))
	b.pressed.connect(callback)
	if parent == null: content.add_child(b)
	else: parent.add_child(b)
	return b

func _panel(kind:String,heading:String,kicker:String = "",wide:bool = false) -> void:
	if is_instance_valid(modal):
		ui.remove_child(modal)
		modal.queue_free()
	page = kind
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(modal)
	var dark = ColorRect.new()
	dark.color = Color(0.025,0.035,0.03,0.9 if kind == "dialogue" else 0.84)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dark)
	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 170 if wide else 320
	panel.offset_right = -170 if wide else -320
	panel.offset_top = 150 if kind == "dialogue" else 60
	panel.offset_bottom = -150 if kind == "dialogue" else -60
	panel.add_theme_stylebox_override("panel",_style(Color("111914"),Color("727b66")))
	modal.add_child(panel)
	var scroll = ScrollContainer.new()
	panel.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",18)
	scroll.add_child(content)
	if not kicker.is_empty():
		var k = _label(kicker,13,false)
		k.add_theme_color_override("font_color",MUTED)
		content.add_child(k)
	content.add_child(_label(heading,38))
	var sep = HSeparator.new()
	content.add_child(sep)
	prompt.visible = false
	marker.visible = false
	toast_label.visible = false
	location_label.visible = false

func _paragraph(text:String,size:int = 23) -> void:
	content.add_child(_label(text,size))

func _focus_first() -> void:
	for b in content.find_children("*","Button",true,false):
		if not b.disabled:
			b.grab_focus()
			return

func _close() -> void:
	if is_instance_valid(modal): modal.queue_free()
	modal = null
	page = "play"
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	prompt.visible = true
	toast_label.visible = true
	location_label.visible = true

func _title() -> void:
	_panel("title","No Exit Wound","THREE COLORS OF MADNESS  /  CHAPTER ONE")
	_paragraph("Widow's Bight, 1923",24)
	_paragraph("Eight people are dead at the Ophion estate.\nThe town is prepared to account for six.",28)
	_paragraph("The estate and the first town inquiry\nThird-person 3D prototype",16)
	if not _available_save_path().is_empty(): _button("Continue investigation",_load_game)
	_button("Begin at the estate",_new_game)
	_button("Accessibility & controls",func(): return_page="title"; _settings())
	_button("Quit",func(): get_tree().quit())
	_focus_first()

func _new_game() -> void:
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
	scene_cards = cards
	scene_index = 0
	scene_callback = after
	_draw_card()

func _draw_card() -> void:
	var card = scene_cards[scene_index]
	_panel("dialogue",str(card[0]),"NO EXIT WOUND  /  %02d" % (scene_index+1))
	_paragraph(str(card[1]),27)
	var space = Control.new()
	space.custom_minimum_size.y = 30
	content.add_child(space)
	_button("Continue",_next_card)
	for child in content.get_children():
		if child is Label: child.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_first()

func _next_card() -> void:
	scene_index += 1
	if scene_index >= scene_cards.size():
		var cb = scene_callback
		_close()
		cb.call()
	else: _draw_card()

func _physics_process(delta:float) -> void:
	if page != "play": return
	state.minutes += delta/60
	var axis = Input.get_vector("walk_left","walk_right","walk_forward","walk_back")
	var movement = Vector3(axis.x,0,axis.y).rotated(Vector3.UP,yaw)
	var speed = 3.5 if Input.is_action_pressed("brisk") else 2.15
	player.velocity.x = move_toward(player.velocity.x,movement.x*speed,delta*13)
	player.velocity.z = move_toward(player.velocity.z,movement.z*speed,delta*13)
	if not player.is_on_floor(): player.velocity.y -= 18*delta
	else: player.velocity.y = -0.2
	player.move_and_slide()
	player.position.x = clampf(player.position.x,movement_bounds.position.x,movement_bounds.end.x)
	player.position.z = clampf(player.position.z,movement_bounds.position.y,movement_bounds.end.y)
	if player.position.y < -3: player.position = Vector3(0,0.1,30)
	if movement.length() > 0.1:
		model.rotation.y = lerp_angle(model.rotation.y,atan2(-movement.x,-movement.z),delta*10)
		animation_time += delta*speed*3
	var swing = sin(animation_time)*0.34*movement.length()
	model.get_node("LeftLeg").rotation.x = swing
	model.get_node("RightLeg").rotation.x = -swing
	model.get_node("LeftArm").rotation.x = -swing*0.8
	model.get_node("RightArm").rotation.x = swing*0.8
	var orbit = Input.get_axis("camera_left","camera_right")
	yaw -= orbit*delta*1.5
	_update_camera(delta)
	_find_focus()
	if state.world == "estate" and player.position.z < 6:
		aperture_target = 1.2
		if not state.visited.has("garden"):
			state.visited.append("garden")
			_save_game()
	var region = _region_name()
	if region != last_region:
		last_region = region
		location_label.text = region+"\n—  "+("BEFORE DAWN" if state.world == "estate" else "PICKMAN STREET")+"  —"
		location_time = 4
	autosave_time += delta
	if autosave_time > 20:
		autosave_time = 0
		_save_game()

func _process(delta:float) -> void:
	aperture = move_toward(aperture,aperture_target,delta*0.16)
	film.set_shader_parameter("iris",aperture)
	if page == "play": comfort_time = maxf(0,comfort_time-delta)
	var unease = minf(1.0,float(state.evidence.size())/12.0)
	film.set_shader_parameter("distortion",float(settings.distortion)*unease*(0.1 if comfort_time > 0 else 1.0))
	toast_time = maxf(0,toast_time-delta)
	toast_label.modulate.a = minf(1,toast_time)
	location_time = maxf(0,location_time-delta)
	location_label.modulate.a = minf(1,location_time)

func _update_camera(delta:float) -> void:
	var pivot = player.global_position+Vector3(0,1.45,0)
	var offset = Vector3(0,sin(pitch)*distance,cos(pitch)*distance).rotated(Vector3.UP,yaw)
	var desired = pivot+offset
	if is_inside_tree():
		var query = PhysicsRayQueryParameters3D.create(pivot,desired,1)
		var hit = get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty(): desired = hit.position+hit.normal*0.3
	camera.global_position = camera.global_position.lerp(desired,minf(1,delta*12))
	if camera.global_position.distance_to(pivot) > 0.01: camera.look_at(pivot)

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F11:
		var mode = DisplayServer.window_get_mode()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if page == "play":
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			yaw -= event.relative.x*float(settings.sensitivity)
			pitch = clampf(pitch+event.relative.y*float(settings.sensitivity)*(-1 if settings.invert_y else 1),0.08,1.05)
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP: distance = maxf(3.2,distance-0.5)
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: distance = minf(9,distance+0.5)
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
	if _town_interaction(id): return
	if id == "report":
		_report_screen()
		return
	if id == "exit":
		if state.report.is_empty(): return
		_finish()
		return
	var key = "gardener_plain" if id == "gardener" and state.coat == "Plain wool coat" else id
	if not Story.SCENES.has(key): return
	_cards(Story.SCENES[key],func():
		if not state.visited.has(id): state.visited.append(id)
		if Story.FACTS.has(id): state.discover(id)
		if id == "assistant":
			state.discover("testimony")
			state.discover("eight")
		if id == "odell":
			state.discover("eight")
			state.record("Odell proposed an accident before cause had been established.")
		if key == "gardener_plain": state.record("The gardener saw the woman at the service door. Ask the steward.")
		elif id == "gardener": state.record("The gardener requested eight sheets. Six arrived first.")
		_save_game()
		_toast("Recorded in Walter's case file.  [ Tab ]",4)
	)

func _objective() -> String:
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
	_panel("case","Walter Corwin","PERSONAL EFFECTS  /  PRECINCT 4",true)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",28)
	content.add_child(row)
	var left = VBoxContainer.new()
	left.custom_minimum_size.x = 280
	row.add_child(left)
	left.add_child(_label("ON HIS PERSON",14,false))
	# A spare paperdoll, rendered in the same ink vocabulary as the file.
	var doll = Control.new()
	doll.custom_minimum_size = Vector2(250,190)
	left.add_child(doll)
	for rect in [Rect2(105,5,32,32),Rect2(88,40,65,83),Rect2(65,43,18,76),Rect2(158,43,18,76),Rect2(93,123,22,62),Rect2(127,123,22,62)]:
		var shape = ColorRect.new()
		shape.position = rect.position
		shape.size = rect.size
		shape.color = Color("707a67")
		doll.add_child(shape)
	left.add_child(_label("STRENGTH    2\nPERCEPTION    %d" % state.perception(),21,false))
	left.add_child(_label("Carried weight: %.1f / 12 kg\nSlots: %d / 10" % [4.6+(0.4 if state.evidence.has("knife") else 0),5+(1 if state.evidence.has("knife") else 0)],17,false))
	left.add_child(_label("Strength governs carried weight.\nPerception grows through observation.",16,false))
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",12)
	row.add_child(right)
	right.add_child(_label("CURRENT INQUIRY",14,false))
	right.add_child(_label(_objective(),23))
	right.add_child(_label("EQUIPPED",14,false))
	right.add_child(_label(state.coat+" · worn leather boots\nNotebook · pencil · service revolver\nFlask"+(" · sealed knife envelope" if state.evidence.has("knife") else ""),21))
	_button("Inspect the flask",_flask,right)
	_button("Change to "+("plain wool coat" if state.coat == "Police coat" else "police coat"),func():
		state.coat = "Plain wool coat" if state.coat == "Police coat" else "Police coat"
		_refresh_outfit()
		_save_game()
		_case_file(),right)
	_button("Open the case file",_journal,right)
	_button("Return to the grounds",_close)
	_focus_first()

func _flask() -> void:
	_panel("case","The flask","PERSONAL EFFECTS")
	var levels = ["Empty. The metal carries no weight beyond itself.","A little left. Enough for one short pour.","Partly full. Two short pours remain.","Three short pours by Walter's reckoning."]
	_paragraph(levels[state.flask])
	_paragraph("A familiar weight. A brief narrowing of the world.\nIt has never promised anything more.",24)
	if state.flask > 0:
		_button("Take a short pour",func():
			state.flask -= 1
			comfort_time = 90
			_save_game()
			_close()
			_toast("The edges settle. The facts remain.",4))
	_button("Put it away",_case_file)
	_focus_first()

func _journal() -> void:
	_panel("journal","The preliminary case","WALTER CORWIN  /  ORIGINAL RECORD",true)
	_paragraph(_objective(),20)
	if state.evidence.is_empty(): _paragraph("No observations recorded yet. The garden waits.",24)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",15)
	grid.add_theme_constant_override("v_separation",12)
	content.add_child(grid)
	for id in state.evidence:
		if not facts.has(id): continue
		var b = _button(str(facts[id][0]),func(): _fact(id),grid)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_paragraph("OBSERVATIONS IN RELATION",14)
	if state.evidence.has("naomi"):
		_paragraph("A woman recorded without a name now has one: Naomi Freeman.\nThe original omission remains visible beside the later identification.",22)
	if state.evidence.has("wounds") and state.evidence.has("gas"):
		_paragraph("Wounds without powder marks. Windows without blast damage.\nThe proposed accident accounts for neither observation.",22)
	elif state.evidence.has("eight"):
		_paragraph("Six club members and two other people.\nThe separation of the scenes does not change the count.",22)
	else: _paragraph("Further observations may clarify what these facts share.",20)
	for statement in state.statements: _paragraph("— "+statement,19)
	if not state.report.is_empty():
		_paragraph("REPORT: "+state.report,18)
		_paragraph("Copies: "+", ".join(state.copies),17)
		if state.report_evidence.size() != state.evidence.size(): _paragraph("New observations are in Walter's notebook. "+("File a dated supplement at the precinct; received copies remain unchanged." if state.intake_done else "Return to the field desk to include them in the prepared report."),17)
		if state.supplement_filed: _paragraph("DATED SUPPLEMENT: %d observations recorded at filing." % state.supplement_evidence.size(),17)
	_paragraph("The file records what Walter has observed. Opening it is never required to continue.",15)
	_button("Personal effects",_case_file)
	_button("Close the file",_close)
	_focus_first()

func _fact(id:String) -> void:
	var fact = facts[id]
	_panel("fact",str(fact[0]),"CASE FILE  /  RECOVERABLE OBSERVATION")
	_paragraph(str(fact[1]),27)
	_paragraph("SOURCE\n"+_source_for(id),18)
	_button("Back to the file",_journal)
	_focus_first()

func _report_screen() -> void:
	if state.intake_done:
		_panel("report","Already received","THE ESTATE REPORT")
		_paragraph("The precinct has received this report. Later observations belong in a dated supplement at the precinct.")
		_button("Return to the grounds",_close)
		_focus_first()
		return
	_panel("report","Put it in writing","THE FIELD DESK  /  PRELIMINARY REPORT")
	_paragraph("Eight dead. Identities partly established.\nCause unresolved.\n\nThe report will contain the observations and statements Walter has recorded so far.",24)
	_paragraph("How will you submit it?",24)
	_button("File the observations; retain my notebook",func(): _write_report("Observations filed","report_routine"))
	_button("Request a full inquest; prepare a county copy",func(): _write_report("Full inquest requested","report_inquest"))
	_button("Continue examining before I file",_close)
	_focus_first()

func _write_report(mode:String,scene:String) -> void:
	state.complete_report(mode)
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
	_paragraph("Clue text and intertitles remain outside all film effects.\nThis opening is intentionally silent. No spoken dialogue is omitted.",18)
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
	if film == null: return
	film.set_shader_parameter("grain",float(settings.grain))
	film.set_shader_parameter("contrast",float(settings.contrast))
	film.set_shader_parameter("animated_grain",not bool(settings.reduced_flicker))

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
	var best=""
	var timestamp=0
	for candidate in candidates:
		if FileAccess.file_exists(candidate) and FileAccess.get_modified_time(candidate)>=timestamp:
			best=candidate
			timestamp=FileAccess.get_modified_time(candidate)
	return best

func _save_game() -> bool:
	if not state.started or not capture_mode.is_empty(): return false
	state.position = player.position
	state.yaw = yaw
	var d = state.pack()
	d["comfort_time"] = comfort_time
	d["pitch"] = pitch
	d["distance"] = distance
	var temporary = _save_path()+".tmp"
	var file = FileAccess.open(temporary,FileAccess.WRITE)
	if file == null:
		_toast("Save unavailable. Your session remains playable.",5)
		return false
	file.store_string(JSON.stringify(d,"\t"))
	file.close()
	if DirAccess.rename_absolute(temporary,_save_path()) != OK:
		_toast("Save could not be completed. Your session remains playable.",5)
		return false
	return true

func _load_game() -> void:
	var file=FileAccess.open(_available_save_path(),FileAccess.READ)
	if file == null: _toast("No saved investigation found.",4); return
	var d=JSON.parse_string(file.get_as_text())
	if not d is Dictionary or not state.restore(d): _toast("The save could not be read. Begin a new investigation.",5); return
	_travel(state.world,state.position,state.yaw,false)
	player.position=state.position
	yaw=state.yaw
	pitch=float(d.get("pitch",0.38))
	distance=float(d.get("distance",6.3))
	comfort_time=float(d.get("comfort_time",0))
	aperture=1.2 if state.visited.has("garden") else 0.51
	aperture_target=aperture
	_refresh_outfit()
	_update_camera(1)
	if state.finished: _town_complete()
	else: _close()

func _save_settings() -> void:
	if test_mode or not capture_mode.is_empty(): return
	var file=FileAccess.open("user://opening_settings.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(settings))

func _load_settings() -> void:
	if not FileAccess.file_exists("user://opening_settings.json"): return
	var d=JSON.parse_string(FileAccess.get_file_as_string("user://opening_settings.json"))
	if d is Dictionary:
		for key in settings:
			if d.has(key): settings[key]=d[key]

func _toast(text:String,duration:float = 4) -> void:
	toast_label.text=text
	toast_time=duration

func _notification(what:int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_save_game()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and page == "play" and not test_mode and capture_mode.is_empty(): _pause()

func _capture() -> void:
	state.started=true
	player.position=Vector3(1,0.1,7.5)
	yaw=-0.12
	distance=8
	pitch=0.35
	aperture=1.2
	aperture_target=1.2
	_update_camera(1)
	if capture_mode != "title": _close()
	if capture_mode == "case":
		for id in Story.FACTS: state.discover(id)
		state.visited.assign(["garden","odell"])
		state.complete_report("Full inquest requested")
		_journal()
	if capture_mode == "dialogue": _interact("odell")
	if capture_mode == "settings": _settings()
	if capture_mode == "effects": _case_file()
	if capture_mode == "large_text": settings.text_scale=1.3; _settings()
	if capture_mode == "gate":
		player.position=Vector3(0,0.1,36)
		distance=6.3
		pitch=0.38
		yaw=0
		aperture=0.51
		aperture_target=0.51
		_update_camera(1)
	if capture_mode in ["town","precinct","boardinghouse","room","board","witness"]:
		for id in ["eight","wounds","gas"]: state.discover(id)
		state.complete_report("Full inquest requested")
		state.receive_report()
		state.estate_complete=true
		for id in ["intake","naomi","lodging","lay_lead","service_work"]: state.discover(id)
		var scene=capture_mode
		if capture_mode=="board": scene="room"
		if capture_mode=="witness": scene="boardinghouse"
		_travel(scene,Vector3(0,0.1,17) if scene=="town" else Vector3(0,0.1,4))
		if capture_mode=="board": _board()
		if capture_mode=="witness": _witness_menu()
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	var path=ProjectSettings.globalize_path("res://qa_"+capture_mode+".png")
	var result=get_viewport().get_texture().get_image().save_png(path)
	if result==OK: print("CAPTURE "+path)
	else: push_error("Capture failed: "+str(result))
	get_tree().quit()

func _qa() -> void:
	# Actual scene integration tests exercise cards, progression, copies and disk reload.
	await get_tree().physics_frame
	state.started=true
	_close()
	_interact("odell")
	while page == "dialogue": _next_card()
	assert(state.evidence.has("eight"),"Required consultation supplies the count without optional collection")
	assert(state.visited.has("odell"))
	_write_report("Observations filed","report_routine")
	while page == "dialogue": _next_card()
	assert(state.copies.size()==2)
	assert(not state.visited.has("wounds"),"Minimal path must not claim examinations not performed")
	for id in ["wounds","eight","knife","watch","gas","register","shoes","assistant"]:
		_interact(id)
		while page == "dialogue": _next_card()
	assert(state.evidence.size()==8)
	assert(state.report_evidence.size()==1,"Additional notebook observations must not rewrite already prepared copies")
	state.coat="Plain wool coat"
	_interact("gardener")
	while page == "dialogue": _next_card()
	assert(state.statements.has("The gardener saw the woman at the service door. Ask the steward."))
	_write_report("Full inquest requested","report_inquest")
	while page == "dialogue": _next_card()
	assert(state.copies.size()==3)
	state.flask=1
	comfort_time=45
	player.position=Vector3(10,0.1,-3)
	assert(_save_game())
	state=CaseState.new()
	_load_game()
	assert(state.evidence.size()==8 and state.flask==1 and state.copies.size()==3)
	assert(state.coat=="Plain wool coat" and comfort_time==45)
	assert(player.position.distance_to(Vector3(10,0.1,-3))<0.01)
	_journal()
	assert(page=="journal")
	_case_file()
	assert(page=="case")
	_settings()
	assert(page=="settings")
	_finish()
	assert(state.estate_complete)
	assert(_save_game())
	var file=FileAccess.open(_save_path(),FileAccess.READ)
	var saved=JSON.parse_string(file.get_as_text())
	assert(saved.estate_complete and saved.copies.size()==3)
	print("QA PASS: minimal route; eight observations; clothing testimony; two/three copies; full save/load; protected menus; completion")
	# Walk through actual physics using the same input actions as the player.
	state.finished=false
	_close()
	player.position=Vector3(0,0.1,36)
	yaw=0
	for stop in [Vector3(-1,0,31),Vector3(0,0,7),Vector3(0,0,1),Vector3(-4,0,-2),Vector3(-6,0,-0.4),Vector3(-12,0,1),Vector3(-5,0,1),Vector3(6,0,0),Vector3(12,0,-4),Vector3(23,0,-3.3),Vector3(25.6,0,-4),Vector3(12,0,-4),Vector3(10,0,-12),Vector3(4,0,-11.5),Vector3(7.4,0,-12.7),Vector3(6,0,-12.7),Vector3(-8,0,-18),Vector3(-5,0,-11),Vector3(-5,0,1),Vector3(0,0,7),Vector3(0,0,39)]:
		await _walk_to(stop)
	assert(focused=="exit","Departure must be reachable through real collision and interaction focus")
	# The hedge must block movement, rather than merely decorate the lawn.
	player.position=Vector3(10,0.1,9)
	Input.action_press("walk_forward")
	for i in 100: await get_tree().physics_frame
	Input.action_release("walk_forward")
	assert(player.position.z>6.6,"Hedge must block the player")
	print("QA PASS: actual WASD traversal through gate, garden, birch grove and terrace; departure focus; hedge collision")
	get_tree().quit()

func _walk_to(destination:Vector3) -> void:
	for i in 1500:
		var offset=Vector2(destination.x-player.position.x,destination.z-player.position.z)
		if offset.length()<0.25: break
		var dir=offset.normalized()
		for action in ["walk_left","walk_right","walk_forward","walk_back"]: Input.action_release(action)
		if dir.x>0: Input.action_press("walk_right",dir.x)
		else: Input.action_press("walk_left",-dir.x)
		if dir.y>0: Input.action_press("walk_back",dir.y)
		else: Input.action_press("walk_forward",-dir.y)
		await get_tree().physics_frame
	for action in ["walk_left","walk_right","walk_forward","walk_back"]: Input.action_release(action)
	assert(Vector2(destination.x-player.position.x,destination.z-player.position.z).length()<0.6,"Unreachable walking destination: "+str(destination)+" from "+str(player.position))

func _travel(destination:String,spawn:Vector3,view_yaw:float=0.0,save:bool=true) -> void:
	if is_instance_valid(estate):
		remove_child(estate)
		estate.queue_free()
	if destination == "estate": estate=Estate.new()
	else:
		estate=Town.new()
		estate.location=destination
	add_child(estate)
	state.world=destination
	player.position=spawn
	player.velocity=Vector3.ZERO
	yaw=view_yaw
	pitch=0.38 if destination in ["estate","town"] else 0.48
	distance=6.3 if destination in ["estate","town"] else 4.8
	movement_bounds=Rect2(-31,-18.4,62,60.4) if destination=="estate" else (Rect2(-29,-6,58,28) if destination=="town" else Rect2(-8.45,-7.4,16.9,15.1))
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
		"town": return "WIDOW'S BIGHT"
		"precinct": return "PRECINCT 4"
		"boardinghouse": return "MRS. ALMY'S PARLOR"
		"room": return "CORWIN'S ROOM"
	return "THE BIRCH GROVE" if player.position.x > 18 else ("THE TERRACE" if player.position.z < -10 else ("THE ROSE GARDEN" if player.position.z < 6 else "THE OPHION ESTATE"))

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

func _town_observation(id:String,return_to_witness:bool=false) -> void:
	_cards(TownStory.SCENES[id],func():
		state.discover(id)
		if not state.inquiry_topics.has(id): state.inquiry_topics.append(id)
		_save_game()
		if return_to_witness: _witness_menu()
		else: _close(); _toast("Source recorded in Walter's notebook.  [ J ]",4))

func _intake() -> void:
	if state.intake_done:
		_panel("case","Received as written","PRECINCT 4  /  INCOMING REPORT")
		_paragraph("%s\n%d observations in the estate report.\n\nThe received copy remains unchanged." % [state.report,state.report_evidence.size()],24)
		if state.county_evidence.size()>0: _paragraph("The first county copy contains %d observations." % state.county_evidence.size(),20)
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
	state.file_supplement(county)
	_save_game()
	var cards=TownStory.SCENES.supplement.duplicate(true)
	if county: cards.append_array(TownStory.SCENES.county_supplement)
	_cards(cards,func(): _close(); _toast("Dated supplement received. Earlier copies retained.",5))

func _board() -> void:
	_panel("board","What belongs beside what","CORWIN'S ROOM  /  THE CASE BOARD",true)
	_paragraph("The cards reflect the investigation already made.\nReading them does not decide whether it can continue.",19)
	var grid=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",18)
	content.add_child(grid)
	for id in state.evidence:
		if id=="exemption" or not facts.has(id): continue
		var box=VBoxContainer.new()
		box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(box)
		var b=_button(str(facts[id][0]),func(): _fact(id),box)
		b.custom_minimum_size.y=68
		b.clip_text=true
		box.custom_minimum_size.x=270
		var source=_label(_source_for(id),14,false)
		box.add_child(source)
	if state.evidence.has("naomi") and state.evidence.has("lodging"):
		_paragraph("UNIDENTIFIED WOMAN  →  NAOMI FREEMAN  →  A LOCAL ADDRESS\nMrs. Almy's statement and the meal ledger support the same identification.",22)
	if state.evidence.has("lay_lead"):
		_paragraph("AN UNPAID LAY  →  DOCUMENT NOT EXAMINED\nThe claim is a question to investigate. It does not establish why she was killed.",22)
	if state.evidence.has("intake"):
		_paragraph("SIX IN THE HEADING  ↔  EIGHT IN WALTER'S REPORT\nThe disagreement has a source on each side. Neither page replaces the other.",22)
	_button("Read the complete notebook",_journal)
	_button("Step away from the board",_close)
	_focus_first()

func _town_complete() -> void:
	_panel("ending","A name brought home","END OF THE FIRST TOWN INQUIRY")
	_paragraph("Naomi Freeman.\n\nThe town has not changed its account.\nWalter's account has become harder to dismiss.",27)
	_paragraph("Notebook: %d observations\nEstate report: %d observations, retained as submitted\nDated supplements: %d\nCounty dispatch: %s" % [state.evidence.size(),state.report_evidence.size(),state.supplement_history.size(),"recorded" if state.county_dispatched else "none"],20)
	_paragraph("The current build ends here. The club's staff and records are the next inquiry.\nYour investigation is saved; you can keep exploring this part of town.",19)
	_button("Review the board",_board)
	_button("Continue exploring",_close)
	_button("Save and return to title",func(): _save_game(); _title())
	_button("Save and quit",func(): _save_game(); get_tree().quit())
	_focus_first()

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
