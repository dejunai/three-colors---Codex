extends RefCounted

const PROPS: Array[Dictionary] = [
	{"id":"LoungeBookshelf", "path":"res://assets/models/props/domestic/bookshelf_narrow.glb", "pos":Vector3(6.9,0,-6.85), "yaw":PI/2, "scale":2.7, "collision":Vector3(0.27,1,0.70), "support":"floor"},
	{"id":"LoungeSideboard", "path":"res://assets/models/props/domestic/sideboard.glb", "pos":Vector3(8.0,0,3.5), "yaw":PI, "scale":3.2, "collision":Vector3(0.324,0.502,1.0), "support":"floor"},
	{"id":"LoungeTableLamp", "path":"res://assets/models/props/common/table_lamp_a.glb", "pos":Vector3(7.72,1.61,3.5), "yaw":0.0, "scale":0.58, "support":"on:LoungeSideboard:top", "cast_shadow":false, "clearance_check":false},
	{"id":"LoungeDisplaySloped", "path":"res://assets/models/props/civic/display_case_sloped.glb", "pos":Vector3(-5.8,0,4.65), "yaw":PI/2, "scale":2.1, "collision":Vector3(0.51,0.70,1), "support":"floor"},
	{"id":"LoungeDisplayRectangular", "path":"res://assets/models/props/civic/display_case_rectangular.glb", "pos":Vector3(4.7,0,4.65), "yaw":PI/2, "scale":2.0, "collision":Vector3(0.50,0.66,1), "support":"floor"},
	{"id":"LoungeWallClock", "path":"res://assets/models/props/common/wall_clock_body.glb", "pos":Vector3(0,1.75,-7.63), "yaw":PI/2, "scale":1.05, "support":"wall:back", "clearance_check":false},
	{"id":"LoungeRug", "path":"res://assets/models/props/common/rug_patterned.glb", "pos":Vector3(0,0.006,-0.7), "yaw":0.0, "scale":5.7, "support":"floor", "clearance_check":false},
	{"id":"LoungeBarCounter", "path":"res://assets/models/props/estate/lounge_bar_counter.glb", "pos":Vector3(0,0,-5.75), "yaw":PI/2, "scale":6.0, "collision":Vector3(0.301,0.278,1.0), "support":"floor"},
	{"id":"LoungeFireplace", "path":"res://assets/models/props/domestic/stone_fireplace.glb", "pos":Vector3(8.45,0,-2.8), "yaw":PI, "scale":3.4, "collision":Vector3(0.392,0.675,1.0), "support":"floor"},
	{"id":"LoungeClubSofa", "path":"res://assets/models/props/domestic/club_sofa.glb", "pos":Vector3(5.65,0,-0.2), "yaw":PI, "scale":3.8, "collision":Vector3(0.39,0.393,1.0), "support":"floor"},
	{"id":"LoungePillowBurgundy", "path":"res://assets/models/props/domestic/throw_pillow_burgundy.glb", "pos":Vector3(5.05,0.62,-0.95), "yaw":PI, "scale":0.62, "support":"on:LoungeClubSofa:seat", "clearance_check":false},
	{"id":"LoungePillowGreen", "path":"res://assets/models/props/domestic/throw_pillow_green.glb", "pos":Vector3(5.05,0.62,0.75), "yaw":PI, "scale":0.62, "support":"on:LoungeClubSofa:seat", "clearance_check":false},
	{"id":"LoungeClubChairNorth", "path":"res://assets/models/props/domestic/club_armchair.glb", "pos":Vector3(-5.1,0,-1.45), "yaw":0.0, "scale":1.35, "collision":Vector3(0.862,0.893,1.0), "support":"floor"},
	{"id":"LoungeClubChairSouth", "path":"res://assets/models/props/domestic/club_armchair.glb", "pos":Vector3(-5.1,0,1.45), "yaw":0.0, "scale":1.35, "collision":Vector3(0.862,0.893,1.0), "support":"floor"},
	{"id":"LoungeRoundTable", "path":"res://assets/models/props/domestic/round_table_low.glb", "pos":Vector3(-3.55,0,0), "yaw":0.0, "scale":1.72, "collision":Vector3(0.994,0.422,1.0), "support":"floor"},
	{"id":"LoungeAshtray", "path":"res://assets/models/props/common/ashtray.glb", "pos":Vector3(-3.55,0.73,0), "yaw":0.0, "scale":0.24, "support":"on:LoungeRoundTable:top", "clearance_check":false},
	{"id":"PantryDoorStates", "path":"res://assets/models/props/estate/pantry_door_states_hd.tscn", "pos":Vector3(-8.58,0,-3.0), "yaw":PI/2, "scale":3.1, "collision":Vector3(0.7145,1,0.3656), "support":"floor"},
]

const SUPPORT_PLANES := {
	"res://assets/models/props/domestic/sideboard.glb": {"top":{"y":0.503125, "footprint":Rect2(-0.5,-0.5,1.0,1.0)}},
	"res://assets/models/props/domestic/club_sofa.glb": {"seat":{"y":0.16316, "footprint":Rect2(-0.5,-0.5,1.0,1.0)}},
	"res://assets/models/props/domestic/round_table_low.glb": {"top":{"y":0.42442, "footprint":Rect2(-0.48,-0.48,0.96,0.96)}},
}

const CLEARANCES := {
	"barman":{"pos":Vector3(0,0,-4.45), "radius":0.3},
	"pantry_door":{"pos":Vector3(-7.4,0,-3.0), "radius":0.25},
	"lounge_exit":{"pos":Vector3(0,0,7.2), "radius":0.35},
	"staff:steward":{"pos":Vector3(0,0,-7.0), "radius":0.30},
}
