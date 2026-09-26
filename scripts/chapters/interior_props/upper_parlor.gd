extends RefCounted

const PROPS: Array[Dictionary] = [
	{"id":"ParlorRug", "path":"res://assets/models/props/common/rug_patterned.glb", "pos":Vector3(0,0.006,0), "yaw":0.0, "scale":5.8, "support":"floor", "clearance_check":false},
	{"id":"ParlorFireplace", "path":"res://assets/models/props/domestic/stone_fireplace.glb", "pos":Vector3(0,0,-7.2), "yaw":-PI/2, "scale":3.4, "collision":Vector3(0.392,0.675,1.0), "support":"floor"},
	{"id":"ParlorTuftedSofa", "path":"res://assets/models/props/domestic/parlor_sofa_tufted.glb", "pos":Vector3(-5.6,0,-0.5), "yaw":-PI/2, "scale":3.8, "collision":Vector3(0.39,0.393,1.0), "support":"floor"},
	{"id":"ParlorPillowBurgundy", "path":"res://assets/models/props/domestic/throw_pillow_burgundy.glb", "pos":Vector3(-5.0,0.62,-1.2), "yaw":-PI/2, "scale":0.62, "support":"on:ParlorTuftedSofa:seat", "clearance_check":false},
	{"id":"ParlorPillowGreen", "path":"res://assets/models/props/domestic/throw_pillow_green.glb", "pos":Vector3(-5.0,0.62,0.5), "yaw":-PI/2, "scale":0.62, "support":"on:ParlorTuftedSofa:seat", "clearance_check":false},
	{"id":"ParlorArmchairNorth", "path":"res://assets/models/props/domestic/parlor_armchair_a.glb", "pos":Vector3(4.8,0,-1.7), "yaw":PI, "scale":1.35, "collision":Vector3(0.862,0.893,1.0), "support":"floor"},
	{"id":"ParlorArmchairSouth", "path":"res://assets/models/props/domestic/parlor_armchair_b.glb", "pos":Vector3(4.8,0,1.7), "yaw":PI, "scale":1.35, "collision":Vector3(0.862,0.893,1.0), "support":"floor"},
	{"id":"ParlorLowTable", "path":"res://assets/models/props/domestic/low_table.glb", "pos":Vector3(0,0,0), "yaw":0.0, "scale":2.35, "collision":Vector3(0.609,0.339,1.0), "support":"floor"},
	{"id":"ParlorDecorativeBowl", "path":"res://assets/models/props/domestic/decorative_bowl_ceramic.glb", "pos":Vector3(0,0.73,0), "yaw":0.0, "scale":0.42, "support":"on:ParlorLowTable:top", "clearance_check":false},
	{"id":"ParlorSideboard", "path":"res://assets/models/props/domestic/sideboard.glb", "pos":Vector3(5.5,0,-5.7), "yaw":-PI/2, "scale":3.0, "collision":Vector3(0.324,0.502,1.0), "support":"floor"},
	{"id":"ParlorTableLamp", "path":"res://assets/models/props/common/table_lamp_b.glb", "pos":Vector3(4.55,1.51,-5.7), "yaw":0.0, "scale":0.58, "support":"on:ParlorSideboard:top", "cast_shadow":false, "clearance_check":false},
	{"id":"ParlorRoundVase", "path":"res://assets/models/props/domestic/vase_ceramic_round.glb", "pos":Vector3(6.25,1.51,-5.7), "yaw":0.0, "scale":0.48, "support":"on:ParlorSideboard:top", "clearance_check":false},
]

const SUPPORT_PLANES := {
	"res://assets/models/props/domestic/parlor_sofa_tufted.glb": {"seat":{"y":0.16316, "footprint":Rect2(-0.5,-0.5,1.0,1.0)}},
	"res://assets/models/props/domestic/low_table.glb": {"top":{"y":0.31064, "footprint":Rect2(-0.48,-0.48,0.96,0.96)}},
	"res://assets/models/props/domestic/sideboard.glb": {"top":{"y":0.50333, "footprint":Rect2(-0.5,-0.5,1.0,1.0)}},
}

const CLEARANCES := {
	"local_resident":{"pos":Vector3(3,0,-2), "radius":0.42},
	"route_return":{"pos":Vector3(0,0,7.2), "radius":0.35},
}
