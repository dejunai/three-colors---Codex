extends Control

signal item_pressed(item: String)

const INK = Color("302519")
const MUTED = Color("785f42")
const POLICE = Color("3f4b43")
const PLAIN = Color("685a4b")
const TROUSERS = Color("343b39")
const LEATHER = Color("3c281b")
const BRASS = Color("b18437")

var coat := "Police coat"
var badge_visible := true
var badge_lost := false
var flask_spilled := false
var flask_level := 3
var ammo := 6
var carries_notebook := true

func configure(state) -> void:
	name = "WalterPaperDoll"
	coat = state.coat
	badge_lost = state.dialogue_state.flag("badge_lost")
	badge_visible = coat == "Police coat" and not badge_lost
	flask_spilled = state.flask_spilled
	flask_level = state.flask
	ammo = state.ammo
	custom_minimum_size = Vector2(280, 300)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_PASS
	_add_slot("COAT", Rect2(0, 69, 72, 34), "coat")
	_add_slot("BADGE", Rect2(208, 69, 72, 34), "badge")
	_add_slot("NOTEBOOK", Rect2(0, 116, 86, 34), "notebook")
	_add_slot("REVOLVER", Rect2(194, 139, 86, 34), "revolver")
	_add_slot("FLASK", Rect2(0, 166, 72, 34), "flask")
	_add_slot("BOOTS", Rect2(208, 246, 72, 34), "boots")
	queue_redraw()

func _slot_style(border: Color, fill: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style

func _add_slot(label: String, rect: Rect2, item: String) -> void:
	var button = Button.new()
	button.name = item.capitalize() + "Slot"
	button.text = label
	button.tooltip_text = "Inspect " + item
	button.position = rect.position
	button.size = rect.size
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_stylebox_override("normal", _slot_style(Color("a88756"), Color("e4d2a8")))
	button.add_theme_stylebox_override("hover", _slot_style(Color("974735"), Color("f3e2ba")))
	button.add_theme_stylebox_override("pressed", _slot_style(Color("74392f"), Color("ceb17c")))
	button.add_theme_stylebox_override("focus", _slot_style(Color("9b382d"), Color("f3e2ba")))
	button.pressed.connect(func(): item_pressed.emit(item))
	add_child(button)

func _draw() -> void:
	var coat_color = POLICE if coat == "Police coat" else PLAIN
	# Callout rules connect the controls to the carried object without covering it.
	for line in [
		[Vector2(72, 86), Vector2(108, 102)],
		[Vector2(208, 86), Vector2(158, 96)],
		[Vector2(86, 133), Vector2(121, 121)],
		[Vector2(194, 156), Vector2(169, 163)],
		[Vector2(72, 183), Vector2(107, 164)],
		[Vector2(208, 263), Vector2(157, 264)]
	]: draw_line(line[0], line[1], MUTED, 1.2, true)

	# Hat and head.
	draw_circle(Vector2(140, 42), 18, Color("d3c3a2"))
	draw_rect(Rect2(120, 18, 40, 10), LEATHER, true)
	draw_polygon(PackedVector2Array([Vector2(125,18),Vector2(130,5),Vector2(153,5),Vector2(158,18)]), PackedColorArray([LEATHER]))
	draw_line(Vector2(114, 28), Vector2(166, 28), LEATHER, 5, true)

	# Coat, lapels, arms and belt.
	draw_polygon(PackedVector2Array([Vector2(113,65),Vector2(167,65),Vector2(178,172),Vector2(102,172)]), PackedColorArray([coat_color]))
	draw_polygon(PackedVector2Array([Vector2(113,70),Vector2(88,82),Vector2(92,166),Vector2(110,162)]), PackedColorArray([coat_color]))
	draw_polygon(PackedVector2Array([Vector2(167,70),Vector2(192,82),Vector2(188,166),Vector2(170,162)]), PackedColorArray([coat_color]))
	draw_line(Vector2(140, 68), Vector2(140, 170), Color("29221c"), 2, true)
	draw_polygon(PackedVector2Array([Vector2(119,68),Vector2(140,103),Vector2(134,121)]), PackedColorArray([Color("c5b38f")]))
	draw_polygon(PackedVector2Array([Vector2(161,68),Vector2(140,103),Vector2(146,121)]), PackedColorArray([Color("c5b38f")]))
	draw_rect(Rect2(102, 151, 76, 8), LEATHER, true)

	# Notebook pocket, badge, holster/revolver and flask or severed strap.
	draw_rect(Rect2(116, 111, 20, 28), Color("8a6a3c"), true)
	draw_line(Vector2(118, 115), Vector2(134, 115), Color("d8c69a"), 2, true)
	if badge_visible:
		draw_polygon(PackedVector2Array([Vector2(153,91),Vector2(162,94),Vector2(160,106),Vector2(153,111),Vector2(146,106),Vector2(144,94)]), PackedColorArray([BRASS]))
	draw_rect(Rect2(164, 151, 17, 35), LEATHER, true)
	draw_rect(Rect2(166, 145, 5, 19), Color("77756c"), true)
	for round_index in mini(ammo, 6):
		draw_circle(Vector2(107 + round_index * 7, 156), 2, BRASS)
	if flask_spilled:
		draw_line(Vector2(104,153), Vector2(98,179), LEATHER, 3, true)
		draw_line(Vector2(98,179), Vector2(103,185), LEATHER, 2, true)
	else:
		draw_rect(Rect2(95, 154, 17, 31), Color("8b8c83"), true)
		draw_rect(Rect2(99, 149, 9, 6), Color("565951"), true)
		var fill_height = 20.0 * clampf(float(flask_level) / 3.0, 0.0, 1.0)
		if fill_height > 0: draw_rect(Rect2(98, 181 - fill_height, 11, fill_height), Color("9a6334"), true)

	# Trousers and worn leather boots.
	draw_polygon(PackedVector2Array([Vector2(108,172),Vector2(138,172),Vector2(132,251),Vector2(105,251)]), PackedColorArray([TROUSERS]))
	draw_polygon(PackedVector2Array([Vector2(142,172),Vector2(172,172),Vector2(175,251),Vector2(148,251)]), PackedColorArray([TROUSERS]))
	draw_polygon(PackedVector2Array([Vector2(104,246),Vector2(133,246),Vector2(134,271),Vector2(96,271)]), PackedColorArray([LEATHER]))
	draw_polygon(PackedVector2Array([Vector2(147,246),Vector2(176,246),Vector2(184,271),Vector2(146,271)]), PackedColorArray([LEATHER]))

