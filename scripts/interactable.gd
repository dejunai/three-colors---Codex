extends Area3D
class_name EvidenceInteractable

var display_name := "Examine"
var description := ""
var evidence_id := ""
var inventory_id := ""
var action := ""
var one_shot := false
var disabled := false

func _ready() -> void:
	add_to_group("interactable")
	collision_layer = 4
	collision_mask = 0

func configure(
	new_display_name: String,
	new_description: String,
	new_evidence_id := "",
	new_inventory_id := "",
	new_action := "",
	new_one_shot := false
) -> void:
	display_name = new_display_name
	description = new_description
	evidence_id = new_evidence_id
	inventory_id = new_inventory_id
	action = new_action
	one_shot = new_one_shot

func interaction_text() -> String:
	if disabled:
		return ""
	return "[F / LEFT CLICK]  %s" % display_name.to_upper()

func interact() -> Dictionary:
	if disabled:
		return {"ok": false, "message": ""}
	var newly_discovered := false
	var newly_collected := false
	if not evidence_id.is_empty():
		newly_discovered = GameState.discover_evidence(evidence_id)
	if not inventory_id.is_empty():
		newly_collected = GameState.add_inventory(inventory_id)
	if one_shot and (newly_discovered or newly_collected or (evidence_id.is_empty() and inventory_id.is_empty())):
		disabled = true
	var message := description
	if not evidence_id.is_empty() and not newly_discovered:
		message = "%s\n\nAlready recorded in the case file." % description
	return {
		"ok": true,
		"message": message,
		"action": action,
		"target": self
	}

