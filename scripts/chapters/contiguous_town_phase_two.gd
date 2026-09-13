extends RefCounted

const LowerStreet = preload("res://scripts/chapters/lower_street.gd")
const Waterfront = preload("res://scripts/chapters/waterfront_district.gd")
const Places = preload("res://scripts/chapters/town_places.gd")
const LOWER_ORIGIN = Vector3(91, -2.3, 0)
const WATERFRONT_ORIGIN = Vector3(100, -5.0, -60)

class PlacementProxy extends Node3D:
	var host: Node
	var routes: Dictionary

	func _init(owner: Node) -> void:
		host = owner
		routes = owner.routes

	func box(parent: Node, p: Vector3, size: Vector3, color: String, solid: bool = false):
		return host.box(self if parent == self or parent == host else parent, p, size, color, solid)

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

static func build_waterfront_approach(g: Node) -> void:
	var root = g.get_node("ContiguousTownPhaseTwo")
	var run = 14.0
	var drop = 2.7
	var length = sqrt(run * run + drop * drop)
	var center = Vector3(100, -3.85, -24)
	var ramp = g.box(root, center, Vector3(5.5, 0.42, length), "59665f")
	ramp.name = "WaterfrontDescent"
	ramp.rotation.x = -atan2(drop, run)
	var body = StaticBody3D.new()
	body.name = "WaterfrontDescentCollision"
	body.position = center
	body.rotation = ramp.rotation
	root.add_child(body)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(5.5, 0.42, length)
	collision.shape = shape
	body.add_child(collision)
	for side in [-1.0, 1.0]:
		g.box(root, Vector3(100 + side * 3.2, -3.5, -24), Vector3(0.5, 2.7, 15), "46534c", true)
	g.target("route_waterfront", "Continue downhill to the waterfront", Vector3(100, -5.0, -31))
	g.routes["route_waterfront"] = ["waterfront", Vector3(0, 0.1, 23), 0.0]
	# A low, unreachable preview keeps the abandoned island visible throughout
	# the descent without turning it into a destination.
	var station = Node3D.new()
	station.name = "DistantWhalingStation"
	root.add_child(station)
	g.box(station, Vector3(103, -6.8, -128), Vector3(30, 2.0, 13), "626b62")
	g.box(station, Vector3(102, -4.8, -128), Vector3(14, 4.2, 6), "46534d")
	g.box(station, Vector3(95, -2.7, -129), Vector3(1.8, 8.0, 1.8), "3d4b45")

static func build_waterfront(g: Node) -> void:
	var root = g.get_node("ContiguousTownPhaseTwo")
	var preview = root.get_node_or_null("DistantWhalingStation")
	if preview != null: preview.free()
	var proxy = PlacementProxy.new(g)
	proxy.name = "WaterfrontExterior"
	proxy.position = WATERFRONT_ORIGIN
	root.add_child(proxy)
	Waterfront.new().build(proxy)
	for id in ["route_waterfront", "route_pickman"]:
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
	if spot.is_empty(): return spot
	var district = String(spot[0])
	var position: Vector3 = spot[1]
	if district == "lower": return ["town", LOWER_ORIGIN + position]
	if district == "waterfront": return ["town", WATERFRONT_ORIGIN + position]
	return spot
