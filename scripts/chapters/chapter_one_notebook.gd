extends RefCounted

# Render detached values only. No CaseState reference, discovery, linking, or save API.
func render(view:CanvasLayer,snapshot:Dictionary,facts:Dictionary,links:Dictionary,close:Callable) -> void:
	var p = int(snapshot.perception)
	view._paragraph("CAUSE UNRESOLVED  (PERCEPTION %d)" % p,22)
	view._paragraph("CONNECTIONS DRAWN",18)
	var found = false
	for entry in links.values():
		if entry.id in snapshot.links:
			found = true
			view._paragraph(str(entry.title)+"\n"+str(entry.summary),20)
	if not found: view._paragraph("No connections drawn yet.",20)
	view._paragraph("RECORDED OBSERVATIONS",18)
	if snapshot.evidence.is_empty(): view._paragraph("No observations recorded yet.")
	for id in snapshot.evidence:
		if not facts.has(id): continue
		var paper = preload("res://scripts/shared/case_paper.gd").new()
		view.content.add_child(paper)
		var entry = VBoxContainer.new()
		entry.add_theme_constant_override("separation",12)
		paper.add_child(entry)
		entry.add_child(view._label(str(facts[id][0]),24))
		entry.add_child(view._label(str(facts[id][1]),21))
		var source = view._label(str(snapshot.sources.get(id,facts[id][2])),16,false)
		source.add_theme_color_override("font_color",Color("79533c"))
		entry.add_child(source)
	for statement in snapshot.statements: view._paragraph("— "+str(statement),19)
	view._button("Close the notebook",close)
	view._focus_first()
