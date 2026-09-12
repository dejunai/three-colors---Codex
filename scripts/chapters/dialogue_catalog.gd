extends RefCounted

# Authored IDs stay unchanged. These aliases connect draft schedule/location names
# to existing rooms/frontages; they do not silently create new buildings.
const Runtime = preload("res://scripts/shared/dialogue_runtime.gd")
const BASE = {"business_district":"business", "upper_residential_ridge":"upper", "lower_residential":"lower", "pickman_street":"town", "town_hall":"precinct"}
const HOME = {"miss_wexley":"upper_house_1", "mrs_pell":"upper_house_2", "mr_whitehouse":"upper_house_3", "miriam_ashcroft":"upper_house_4", "sebastian_wick":"upper_house_5", "eleanor_whitlock":"upper_house_6", "gazette_editor":"printer"}
const SLOTS = {
	"museum":["museum",Vector3(2,0,-4)], "museum_committee":["museum",Vector3(-2,0,-4)],
	"stationer":["stationer",Vector3(3,0,-3)], "haberdasher":["haberdasher",Vector3(3,0,-3)],
	"schoolhouse":["schoolhouse",Vector3(0,0,-4)], "schoolhouse_gate":["business",Vector3(-16,0,-2)],
	"printer":["business",Vector3(3,0,18)], "repairer":["business",Vector3(22,0,18)],
	"apothecary":["business",Vector3(-26,0,8)], "registrar":["precinct",Vector3(5,0,-3)],
	"post_office":["post_office",Vector3(4,0,-2)],
	"kessler_shop":["town",Vector3(9,0,-2)], "kessler_parlor":["town",Vector3(12,0,-2)],
	"quay":["waterfront",Vector3(-23,0,2)], "quay_repair":["waterfront",Vector3(20,0,-0.5)],
	"quay_office":["waterfront",Vector3(-7,0,10)],
	"waterfront_chandlery":["waterfront",Vector3(-22,0,10)],
	"waterfront_net_loft":["waterfront",Vector3(8,0,10)],
	"waterfront_fish_stores":["waterfront",Vector3(23,0,10)],
	"waterfront_moorings":["waterfront",Vector3(3,0,-7)],
	"bank_walk":["upper",Vector3(25,0,7)], "business_district":["business",Vector3(25,0,10)],
	"club_road":["upper",Vector3(-12,0,11)], "tavern":["business",Vector3(7,0,18)],
	"garden_walk":["upper",Vector3(-24,0,11)], "ashcroft_house":["upper_house_4",Vector3(3,0,0)],
	"sunroom":["upper_house_4",Vector3(3,0,2)], "veranda":["upper",Vector3(3,0,18)],
	"study":["upper",Vector3(4,0,18)], "club_carriage_stop":["upper",Vector3(8,0,13)],
	"chapel_path":["upper",Vector3(17,0,12)], "whitlock_orangery":["upper",Vector3(22,0,18)],
	"charity_hall":["upper",Vector3(20,0,16)]
}
const RETURNING_STAFF = {"odell_precinct":["precinct",Vector3(3.8,0,1)], "assistant_morgue":["morgue",Vector3(1.6,0,-1)]}
var definitions: Dictionary = {}
var paths: Dictionary = {}
var titles: Dictionary = {}

func scan() -> void:
	if not definitions.is_empty(): return
	for filename in DirAccess.get_files_at("res://dialogue"):
		if not filename.ends_with(".dialogue"): continue
		var def = Runtime.load_npc("res://dialogue/" + filename)
		if def.npc.is_empty() or def.npc.contains("{"): continue
		definitions[def.npc] = def
		paths[def.npc] = filename.trim_suffix(".dialogue")
		titles[def.npc] = def.npc.capitalize()
		for topic in def.topics:
			if topic.id != "default": continue
			for step in topic.steps:
				if step.kind == "line" and step.speaker != "WALTER CORWIN":
					titles[def.npc] = String(step.speaker).capitalize()
					break

func add_facts(facts: Dictionary) -> void:
	scan()
	for npc in definitions:
		for topic in definitions[npc].topics:
			_collect(topic.steps, facts, titles[npc] + " · " + definitions[npc].location, topic.label)

func _collect(steps: Array, facts: Dictionary, source: String, previous: String) -> void:
	for step in steps:
		if step.kind == "notebook": previous = step.text
		elif step.kind == "evidence" and not facts.has(step.id):
			facts[step.id] = [String(step.id).replace("_"," ").to_upper(), previous, source]
		elif step.kind == "fork":
			for option in step.options: _collect(option.steps, facts, source, previous)

func slot(npc: String, state) -> Array:
	if RETURNING_STAFF.has(npc) and (state.day < 2 or not state.estate_complete): return []
	var def = definitions[npc]
	var phase = Runtime.DayClock.phase(state.clock_minutes)
	if phase == "night": return []
	var schedule: Dictionary = def.schedule
	var where = String(schedule.get("midday" if phase=="noon" else phase, schedule.get("dawn", def.location)))
	where = where.trim_prefix("{").trim_suffix("}")
	if where == "closed": return []
	if where == "home": where = HOME.get(npc, def.location)
	if RETURNING_STAFF.has(npc) and where == RETURNING_STAFF[npc][0]: return RETURNING_STAFF[npc]
	if SLOTS.has(where): return SLOTS[where]
	var places = preload("res://scripts/chapters/town_places.gd")
	if where.begins_with("upper_house_") or where.begins_with("lower_house_"):
		if places.valid(where): return [where, Vector3(3,0,1)]
		var spec = places.entry(where)
		var hub = places.parent_hub(where)
		if not spec.is_empty(): return [hub, places.front(places.BUILDINGS[hub].find(spec)) + Vector3(3,0,-3)]
	var world = String(BASE.get(where, where))
	if world == "business": return [world, Vector3(-25,0,14)]
	if world == "upper": return [world, Vector3(-23,0,9)]
	if world == "lower": return [world, Vector3(12,0,11)]
	return [world, Vector3(3,0,-2)]
