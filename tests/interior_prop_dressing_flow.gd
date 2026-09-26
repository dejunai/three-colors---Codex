extends SceneTree

const Town = preload("res://town.gd")
const TownExpansion = preload("res://town_expansion.gd")
const TABLES := {
	"room": preload("res://scripts/chapters/interior_props/corwin_room.gd"),
	"precinct": preload("res://scripts/chapters/interior_props/precinct.gd"),
	"lounge": preload("res://scripts/chapters/interior_props/smoking_lounge.gd"),
	"upper_house_1": preload("res://scripts/chapters/interior_props/upper_parlor.gd"),
	"post_office": preload("res://scripts/chapters/interior_props/post_office.gd"),
}
const TARGETS := {
	"room": ["board", "sleep", "day_close", "exemption", "interior_exit"],
	"precinct": ["intake_clerk", "intake", "supplement", "survey_drawer", "route_morgue", "interior_exit"],
	"lounge": ["barman", "pantry_door", "lounge_exit"],
	"post_office": ["route_return"],
	"upper_house_1": ["local_resident", "route_return"],
}
const WALLS := {"left":-8.85, "right":8.85, "back":-7.70}
const CEILING_Y := 4.2
const TOLERANCE := 0.025

var violations: Array[String] = []

func _violate(room: String, prop_id: String, rule: String, detail: String) -> void:
	var line := "%s | %s | %s | %s" % [room,prop_id,rule,detail]
	violations.append(line)
	print("PLACEMENT VIOLATION | ",line)

