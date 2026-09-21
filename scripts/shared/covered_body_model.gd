extends RefCounted

# Static 3D model for draped/covered deceased figures (Naomi Whitehouse, her young son, and morgue slabs).
# Model represents a deceased figure fully draped in a morgue sheet.

const SCENE: PackedScene = preload("res://assets/models/covered_body.glb")
const SCALE_FACTOR: float = 1.05
const CHILD_SCALE_RATIO: float = 0.58

static func create(small: bool = false) -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "CoveredBody_Child" if small else "CoveredBody"
	var rendered := SCENE.instantiate()
	rendered.name = "RenderedCoveredBody"
	var scale_mult := SCALE_FACTOR * (CHILD_SCALE_RATIO if small else 1.0)
	rendered.scale = Vector3.ONE * scale_mult
	wrapper.add_child(rendered)
	return wrapper
