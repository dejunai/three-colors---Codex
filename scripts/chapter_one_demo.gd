extends Node3D

const PlayerScript = preload("res://scripts/player_controller.gd")
const InteractableScript = preload("res://scripts/interactable.gd")
const HazardScript = preload("res://scripts/tunnel_hazard.gd")
const FilmShader = preload("res://shaders/film_1923.gdshader")

const INK := Color("17191d")
const CHARCOAL := Color("2a2c31")
const ASH := Color("6d7075")
const PAPER := Color("c5c0af")
const BONE := Color("a8a496")
const CRIMSON := Color("8f1019")
const IMPOSSIBLE_BLUE := Color("315a78")

var environment_root: Node3D
var player
var camera: Camera3D
var world_environment: WorldEnvironment
var film_material: ShaderMaterial
var case_panel: PanelContainer
var evidence_list: VBoxContainer
var inventory_label: Label
var stats_label: Label
var links_label: Label
var selected_label: Label
var prompt_label: Label
var toast_panel: PanelContainer
var toast_label: Label
var slice_label: Label
var end_panel: PanelContainer

var selected_evidence: Array[String] = []
var material_cache: Dictionary = {}
var reveal_nodes: Array[Dictionary] = []
var hazard
var flask_prop: Node3D
var tunnel_spill_done := false
var tunnel_start := Vector3(0.0, 0.82, 8.0)
var rose_frame_open := false
var aperture_current := 0.49
var aperture_target := 0.49
var frame_width_current := 0.5625
var frame_width_target := 0.5625
var tunnel_darkness_current := 0.0
var tunnel_darkness_target := 0.0
var camera_offset := Vector3(9.5, 10.5, 11.5)
var camera_size_target := 15.0
var toast_generation := 0

func _ready() -> void:
	GameState.reset_demo()
	_setup_world()
	_setup_player()
	_setup_camera()
	_setup_film_overlay()
	_setup_interface()
	GameState.state_changed.connect(_on_state_changed)
	var starting_slice := 0
	var open_case_on_start := false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--slice="):
			starting_slice = clampi(int(argument.trim_prefix("--slice=")), 0, 2)
		elif argument == "--seed-demo":
			_seed_demo_case()
		elif argument == "--open-case":
			open_case_on_start = true
	_build_slice(starting_slice)
	if open_case_on_start:
		_toggle_case_ui(true)

func _seed_demo_case() -> void:
	for evidence_id in ["impossible_wound", "clean_knife", "unnamed_victims", "club_token", "boardinghouse_account", "meeting_ledger", "service_plan"]:
		GameState.discover_evidence(evidence_id)
	GameState.try_link("clean_knife", "impossible_wound")
	GameState.try_link("club_token", "meeting_ledger")

func _process(delta: float) -> void:
	if player != null and camera != null:
		var desired: Vector3 = player.global_position + camera_offset
		camera.global_position = camera.global_position.lerp(desired, clampf(delta * 4.5, 0.0, 1.0))
		camera.look_at(player.global_position + Vector3.UP * 0.65, Vector3.UP)
		camera.size = lerpf(camera.size, camera_size_target, clampf(delta * 3.0, 0.0, 1.0))

	if GameState.current_slice == 0 and not rose_frame_open and player.global_position.z < 6.2:
		rose_frame_open = true
		aperture_target = 2.0
		frame_width_target = 1.0
		_show_toast("The rose garden enters the frame.", 2.2)

	if GameState.current_slice == 2 and not tunnel_spill_done and player.global_position.z < 3.0:
		_spill_flask()

	aperture_current = lerpf(aperture_current, aperture_target, clampf(delta * 1.15, 0.0, 1.0))
	frame_width_current = lerpf(frame_width_current, frame_width_target, clampf(delta * 1.0, 0.0, 1.0))
	tunnel_darkness_current = lerpf(tunnel_darkness_current, tunnel_darkness_target, clampf(delta * 1.5, 0.0, 1.0))
	if film_material != null:
		film_material.set_shader_parameter("time_value", Time.get_ticks_msec() / 1000.0)
		film_material.set_shader_parameter("instability", GameState.instability)
		film_material.set_shader_parameter("aperture_radius", aperture_current)
		film_material.set_shader_parameter("frame_width", frame_width_current)
		film_material.set_shader_parameter("tunnel_darkness", tunnel_darkness_current)

	_update_reveal_nodes()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_ui"):
		_toggle_case_ui()
		get_viewport().set_input_as_handled()
		return
	if case_panel != null and case_panel.visible:
		return
	if event.is_action_pressed("slice_1"):
		_build_slice(0)
	elif event.is_action_pressed("slice_2"):
		_build_slice(1)
	elif event.is_action_pressed("slice_3"):
		_build_slice(2)

