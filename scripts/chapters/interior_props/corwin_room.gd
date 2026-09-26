extends RefCounted

const PROPS: Array[Dictionary] = [
	{"id":"CorwinBed", "path":"res://assets/models/props/domestic/metal_bed.glb", "pos":Vector3(-5.5,0,-3.6), "yaw":PI/2, "scale":3.2, "collision":Vector3(1,0.5,0.72), "support":"floor"},
	{"id":"CorwinRug", "path":"res://assets/models/props/common/rug_plain.glb", "pos":Vector3(-1.4,0.006,-3.0), "yaw":0.0, "scale":4.4, "support":"floor", "clearance_check":false},
	{"id":"CorwinDesk", "path":"res://assets/models/props/civic/wooden_desk_long.glb", "pos":Vector3(3.5,0,-4), "yaw":PI/2, "scale":2.25, "collision":Vector3(0.5,0.44,1), "support":"floor"},
	{"id":"CorwinDeskChair", "path":"res://assets/models/props/domestic/wooden_chair_ladderback.glb", "pos":Vector3(3.5,0,-2.7), "yaw":PI/2, "scale":1.2, "collision":Vector3(0.62,0.9,0.62), "support":"floor"},
	{"id":"CorwinRadiator", "path":"res://assets/models/props/common/radiator_long.glb", "pos":Vector3(-8.35,0,0.5), "yaw":0.0, "scale":2.8, "collision":Vector3(0.19,0.56,1), "support":"floor"},
	{"id":"CorwinWashstand", "path":"res://assets/models/props/domestic/washstand_table.glb", "pos":Vector3(-6.25,0,5.45), "yaw":PI/2, "scale":1.4, "collision":Vector3(0.78,0.9,1), "support":"floor"},
	{"id":"CorwinWashBasin", "path":"res://assets/models/props/domestic/wash_basin_enamel.glb", "pos":Vector3(-6.25,1.26,5.45), "yaw":0.0, "scale":0.65, "support":"on:CorwinWashstand:top", "clearance_check":false},
	{"id":"CorwinWashPitcher", "path":"res://assets/models/props/domestic/wash_pitcher_enamel.glb", "pos":Vector3(-5.75,1.26,5.45), "yaw":0.0, "scale":0.45, "support":"on:CorwinWashstand:top", "clearance_check":false},
	{"id":"CorwinDresser", "path":"res://assets/models/props/domestic/wooden_dresser.glb", "pos":Vector3(6.8,0,3.5), "yaw":PI, "scale":1.45, "collision":Vector3(0.53,0.70,1), "support":"floor"},
]

const SUPPORT_PLANES := {
	"res://assets/models/props/domestic/washstand_table.glb": {"top":{"y":0.9, "footprint":Rect2(-0.5,-0.5,1.0,1.0)}},
}

const CLEARANCES := {
	"board":{"pos":Vector3(0,0,-6.2), "radius":0.3},
	"sleep":{"pos":Vector3(-3.4,0,-2.2), "radius":0.3},
	"day_close":{"pos":Vector3(3.5,0,-2.9), "radius":0.0},
	"exemption":{"pos":Vector3(6.8,0,3.5), "radius":0.0},
	"interior_exit":{"pos":Vector3(0,0,7.2), "radius":0.35},
}
