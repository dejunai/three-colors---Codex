extends RefCounted

# Render detached values only. No CaseState reference, discovery, linking, or save API.
func render(view:CanvasLayer,snapshot:Dictionary,facts:Dictionary,links:Dictionary,close:Callable) -> void:
	var p = int(snapshot.perception)
	view._paragraph("CAUSE UNRESOLVED  (PERCEPTION %d)" % p,22)
	if snapshot.evidence.is_empty(): view._paragraph("No observations recorded yet.")
	for id in snapshot.evidence:
		if not facts.has(id): continue
		view._paragraph(str(facts[id][0]),22)
		view._paragraph(str(facts[id][1]),20)
		view._paragraph(str(snapshot.sources.get(id,facts[id][2])),16)
	view._paragraph("CONNECTIONS DRAWN",18)
	var found = false
	for entry in links.values():
		if entry.id in snapshot.links:
			found = true
			view._paragraph(str(entry.title)+"\n"+str(entry.summary),20)
	if not found: view._paragraph("No connections drawn yet.",20)
	for statement in snapshot.statements: view._paragraph("— "+str(statement),19)
	view._button("Close the notebook",close)
	view._focus_first()