func _setup_world() -> void:
	world_environment = WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("111319")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("89909a")
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color("737982")
	env.fog_light_energy = 0.32
	env.fog_density = 0.012
	world_environment.environment = env
	add_child(world_environment)

	var key_light := DirectionalLight3D.new()
	key_light.name = "MoonKey"
	key_light.rotation_degrees = Vector3(-58.0, -28.0, 0.0)
	key_light.light_color = Color("d9dce0")
	key_light.light_energy = 1.15
	key_light.shadow_enabled = true
	add_child(key_light)

	environment_root = Node3D.new()
	environment_root.name = "CurrentSlice"
	add_child(environment_root)

func _setup_player() -> void:
	player = PlayerScript.new()
	player.name = "WalterCorwin"
	player.collision_layer = 2
	player.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.34
	shape.height = 1.55
	collision.shape = shape
	collision.position.y = 0.78
	player.add_child(collision)
	var visual := _build_dummy(player, Vector3(0.0, 0.0, 0.0), false, 0.92, CHARCOAL)
	visual.name = "WalterDummy"
	add_child(player)
	player.prompt_changed.connect(_on_prompt_changed)
	player.interacted.connect(_on_player_interacted)

func _setup_camera() -> void:
	camera = Camera3D.new()
	camera.name = "OrthographicCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = camera_size_target
	camera.near = 0.1
	camera.far = 120.0
	camera.current = true
	add_child(camera)
	player.set_camera(camera)

func _setup_film_overlay() -> void:
	var film_layer := CanvasLayer.new()
	film_layer.name = "FilmPresentation"
	film_layer.layer = 50
	add_child(film_layer)
	var film_rect := ColorRect.new()
	film_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	film_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	film_material = ShaderMaterial.new()
	film_material.shader = FilmShader
	film_rect.material = film_material
	film_layer.add_child(film_rect)

func _setup_interface() -> void:
	var ui := CanvasLayer.new()
	ui.name = "ProtectedInterface"
	ui.layer = 100
	add_child(ui)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(root)

	slice_label = Label.new()
	slice_label.position = Vector2(24, 20)
	slice_label.add_theme_font_size_override("font_size", 18)
	slice_label.add_theme_color_override("font_color", PAPER)
	root.add_child(slice_label)

	var controls := Label.new()
	controls.text = "WASD MOVE   •   F / LEFT CLICK INTERACT   •   TAB CASE FILE\nDEV SHORTCUTS: 1 ROSE   2 INVESTIGATION   3 TUNNEL"
	controls.position = Vector2(24, 50)
	controls.add_theme_font_size_override("font_size", 12)
	controls.add_theme_color_override("font_color", Color(PAPER, 0.68))
	root.add_child(controls)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-270, -68)
	prompt_label.size = Vector2(540, 42)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 17)
	prompt_label.add_theme_color_override("font_color", Color.WHITE)
	root.add_child(prompt_label)

	toast_panel = PanelContainer.new()
	toast_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_panel.position = Vector2(-310, -178)
	toast_panel.size = Vector2(620, 96)
	toast_panel.add_theme_stylebox_override("panel", _panel_style(Color("111216e6"), Color("777267")))
	toast_panel.visible = false
	root.add_child(toast_panel)
	toast_label = Label.new()
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", PAPER)
	toast_label.add_theme_font_size_override("font_size", 15)
	toast_panel.add_child(toast_label)

	_build_case_panel(root)
	_build_end_panel(root)

