extends Control

# Presentation only. Positions, threads and pins share this scrolling Control's
# coordinates. Never writes evidence, links, Perception or saves.
var thread_layer: Control
var cards: Dictionary = {}
var connections: Array = []
var card_height := 250.0

func configure(view:CanvasLayer,evidence:Array,facts:Dictionary,confirmed:Array,links:Dictionary,sources:Dictionary,select:Callable) -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clip_contents = true
	card_height = 250.0 * maxf(1.0,float(view.settings.text_scale))
	for id in evidence:
		if not facts.has(id) or id == "exemption": continue
		var card = Button.new()
		card.text = str(facts[id][0])
		card.tooltip_text = str(facts[id][1])
		card.add_theme_font_override("font",view.serif)
		card.add_theme_font_size_override("font_size",int(21*float(view.settings.text_scale)))
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_theme_color_override("font_color",Color.TRANSPARENT)
		card.add_theme_color_override("font_hover_color",Color.TRANSPARENT)
		card.add_theme_color_override("font_pressed_color",Color.TRANSPARENT)
		card.add_theme_color_override("font_focus_color",Color.TRANSPARENT)
		for mode in ["normal","hover","pressed"]:
			var paper = view._style(Color("efdfb4") if mode == "normal" else Color("fff0c9"),Color("aa8449"))
			paper.content_margin_top = 28*float(view.settings.text_scale)
			paper.content_margin_bottom = card_height-80*float(view.settings.text_scale)
			paper.shadow_color = Color(0.12,0.07,0.02,0.4)
			paper.shadow_size = 4
			paper.shadow_offset = Vector2(2,3)
			card.add_theme_stylebox_override(mode,paper)
		var focus = view._style(Color(0,0,0,0),Color("a23a2a"))
		focus.set_border_width_all(3)
		card.add_theme_stylebox_override("focus",focus)
		card.pressed.connect(func(): select.call(str(id)))
		add_child(card)
		cards[id] = card
		# Keep the Button's full text for keyboard/accessibility identification;
		# its visible title has a bounded two-line layout above the excerpt.
		var title = view._label(str(facts[id][0]),21)
		title.add_theme_color_override("font_color",Color("35291d"))
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		title.offset_left = 20
		title.offset_right = -20
		title.offset_top = 28*float(view.settings.text_scale)
		title.offset_bottom = 85*float(view.settings.text_scale)
		title.max_lines_visible = 2
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(title)
		var excerpt = view._label(str(facts[id][1]),17)
		excerpt.add_theme_color_override("font_color",Color("4b3825"))
		excerpt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		excerpt.offset_left = 20
		excerpt.offset_right = -20
		excerpt.offset_top = 90*float(view.settings.text_scale)
		excerpt.offset_bottom = -36
		excerpt.max_lines_visible = 4
		excerpt.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		card.add_child(excerpt)
		var caption = view._label(str(sources.get(id,facts[id][2])),12,false)
		caption.add_theme_color_override("font_color",Color("805d38"))
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		caption.offset_left = 16
		caption.offset_right = -16
		caption.max_lines_visible = 1
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		caption.offset_top = -28
		caption.offset_bottom = -8
		card.add_child(caption)
	for pair in links:
		if str(links[pair].id) not in confirmed: continue
		var ids = str(pair).split("|")
		if ids.size() == 2 and cards.has(ids[0]) and cards.has(ids[1]):
			connections.append([ids[0],ids[1]])
	thread_layer = preload("res://scripts/shared/case_threads.gd").new()
	thread_layer.board = self
	thread_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(thread_layer)
	# ScrollContainer culls Controls by their rect, including custom drawing.
	thread_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(_layout)

func _ready() -> void:
	_layout()

func _layout() -> void:
	var columns = maxi(1,int((size.x-36)/320))
	var width = (size.x-48-(columns-1)*28)/columns
	var index = 0
	for card in cards.values():
		card.position = Vector2(24+(index%columns)*(width+28),32+(index/columns)*(card_height+44))
		card.size = Vector2(width,card_height)
		index += 1
	custom_minimum_size.y = maxf(160,64+ceilf(float(cards.size())/columns)*(card_height+44))
	queue_redraw()
	if is_instance_valid(thread_layer): thread_layer.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,size),Color("9b713a"))
	# Deterministic flecks avoid an asset dependency or animated texture noise.
	for i in range(int(size.x*size.y/650)):
		var point = Vector2(fposmod(i*137.3,size.x),fposmod(i*71.9,size.y))
		draw_circle(point,1.2,Color(0.29,0.17,0.06,0.2))
	draw_rect(Rect2(Vector2(3,3),size-Vector2(6,6)),Color("5c3c20"),false,6)

func draw_threads(surface:Control) -> void:
	var index = 0
	for pair in connections:
		var a: Control = cards[pair[0]]
		var b: Control = cards[pair[1]]
		var start = a.position+Vector2(a.size.x/2,12)
		var end = b.position+Vector2(b.size.x/2,12)
		var rise = 18 + (index % 4)*5
		index += 1
		var points = PackedVector2Array([start,start-Vector2(0,rise)])
		if not is_equal_approx(start.y,end.y):
			var gutter = minf(a.position.x,b.position.x)-8-(index%3)*4
			points.append(Vector2(gutter,start.y-rise))
			points.append(Vector2(gutter,end.y-rise))
		points.append(end-Vector2(0,rise))
		points.append(end)
		var thread = PackedVector2Array()
		for i in range(points.size()-1):
			var first = points[i]
			var last = points[i+1]
			for step in range(13):
				var t = float(step)/12
				var sag = Vector2(0,sin(t*PI)*5) if absf(last.x-first.x)>1 else Vector2(sin(t*PI)*2,0)
				thread.append(first.lerp(last,t)+sag)
		surface.draw_polyline(thread,Color("76291f"),3.5,true)
		surface.draw_polyline(thread,Color("bc5140"),1.2,true)
	for card in cards.values():
		var pin: Vector2 = card.position+Vector2(card.size.x/2,12)
		surface.draw_circle(pin+Vector2(1,2),6,Color("715126"))
		surface.draw_circle(pin,5,Color("c89b35"))
		surface.draw_circle(pin-Vector2(1.5,1.5),1.6,Color("ffe4a0"))

