extends CanvasLayer

# Full-bleed photographic title/prologue presentation, visually separate from
# chapter_interface.gd's dark in-game modal system on purpose: title/prologue
# use real photo backgrounds, a gradient scrim, and three bundled serif faces,
# none of which the rest of the UI wants. Only chapter_one.gd's _title() and
# _new_game()'s prologue sequence use this; nothing else should reference it.

const SHADER = preload("res://shaders/prologue_photo.gdshader")

const FONT_DISPLAY = preload("res://assets/fonts/CormorantGaramond-SemiBold.ttf")
const FONT_DISPLAY_MEDIUM = preload("res://assets/fonts/CormorantGaramond-Medium.ttf")
const FONT_DISPLAY_ITALIC = preload("res://assets/fonts/CormorantGaramond-MediumItalic.ttf")
const FONT_BODY = preload("res://assets/fonts/EBGaramond-Regular.ttf")
const FONT_BODY_MEDIUM = preload("res://assets/fonts/EBGaramond-Medium.ttf")
const FONT_BODY_ITALIC = preload("res://assets/fonts/EBGaramond-Italic.ttf")
const FONT_KICKER = preload("res://assets/fonts/SpecialElite-Regular.ttf")
const MUSIC = preload("res://assets/audio/civic-reel.wav")

const INK = Color("0a0908")
const PAPER = Color("e8dcc8")
const PAPER_2 = Color("d8cbb4")
const BONE = Color("f3ead8")
const FOG = Color("8a8680")
const LANTERN = Color("c4a06a")
const MUTE = Color("6e675c")

var root: Control
var music: AudioStreamPlayer

func _ready() -> void:
	layer = 35
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	music = AudioStreamPlayer.new()
	music.stream = MUSIC
	music.volume_db = -8
	music.bus = "Master"
	add_child(music)

func _clear() -> void:
	for child in root.get_children(): child.queue_free()

func _tracked_font(base: FontFile, glyph_spacing: int) -> FontVariation:
	var variation = FontVariation.new()
	variation.base_font = base
	variation.spacing_glyph = glyph_spacing
	return variation

func _kicker_label(text: String) -> Label:
	var l = Label.new()
	l.text = text.to_upper()
	l.add_theme_font_override("font", _tracked_font(FONT_KICKER, 3))
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", LANTERN)
	return l

func _title_label(text: String, size: int = 52) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_DISPLAY)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", PAPER)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _body_label(text: String, color: Color = PAPER_2, size: int = 20) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_BODY)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 620
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return l

func _flavor_label(text: String) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_override("font", FONT_DISPLAY_ITALIC)
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", FOG)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func button(text: String, callback: Callable, ghost: bool = false) -> Button:
	var b = Button.new()
	b.text = text
	b.add_theme_font_override("font", _tracked_font(FONT_DISPLAY_MEDIUM, 1))
	b.add_theme_font_size_override("font_size", 19)
	b.custom_minimum_size.y = 48
	var normal = StyleBoxFlat.new()
	normal.set_corner_radius_all(10)
	normal.content_margin_left = 26
	normal.content_margin_right = 26
	normal.content_margin_top = 10
	normal.content_margin_bottom = 10
	var hover = normal.duplicate()
	var pressed = normal.duplicate()
	if ghost:
		normal.bg_color = Color(0, 0, 0, 0)
		normal.border_color = BONE
		normal.set_border_width_all(1)
		hover.bg_color = Color(BONE.r, BONE.g, BONE.b, 0.1)
		hover.border_color = BONE
		hover.set_border_width_all(1)
		pressed.bg_color = Color(BONE.r, BONE.g, BONE.b, 0.18)
		pressed.border_color = BONE
		pressed.set_border_width_all(1)
		b.add_theme_color_override("font_color", BONE)
		b.add_theme_color_override("font_hover_color", LANTERN)
		b.add_theme_color_override("font_pressed_color", LANTERN)
	else:
		normal.bg_color = BONE
		hover.bg_color = PAPER
		pressed.bg_color = PAPER_2
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_hover_color", INK)
		b.add_theme_color_override("font_pressed_color", INK)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), LANTERN))
	b.pressed.connect(callback)
	return b

func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(10)
	return s

# scrim: ink at 35% opacity at top, ramping to 82% by 70% down, held to the bottom.
func _scrim() -> TextureRect:
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([
		Color(INK.r, INK.g, INK.b, 0.35),
		Color(INK.r, INK.g, INK.b, 0.82),
		Color(INK.r, INK.g, INK.b, 0.82)])
	gradient.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
	var texture = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var rect = TextureRect.new()
	rect.texture = texture
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return rect

func _background(image: Texture2D) -> TextureRect:
	var bg = TextureRect.new()
	bg.texture = image
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material = ShaderMaterial.new()
	material.shader = SHADER
	bg.material = material
	return bg

# Prologue slide: kicker/title/body over a photo, a single ghost "Continue" advances.
func show_slide(image: Texture2D, kicker: String, heading: String, body: String, after: Callable) -> void:
	_clear()
	if not music.playing: music.play()
	root.add_child(_background(image))
	root.add_child(_scrim())
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 72)
	root.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_vertical = Control.SIZE_SHRINK_END
	margin.add_child(vbox)
	if not kicker.is_empty(): vbox.add_child(_kicker_label(kicker))
	vbox.add_child(_title_label(heading, 44))
	vbox.add_child(_body_label(body))
	var spacer = Control.new()
	spacer.custom_minimum_size.y = 12
	vbox.add_child(spacer)
	vbox.add_child(button("Continue", after, true))
	_focus_first()

# Title screen: tagline over club-night.jpg, primary/ghost buttons in a row.
func show_title(image: Texture2D, heading: String, tagline: String, flavor: String, buttons: Array) -> void:
	_clear()
	if not music.playing: music.play()
	root.add_child(_background(image))
	root.add_child(_scrim())
	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 72)
	root.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.size_flags_vertical = Control.SIZE_SHRINK_END
	margin.add_child(vbox)
	vbox.add_child(_kicker_label("Widow's Bight Historical Society · A Civic Reel"))
	vbox.add_child(_title_label(heading, 60))
	vbox.add_child(_body_label(tagline, PAPER, 21))
	vbox.add_child(_flavor_label(flavor))
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size.y = 10
	vbox.add_child(top_spacer)
	vbox.add_child(row)
	for spec in buttons:
		row.add_child(button(spec[0], spec[1], spec.size() > 2 and spec[2]))
	_focus_first()

func _focus_first() -> void:
	for b in root.find_children("*", "Button", true, false):
		if not b.disabled:
			b.grab_focus()
			return

func stop_music() -> void:
	if music.playing: music.stop()

func hide_all() -> void:
	_clear()