func _build_case_panel(root: Control) -> void:
	case_panel = PanelContainer.new()
	case_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	case_panel.offset_left = 120
	case_panel.offset_top = 72
	case_panel.offset_right = -120
	case_panel.offset_bottom = -72
	case_panel.add_theme_stylebox_override("panel", _panel_style(Color("111216f5"), Color("918a78"), 2))
	case_panel.visible = false
	root.add_child(case_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	case_panel.add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 30)
	margin.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(435, 0)
	left.add_theme_constant_override("separation", 10)
	columns.add_child(left)
	var heading := Label.new()
	heading.text = "CASE FILE // WALTER CORWIN"
	heading.add_theme_font_size_override("font_size", 25)
	heading.add_theme_color_override("font_color", PAPER)
	left.add_child(heading)
	var rule := HSeparator.new()
	left.add_child(rule)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size", 16)
	left.add_child(stats_label)
	inventory_label = Label.new()
	inventory_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(inventory_label)
	var fact_heading := Label.new()
	fact_heading.text = "VERIFIED FACTS"
	fact_heading.add_theme_font_size_override("font_size", 17)
	fact_heading.add_theme_color_override("font_color", Color("ddd7c4"))
	left.add_child(fact_heading)
	evidence_list = VBoxContainer.new()
	evidence_list.add_theme_constant_override("separation", 4)
	left.add_child(evidence_list)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	columns.add_child(right)
	var board_heading := Label.new()
	board_heading.text = "LINK TWO PIECES OF EVIDENCE"
	board_heading.add_theme_font_size_override("font_size", 18)
	right.add_child(board_heading)
	selected_label = Label.new()
	selected_label.custom_minimum_size = Vector2(0, 58)
	selected_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(selected_label)
	var link_button := Button.new()
	link_button.text = "DRAW THE LINE"
	link_button.custom_minimum_size = Vector2(0, 44)
	link_button.pressed.connect(_attempt_selected_link)
	right.add_child(link_button)
	links_label = Label.new()
	links_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	links_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(links_label)
	var note := Label.new()
	note.text = "The handwriting may drift. Facts shown under VERIFIED FACTS do not.\n\n[TAB] CLOSE"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color(PAPER, 0.62))
	right.add_child(note)

func _build_end_panel(root: Control) -> void:
	end_panel = PanelContainer.new()
	end_panel.set_anchors_preset(Control.PRESET_CENTER)
	end_panel.position = Vector2(-330, -155)
	end_panel.size = Vector2(660, 310)
	end_panel.add_theme_stylebox_override("panel", _panel_style(Color("090a0df5"), CRIMSON, 2))
	end_panel.visible = false
	root.add_child(end_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 26)
	end_panel.add_child(margin)
	var text := Label.new()
	text.text = "VERTICAL SLICE COMPLETE\n\nWalter has learned enough to know the tunnel is not an answer. The full chapter would carry the case back into town, where completing it produces the understanding that ends him.\n\n[TAB] Review the case file   •   [1–3] Revisit a slice"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 18)
	text.add_theme_color_override("font_color", PAPER)
	margin.add_child(text)

func _build_slice(index: int) -> void:
	_clear_environment()
	selected_evidence.clear()
	GameState.set_slice(index)
	hazard = null
	flask_prop = null
	tunnel_spill_done = false
	end_panel.visible = false
	player.active = true
	match index:
		0:
			_build_rose_garden()
		1:
			_build_investigation_room()
		2:
			_build_tunnel()
	_refresh_case_ui()

