extends CanvasLayer

const PAPER = Color("d6d2bd")
const MUTED = Color("a6aa9b")
var case_palette := false
var settings: Dictionary
var ui: Control
var modal: Control
var content: VBoxContainer
var prompt: Label
var location_label: Label
var toast_label: Label
var hazard_caption: Label
var serif: SystemFont
var sans: SystemFont

func _ready() -> void:
	serif = SystemFont.new()
	serif.font_names = PackedStringArray(["Georgia","Times New Roman"])
	sans = SystemFont.new()
	sans.font_names = PackedStringArray(["Segoe UI","Arial"])
	layer=30
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)
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
	hazard_caption = _label("",21,false)
	hazard_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hazard_caption.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hazard_caption.offset_top = 154
	hazard_caption.offset_bottom = 214
	ui.add_child(hazard_caption)

func _label(text:String, size:int = 24, literary:bool = true) -> Label:
	var l = Label.new()
	l.text = text
	l.set_meta("base_font_size",size)
	l.add_theme_font_override("font",serif if literary else sans)
	l.add_theme_font_size_override("font_size",int(size*float(settings.text_scale)))
	l.add_theme_color_override("font_color",Color("302519") if case_palette else PAPER)
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
	b.set_meta("base_font_size",18)
	b.custom_minimum_size.y = 48
	b.add_theme_font_override("font",sans)
	b.add_theme_font_size_override("font_size",int(18*float(settings.text_scale)))
	b.add_theme_color_override("font_color",Color("302519") if case_palette else PAPER)
	b.add_theme_color_override("font_hover_color",Color.WHITE)
	b.add_theme_stylebox_override("normal",_style(Color("18201b")))
	b.add_theme_stylebox_override("hover",_style(Color("303a2e"),PAPER))
	b.add_theme_stylebox_override("pressed",_style(Color("3d4938"),PAPER))
	b.add_theme_stylebox_override("focus",_style(Color(0,0,0,0),PAPER))
	if case_palette:
		b.add_theme_color_override("font_color",Color("352719"))
		b.add_theme_color_override("font_hover_color",Color("251910"))
		b.add_theme_color_override("font_pressed_color",Color("251910"))
		b.add_theme_color_override("font_focus_color",Color("251910"))
		b.add_theme_stylebox_override("normal",_style(Color("e5cf9e"),Color("98713d")))
		b.add_theme_stylebox_override("hover",_style(Color("f5e5bb"),Color("974735")))
		b.add_theme_stylebox_override("pressed",_style(Color("c9ad79"),Color("74392f")))
		b.add_theme_stylebox_override("focus",_style(Color(0,0,0,0),Color("9b382d")))
	b.pressed.connect(callback)
	if parent == null: content.add_child(b)
	else: parent.add_child(b)
	return b

func _panel(kind:String,heading:String,kicker:String = "",wide:bool = false) -> void:
	if is_instance_valid(modal):
		ui.remove_child(modal)
		modal.queue_free()
	case_palette = kind in ["board","notebook","journal","fact","examine"]
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
	if kind == "examine":
		panel.offset_left = 40
		panel.offset_right = -40
		panel.offset_top = 32
		panel.offset_bottom = -32
		var wood = _style(Color("241609"),Color("140b04"))
		wood.set_border_width_all(14)
		wood.set_corner_radius_all(2)
		panel.add_theme_stylebox_override("panel",wood)
	elif case_palette:
		panel.offset_left = 40
		panel.offset_right = -40
		panel.offset_top = 32
		panel.offset_bottom = -32
		panel.add_theme_stylebox_override("panel",_style(Color("ead9b4"),Color("976838")))
	modal.add_child(panel)
	# Object-examination frames get a brass inlay strip between the wood and the parchment.
	var inner: Container = panel
	if kind == "examine":
		var brass_margin = MarginContainer.new()
		for side in ["left","right","top","bottom"]: brass_margin.add_theme_constant_override("margin_"+side,8)
		panel.add_child(brass_margin)
		var brass = PanelContainer.new()
		var brass_style = _style(Color("d8c39a"),Color("b08d3e"))
		brass_style.set_border_width_all(3)
		brass.add_theme_stylebox_override("panel",brass_style)
		brass_margin.add_child(brass)
		inner = brass
	var scroll = ScrollContainer.new()
	inner.add_child(scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",18)
	scroll.add_child(content)
	if not kicker.is_empty():
		var k = _label(kicker,13,false)
		k.add_theme_color_override("font_color",Color("745138") if case_palette else MUTED)
		content.add_child(k)
	content.add_child(_label(heading,38))
	var sep = HSeparator.new()
	content.add_child(sep)
	prompt.visible = false
	toast_label.visible = false
	location_label.visible = false

func _paragraph(text:String,size:int = 23) -> void:
	content.add_child(_label(text,size))

func _focus_first() -> void:
	for b in content.find_children("*","Button",true,false):
		if not b.disabled:
			b.grab_focus()
			return

func close() -> void:
	if is_instance_valid(modal): modal.queue_free()
	modal=null
	case_palette=false
	prompt.visible=true
	toast_label.visible=true
	location_label.visible=true

func apply_settings() -> void:
	for control in ui.find_children("*","Control",true,false):
		if control.has_meta("base_font_size"):
			control.add_theme_font_size_override("font_size",int(float(control.get_meta("base_font_size"))*float(settings.text_scale)))
