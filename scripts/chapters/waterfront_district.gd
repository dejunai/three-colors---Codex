extends RefCounted

# Ordinary working waterfront. The distant station is scenery, never a route.
const DistrictSurfaces = preload("res://scripts/shared/district_surfaces.gd")
const WATERFRONT_MODEL = preload("res://assets/models/waterfront_phase1.glb")
const BOAT_FRAME_MODEL = preload("res://assets/models/waterfront/boat_frame.glb")
const CARGO_CLUSTER_MODEL = preload("res://assets/models/waterfront/cargo_cluster.glb")
const DOCK_CRANE_MODEL = preload("res://assets/models/waterfront/dock_crane.glb")
const DOCK_SHED_MODEL = preload("res://assets/models/waterfront/dock_shed.glb")
const FISHING_BOAT_MODEL = preload("res://assets/models/waterfront/fishing_boat.glb")
const CHANDLERY_MODEL = preload("res://assets/models/exteriors/storefront_2.glb")
const FISH_STORES_MODEL = preload("res://assets/models/exteriors/storefront_1.glb")

var _legacy_visuals: Node3D

func block(w: Node, p: Vector3, size: Vector3, tint: String, solid: bool = false, kind: String = "salt_wood") -> MeshInstance3D:
	return DistrictSurfaces.apply(w.box(_legacy_visuals if is_instance_valid(_legacy_visuals) else w, p, size, tint, solid), kind, tint)

func legacy_box(w: Node, p: Vector3, size: Vector3, tint: String, solid: bool = false) -> MeshInstance3D:
	return w.box(_legacy_visuals if is_instance_valid(_legacy_visuals) else w, p, size, tint, solid)

func legacy_cylinder(w: Node, p: Vector3, radius: float, height: float, tint: String) -> MeshInstance3D:
	return w.cylinder(_legacy_visuals if is_instance_valid(_legacy_visuals) else w, p, radius, height, tint)

func place_prop(parent: Node3D, packed: PackedScene, prop_name: String, position: Vector3, uniform_scale: float, yaw: float = 0.0) -> Node3D:
	var prop := packed.instantiate() as Node3D
	prop.name = prop_name
	prop.position = position
	prop.scale = Vector3.ONE * uniform_scale
	prop.rotation.y = yaw
	parent.add_child(prop)
	return prop

func place_scaled_prop(parent: Node3D, packed: PackedScene, prop_name: String, position: Vector3, model_scale: Vector3, yaw: float = 0.0) -> Node3D:
	var prop := packed.instantiate() as Node3D
	prop.name = prop_name
	prop.position = position
	prop.scale = model_scale
	prop.rotation.y = yaw
	parent.add_child(prop)
	return prop

func hide_frontage(rendered: Node3D, prefixes: Array[String]) -> void:
	var frontage := rendered.find_child("WorkingFrontage", true, false)
	if frontage == null: return
	for child in frontage.get_children():
		for prefix in prefixes:
			if String(child.name).begins_with(prefix):
				child.visible = false
				break

func build_frontage_landmarks(w: Node3D, rendered: Node3D) -> void:
	# Replace only the two strongest generated storefronts. Freight Office and
	# Net Loft retain the authored waterfront kit and keep the frontage varied.
	hide_frontage(rendered, ["Chandlery", "FishStores", "FishStoreVent"])
	var landmarks := Node3D.new()
	landmarks.name = "RenderedWaterfrontLandmarks"
	w.add_child(landmarks)
	place_scaled_prop(landmarks, CHANDLERY_MODEL, "HarborSupplyChandlery", Vector3(-22, 0, 17), Vector3(6.0, 3.1, 4.5), PI)
	place_scaled_prop(landmarks, FISH_STORES_MODEL, "FishStoresExterior", Vector3(23, 0, 17), Vector3(6.2, 2.95, 4.65), PI)