func _build_rose_garden() -> void:
	slice_label.text = "CHAPTER ONE // SLICE I — THE ROSE GARDEN"
	world_environment.environment.background_color = Color("16191f")
	world_environment.environment.fog_density = 0.009
	camera_offset = Vector3(10.5, 12.5, 13.5)
	camera_size_target = 18.0
	player.teleport(Vector3(0.0, 0.05, 10.0))
	rose_frame_open = false
	aperture_current = 0.49
	aperture_target = 0.49
	frame_width_current = 0.5625
	frame_width_target = 0.5625
	tunnel_darkness_target = 0.0

	_add_box(environment_root, "Lawn", Vector3(0, -0.28, 0), Vector3(20, 0.5, 25), Color("41464a"), true)
	_add_box(environment_root, "ClubFacade", Vector3(0, 2.5, -10.0), Vector3(13, 5.5, 1.2), Color("4d4b48"), true)
	_add_box(environment_root, "ClubDoor", Vector3(0, 1.35, -9.25), Vector3(2.0, 2.7, 0.25), Color("242328"), false)
	_add_label3d(environment_root, "OPHION CLUB", Vector3(0, 4.55, -9.3), PAPER, 34)

	for x in [-8.6, 8.6]:
		_add_box(environment_root, "BoundaryHedge", Vector3(x, 0.75, 0), Vector3(1.0, 1.6, 22), Color("303738"), true)
	for z in [-5.9, 3.0]:
		_add_box(environment_root, "RoseHedge", Vector3(0, 0.62, z), Vector3(12.5, 1.25, 0.75), Color("303638"), true)
	for x in [-5.2, -3.4, -1.6, 0.2, 2.0, 3.8, 5.6]:
		_add_rose_bush(Vector3(x, 0.65, -5.25))
	for x in [-5.0, -2.8, -0.6, 1.6, 3.8, 5.4]:
		_add_rose_bush(Vector3(x, 0.65, 2.35))

	var body_positions := [
		Vector3(-3.8, 0.18, -2.8), Vector3(-2.3, 0.18, -3.7), Vector3(-0.8, 0.18, -4.1),
		Vector3(0.9, 0.18, -4.05), Vector3(2.5, 0.18, -3.55), Vector3(3.9, 0.18, -2.65)
	]
	for body_position in body_positions:
		_build_dummy(environment_root, body_position, true, 0.94, Color("55565a"))
	_build_dummy(environment_root, Vector3(-6.4, 0.16, 0.5), true, 0.9, Color("4b4d52"))
	_build_dummy(environment_root, Vector3(-5.45, 0.13, 0.9), true, 0.58, Color("595a5e"))

	_add_interactable(Vector3(-0.8, 0.8, -3.9), "Examine the wounds", "A precise hole above the bridge of each nose. No scorching. No corresponding wound behind the skull.", "impossible_wound")
	_add_interactable(Vector3(4.95, 0.65, -5.0), "Recover the knife", "A good boning knife, wiped too carefully, tucked beneath the hedge root.", "clean_knife", "Kessler's boning knife")
	_add_interactable(Vector3(-5.9, 0.65, 0.55), "Examine the two outsiders", "A woman and a young boy, placed outside the careful half-circle. The first report has already called them transients.", "unnamed_victims")
	_add_interactable(Vector3(-3.35, 0.75, -2.55), "Take the club token", "A silver token marked OPHION. The same hard edge presses through five other coat pockets.", "club_token", "Ophion token")
	_add_interactable(Vector3(6.9, 0.9, -7.1), "Leave for Corwin's room", "The scene will remain. The case will not build itself.", "", "", "to_investigation")
	_show_toast("Approach the rose garden. Record at least three pieces of evidence before leaving.", 4.0)

