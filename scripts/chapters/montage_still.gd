extends Control

# Fixed monochrome storyboard stills, with accessible intertitles outside the image.
var scene_index = 0
const LIGHT = Color("b4b2a0")
const DARK = Color("242b27")

func _draw() -> void:
	var scale_factor = Vector2(size.x / 720.0,size.y / 210.0)
	draw_set_transform(Vector2.ZERO,0,scale_factor)
	draw_rect(Rect2(0,0,720,210),DARK)
	for x in [65,190,480,605]:
		draw_rect(Rect2(x,22,55,100),Color("616a5d"))
		draw_line(Vector2(x+27,22),Vector2(x+27,122),DARK,4)
		draw_line(Vector2(x,72),Vector2(x+55,72),DARK,4)
	draw_line(Vector2(20,181),Vector2(700,181),LIGHT,2)
	if scene_index == 1:
		draw_rect(Rect2(245,125,215,12),LIGHT)
		for x in [260,442]: draw_line(Vector2(x,137),Vector2(x,180),LIGHT,4)
		draw_rect(Rect2(320,110,55,9),Color("7b8271"))
	else:
		draw_rect(Rect2(276,137,165,9),LIGHT)
		for x in [290,425]: draw_line(Vector2(x,146),Vector2(x,181),LIGHT,4)
	for x in [225,490]:
		draw_circle(Vector2(x,77),14,LIGHT)
		draw_colored_polygon(PackedVector2Array([Vector2(x-17,94),Vector2(x+17,94),Vector2(x+26,159),Vector2(x-26,159)]),Color("858e7b"))
		for dx in [-10,10]: draw_line(Vector2(x+dx,155),Vector2(x+dx,181),LIGHT,6)
	if scene_index == 2:
		draw_rect(Rect2(325,70,70,48),Color("444e40"))
		for x in [335,357,380]: draw_rect(Rect2(x,80,8,24),LIGHT)
