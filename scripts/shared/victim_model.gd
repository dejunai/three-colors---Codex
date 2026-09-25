extends RefCounted

# Static 3D model for the murder victims lying on the estate rose lawn.
# Model represents an evening-wear murder victim covered from waist down by a morgue sheet.

const SCENE: PackedScene = preload("res://assets/models/murder_victim.glb")
const SCALE_FACTOR: float = 1.05

static func create() -> Node3D:
	var wrapper := Node3D.new()
	wrapper.name = "MurderVictim"
	var rendered := SCENE.instantiate()
	rendered.name = "RenderedVictim"
	rendered.scale = Vector3.ONE * SCALE_FACTOR
	wrapper.add_child(rendered)
	return wrapper
