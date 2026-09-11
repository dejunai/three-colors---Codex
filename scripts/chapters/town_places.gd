extends RefCounted

# Stable save identifiers. Entries: id, sign, interior dressing, depth.
const BUILDINGS = {
	"business": [
		["schoolhouse","SCHOOLHOUSE","school","light"],
		["museum","LOCAL MUSEUM","museum","light"],
		["stationer","STATIONER · ROOMS ABOVE","shop","occupied"],
		["haberdasher","HABERDASHER · ROOMS ABOVE","shop","light"],
		["printer","PRINTING OFFICE","shop","exterior"],
		["repairer","CLOCK REPAIRS","shop","exterior"]],
	"upper": [
		["upper_house_1","RESIDENCE No. 1","parlor","occupied"],
		["upper_house_2","RESIDENCE No. 2","parlor","light"],
		["upper_house_3","RESIDENCE No. 3","parlor","light"],
		["upper_house_4","RESIDENCE No. 4","parlor","light"],
		["upper_house_5","RESIDENCE No. 5","parlor","exterior"],
		["upper_house_6","RESIDENCE No. 6","parlor","exterior"]],
	"lower": [
		["lower_house_1","DWELLING No. 1","home","occupied"],
		["lower_house_2","DWELLING No. 2","home","light"],
		["lower_house_3","DWELLING No. 3","home","light"],
		["lower_house_4","DWELLING No. 4","home","light"],
		["lower_house_5","DWELLING No. 5","home","exterior"],
		["lower_house_6","DWELLING No. 6","home","exterior"]]
}
const HUB_TITLES = {"waterfront":"The waterfront","upper":"Upper residential quarter","business":"Business district","lower":"Lower residential quarter","morgue":"Precinct morgue","post_office":"Pickman Street post office"}

static func entry(id:String) -> Array:
	for hub in BUILDINGS:
		for spec in BUILDINGS[hub]:
			if spec[0]==id: return spec
	return []

static func parent_hub(id:String) -> String:
	for hub in BUILDINGS:
		for spec in BUILDINGS[hub]:
			if spec[0]==id: return hub
	return ""

static func valid(id:String) -> bool:
	if HUB_TITLES.has(id): return true
	var spec=entry(id)
	return not spec.is_empty() and spec[3]!="exterior"

static func title(id:String) -> String:
	if HUB_TITLES.has(id): return HUB_TITLES[id]
	var spec=entry(id)
	return spec[1] if not spec.is_empty() else id

static func front(index:int) -> Vector3:
	return Vector3([-19,0,19][index%3],0,-5 if index<3 else 21)
