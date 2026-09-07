extends Node

signal state_changed
signal toast_requested(message: String)

const EVIDENCE_CATALOG := {
	"impossible_wound": {
		"title": "Impossible wound",
		"fact": "Six frontal bullet wounds. No powder burns. No exit wounds.",
		"source": "Rose-garden examination"
	},
	"clean_knife": {
		"title": "Kessler's knife",
		"fact": "A butcher's boning knife was wiped clean and hidden beneath a hedge.",
		"source": "Rose-garden hedge"
	},
	"unnamed_victims": {
		"title": "The unnamed victims",
		"fact": "A woman and young boy were placed away from the six club members.",
		"source": "Birch line"
	},
	"club_token": {
		"title": "Ophion token",
		"fact": "Each of the six men carried the same private-club token.",
		"source": "Wexford's coat"
	},
	"boardinghouse_account": {
		"title": "Boardinghouse account",
		"fact": "The woman and boy had stayed locally. Someone knew they were here.",
		"source": "Mrs. Vale, boardinghouse keeper"
	},
	"meeting_ledger": {
		"title": "Club meeting ledger",
		"fact": "The six men met on the final Thursday of each month.",
		"source": "Ophion Club ledger"
	},
	"service_plan": {
		"title": "Contradictory floor plan",
		"fact": "The service corridor extends beyond the club's recorded foundation.",
		"source": "Municipal plan and direct observation"
	},
	"corroded_whistle": {
		"title": "Corroded police whistle",
		"fact": "A police whistle lies in old silt beneath the estate.",
		"source": "Tunnel floor"
	}
}

const VALID_LINKS := {
	"clean_knife|impossible_wound": {
		"id": "staged_ritual",
		"title": "Violence without a weapon",
		"summary": "The knife was present but did not make the fatal wounds. The scene was arranged."
	},
	"boardinghouse_account|unnamed_victims": {
		"id": "erased_identities",
		"title": "People made into transients",
		"summary": "The official description is convenient, not true. The victims had names and a local trail."
	},
	"club_token|meeting_ledger": {
		"id": "ophion_circle",
		"title": "The Ophion circle",
		"summary": "The dead were not merely acquaintances. They maintained a private monthly practice."
	},
	"meeting_ledger|service_plan": {
		"id": "beneath_the_club",
		"title": "Meetings below the recorded club",
		"summary": "The ledger's private meetings coincide with a corridor the official plan denies."
	}
}

var discovered: Array[String] = []
var inventory: Array[String] = []
var links: Array[String] = []
var link_summaries: Dictionary = {}
var strength := 1
var perception := 1
var instability := 0.06
var current_slice := 0

func reset_demo() -> void:
	discovered.clear()
	inventory.clear()
	links.clear()
	link_summaries.clear()
	strength = 1
	perception = 1
	instability = 0.06
	current_slice = 0
	state_changed.emit()

func discover_evidence(evidence_id: String) -> bool:
	if evidence_id.is_empty() or discovered.has(evidence_id):
		return false
	discovered.append(evidence_id)
	instability = clampf(instability + 0.035, 0.0, 0.72)
	_recalculate_perception()
	state_changed.emit()
	return true

func add_inventory(item_id: String) -> bool:
	if item_id.is_empty() or inventory.has(item_id):
		return false
	inventory.append(item_id)
	state_changed.emit()
	return true

func remove_inventory(item_id: String) -> bool:
	if not inventory.has(item_id):
		return false
	inventory.erase(item_id)
	state_changed.emit()
	return true

func try_link(first_id: String, second_id: String) -> Dictionary:
	var ids := [first_id, second_id]
	ids.sort()
	var key: String = "%s|%s" % [ids[0], ids[1]]
	if not VALID_LINKS.has(key):
		instability = clampf(instability + 0.015, 0.0, 0.72)
		state_changed.emit()
		return {"ok": false, "message": "The line does not hold. The facts remain separate."}
	var link: Dictionary = VALID_LINKS[key]
	var link_id: String = link["id"]
	if links.has(link_id):
		return {"ok": false, "message": "That connection is already recorded."}
	links.append(link_id)
	link_summaries[link_id] = link
	instability = clampf(instability + 0.09, 0.0, 0.72)
	_recalculate_perception()
	state_changed.emit()
	return {"ok": true, "message": "LINKED — %s" % link["title"]}

func set_slice(index: int) -> void:
	current_slice = index
	state_changed.emit()

func add_instability(amount: float) -> void:
	instability = clampf(instability + amount, 0.0, 0.85)
	state_changed.emit()

func evidence_entry(evidence_id: String) -> Dictionary:
	return EVIDENCE_CATALOG.get(evidence_id, {})

func has_evidence(evidence_id: String) -> bool:
	return discovered.has(evidence_id)

func has_link(link_id: String) -> bool:
	return links.has(link_id)

func _recalculate_perception() -> void:
	perception = clampi(1 + int(discovered.size() / 2) + links.size(), 1, 5)