func _world_bounds(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var meshes := node.find_children("*","MeshInstance3D",true,false)
	if node is MeshInstance3D: meshes.push_front(node)
	for child in meshes:
		var mesh := child as MeshInstance3D
		if mesh.mesh == null: continue
		var bounds: AABB = mesh.global_transform * mesh.get_aabb()
		if first: result=bounds; first=false
		else: result=result.merge(bounds)
	return result

func _rect_world_bounds(parent: Node3D, rect: Rect2, y: float) -> Rect2:
	var points: Array[Vector2] = []
	for corner in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		var point := parent.to_global(Vector3(corner.x,y,corner.y))
		points.append(Vector2(point.x,point.z))
	var minimum := points[0]; var maximum := points[0]
	for point in points: minimum=minimum.min(point); maximum=maximum.max(point)
	return Rect2(minimum,maximum-minimum)

func _contains_rect(outer: Rect2, inner: Rect2) -> bool:
	return inner.position.x>=outer.position.x-TOLERANCE and inner.position.y>=outer.position.y-TOLERANCE and inner.end.x<=outer.end.x+TOLERANCE and inner.end.y<=outer.end.y+TOLERANCE

func _validate_table(room: String, table) -> void:
	var ids := {}
	for row in table.PROPS:
		var prop_id := String(row.get("id",""))
		if prop_id.is_empty(): _violate(room,"<missing>","table.id","row has no id"); continue
		if ids.has(prop_id): _violate(room,prop_id,"table.id","duplicate id")
		ids[prop_id]=row
		var path := String(row.get("path",""))
		if not ResourceLoader.exists(path): _violate(room,prop_id,"table.path","cannot load "+path)
		if not row.has("scale") or float(row.scale)<=0.0: _violate(room,prop_id,"table.scale","must be one positive number")
	for prop_id in ids:
		var row: Dictionary=ids[prop_id]
		var support := String(row.get("support","")); var parts := support.split(":")
		if support in ["floor","ceiling"]: continue
		if parts.size()==2 and parts[0]=="wall":
			if not WALLS.has(parts[1]): _violate(room,prop_id,"table.support","unknown wall "+parts[1])
			continue
		if parts.size()!=3 or not parts[0] in ["on","inside"]:
			_violate(room,prop_id,"table.support","invalid support "+support); continue
		if not ids.has(parts[1]): _violate(room,prop_id,"table.support","missing parent "+parts[1]); continue
		var parent_path := String(ids[parts[1]].path)
		var definitions: Dictionary=table.SUPPORT_PLANES.get(parent_path,{})
		if not definitions.has(parts[2]): _violate(room,prop_id,"table.support","undefined region %s on %s" % [parts[2],parts[1]])

func _check_support(room: String, table, world: Node3D, row: Dictionary, node: Node3D) -> void:
	var prop_id := String(row.id); var support := String(row.support); var bounds := _world_bounds(node)
	if bounds.size==Vector3.ZERO: _violate(room,prop_id,"bounds","no rendered mesh bounds"); return
	var tilt: Vector2=row.get("tilt",Vector2.ZERO)
	if absf(node.rotation.x-tilt.x)>0.0001 or absf(node.rotation.z-tilt.y)>0.0001: _violate(room,prop_id,"tilt","actual=(%.4f,%.4f), expected=(%.4f,%.4f)" % [node.rotation.x,node.rotation.z,tilt.x,tilt.y])
	if not (is_equal_approx(node.scale.x,node.scale.y) and is_equal_approx(node.scale.y,node.scale.z)): _violate(room,prop_id,"scale","non-uniform "+str(node.scale))
	if support=="floor":
		if absf(bounds.position.y)>TOLERANCE: _violate(room,prop_id,"floor","bottom %.4f m from Y=0" % bounds.position.y)
	elif support=="ceiling":
		if absf(bounds.end.y-CEILING_Y)>TOLERANCE: _violate(room,prop_id,"ceiling","top error %.4f m" % (bounds.end.y-CEILING_Y))
		for child in node.find_children("*","MeshInstance3D",true,false):
			if (child as MeshInstance3D).cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: _violate(room,prop_id,"shadow","ceiling mesh still casts shadows")
	elif support.begins_with("wall:"):
		var wall := support.get_slice(":",1); var plane := float(WALLS[wall])
		var distance := minf(absf(bounds.position.x-plane),absf(bounds.end.x-plane)) if wall in ["left","right"] else minf(absf(bounds.position.z-plane),absf(bounds.end.z-plane))
		if distance>TOLERANCE: _violate(room,prop_id,"wall","nearest face %.4f m from %s plane" % [distance,wall])
	else:
		var parts := support.split(":"); var parent := world.get_node_or_null(parts[1]) as Node3D
		if parent==null: return
		var parent_row: Dictionary={}
		for candidate in table.PROPS:
			if candidate.id==parts[1]: parent_row=candidate; break
		var definition: Dictionary=table.SUPPORT_PLANES[String(parent_row.path)][parts[2]]
		if parts[0]=="on":
			var y := float(definition.y); var plane_y := parent.to_global(Vector3(0,y,0)).y
			if absf(bounds.position.y-plane_y)>TOLERANCE: _violate(room,prop_id,"support.height","bottom %.4f, plane %.4f, error %.4f" % [bounds.position.y,plane_y,bounds.position.y-plane_y])
			var outer := _rect_world_bounds(parent,definition.footprint,y)
			var inner := Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))
			if not _contains_rect(outer,inner): _violate(room,prop_id,"support.footprint","bounds "+str(inner)+" outside "+str(outer))
		else:
			var region: AABB=parent.global_transform*(definition.box as AABB)
			if not region.grow(TOLERANCE).encloses(bounds): _violate(room,prop_id,"support.region","bounds "+str(bounds)+" outside "+str(region))

func _row_half(row: Dictionary) -> Vector2:
	var size: Vector3=row.get("collision",Vector3.ZERO)
	return Vector2(size.x,size.z)*float(row.scale)*0.5

