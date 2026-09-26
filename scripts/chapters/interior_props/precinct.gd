extends RefCounted

const PROPS: Array[Dictionary] = [
	{"id":"PrecinctIntakeCounterLeft", "path":"res://assets/models/props/civic/precinct_counter.glb", "pos":Vector3(-1.78,0,-2.5), "yaw":0.0, "scale":3.55, "collision":Vector3(1,0.28,0.48), "support":"floor"},
	{"id":"PrecinctIntakeCounterRight", "path":"res://assets/models/props/civic/precinct_counter.glb", "pos":Vector3(1.78,0,-2.5), "yaw":0.0, "scale":3.55, "collision":Vector3(1,0.28,0.48), "support":"floor"},
	{"id":"PrecinctClerkChair", "path":"res://assets/models/props/domestic/wooden_chair_ladderback.glb", "pos":Vector3(0,0,-4.2), "yaw":-PI/2, "scale":1.2, "collision":Vector3(0.62,0.9,0.62), "support":"floor", "clearance_check":false},
	{"id":"PrecinctFilesSingle", "path":"res://assets/models/props/civic/filing_cabinet_single.glb", "pos":Vector3(-7.1,0,-6.35), "yaw":0.0, "scale":2.6, "collision":Vector3(0.38,1,0.45), "support":"floor"},
	{"id":"PrecinctFilesWide", "path":"res://assets/models/props/civic/filing_cabinet_wide.glb", "pos":Vector3(7.25,0,-6.4), "yaw":0.0, "scale":2.5, "collision":Vector3(0.75,1,0.8), "support":"floor"},
	{"id":"PrecinctSideDesk", "path":"res://assets/models/props/civic/wooden_desk_long.glb", "pos":Vector3(-5,0,1), "yaw":PI/2, "scale":2.25, "collision":Vector3(0.5,0.44,1), "support":"floor"},
	{"id":"PrecinctSideChair", "path":"res://assets/models/props/domestic/wooden_chair_ladderback.glb", "pos":Vector3(-5,0,2.72), "yaw":PI/2, "scale":1.15, "collision":Vector3(0.62,0.9,0.62), "support":"floor"},
	{"id":"PrecinctDeskLamp", "path":"res://assets/models/props/common/desk_lamp.glb", "pos":Vector3(-5.65,0.98,0.85), "yaw":0.0, "scale":0.65, "support":"on:PrecinctSideDesk:top", "clearance_check":false},
	{"id":"PrecinctBookStack", "path":"res://assets/models/props/common/book_stack.glb", "pos":Vector3(-4.45,0.99,0.9), "yaw":0.0, "scale":0.42, "support":"on:PrecinctSideDesk:top", "clearance_check":false},
	{"id":"PrecinctWaitingChair0", "path":"res://assets/models/props/domestic/wooden_chair_ladderback.glb", "pos":Vector3(7,0,0), "yaw":PI, "scale":1.15, "collision":Vector3(0.62,0.9,0.62), "support":"floor"},
	{"id":"PrecinctWaitingChair2", "path":"res://assets/models/props/domestic/wooden_chair_ladderback.glb", "pos":Vector3(7,0,2), "yaw":PI, "scale":1.15, "collision":Vector3(0.62,0.9,0.62), "support":"floor"},
	{"id":"PrecinctWaitingChair4", "path":"res://assets/models/props/domestic/wooden_chair_ladderback.glb", "pos":Vector3(7,0,4), "yaw":PI, "scale":1.15, "collision":Vector3(0.62,0.9,0.62), "support":"floor"},
]

const SUPPORT_PLANES := {
	"res://assets/models/props/civic/wooden_desk_long.glb": {"top":{"y":0.4356, "footprint":Rect2(-0.5,-0.5,1.0,1.0)}},
}

const CLEARANCES := {
	"intake_clerk":{"pos":Vector3(0.4,0,-2.5), "radius":0.0},
	"intake":{"pos":Vector3(0,0,-1.3), "radius":0.25},
	"supplement":{"pos":Vector3(-5,0,2.1), "radius":0.25},
	"survey_drawer":{"pos":Vector3(7,0,-3.8), "radius":0.25},
	"route_morgue":{"pos":Vector3(-4,0,-6.2), "radius":0.3},
	"interior_exit":{"pos":Vector3(0,0,7.2), "radius":0.35},
	"staff:intake_clerk":{"pos":Vector3(0.4,0,-4.0), "radius":0.42},
	"staff:odell_precinct":{"pos":Vector3(3.8,0,1.0), "radius":0.42},
}
