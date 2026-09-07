extends RefCounted

# Chapter One archive content, rendered through the shared panel manager.

func _case_file(g:Node) -> void:
	g._panel("case","Walter Corwin","PERSONAL EFFECTS  /  PRECINCT 4",true)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation",28)
	g.content.add_child(row)
	var left = VBoxContainer.new()
	left.custom_minimum_size.x = 280
	row.add_child(left)
	left.add_child(g._label("ON HIS PERSON",14,false))
	# A spare paperdoll, rendered in the same ink vocabulary as the file.
	var doll = Control.new()
	doll.custom_minimum_size = Vector2(250,190)
	left.add_child(doll)
	for rect in [Rect2(105,5,32,32),Rect2(88,40,65,83),Rect2(65,43,18,76),Rect2(158,43,18,76),Rect2(93,123,22,62),Rect2(127,123,22,62)]:
		var shape = ColorRect.new()
		shape.position = rect.position
		shape.size = rect.size
		shape.color = Color("707a67")
		doll.add_child(shape)
	left.add_child(g._label("STRENGTH    2\nPERCEPTION    %d" % g.state.perception(),21,false))
	left.add_child(g._label("Carried weight: %.1f / 12 kg\nSlots: %d / 10" % [4.6+(0.4 if g.state.evidence.has("knife") else 0),5+(1 if g.state.evidence.has("knife") else 0)],17,false))
	left.add_child(g._label("Strength governs carried weight.\nPerception grows through observation.",16,false))
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",12)
	row.add_child(right)
	right.add_child(g._label("CURRENT INQUIRY",14,false))
	right.add_child(g._label(g._objective(),23))
	right.add_child(g._label("EQUIPPED",14,false))
	right.add_child(g._label(g.state.coat+" · worn leather boots\nNotebook · pencil · service revolver\nFlask"+(" · sealed knife envelope" if g.state.evidence.has("knife") else ""),21))
	g._button("Inspect the flask",g._flask,right)
	g._button("Change to "+("plain wool coat" if g.state.coat == "Police coat" else "police coat"),func():
		g.state.coat = "Plain wool coat" if g.state.coat == "Police coat" else "Police coat"
		g._refresh_outfit()
		g._save_game()
		g._case_file(),right)
	g._button("Open the case file",g._journal,right)
	g._button("Return to the grounds",g._close)
	g._focus_first()

func _flask(g:Node) -> void:
	g._panel("case","The flask","PERSONAL EFFECTS")
	var levels = ["Empty. The metal carries no weight beyond itself.","A little left. Enough for one short pour.","Partly full. Two short pours remain.","Three short pours by Walter's reckoning."]
	g._paragraph(levels[g.state.flask])
	g._paragraph("A familiar weight. A brief narrowing of the world.\nIt has never promised anything more.",24)
	if g.state.flask > 0:
		g._button("Take a short pour",func():
			g._take_pour()
			g._close()
			g._toast("The edges settle. The facts remain.",4))
	g._button("Put it away",g._case_file)
	g._focus_first()

func _journal(g:Node) -> void:
	g._panel("journal","The preliminary case","WALTER CORWIN  /  ORIGINAL RECORD",true)
	g._paragraph(g._objective(),20)
	if g.state.evidence.is_empty(): g._paragraph("No observations recorded yet. The garden waits.",24)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",15)
	grid.add_theme_constant_override("v_separation",12)
	g.content.add_child(grid)
	for id in g.state.evidence:
		if not g.facts.has(id): continue
		var b = g._button(str(g.facts[id][0]),func(): g._fact(id),grid)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	g._paragraph("OBSERVATIONS IN RELATION",14)
	if g.state.evidence.has("naomi"):
		g._paragraph("A woman recorded without a name now has one: Naomi Freeman.\nThe original omission remains visible beside the later identification.",22)
	if g.state.evidence.has("wounds") and g.state.evidence.has("gas"):
		g._paragraph("Wounds without powder marks. Windows without blast damage.\nThe proposed accident accounts for neither observation.",22)
	elif g.state.evidence.has("eight"):
		g._paragraph("Six club members and two other people.\nThe separation of the scenes does not change the count.",22)
	else: g._paragraph("Further observations may clarify what these facts share.",20)
	for statement in g.state.statements: g._paragraph("— "+statement,19)
	if not g.state.report.is_empty():
		g._paragraph("REPORT: "+g.state.report,18)
		g._paragraph("Copies: "+", ".join(g.state.copies),17)
		if g.state.report_evidence.size() != g.state.evidence.size(): g._paragraph("New observations are in Walter's notebook. "+("File a dated supplement at the precinct; received copies remain unchanged." if g.state.intake_done else "Return to the field desk to include them in the prepared report."),17)
		if g.state.supplement_filed: g._paragraph("DATED SUPPLEMENT: %d observations recorded at filing." % g.state.supplement_evidence.size(),17)
	g._paragraph("The file records what Walter has observed. Opening it is never required to continue.",15)
	g._button("Personal effects",g._case_file)
	g._button("Close the file",g._close)
	g._focus_first()