func _point_clear(row: Dictionary, point: Vector3, radius: float) -> bool:
	var half := _row_half(row)
	if half==Vector2.ZERO: return true
	var delta := Vector2(point.x-float(row.pos.x),point.z-float(row.pos.z)).rotated(-float(row.yaw))
	var gap := Vector2(maxf(absf(delta.x)-half.x,0.0),maxf(absf(delta.y)-half.y,0.0))
	return gap.length()>=radius-TOLERANCE

func _obb_overlap(a: Dictionary, b: Dictionary) -> bool:
	var ah := _row_half(a); var bh := _row_half(b)
	if ah==Vector2.ZERO or bh==Vector2.ZERO: return false
	var delta := Vector2(b.pos.x-a.pos.x,b.pos.z-a.pos.z)
	var ax := Vector2.RIGHT.rotated(a.yaw); var az := Vector2.DOWN.rotated(a.yaw)
	var bx := Vector2.RIGHT.rotated(b.yaw); var bz := Vector2.DOWN.rotated(b.yaw)
	for axis in [ax,az,bx,bz]:
		var ar := ah.x*absf(axis.dot(ax))+ah.y*absf(axis.dot(az))
		var br := bh.x*absf(axis.dot(bx))+bh.y*absf(axis.dot(bz))
		if absf(delta.dot(axis))>=ar+br-TOLERANCE: return false
	return true

func _check_clearance(room: String, table) -> void:
	var solid_rows: Array[Dictionary]=[]
	for row in table.PROPS:
		if bool(row.get("clearance_check",true)) and row.get("collision",Vector3.ZERO)!=Vector3.ZERO: solid_rows.append(row)
	for row in solid_rows:
		for clearance_id in table.CLEARANCES:
			var clearance: Dictionary=table.CLEARANCES[clearance_id]
			if float(clearance.radius)>0.0 and not _point_clear(row,clearance.pos,float(clearance.radius)): _violate(room,row.id,"clearance","intrudes into %s radius %.2f" % [clearance_id,clearance.radius])
	for i in solid_rows.size():
		for j in range(i+1,solid_rows.size()):
			if _obb_overlap(solid_rows[i],solid_rows[j]): _violate(room,solid_rows[i].id,"overlap","overlaps "+String(solid_rows[j].id))

func _initialize() -> void:
	for location in TABLES:
		var table=TABLES[location]
		_validate_table(location,table)
		var world=TownExpansion.new() if location in ["post_office","upper_house_1"] else Town.new()
		world.location=location; root.add_child(world); await process_frame
		for row in table.PROPS:
			var prop := world.get_node_or_null(row.id) as Node3D
			if prop==null: _violate(location,row.id,"scene","missing rendered prop"); continue
			assert(prop.find_children("*","StaticBody3D",true,false).is_empty(),row.id+" must remain presentation-only")
			_check_support(location,table,world,row,prop)
		for target_id in TARGETS[location]: assert(world.points.has(target_id),location+" lost interaction target "+target_id)
		_check_clearance(location,table)
		if location=="precinct": assert(world.has_node("PrecinctBookStack"),"Precinct uses period book clutter")
		if location=="post_office": assert(world.get_node("PostOfficeLetterBundle01")!=null,"Sorting wall keeps individually adjustable mail bundles")
		if location=="lounge":
			assert(world.steward_actor.position.is_equal_approx(Vector3(0,0,-7.0)),"Steward position is fixed")
			var states := world.get_node("PantryDoorStates")
			assert(states.get_node("Boarded").visible and not states.get_node("Cleared").visible,"Pantry begins boarded")
			world.sync_pantry(true,true)
			assert(not states.get_node("Boarded").visible and states.get_node("Cleared").visible,"Portal history shows cleared pantry")
		world.free()
	if not violations.is_empty():
		print("INTERIOR PROP DRESSING FAILED: %d numeric placement violation(s); use the lines above as Grok's fix list" % violations.size())
		quit(1)
		return
	print("INTERIOR PROP DRESSING PASS: five room tables validate; support, grounding, facing, shadow, overlap, and gameplay contracts hold")
	quit(0)
