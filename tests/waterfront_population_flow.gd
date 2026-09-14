extends SceneTree

const Catalog = preload("res://scripts/chapters/dialogue_catalog.gd")
const DayClock = preload("res://scripts/shared/day_clock.gd")
const CaseState = preload("res://case_state.gd")
const RESIDENTS = ["waterfront_cooper", "waterfront_tally_runner", "waterfront_ice_carrier", "waterfront_sail_mender", "waterfront_fish_porter", "waterfront_stevedore"]

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var catalog = Catalog.new()
	catalog.scan()
	var state = CaseState.new()
	state.started = true
	for resident in RESIDENTS:
		assert(catalog.definitions.has(resident), "Missing resident definition: " + resident)
		assert(catalog.definitions[resident].errors.is_empty(), str(catalog.definitions[resident].errors))
	for sample in [DayClock.MORNING, DayClock.NOON]:
		state.clock_minutes = sample
		var occupied: Dictionary = {}
		for resident in RESIDENTS:
			var slot: Array = catalog.slot(resident, state)
			assert(slot.size() == 2 and slot[0] == "waterfront", resident + " missing from waterfront")
			var key = str(slot[1])
			assert(not occupied.has(key), resident + " overlaps " + String(occupied.get(key, "")))
			occupied[key] = resident
	for sample in [DayClock.EVENING, DayClock.NIGHT]:
		state.clock_minutes = sample
		for resident in RESIDENTS:
			assert(catalog.slot(resident, state).is_empty(), resident + " should leave the waterfront after midday")
	print("WATERFRONT POPULATION PASS: ", RESIDENTS.size(), " ambient workers, distinct morning/noon placements, absent evening/night")
	quit()
