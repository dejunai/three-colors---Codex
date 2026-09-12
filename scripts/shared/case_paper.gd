extends PanelContainer

# Decoration only; recorded text remains supplied by the detached notebook snapshot.
func _ready() -> void:
	var paper = StyleBoxFlat.new()
	paper.bg_color = Color("f2e5c6")
	paper.content_margin_left = 42
	paper.content_margin_right = 24
	paper.content_margin_top = 20
	paper.content_margin_bottom = 22
	add_theme_stylebox_override("panel",paper)
	resized.connect(queue_redraw)

func _draw() -> void:
	for y in range(48,int(size.y),32):
		draw_line(Vector2(8,y),Vector2(size.x-8,y),Color(0.37,0.49,0.52,0.14),1)
	draw_line(Vector2(28,8),Vector2(28,size.y-8),Color("bc8070"),1)
