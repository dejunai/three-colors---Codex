extends RefCounted

const PROPS: Array[Dictionary] = [
	{"id":"PostOfficeCounterLeft", "path":"res://assets/models/props/civic/post_office_counter.glb", "pos":Vector3(-2.15,0,-2.25), "yaw":0.0, "scale":4.0, "collision":Vector3(1,0.43,0.26), "support":"floor"},
	{"id":"PostOfficeCounterRight", "path":"res://assets/models/props/civic/post_office_counter.glb", "pos":Vector3(2.15,0,-2.25), "yaw":0.0, "scale":4.0, "collision":Vector3(1,0.43,0.26), "support":"floor"},
	{"id":"PostOfficePigeonholesLeft", "path":"res://assets/models/props/civic/post_office_pigeonholes.glb", "pos":Vector3(-2.65,0,-7.25), "yaw":0.0, "scale":5.3, "collision":Vector3(1,0.55,0.20), "support":"floor"},
	{"id":"PostOfficePigeonholesRight", "path":"res://assets/models/props/civic/post_office_pigeonholes.glb", "pos":Vector3(2.65,0,-7.25), "yaw":0.0, "scale":5.3, "collision":Vector3(1,0.55,0.20), "support":"floor"},
	{"id":"PostOfficeBalanceScale", "path":"res://assets/models/props/civic/post_office_balance_scale.glb", "pos":Vector3(-1.55,1.0,-2.15), "yaw":0.0, "scale":1.35, "support":"on:PostOfficeCounterLeft:top", "clearance_check":false},
	{"id":"PostOfficeEnvelopeStack", "path":"res://assets/models/props/civic/envelope_stack.glb", "pos":Vector3(-2.35,1.0,-2.05), "yaw":PI/2, "scale":0.72, "support":"on:PostOfficeCounterLeft:top", "clearance_check":false},
	{"id":"PostOfficeParcelSquare", "path":"res://assets/models/props/civic/parcel_tied_square.glb", "pos":Vector3(-0.85,1.0,-2.2), "yaw":0.18, "scale":0.55, "support":"on:PostOfficeCounterLeft:top", "clearance_check":false},
	{"id":"PostOfficeParcelLarge", "path":"res://assets/models/props/civic/parcel_wrapped_large.glb", "pos":Vector3(2.55,1.0,-2.2), "yaw":PI/2, "scale":0.64, "support":"on:PostOfficeCounterRight:top", "clearance_check":false},
	{"id":"PostOfficeParcelLong", "path":"res://assets/models/props/civic/parcel_wrapped_long.glb", "pos":Vector3(3.55,1.0,-2.05), "yaw":PI/2, "scale":0.72, "support":"on:PostOfficeCounterRight:top", "clearance_check":false},
	{"id":"PostOfficeParcelFloorSmall", "path":"res://assets/models/props/civic/parcel_tied_square.glb", "pos":Vector3(-6.1,0,4.15), "yaw":0.16, "scale":0.66, "support":"floor", "clearance_check":false},
	{"id":"PostOfficeParcelFloorLarge", "path":"res://assets/models/props/civic/parcel_wrapped_large.glb", "pos":Vector3(-5.65,0,4.7), "yaw":-0.10, "scale":0.92, "support":"floor", "clearance_check":false},
	{"id":"PostOfficePendantLeft", "path":"res://assets/models/props/civic/post_office_pendant_a.glb", "pos":Vector3(-3.2,2.58,0.7), "yaw":0.0, "scale":1.18, "support":"ceiling", "cast_shadow":false, "clearance_check":false},
	{"id":"PostOfficePendantRight", "path":"res://assets/models/props/civic/post_office_pendant_b.glb", "pos":Vector3(3.2,2.58,0.7), "yaw":0.0, "scale":1.18, "support":"ceiling", "cast_shadow":false, "clearance_check":false},
	{"id":"PostOfficeCorkboard", "path":"res://assets/models/props/civic/post_office_corkboard.glb", "pos":Vector3(-8.78,0.95,0.8), "yaw":PI, "scale":2.6, "support":"wall:left", "clearance_check":false},
	{"id":"PostOfficeFrostedWindow", "path":"res://assets/models/props/civic/post_office_frosted_window.glb", "pos":Vector3(8.71,0.95,2.4), "yaw":PI, "scale":2.4, "support":"wall:right", "clearance_check":false},
	{"id":"PostOfficeHangingSign", "path":"res://assets/models/props/civic/post_office_hanging_sign.glb", "pos":Vector3(8.71,1.35,-2.8), "yaw":0.0, "scale":2.15, "support":"wall:right", "clearance_check":false},
	{"id":"PostOfficeLetterBundle01", "path":"res://assets/models/props/civic/envelope_stack.glb", "pos":Vector3(-4.4,0.65,-6.95), "yaw":0.0, "scale":0.25, "support":"inside:PostOfficePigeonholesLeft:cells", "tilt":Vector2(0.0,-0.03), "clearance_check":false},
	{"id":"PostOfficeLetterBundle02", "path":"res://assets/models/props/civic/envelope_stack.glb", "pos":Vector3(-2.0,1.22,-6.95), "yaw":0.1, "scale":0.29, "support":"inside:PostOfficePigeonholesLeft:cells", "tilt":Vector2(0.0,0.02), "clearance_check":false},
	{"id":"PostOfficeLetterBundle03", "path":"res://assets/models/props/civic/envelope_stack.glb", "pos":Vector3(-0.35,0.72,-6.95), "yaw":-0.08, "scale":0.24, "support":"inside:PostOfficePigeonholesLeft:cells", "tilt":Vector2(0.0,-0.015), "clearance_check":false},
	{"id":"PostOfficeLetterBundle04", "path":"res://assets/models/props/civic/envelope_stack.glb", "pos":Vector3(2.2,1.72,-6.95), "yaw":0.12, "scale":0.27, "support":"inside:PostOfficePigeonholesRight:cells", "tilt":Vector2(0.0,0.025), "clearance_check":false},
	{"id":"PostOfficeLetterBundle05", "path":"res://assets/models/props/civic/envelope_stack.glb", "pos":Vector3(4.25,2.28,-6.95), "yaw":-0.1, "scale":0.23, "support":"inside:PostOfficePigeonholesRight:cells", "tilt":Vector2(0.0,-0.02), "clearance_check":false},
	{"id":"PostOfficeChairLeft", "path":"res://assets/models/props/domestic/wooden_chair_ladderback.glb", "pos":Vector3(-6.2,0,3.1), "yaw":0.0, "scale":1.15, "collision":Vector3(0.62,0.9,0.62), "support":"floor"},
	{"id":"PostOfficeChairRight", "path":"res://assets/models/props/domestic/wooden_chair_ladderback.glb", "pos":Vector3(6.2,0,3.1), "yaw":PI, "scale":1.15, "collision":Vector3(0.62,0.9,0.62), "support":"floor"},
	{"id":"PostOfficeCrate", "path":"res://assets/models/props/common/wooden_crate_lidded.glb", "pos":Vector3(-7.1,0,4.6), "yaw":0.0, "scale":1.3, "collision":Vector3(1,0.66,0.65), "support":"floor"},
	{"id":"PostOfficeOpenCrate", "path":"res://assets/models/props/common/wooden_crate_open.glb", "pos":Vector3(7.0,0,4.7), "yaw":0.0, "scale":1.15, "collision":Vector3(1,0.61,0.72), "support":"floor"},
	{"id":"PostOfficeBarrel", "path":"res://assets/models/props/common/wooden_barrel.glb", "pos":Vector3(7.55,0,0.55), "yaw":0.0, "scale":1.1, "collision":Vector3(0.70,1,0.71), "support":"floor"},
]

const SUPPORT_PLANES := {
	"res://assets/models/props/civic/post_office_counter.glb": {"top":{"y":0.25, "footprint":Rect2(-0.48,-0.12,0.96,0.24)}},
	"res://assets/models/props/civic/post_office_pigeonholes.glb": {"cells":{"box":AABB(Vector3(-0.49,0.07,0.0),Vector3(0.98,0.50,0.12))}},
}

const CLEARANCES := {
	"route_return":{"pos":Vector3(0,0,7.2), "radius":0.35},
	"post_office_clerk":{"pos":Vector3(4,0,-1.55), "radius":0.15},
	"staff:post_office_clerk":{"pos":Vector3(4,0,-3.05), "radius":0.25},
}
