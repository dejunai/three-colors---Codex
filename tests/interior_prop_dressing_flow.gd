extends SceneTree

const Town = preload("res://town.gd")
const TownExpansion = preload("res://town_expansion.gd")

const EXPECTED := {
	"room": ["CorwinBed", "CorwinDesk", "CorwinDresser", "CorwinRadiator", "CorwinWashstand", "CorwinWashBasin", "CorwinWashPitcher"],
	"precinct": ["PrecinctIntakeCounterLeft", "PrecinctIntakeCounterRight", "PrecinctFilesSingle", "PrecinctFilesWide", "PrecinctSideDesk", "PrecinctDeskLamp"],
	"lounge": ["LoungeBookshelf", "LoungeDisplaySloped", "LoungeDisplayRectangular", "LoungeWallClock", "PantryDoorStates"],
	"post_office": ["PostOfficeCounterLeft", "PostOfficeCounterRight", "PostOfficePigeonholesLeft", "PostOfficePigeonholesRight", "PostOfficeCrate", "PostOfficeOpenCrate", "PostOfficeBarrel"],
}

const TARGETS := {
	"room": ["board", "sleep", "day_close", "exemption", "interior_exit"],
	"precinct": ["intake_clerk", "intake", "supplement", "survey_drawer", "route_morgue", "interior_exit"],
	"lounge": ["barman", "pantry_door", "lounge_exit"],
	"post_office": ["route_return"],
}

func _initialize() -> void:
	for location in EXPECTED:
		var world = TownExpansion.new() if location == "post_office" else Town.new()
		world.location = location
		root.add_child(world)
		await process_frame
		for prop_name in EXPECTED[location]:
			var prop := world.get_node_or_null(prop_name) as Node3D
			assert(prop != null, location + " missing rendered prop " + prop_name)
			assert(prop.find_children("*", "MeshInstance3D", true, false).size() > 0, prop_name + " has no rendered mesh")
			assert(is_equal_approx(prop.scale.x, prop.scale.y) and is_equal_approx(prop.scale.y, prop.scale.z), prop_name + " must use uniform scale")
			assert(prop.find_children("*", "StaticBody3D", true, false).is_empty(), prop_name + " must remain presentation-only")
		for target_id in TARGETS[location]:
			assert(world.points.has(target_id), location + " lost interaction target " + target_id)
		if location == "precinct": assert(world.has_node("PrecinctBookStack"), "Precinct must use period book clutter instead of lever-arch binders")
		if location == "post_office": assert(world.find_children("PostOfficeLetterBundle*", "MeshInstance3D", true, false).size() >= 5, "Post-office sorting wall needs visible mail bundles")
		if location == "lounge":
			assert(not world.has_node("LoungeTableLeft") and not world.has_node("LoungeArmchairLeftA"), "Rustic furniture must be removed from the club lounge")
			var states := world.get_node("PantryDoorStates")
			assert(states.get_node("Boarded").visible and not states.get_node("Cleared").visible, "Pantry begins visibly boarded")
			world.sync_pantry(true, true)
			assert(not states.get_node("Boarded").visible and states.get_node("Cleared").visible, "Completed pantry portal shows removed boards")
		for shade in world.find_children("InteriorLampShade", "MeshInstance3D", true, false): assert(shade.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Interior shades must not cast floor blobs")
		world.free()
	print("INTERIOR PROP DRESSING PASS: domestic, precinct, post office, and lounge props render with gameplay targets intact")
	quit(0)