func _build_investigation_room() -> void:
	slice_label.text = "CHAPTER ONE // SLICE II — THE CASE TAKES SHAPE"
	world_environment.environment.background_color = Color("111319")
	world_environment.environment.fog_density = 0.0
	camera_offset = Vector3(8.2, 9.4, 10.4)
	camera_size_target = 12.5
	player.teleport(Vector3(0.0, 0.05, 5.1))
	rose_frame_open = true
	aperture_target = 2.0
	frame_width_target = 1.0
	tunnel_darkness_target = 0.0
	GameState.add_inventory("Walter's flask")

	_add_box(environment_root, "Floor", Vector3(0, -0.25, 0), Vector3(13, 0.45, 13), Color("353538"), true)
	_add_box(environment_root, "BackWall", Vector3(0, 2.3, -6.1), Vector3(13, 4.8, 0.45), Color("55514b"), true)
	_add_box(environment_root, "LeftWall", Vector3(-6.3, 2.3, 0), Vector3(0.45, 4.8, 12), Color("4b4946"), true)
	_add_box(environment_root, "RightWall", Vector3(6.3, 2.3, 0), Vector3(0.45, 4.8, 12), Color("4b4946"), true)
	_add_box(environment_root, "Desk", Vector3(1.4, 0.62, 0.8), Vector3(3.0, 1.0, 1.4), Color("403c39"), true)
	_add_box(environment_root, "CaseBoard", Vector3(0, 2.35, -5.76), Vector3(6.5, 3.5, 0.16), Color("755f48"), false)
	for card_position in [Vector3(-2.2, 2.8, -5.64), Vector3(-0.65, 1.7, -5.64), Vector3(1.1, 2.7, -5.64), Vector3(2.2, 1.55, -5.64)]:
		_add_box(environment_root, "EvidenceCard", card_position, Vector3(1.15, 0.72, 0.05), PAPER, false)
	_add_box(environment_root, "RedThreadA", Vector3(-1.43, 2.25, -5.58), Vector3(1.6, 0.035, 0.035), CRIMSON, false)
	_add_box(environment_root, "RedThreadB", Vector3(0.25, 2.25, -5.58), Vector3(1.9, 0.035, 0.035), CRIMSON, false)

	var witness := _build_dummy(environment_root, Vector3(-3.7, 0.0, 0.2), false, 0.9, Color("606064"))
	_add_label3d(witness, "MRS. VALE", Vector3(0, 2.25, 0), PAPER, 24)
	_add_interactable(Vector3(-3.7, 1.0, 0.2), "Question Mrs. Vale", "She fed the woman and boy more than once. They were not rootless, and they were not unknown.", "boardinghouse_account")
	_add_interactable(Vector3(1.4, 1.4, 0.8), "Read the recovered ledger", "Six names repeat on the final Thursday of every month. The meetings continue for two years.", "meeting_ledger")
	_add_interactable(Vector3(3.9, 1.05, -4.9), "Compare the floor plan", "The recorded foundation ends twelve feet before the service corridor does.", "service_plan")
	_add_interactable(Vector3(0.0, 1.9, -5.25), "Open the evidence board", "The case exists in the lines between facts, not in any single card.", "", "", "open_case")
	_add_interactable(Vector3(5.7, 1.0, -3.9), "Follow the service corridor", "A boarded service door waits beyond the pantry.", "", "", "to_tunnel")
	_show_toast("Question the witness, inspect the room, then use [TAB] to link two facts.", 4.0)