func collision_box(parent: Node3D, body_name: String, position: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = body_name
	body.position = position
	parent.add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func build_hero_props(w: Node3D, rendered: Node3D) -> void:
	var props := Node3D.new()
	props.name = "HeroQuayProps"
	w.add_child(props)
	# Replace the provisional boat silhouette while keeping it available in the
	# source model for comparison and rollback.
	var provisional_boat := rendered.find_child("FishingBoat", true, false)
	if provisional_boat != null: provisional_boat.visible = false
	place_prop(props, FISHING_BOAT_MODEL, "FishingBoatDetailed", Vector3(3, -2.4, -17), 4.5, 0.0)
	# Repair-yard and working-apron landmarks. These positions deliberately stay
	# clear of the authored waterfront schedule anchors and the central return lane.
	place_prop(props, BOAT_FRAME_MODEL, "BoatFrameDetailed", Vector3(22, 0.04, -4.5), 2.4, -0.12)
	place_prop(props, CARGO_CLUSTER_MODEL, "CargoClusterDetailed", Vector3(-17, 0.04, -4.5), 1.35, 0.18)
	place_prop(props, DOCK_CRANE_MODEL, "DockCraneDetailed", Vector3(-27, 0.04, -4.5), 3.2, 0.08)
	place_prop(props, DOCK_SHED_MODEL, "DockShedDetailed", Vector3(16, 0.04, 5), 3.4, 0.0)
	# Broad, cheap proxies prevent walking through the dense render meshes. The
	# shed uses three walls so its seaward-facing work bay remains enterable.
	collision_box(w, "BoatFrameCollision", Vector3(22, 1.05, -4.5), Vector3(4.0, 2.1, 4.6))
	collision_box(w, "CargoClusterCollision", Vector3(-17, 0.5, -4.5), Vector3(2.5, 1.0, 2.4))
	collision_box(w, "DockCraneCollision", Vector3(-27, 1.0, -4.5), Vector3(4.5, 2.0, 2.2))
	collision_box(w, "DockShedBackCollision", Vector3(16, 2.5, 8.0), Vector3(5.5, 5.0, 0.4))
	collision_box(w, "DockShedWestCollision", Vector3(13.3, 2.5, 5.3), Vector3(0.4, 5.0, 5.8))
	collision_box(w, "DockShedEastCollision", Vector3(18.7, 2.5, 5.3), Vector3(0.4, 5.0, 5.8))

func build(w: Node3D) -> void:
	_legacy_visuals = Node3D.new()
	_legacy_visuals.name = "LegacyWaterfrontCollisionVisuals"
	w.add_child(_legacy_visuals)
	block(w,Vector3(0,-0.5,8),Vector3(64,1,42),"505952",true,"algae_stone")
	legacy_box(w,Vector3(0,-1.35,-53),Vector3(190,0.12,92),"465b60")
	# Seawall: continuous collision keeps the water outside the playable quay.
	block(w,Vector3(0,-0.3,-12),Vector3(64,2.2,1.4),"667066",true,"algae_stone")
	for x in range(-30,31,3):
		block(w,Vector3(x,0.85,-12),Vector3(2.95,0.25,1.6),"82877d",false,"cut_stone")
		block(w,Vector3(x,-0.35,-12.76),Vector3(0.06,1.6,0.03),"3e4c48",false,"rust_metal")
	# Narrow plank apron and mooring hardware.
	for x in range(-30,31):
		block(w,Vector3(x,0.03,-8),Vector3(0.94,0.08,6),"77796b",false,"salt_wood")
	for x in [-27,-15,-3,9,21,29]:
		var bollard = legacy_cylinder(w,Vector3(x,0.45,-10.5),0.19,0.9,"343e39")
		DistrictSurfaces.apply(bollard,"rust_metal","343e39")
		block(w,Vector3(x,0.8,-10.5),Vector3(0.8,0.12,0.22),"343e39",false,"rust_metal")
	# Simple fishing boats moored below the quay, without boarding prompts.
	for x in [-20,3,23]:
		block(w,Vector3(x,-0.85,-18),Vector3(3.3,0.6,7),"333d37",false,"tar_wood")
		block(w,Vector3(x,-0.48,-18),Vector3(2.6,0.12,5.8),"858473",false,"salt_wood")
		block(w,Vector3(x,0.1,-19),Vector3(1.7,1.1,1.7),"656c5d",false,"salt_wood")
		var mast = legacy_cylinder(w,Vector3(x,1.7,-17),0.07,5.4,"5b6053")
		DistrictSurfaces.apply(mast,"tar_wood","5b6053")
	# Four modest fronts, reserved for future writers; no invented residents.
	for spec in [[-22,"CHANDLERY"],[-7,"FREIGHT OFFICE"],[8,"NET LOFT"],[23,"FISH STORES"]]:
		var x:float=spec[0]
		var wall_tint: String = "6e7165"
		match int(x):
			-7: wall_tint = "626b65"
			8: wall_tint = "737466"
			23: wall_tint = "5f685e"
		var wall_kind: String = "salt_wood" if int(x) in [-22,8] else "soot_brick"
		block(w,Vector3(x,3,17),Vector3(12,6,9),wall_tint,true,wall_kind)
		block(w,Vector3(x,6.2,17),Vector3(12.6,0.4,9.5),"35453e",false,"slate")
		block(w,Vector3(x,1.4,12.42),Vector3(1.7,2.8,0.12),"34463b",false,"tar_wood")
		for dx in [-3.5,3.5]:
			block(w,Vector3(x+dx,2.4,12.42),Vector3(2.1,1.7,0.12),"344943",false,"tar_wood")
			block(w,Vector3(x+dx,2.4,12.3),Vector3(0.08,1.9,0.12),"969a85",false,"salt_wood")
		w.lettering(spec[1],Vector3(x,4.3,12.2),30).rotation.y=PI
	# Repairs and nets give the existing residents places to work.
	for x in [17,20,23]:
		block(w,Vector3(x,0.35,-3),Vector3(1.8,0.7,1.3),"79796e",true,"salt_wood")
	for x in [-25,-21]:
		var net_pole = legacy_cylinder(w,Vector3(x,1.4,0),0.07,2.8,"57604f")
		DistrictSurfaces.apply(net_pole,"tar_wood","57604f")
	for y in [0.8,1.1,1.4,1.7,2.0]:
		block(w,Vector3(-23,y,0),Vector3(4,0.025,0.025),"94957c",false,"salt_wood")
	for x in range(-25,-20):
		block(w,Vector3(x,1.4,0),Vector3(0.025,1.5,0.025),"94957c",false,"salt_wood")
	for x in [-27,-12,12,27]: w.lamp(Vector3(x,0,7))
	# Return lane between the buildings, easy to see from the arrival point.
	w.target("route_pickman","Return uphill to Pickman Street",Vector3(0,0,23))
	w.routes["route_pickman"]=["town",Vector3(-26,0.1,7),PI/2]
	# The imported slice owns presentation only. Hidden legacy meshes retain their
	# child collision bodies, so established routes and solid footprints do not move.
	var rendered = WATERFRONT_MODEL.instantiate()
	rendered.name = "RenderedWaterfront"
	w.add_child(rendered)
	build_frontage_landmarks(w, rendered)
	build_hero_props(w, rendered)
	_legacy_visuals.visible = false
	_legacy_visuals = null
	# Low island silhouette; mud covers the base of the abandoned works.
	var island=Node3D.new()
	island.name="OffshoreWhalingStation"
	w.add_child(island)
	DistrictSurfaces.apply(w.box(island,Vector3(9,-0.3,-72),Vector3(28,2.2,13),"626b62"),"algae_stone","626b62")
	DistrictSurfaces.apply(w.box(island,Vector3(8,1.25,-72),Vector3(13,3.8,6),"4a5751"),"tar_wood","4a5751")
	DistrictSurfaces.apply(w.box(island,Vector3(8,3.25,-72),Vector3(14,0.5,7),"364941"),"slate","364941")
	DistrictSurfaces.apply(w.box(island,Vector3(1,3.5,-73),Vector3(1.7,8,1.7),"48574f"),"rust_metal","48574f")
	for spec in [[3,-68,8],[12,-67,12],[20,-71,9]]:
		DistrictSurfaces.apply(w.box(island,Vector3(spec[0],0.8,spec[1]),Vector3(spec[2],2.8,7),"777563"),"tar_wood","777563")
