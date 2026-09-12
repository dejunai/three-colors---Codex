extends Control

var board: Control

func _draw() -> void:
	board.draw_threads(self)
