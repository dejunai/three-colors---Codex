extends RefCounted

const LowerStreet = preload("res://scripts/chapters/lower_street.gd")
const Places = preload("res://scripts/chapters/town_places.gd")
const LOWER_ORIGIN = Vector3(91, -2.3, 0)

class PlacementProxy extends Node3D:
	var host: Node
	var routes: Dictionary

	func _init(owner: Node) -> void:
		host = owner
		routes = owner.routes

	func box(_parent: Node, p: Vector3, size: Vector3, color: String, solid: bool = false):
		return host.box(self, p, size, color, solid)

	func cylinder(_parent: Node, p: Vector3, radius: float, height: float, color: String, top: float = -1.0):
		return host.cylinder(self, p, radius, height, color, top)

	func lettering(text: String, p: Vector3, font_size: int = 56):
		return host.lettering(text, position + p, font_size)

	func target(id: String, title: String, p: Vector3) -> void:
		host.target(id, title, position + p)

	func lamp(p: Vector3, tall: bool = true) -> void:
		host.lamp(position + p, tall)

static func build(g: Node) -> void:
	var root = Node3D.new()
	root.name = "ContiguousTownPhaseTwo"
	g.add_child(root)
	var proxy = PlacementProxy.new(g)
	proxy.name = "LowerDistrictExterior"
	proxy.position = LOWER_ORIGIN
	root.add_child(proxy)
	LowerStreet.new().build(proxy)
	_build_pickman_descent(g, root)
	for id in ["route_lower", "route_pickman"]:
		g.points.erase(id)
		g.routes.erase(id)

static func _build_pickman_descent(g: Node, root: Node3D) -> void:
	var run = 8.0
	var drop = 2.3
	var length = sqrt(run * run + drop * drop)
	# Bury the Pickman edge below its pavement so the character controller meets
	# a descending floor rather than the slab's vertical face.
	var center = Vector3(54, -1.45, 8)
	var ramp = g.box(root, center, Vector3(length, 0.42, 5.5), "687269")
	ramp.name = "LowerDistrictDescent"
	ramp.rotation.z = -atan2(drop, run)
	var body = StaticBody3D.new()
	body.name = "LowerDistrictDescentCollision"
	body.position = center
	body.rotation = ramp.rotation
	root.add_child(body)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(length, 0.42, 5.5)
	collision.shape = shape
	body.add_child(collision)
	for z in [4.7, 11.3]:
		g.box(root, Vector3(54, -0.7, z), Vector3(9, 1.5, 0.5), "4b574e", true)

static func lower_return(interior_id: String) -> Variant:
	var specs: Array = Places.BUILDINGS.lower
	for index in specs.size():
		if String(specs[index][0]) != interior_id: continue
		var toward_street = Vector3(0, 0.1, 1.5 if index < 3 else -1.5)
		return LOWER_ORIGIN + Places.front(index) + toward_street
	return null

static func shared_spot(spot: Array) -> Array:
	if spot.is_empty() or String(spot[0]) != "lower": return spot
	var position: Vector3 = spot[1]
	return ["town", LOWER_ORIGIN + position]