func _build_tunnel() -> void:
	slice_label.text = "CHAPTER ONE // SLICE III — THE DESCENT"
	world_environment.environment.background_color = Color("07090c")
	world_environment.environment.fog_density = 0.028
	camera_offset = Vector3(8.0, 9.0, 10.0)
	camera_size_target = 13.0
	player.teleport(tunnel_start)
	rose_frame_open = true
	aperture_target = 2.0
	frame_width_target = 1.0
	tunnel_darkness_target = 0.22
	GameState.add_inventory("Walter's flask")

	_add_box(environment_root, "TunnelFloor", Vector3(0, -0.35, -8), Vector3(10, 0.55, 36), Color("202327"), true)
	_add_box(environment_root, "LeftRock", Vector3(-5.0, 2.1, -8), Vector3(1.2, 5.0, 36), Color("2b2e31"), true)
	_add_box(environment_root, "RightRock", Vector3(5.0, 2.1, -8), Vector3(1.2, 5.0, 36), Color("292c30"), true)
	for z in [6.0, 1.0, -4.0, -9.0, -14.0, -19.0, -24.0]:
		_add_box(environment_root, "CeilingRib", Vector3(0, 3.5, z), Vector3(9.2, 0.55, 0.75), Color("34363a"), false)
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(-3.6 if int(abs(z)) % 2 == 0 else 3.6, 2.25, z)
		lamp.light_color = Color("b9aa87")
		lamp.light_energy = 1.3
		lamp.omni_range = 5.0
		lamp.shadow_enabled = true
		environment_root.add_child(lamp)

	_add_box(environment_root, "CoverA", Vector3(0.8, 1.1, -7.7), Vector3(2.1, 2.5, 2.2), Color("3a3b3d"), true)
	_add_box(environment_root, "CoverB", Vector3(-1.25, 1.0, -13.2), Vector3(2.4, 2.2, 2.0), Color("383a3d"), true)
	_add_box(environment_root, "SideWallA", Vector3(2.8, 1.0, -10.4), Vector3(0.8, 2.1, 6.5), Color("323437"), true)
	_add_box(environment_root, "SideWallB", Vector3(-3.0, 0.9, -17.0), Vector3(0.9, 2.0, 5.5), Color("323437"), true)

	flask_prop = _add_cylinder(environment_root, "Flask", Vector3(1.3, 0.45, 3.4), 0.22, 0.62, Color("666b6d"), false)
	_add_label3d(environment_root, "THE PASSAGE SHOULD NOT FIT BENEATH THE ESTATE", Vector3(0, 2.8, 5.0), Color(PAPER, 0.7), 20)

	var whistle = _add_interactable(Vector3(-3.6, 0.38, -3.5), "Examine the reflected edge", "A corroded police whistle catches light that does not reach the surrounding silt.", "corroded_whistle")
	reveal_nodes.append({"node": whistle, "threshold": 2})
	for reveal_position in [Vector3(-4.2, 0.05, -6.0), Vector3(-4.0, 0.05, -10.0), Vector3(3.95, 0.05, -15.0), Vector3(4.1, 0.05, -19.0)]:
		var edge := _add_box(environment_root, "PerceptionEdge", reveal_position, Vector3(0.12, 0.08, 2.6), IMPOSSIBLE_BLUE, false)
		reveal_nodes.append({"node": edge, "threshold": 3})

	_build_tunnel_hazard()
	_add_interactable(Vector3(0.0, 0.9, -24.1), "Accept that the passage continues", "Walter cannot progress farther. What he has already seen will follow him back to the completed case.", "", "", "finish_demo")
	_show_toast("The flask is still in Walter's coat. Read the reflected edges; the center route is not the safe route.", 4.5)

func _build_tunnel_hazard() -> void:
	hazard = HazardScript.new()
	hazard.name = "FullyTransformedCultist"
	hazard.collision_layer = 8
	hazard.collision_mask = 1
	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.45
	shape.height = 1.7
	collision.shape = shape
	collision.position.y = 0.82
	hazard.add_child(collision)
	var model := _build_dummy(hazard, Vector3.ZERO, false, 1.04, Color("43464b"))
	model.scale = Vector3(1.18, 0.92, 1.08)
	hazard.model_root = model
	hazard.position = Vector3(-2.0, 0.05, -11.4)
	hazard.configure(player, Vector3(-2.0, 0.05, -11.4), Vector3(2.0, 0.05, -11.4))
	hazard.player_caught.connect(_on_hazard_caught)
	environment_root.add_child(hazard)
	_add_label3d(hazard, "…breath catches…", Vector3(0, 2.45, 0), Color(PAPER, 0.56), 20)

func _on_player_interacted(target, result: Dictionary) -> void:
	if not result.get("ok", false):
		return
	var action_name: String = result.get("action", "")
	match action_name:
		"to_investigation":
			if GameState.discovered.size() < 3:
				_show_toast("Corwin has not looked long enough. Record at least three facts.", 3.0)
				return
			_show_toast(result.get("message", ""), 1.0)
			_build_slice(1)
		"open_case":
			_toggle_case_ui(true)
		"to_tunnel":
			if not GameState.has_evidence("boardinghouse_account") or GameState.links.is_empty():
				_show_toast("The corridor is only an anomaly until a witness and a linked theory give Corwin reason to follow it.", 3.4)
				return
			_build_slice(2)
		"finish_demo":
			player.active = false
			end_panel.visible = true
			GameState.add_instability(0.12)
		_:
			_show_toast(result.get("message", "Recorded."), 4.2)

func _on_hazard_caught() -> void:
	player.active = false
	GameState.add_instability(0.08)
	_show_toast("The thing reaches Walter. The passage returns him to its threshold.", 2.2)
	await get_tree().create_timer(1.15).timeout
	if GameState.current_slice == 2 and hazard != null:
		player.teleport(tunnel_start)
		hazard.reset_hazard()
		player.active = not case_panel.visible

