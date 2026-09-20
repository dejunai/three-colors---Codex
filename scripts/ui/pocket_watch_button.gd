extends Button

# Compact, closed-watch entry point for Personal Effects. The node name and
# tooltip retain a textual identity while the visible control remains an icon.

func _init() -> void:
	name = "PocketWatchButton"
	text = ""
	tooltip_text = "Check the pocket watch"
	custom_minimum_size = Vector2(62, 58)
	size_flags_horizontal = Control.SIZE_SHRINK_END
	focus_mode = Control.FOCUS_ALL
	for state in ["normal", "hover", "pressed", "focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		style.border_color = Color("9b7132") if state != "focus" else Color("9b382d")
		style.set_border_width_all(1 if state in ["hover", "focus"] else 0)
		style.set_corner_radius_all(3)
		add_theme_stylebox_override(state, style)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)
	button_down.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var center = Vector2(size.x * 0.46, size.y * 0.58)
	var bright = is_hovered() or has_focus()
	var brass = Color("d0a24c") if bright else Color("a8752d")
	var dark = Color("5b3b1d")
	# Short chain, bow, crown, and closed hunter case.
	draw_arc(center + Vector2(16, -19), 16, -1.4, 0.6, 18, brass, 2.5, true)
	draw_arc(center + Vector2(0, -18), 7, PI, TAU, 18, brass, 3, true)
	draw_rect(Rect2(center.x - 5, center.y - 16, 10, 5), brass, true)
	draw_circle(center, 17, dark)
	draw_circle(center, 15, brass)
	draw_circle(center, 11, Color("c8953e"))
	draw_arc(center, 8, -2.4, 0.7, 24, Color("e1c27b"), 1.5, true)

