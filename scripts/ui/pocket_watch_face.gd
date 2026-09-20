extends Control

# A code-drawn pocket watch keeps the first UI pass independent of final art while
# still giving the clock a period object rather than a digital readout. Exact time
# remains in accessible text beneath the face.

const FACE = Color("ead9b4")
const FACE_INNER = Color("f3e7c7")
const INK = Color("302519")
const BRASS = Color("a8752d")
const BRASS_LIGHT = Color("d8b66a")
const NIGHT_SKY = Color("1b263c")
const MOON = Color("d9d8c4")
const SUN = Color("d99628")
const ROMAN = ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]

var minutes := 360.0
var aperture_state := "sun"

func configure(value: float, state: String) -> void:
	minutes = value
	aperture_state = state
	name = "PocketWatchFace"
	custom_minimum_size = Vector2(320, 320)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

func _point(center: Vector2, length: float, turns: float) -> Vector2:
	var angle = turns * TAU - PI / 2.0
	return center + Vector2(cos(angle), sin(angle)) * length

func _draw() -> void:
	var center = size * 0.5
	var radius = minf(size.x, size.y) * 0.445
	var font = ThemeDB.fallback_font

	# Bow, crown and layered brass case.
	draw_arc(center + Vector2(0, -radius - 17), 19, PI, TAU, 32, BRASS_LIGHT, 7, true)
	draw_rect(Rect2(center.x - 13, center.y - radius - 13, 26, 12), BRASS, true)
	draw_circle(center, radius + 8, Color("5b3b1d"))
	draw_circle(center, radius + 4, BRASS)
	draw_circle(center, radius, FACE)
	draw_circle(center, radius - 7, FACE_INNER)
	draw_arc(center, radius - 11, 0, TAU, 96, BRASS, 2, true)

	# Minute ticks and heavier five-minute marks.
	for tick in 60:
		var major = tick % 5 == 0
		var outer = _point(center, radius - 15, float(tick) / 60.0)
		var inner = _point(center, radius - (27 if major else 21), float(tick) / 60.0)
		draw_line(inner, outer, INK, 2.4 if major else 1.0, true)

	# Numerals sit outside the hand sweep and leave the upper-middle aperture clear.
	for index in 12:
		var text = ROMAN[index]
		var font_size = 17
		var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var pos = _point(center, radius - 42, float(index) / 12.0)
		draw_string(font, pos - Vector2(text_size.x * 0.5, -text_size.y * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, INK)

	# Day/night aperture. It clicks between these two plates at 6 AM and 6 PM.
	var aperture = center + Vector2(0, -radius * 0.34)
	draw_circle(aperture, 27, BRASS)
	draw_circle(aperture, 23, Color("f6dda5") if aperture_state == "sun" else NIGHT_SKY)
	if aperture_state == "sun":
		for ray in 8:
			draw_line(_point(aperture, 13, float(ray) / 8.0), _point(aperture, 19, float(ray) / 8.0), SUN, 2, true)
		draw_circle(aperture, 9, SUN)
	else:
		draw_circle(aperture + Vector2(-3, 0), 12, MOON)
		draw_circle(aperture + Vector2(3, -3), 11, NIGHT_SKY)

	# Hours include the advancing fraction of the current hour; both hands point to
	# twelve at the midnight clamp.
	var minute_turn = fposmod(minutes, 60.0) / 60.0
	var hour_turn = fposmod(minutes / 60.0, 12.0) / 12.0
	draw_line(center, _point(center, radius * 0.49, hour_turn), INK, 7, true)
	draw_line(center, _point(center, radius * 0.69, minute_turn), INK, 4, true)
	draw_circle(center, 8, BRASS)
	draw_circle(center, 3, INK)