func _spill_flask() -> void:
	tunnel_spill_done = true
	GameState.remove_inventory("Walter's flask")
	GameState.add_instability(0.11)
	_show_toast("The flask tears loose and disappears below. Nothing about its contents betrayed him; the ground simply took it.", 4.4)
	if flask_prop != null:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(flask_prop, "position:y", -5.0, 1.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(flask_prop, "rotation:z", 8.0, 1.25)

func _toggle_case_ui(force_open = null) -> void:
	if force_open == null:
		case_panel.visible = not case_panel.visible
	else:
		case_panel.visible = bool(force_open)
	player.active = not case_panel.visible and not end_panel.visible
	if case_panel.visible:
		_refresh_case_ui()
		prompt_label.text = ""

func _refresh_case_ui() -> void:
	if evidence_list == null:
		return
	stats_label.text = "STRENGTH  %d          PERCEPTION  %d" % [GameState.strength, GameState.perception]
	inventory_label.text = "CARRIED: %s" % ("nothing" if GameState.inventory.is_empty() else ", ".join(GameState.inventory))
	for child in evidence_list.get_children():
		child.queue_free()
	if GameState.discovered.is_empty():
		var empty := Label.new()
		empty.text = "No facts recorded."
		empty.add_theme_color_override("font_color", Color(PAPER, 0.55))
		evidence_list.add_child(empty)
	else:
		for evidence_id in GameState.discovered:
			var entry := GameState.evidence_entry(evidence_id)
			var button := Button.new()
			button.text = "%s\n%s" % [entry.get("title", evidence_id), entry.get("fact", "")]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.toggle_mode = true
			button.button_pressed = selected_evidence.has(evidence_id)
			button.custom_minimum_size = Vector2(0, 48)
			button.pressed.connect(_on_evidence_selected.bind(evidence_id))
			evidence_list.add_child(button)
	_update_selected_label()
	if GameState.links.is_empty():
		links_label.text = "No connections recorded."
	else:
		var text := "RECORDED CONNECTIONS\n\n"
		for link_id in GameState.links:
			var link: Dictionary = GameState.link_summaries[link_id]
			text += "• %s\n%s\n\n" % [link["title"], link["summary"]]
		links_label.text = text

func _on_evidence_selected(evidence_id: String) -> void:
	if selected_evidence.has(evidence_id):
		selected_evidence.erase(evidence_id)
	elif selected_evidence.size() < 2:
		selected_evidence.append(evidence_id)
	else:
		selected_evidence.pop_front()
		selected_evidence.append(evidence_id)
	_refresh_case_ui()

func _update_selected_label() -> void:
	if selected_evidence.is_empty():
		selected_label.text = "Select two verified facts."
	else:
		var names: Array[String] = []
		for evidence_id in selected_evidence:
			names.append(GameState.evidence_entry(evidence_id).get("title", evidence_id))
		selected_label.text = "  ↳  ".join(names)

func _attempt_selected_link() -> void:
	if selected_evidence.size() != 2:
		_show_toast("Two facts are required to draw a line.", 2.5)
		return
	var result := GameState.try_link(selected_evidence[0], selected_evidence[1])
	selected_evidence.clear()
	_show_toast(result.get("message", ""), 3.2)
	_refresh_case_ui()

func _on_state_changed() -> void:
	_refresh_case_ui()

func _on_prompt_changed(text: String) -> void:
	if case_panel != null and not case_panel.visible:
		prompt_label.text = text

func _show_toast(message: String, duration := 3.5) -> void:
	if message.is_empty() or toast_panel == null:
		return
	toast_generation += 1
	var generation := toast_generation
	toast_label.text = message
	toast_panel.visible = true
	_hide_toast_later(generation, duration)

func _hide_toast_later(generation: int, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if generation == toast_generation:
		toast_panel.visible = false

func _update_reveal_nodes() -> void:
	for record in reveal_nodes:
		var node: Node3D = record.get("node")
		if is_instance_valid(node):
			node.visible = GameState.perception >= int(record.get("threshold", 1))

func _clear_environment() -> void:
	reveal_nodes.clear()
	for child in environment_root.get_children():
		child.free()

func _add_interactable(
	position: Vector3,
	title: String,
	description: String,
	evidence_id := "",
	inventory_id := "",
	action := ""
):
	var area = InteractableScript.new()
	area.name = title.validate_node_name()
	area.position = position
	area.configure(title, description, evidence_id, inventory_id, action)
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.72
	collision.shape = shape
	area.add_child(collision)
	var marker := MeshInstance3D.new()
	var marker_mesh := SphereMesh.new()
	marker_mesh.radius = 0.075
	marker_mesh.height = 0.15
	marker.mesh = marker_mesh
	marker.material_override = _material(Color("d7d1bd"), true, Color("d7d1bd"))
	marker.position.y = 0.45
	area.add_child(marker)
	environment_root.add_child(area)
	return area

func _add_rose_bush(position: Vector3) -> void:
	_add_cylinder(environment_root, "RoseStem", position, 0.08, 0.9, Color("353a38"), false)
	for offset in [Vector3(-0.25, 0.38, 0), Vector3(0.18, 0.52, 0.1), Vector3(0.0, 0.66, -0.12)]:
		_add_sphere(environment_root, "Rose", position + offset, 0.18, CRIMSON)

func _build_dummy(parent: Node, position: Vector3, fallen: bool, scale_factor: float, color: Color) -> Node3D:
	var root := Node3D.new()
	root.position = position
	root.scale = Vector3.ONE * scale_factor
	parent.add_child(root)
	var torso := _add_box(root, "Torso", Vector3(0, 1.22, 0), Vector3(0.62, 0.9, 0.35), color, false)
	_add_sphere(root, "Head", Vector3(0, 1.96, 0), 0.28, Color(color, 1.0).lightened(0.11))
	_add_cylinder(root, "LeftArm", Vector3(-0.43, 1.22, 0), 0.10, 0.82, color.darkened(0.06), false).rotation_degrees.z = -8
	_add_cylinder(root, "RightArm", Vector3(0.43, 1.22, 0), 0.10, 0.82, color.darkened(0.06), false).rotation_degrees.z = 8
	_add_cylinder(root, "LeftLeg", Vector3(-0.18, 0.46, 0), 0.12, 0.95, color.darkened(0.12), false)
	_add_cylinder(root, "RightLeg", Vector3(0.18, 0.46, 0), 0.12, 0.95, color.darkened(0.12), false)
	if fallen:
		root.rotation_degrees = Vector3(0, randf_range(-35.0, 35.0), 88.0)
		torso.position.y = 1.1
	return root

func _add_box(parent: Node, name_value: String, position: Vector3, size: Vector3, color: Color, collidable: bool) -> Node3D:
	var root := Node3D.new()
	root.name = name_value
	root.position = position
	parent.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	root.add_child(mesh_instance)
	if collidable:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision.shape = shape
		body.add_child(collision)
		root.add_child(body)
	return root

func _add_cylinder(parent: Node, name_value: String, position: Vector3, radius: float, height: float, color: Color, collidable: bool) -> Node3D:
	var root := Node3D.new()
	root.name = name_value
	root.position = position
	parent.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	root.add_child(mesh_instance)
	if collidable:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision.shape = shape
		body.add_child(collision)
		root.add_child(body)
	return root

func _add_sphere(parent: Node, name_value: String, position: Vector3, radius: float, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = name_value
	root.position = position
	parent.add_child(root)
	var mesh_instance := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 6
	mesh_instance.mesh = mesh
	mesh_instance.material_override = _material(color)
	root.add_child(mesh_instance)
	return root

func _add_label3d(parent: Node, text: String, position: Vector3, color: Color, font_size: int) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.position = position
	label.font_size = font_size
	label.modulate = color
	label.outline_size = 5
	label.no_depth_test = true
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)
	return label

func _material(color: Color, emission := false, emission_color := Color.WHITE) -> StandardMaterial3D:
	var key := "%s_%s_%s" % [color.to_html(true), emission, emission_color.to_html(true)]
	if material_cache.has(key):
		return material_cache[key]
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	if emission:
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = 1.6
	material_cache[key] = material
	return material

func _panel_style(background: Color, border: Color, width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style
