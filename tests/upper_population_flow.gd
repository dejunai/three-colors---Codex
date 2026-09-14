extends SceneTree

const Catalog = preload("res://scripts/chapters/dialogue_catalog.gd")
const DayClock = preload("res://scripts/shared/day_clock.gd")
const CaseState = preload("res://case_state.gd")
const RESIDENTS = ["upper_housemaid", "upper_driver", "upper_gardener", "upper_delivery_boy", "upper_companion"]

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var catalog = Catalog.new()
	catalog.scan()
	var state = CaseState.new()
	state.started = true
	for resident in RESIDENTS:
		assert(catalog.definitions.has(resident), "Missing resident definition: " + resident)
		assert(catalog.definitions[resident].errors.is_empty(), str(catalog.definitions[resident].errors))
	var seen_by_phase: Dictionary = {}
	for sample in [DayClock.MORNING, DayClock.NOON, DayClock.EVENING]:
		state.clock_minutes = sample
		var occupied: Dictionary = {}
		for resident in RESIDENTS:
			var slot: Array = catalog.slot(resident, state)
			assert(slot.size() == 2 and slot[0] == "upper", resident + " missing from upper district")
			var key = str(slot[1])
			assert(not occupied.has(key), resident + " overlaps " + String(occupied.get(key, "")))
			occupied[key] = resident
		seen_by_phase[DayClock.phase(sample)] = occupied.size()
	state.clock_minutes = DayClock.NIGHT
	for resident in RESIDENTS:
		assert(catalog.slot(resident, state).is_empty(), resident + " should be home at night")
	print("UPPER POPULATION PASS: ", RESIDENTS.size(), " ambient residents, distinct daytime placements: ", seen_by_phase)
	quit()
