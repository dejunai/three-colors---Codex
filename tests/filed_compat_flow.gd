extends SceneTree

func _initialize() -> void:
	var C=load("res://case_state.gd")
	var R=load("res://scripts/shared/dialogue_runtime.gd")
	var state=C.new()
	state.intake_done=true
	state.supplement_filed=true
	state.supplement_evidence.assign(["naomi"])
	var old=state.pack()
	old.erase("supplement_history")
	var restored=C.new()
	assert(restored.restore(old))
	assert(R.has_filed_evidence(restored,"naomi"), "Accepted old saves retain received supplements")
	assert(R.has_filed_evidence(old,"naomi"), "Dictionary snapshots follow the same rules")
	state.supplement_history=[{"evidence":["eight"]}]
	assert(not R.has_filed_evidence(state,"naomi"), "Mutable snapshot cannot override actual history")
	state.supplement_filed=false
	assert(R.has_filed_evidence(state,"eight"), "History survives current flag changes")
	state.intake_done=false
	assert(not R.has_filed_evidence(state,"eight"), "History does not bypass intake")
	assert(not R.has_filed_evidence(null,"eight"))
	assert(not R.has_filed_evidence({"intake_done":true,"supplement_history":"bad"},"eight"))
	assert(not R.has_filed_evidence({"intake_done":true,"report_evidence":["behan_name"]},"ophion_name"), "Filed IDs stay exact")
	print("FILED COMPAT PASS: old saves, history authority, intake, dictionaries, exact IDs")
	quit()
