extends RefCounted

# Static 3D placeholder models for ambient and cast NPCs across Ophion and districts.
# Models are unrigged and non-animated, replacing primitive placeholder geometry.

const UPPER_MAN = "UPPER_MAN"
const UPPER_WOMAN = "UPPER_WOMAN"
const LOWER_MAN = "LOWER_MAN"
const LOWER_WOMAN = "LOWER_WOMAN"
const OBSERVER_MAN = "OBSERVER_MAN"
const OBSERVER_WOMAN = "OBSERVER_WOMAN"

const SCENES: Dictionary = {
	UPPER_MAN: preload("res://assets/models/cast_upper_man.glb"),
	UPPER_WOMAN: preload("res://assets/models/cast_upper_woman.glb"),
	LOWER_MAN: preload("res://assets/models/cast_lower_man.glb"),
	LOWER_WOMAN: preload("res://assets/models/cast_lower_woman.glb"),
	OBSERVER_MAN: preload("res://assets/models/cast_observer_man.glb"),
	OBSERVER_WOMAN: preload("res://assets/models/cast_observer_woman.glb"),
}

# Authored base height is ~1.90m; at 1.05x they stand at ~1.99m, fitting naturally
# alongside Walter (1.30 ~2.21m), Odell (1.30 ~2.34m), Coroner (1.18 ~2.01m),
# Steward (1.15 ~1.95m), and Boy (1.05 ~1.78m).
const SCALE_FACTOR: float = 1.05

static func create(archetype: String) -> Node3D:
	var key := archetype if SCENES.has(archetype) else LOWER_MAN
	var wrapper := Node3D.new()
	wrapper.name = "CastModel_" + key
	wrapper.set_meta("archetype", key)
	var scene: PackedScene = SCENES[key]
	var rendered := scene.instantiate()
	rendered.name = "RenderedCast"
	rendered.scale = Vector3.ONE * SCALE_FACTOR
	# Meshy authors face toward +Z; rotate PI to align with Godot's forward (-Z)
	rendered.rotation.y = PI
	wrapper.add_child(rendered)
	return wrapper

static func archetype_for_npc(actor_id: String, location: String = "") -> String:
	var id := actor_id.to_lower()
	var loc := location.to_lower()

	# 1. Observers
	if id.contains("observer"):
		if id.contains("woman") or id.contains("female"):
			return OBSERVER_WOMAN
		return OBSERVER_MAN

	# 2. Known female characters
	var upper_women := [
		"almy", "mrs_almy", "mrs_pell", "mrs_ashcroft", "mrs_whitlock",
		"miss_wexley", "upper_companion", "upper_housemaid", "school_parent"
	]
	if id in upper_women:
		return UPPER_WOMAN

	var lower_women := [
		"old_woman", "widow_kessler", "sarah_munn", "lower_laundress"
	]
	if id in lower_women:
		return LOWER_WOMAN

	var is_female := (
		id.contains("woman") or id.begins_with("mrs_") or id.begins_with("miss_")
		or id.begins_with("widow_") or id.contains("laundress") or id.contains("housemaid")
		or id.contains("companion") or id.contains("sarah") or id.contains("girl")
	)
	if is_female:
		if loc in ["upper", "upper_residential_ridge", "business", "business_district", "boardinghouse"]:
			return UPPER_WOMAN
		return LOWER_WOMAN

	# 3. Known upper / business men
	var upper_men := [
		"mr_whitehouse", "mr_wick", "upper_driver", "upper_gardener", "upper_delivery_boy",
		"clockmaker", "apothecary", "tailor", "stationer", "gazette_editor",
		"schoolteacher", "local_historian", "county_clerk", "post_office_clerk"
	]
	if id in upper_men or id.begins_with("business_"):
		return UPPER_MAN

	if loc in ["upper", "upper_residential_ridge", "business", "business_district", "town_hall", "post_office"]:
		return UPPER_MAN

	# 4. Default to Lower Class Man
	return LOWER_MAN

static func create_for_npc(actor_id: String, location: String = "") -> Node3D:
	var arch := archetype_for_npc(actor_id, location)
	return create(arch)