func _fact(g:Node,id:String) -> void:
	var fact = g.facts[id]
	g._panel("fact",str(fact[0]),"CASE FILE  /  RECOVERABLE OBSERVATION")
	g._paragraph(str(fact[1]),27)
	g._paragraph("SOURCE\n"+g._source_for(id),18)
	g._button("Back to the file",g._journal)
	g._focus_first()

func _report_screen(g:Node) -> void:
	if g.state.intake_done:
		g._panel("report","Already received","THE ESTATE REPORT")
		g._paragraph("The precinct has received this report. Later observations belong in a dated supplement at the precinct.")
		g._button("Return to the grounds",g._close)
		g._focus_first()
		return
	g._panel("report","Put it in writing","THE FIELD DESK  /  PRELIMINARY REPORT")
	g._paragraph("Eight dead. Identities partly established.\nCause unresolved.\n\nThe report will contain the observations and statements Walter has recorded so far.",24)
	g._paragraph("How will you submit it?",24)
	g._button("File the observations; retain my notebook",func(): g._write_report("Observations filed","report_routine"))
	g._button("Request a full inquest; prepare a county copy",func(): g._write_report("Full inquest requested","report_inquest"))
	g._button("Continue examining before I file",g._close)
	g._focus_first()

func _board(g:Node) -> void:
	g._panel("board","What belongs beside what","CORWIN'S ROOM  /  THE CASE BOARD",true)
	g._paragraph("The cards reflect the investigation already made.\nReading them does not decide whether it can continue.",19)
	var grid=GridContainer.new()
	grid.columns=2
	grid.add_theme_constant_override("h_separation",18)
	grid.add_theme_constant_override("v_separation",18)
	g.content.add_child(grid)
	for id in g.state.evidence:
		if id=="exemption" or not g.facts.has(id): continue
		var box=VBoxContainer.new()
		box.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		grid.add_child(box)
		var b=g._button(str(g.facts[id][0]),func(): g._fact(id),box)
		b.custom_minimum_size.y=68
		b.clip_text=true
		box.custom_minimum_size.x=270
		var source=g._label(g._source_for(id),14,false)
		box.add_child(source)
	if g.state.evidence.has("naomi") and g.state.evidence.has("lodging"):
		g._paragraph("UNIDENTIFIED WOMAN  →  NAOMI FREEMAN  →  A LOCAL ADDRESS\nMrs. Almy's statement and the meal ledger support the same identification.",22)
	if g.state.evidence.has("lay_lead"):
		g._paragraph("AN UNPAID LAY  →  DOCUMENT NOT EXAMINED\nThe claim is a question to investigate. It does not establish why she was killed.",22)
	if g.state.evidence.has("intake"):
		g._paragraph("SIX IN THE HEADING  ↔  EIGHT IN WALTER'S REPORT\nThe disagreement has a source on each side. Neither page replaces the other.",22)
	if g.state.evidence.has("municipal_foundation"):
		g._paragraph("SERVICE PLAN  ↔  MUNICIPAL SHEET  ↔  MEASURED PASSAGE\nTwo drawings agree on a limit the passage exceeds. The extension remains unexplained.",22)
	if g.state.evidence.has("crew") and g.state.statements.has("The gardener saw the woman at the service door. Ask the steward."):
		g._paragraph("THE SERVICE DOOR\nThe gardener placed the unidentified woman there once. The groundskeeper keeps a fixed distance from it now. Neither observation explains the other.",22)
	if g.state.evidence.has("old_woman") and g.state.evidence.has("behan_name"):
		g._paragraph("A DELUSION OF BEING CHOSEN  ↔  BEWARE THE OLD GODS\nA priest calls the club's founding myth a vanity. An unnamed woman warns him it isn't only that. Two halves of an argument neither speaker knew the other was making.",22)
	if g.state.evidence.has("crew") and g.state.evidence.has("pantry_lead"):
		g._paragraph("THE GROUNDSKEEPER  ↔  THE BARMAN\nOne keeps his distance from a door in daylight. The other names the same door and will not go near it either. Neither will say why.",22)
	g._button("Read the complete notebook",g._journal)
	g._button("Step away from the board",g._close)
	g._focus_first()

func _town_complete(g:Node) -> void:
	g._panel("ending","A name brought home","END OF THE FIRST TOWN INQUIRY")
	g._paragraph("Naomi Freeman.\n\nThe town has not changed its account.\nWalter's account has become harder to dismiss.",27)
	g._paragraph("Notebook: %d observations\nEstate report: %d observations, retained as submitted\nDated supplements: %d\nCounty dispatch: %s" % [g.state.evidence.size(),g.state.report_evidence.size(),g.state.supplement_history.size(),"recorded" if g.state.county_dispatched else "none"],20)
	g._paragraph("The service passage beneath the estate is open for inquiry. Your notebook and the copies already filed remain separate records.",19)
	g._button("Return to the service passage" if g.state.tunnel_complete else "Continue to the service passage",g._begin_tunnel)
	if g.state.tunnel_complete: g._paragraph(g._custody_result(),20)
	g._button("Review the board",g._board)
	g._button("Continue exploring",g._close)
	g._button("Save and return to title",func(): g._save_game(); g._title())
	g._button("Save and quit",func(): g._save_game(); g.get_tree().quit())
	g._focus_first()

