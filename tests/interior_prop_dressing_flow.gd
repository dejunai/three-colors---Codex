extends SceneTree

const Town = preload("res://town.gd")
const TownExpansion = preload("res://town_expansion.gd")

const EXPECTED := {
	"room": ["CorwinBed", "CorwinDesk", "CorwinDresser", "CorwinRadiator", "CorwinWashstand", "CorwinWashBasin", "CorwinWashPitcher"],
	"precinct": ["PrecinctIntakeCounter", "PrecinctFilesSingle", "PrecinctFilesWide", "PrecinctSideDesk", "PrecinctDeskLamp", "PrecinctBinderStack"],
	"lounge": ["LoungeTableLeft", "LoungeTableRight", "LoungeArmchairLeftA", "LoungeArmchairRightB", "LoungeBookshelf", "LoungeDisplaySloped", "LoungeDisplayRectangular", "LoungeWallClock"],
	"post_office": ["PostOfficeCounter", "PostOfficePigeonholes", "PostOfficeCrate", "PostOfficeOpenCrate", "PostOfficeBarrel"],
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
		for target_id in TARGETS[location]:
			assert(world.points.has(target_id), location + " lost interaction target " + target_id)
		world.free()
	print("INTERIOR PROP DRESSING PASS: domestic, precinct, post office, and lounge props render with gameplay targets intact")
	quit(0)
