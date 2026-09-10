extends RefCounted

# Chapter One archive content, rendered through the shared panel manager.

# Meaningful connections between two pieces of evidence, confirmed only when
# the player draws them on the board rather than revealed automatically.
# Keys are two evidence ids, sorted and joined by "|"; this table is Chapter
# One's own content and deliberately does not live in case_state.gd, which
# stays chapter-agnostic and only counts confirmed link ids.
const LINKS := {
	"estate_day_book|service_work": {"id":"staff_book_entry", "title":"AN ENTRY IN THE STAFF BOOK", "summary":"Almy recalls Naomi asking about estate work. The staff book records N. Freeman doing day work in the kitchen wing. The entry is consistent with her account, without establishing why Naomi died."},
	"curriculum_abridgment|reader_omission_letter": {"id":"reader_omission", "title":"THE ABRIDGMENT IN WRITING", "summary":"Abernathy describes omitting the crew list. The school's covering letter records that instruction and committee approval. The document corroborates the decision he acknowledged."},

	"eight|press_suppression": {"id": "press_count", "title": "THE PAPER CHOSE SIX", "summary": "Walter counted eight dead. The editor admits that his paper reported six subscribers. The omission is acknowledged by its source.", "deduction": "Walter counted eight dead. The editor admits that his paper reported six subscribers. The omission is acknowledged by its source."},
	"kessler_knife_confirmed|knife": {"id": "knife_owner", "title": "A TOOL WITH AN OWNER", "summary": "The knife observed at the estate now has an identified owner: Mrs. Kessler recognizes Otto's tool and says he carried it to the club.", "deduction": "The knife observed at the estate now has an identified owner: Mrs. Kessler recognizes Otto's tool and says he carried it to the club."},
	"fused_hairspring_anomaly|watch": {"id": "watch_examination", "title": "THE STOPPED MOVEMENT", "summary": "The watch found in the garden has been examined by the clockmaker. His account of its fused hairspring adds a mechanical observation; it does not establish the cause.", "deduction": "The watch found in the garden has been examined by the clockmaker. His account of its fused hairspring adds a mechanical observation; it does not establish the cause."},
	"naomi|new_bedford_letters": {"id": "letters_addressed", "title": "A NAME ON THE ENVELOPES", "summary": "Mrs. Almy identifies Naomi Freeman. The postmaster reports letters addressed to that name from New Bedford, marked for a mother and brother.", "deduction": "Mrs. Almy identifies Naomi Freeman. The postmaster reports letters addressed to that name from New Bedford, marked for a mother and brother."},
	"club_devotion|maternal_delusion": {"id": "same_maternal_words", "title": "THE SAME WORDS AT HOME", "summary": "The steward and Mrs. Kessler independently recall Kessler saying she would have them home and was no different from any mother. Neither account identifies her.", "deduction": "The steward and Mrs. Kessler independently recall Kessler saying she would have them home and was no different from any mother. Neither account identifies her."},
	"lay_lead|quay_inquiry": {"id": "claim_at_quay", "title": "A CLAIM CALLED AN INQUIRY", "summary": "Mrs. Almy recalls Naomi seeking an unpaid lay. Mr. Vale remembers correcting the quay clerk who reduced her claim to an inquiry.", "deduction": "Mrs. Almy recalls Naomi seeking an unpaid lay. Mr. Vale remembers correcting the quay clerk who reduced her claim to an inquiry."},
	"fabricated_foul_air|gas": {"id": "gas_before_exam", "title": "AN EXPLANATION BEFORE EXAMINATION", "summary": "The visible scene shows no blast damage. The editor says Fenn's associate supplied the foul-air explanation before any autopsy. The timing of that explanation is now recorded.", "deduction": "The visible scene shows no blast damage. The editor says Fenn's associate supplied the foul-air explanation before any autopsy. The timing of that explanation is now recorded."},
	"lodging|naomi": {
		"id": "naomi_address",
		"title": "TWO RECORDS, ONE WOMAN",
		"summary": "Almy identifies Naomi Freeman. Her meal ledger records N. Freeman and two meals, with a balance carried forward. The contemporary entry corroborates her recollection; it does not establish the boy's name.",
		"deduction": "Almy identifies Naomi Freeman. Her meal ledger records N. Freeman and two meals, with a balance carried forward. The contemporary entry corroborates her recollection; it does not establish the boy's name."
	},
	"lay_lead|naomi": {
		"id": "naomi_lay",
		"title": "THE CLAIM HAS A NAME NOW",
		"summary": "Almy identifies Naomi Freeman and recalls her seeking an unpaid whaling lay. Walter has not examined the claim. This is an account of what brought Naomi to town, not an explanation for her death.",
		"deduction": "Almy identifies Naomi Freeman and recalls her seeking an unpaid whaling lay. Walter has not examined the claim. This is an account of what brought Naomi to town, not an explanation for her death."
	},
	"eight|intake": {
		"id": "count_disagreement",
		"title": "THE HEADING DISAGREES WITH THE COUNT",
		"summary": "Walter's recorded count is eight. The captain's heading received at intake names six club members and an apparent accident. Both records are preserved; the heading does not account for the other two deaths.",
		"deduction": "Walter's recorded count is eight. The captain's heading received at intake names six club members and an apparent accident. Both records are preserved; the heading does not account for the other two deaths."
	},
	"lower_foundation|municipal_foundation": {
		"id": "two_drawings",
		"title": "TWO DRAWINGS, ONE LIMIT",
		"summary": "The municipal sheet and service plan end at the same support. Walter's measured passage continues beyond it. Their agreement corroborates the discrepancy, not its date, purpose or maker.",
		"deduction": "The municipal sheet and service plan end at the same support. Walter's measured passage continues beyond it. Their agreement corroborates the discrepancy, not its date, purpose or maker."
	},
	"behan_name|old_woman": {
		"id": "chosen_delusion",
		"title": "A DELUSION OF BEING CHOSEN",
		"summary": "Behan describes the club's belief in being chosen. An unnamed woman warns Walter about the old gods. Their statements can be compared; neither establishes the existence or nature of a covenant.",
		"deduction": "Behan describes the club's belief in being chosen. An unnamed woman warns Walter about the old gods. Their statements can be compared; neither establishes the existence or nature of a covenant."
	},
	"crew|pantry_lead": {
		"id": "same_door",
		"title": "THE GROUNDSKEEPER AND THE STEWARD",
		"summary": "The groundskeeper keeps a precise distance from the kitchen-wing service entrance. The steward names a boarded pantry door in that wing and refuses to show it. Both accounts draw attention to the wing; neither explains the behavior or makes the two doors identical.",
		"deduction": "The groundskeeper keeps a precise distance from the kitchen-wing service entrance. The steward names a boarded pantry door in that wing and refuses to show it. Both accounts draw attention to the wing; neither explains the behavior or makes the two doors identical."
	}
}

static func _link_key(a:String,b:String) -> String:
	var ids=[a,b]
	ids.sort()
	return "%s|%s" % [ids[0],ids[1]]

# Returns the link entry on success (already-confirmed or newly confirmed),
# or an empty dictionary if the pair names no real connection.
static func _try_link(g:Node,a:String,b:String) -> Dictionary:
	if a==b or not g.state.evidence.has(a) or not g.state.evidence.has(b): return {}
	var key=_link_key(a,b)
	if not LINKS.has(key): return {}
	var link:Dictionary=LINKS[key]
	g.state.record_link(link.id)
	return link

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
	var equipped_text = g.state.coat+" · worn leather boots\nNotebook · pencil · service revolver (%d/6 rounds)\n" % g.state.ammo + ("Flask (lost on descent)" if g.state.flask_spilled else "Flask") + (" · sealed knife envelope" if g.state.evidence.has("knife") else "")
	right.add_child(g._label(equipped_text,21))
	g._button("Inspect the flask",g._flask,right)
	g._button("Change to "+("plain wool coat" if g.state.coat == "Police coat" else "police coat"),func():
		g.state.coat = "Plain wool coat" if g.state.coat == "Police coat" else "Police coat"
		g._refresh_outfit()
		g._save_game()
		g._case_file(),right)
	g._button("Read the notebook",g._notebook,right)
	g._button("Open the case file",g._journal,right)
	g._button("Return to the grounds",g._close)
	g._focus_first()

func _flask(g:Node) -> void:
	g._panel("case","The flask","PERSONAL EFFECTS")
	if g.state.flask_spilled:
		g._paragraph("Lost in the dark below.",27)
		var lost_text = "All three short pours were" if g.state.flask_spill_amount == 3 else ("Two short pours were" if g.state.flask_spill_amount == 2 else ("One short pour was" if g.state.flask_spill_amount == 1 else "The flask was already empty when it"))
		g._paragraph("%s lost when a jagged spur of rock tore the flask from its strap on the descent.\n\nHe did not chase it into the dark. The case had only ever let the flask hold as much peace as it had use for, and had decided it needed him thirsty now." % lost_text, 22)
		g._paragraph("The severed leather strap hangs empty at his belt.", 18)
	else:
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
	g._button("Read the notebook",g._notebook)
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
	# First control, above the evidence list: available without opening a card.
	var link_button=g._button("Link",func(): _link_picker(g,""))
	var count=0
	for id in g.state.evidence:
		if g.facts.has(id): count+=1
	link_button.disabled=count<2
	if count<2: link_button.tooltip_text="Two recorded observations are needed."
	g._paragraph("Walter’s observations",19)
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
		var b=g._button(str(g.facts[id][0]),func(): _link_observation(g,id),box)
		b.custom_minimum_size.y=68
		b.clip_text=true
		box.custom_minimum_size.x=270
		var source=g._label(g._source_for(id),14,false)
		box.add_child(source)
	if g.state.evidence.has("crew") and g.state.statements.has("The gardener saw the woman at the service door. Ask the steward."):
		g._paragraph("THE SERVICE DOOR\nThe gardener placed the unidentified woman there once. The groundskeeper keeps a fixed distance from it now. Neither observation explains the other.",22)
	var confirmed=false
	for entry in LINKS.values():
		if not g.state.has_link(entry.id): continue
		if not confirmed:
			g._paragraph("CONNECTIONS DRAWN",14)
			confirmed=true
		g._paragraph(str(entry.title)+"\n"+str(entry.summary),22)
	g._paragraph("CAUSE UNRESOLVED  (PERCEPTION %d)\nA fuller record sharpens the questions. It does not supply an answer absent from the evidence." % g.state.perception(),22)
	if g.state.evidence.has("eight") and g.state.evidence.has("intake"):
		g._paragraph("THE RECORDED COUNT\nEight deaths in Walter's notes; six club members in the captain's heading. Both sources remain on file.",20)
	if g.state.evidence.has("lower_foundation"):
		g._paragraph("THE MEASURED PASSAGE\nWalter measured a passage beyond the recorded foundation. Its cause remains unestablished.",20)
	g._button("Read the complete notebook",g._journal)
	g._button("Step away from the board",g._close)
	g._focus_first()

func _link_observation(g:Node,id:String) -> void:
	if not g.state.evidence.has(id) or not g.facts.has(id): return
	g._panel("board",str(g.facts[id][0]),"THE CASE BOARD / SELECTED OBSERVATION")
	g._paragraph(str(g.facts[id][1]),25)
	g._paragraph("SOURCE\n"+g._source_for(id),18)
	if g.state.evidence.size()>1: g._button("Link",func(): _link_picker(g,id))
	else: g._paragraph("Record another observation before drawing a connection.",20)
	g._button("Back to the board",func(): _board(g))
	g._focus_first()

func _link_picker(g:Node,first_id:String) -> void:
	if first_id.is_empty():
		g._panel("board","Choose the first observation","THE CASE BOARD / LINK",true)
		for id in g.state.evidence:
			if not g.facts.has(id): continue
			g._button(str(g.facts[id][0]),func(): _link_picker(g,id))
			g._paragraph(str(g.facts[id][1]),20)
		g._button("Cancel",func(): _board(g))
		g._focus_first()
		return
	if not g.state.evidence.has(first_id) or not g.facts.has(first_id): return
	g._panel("board","Choose a second observation","THE CASE BOARD / COMPARE NOTES",true)
	g._paragraph("LINK FROM: "+str(g.facts[first_id][0]),22)
	g._paragraph("Select another observation below. The first is left out of this list.",19)
	for id in g.state.evidence:
		if id==first_id or not g.facts.has(id): continue
		g._button(str(g.facts[id][0]),func(): _link_result(g,first_id,id))
		g._paragraph(str(g.facts[id][1]),20)
		g._paragraph(g._source_for(id),16)
	g._button("Cancel",func(): _link_observation(g,first_id))
	g._focus_first()

static func _negative_feedback(g:Node,a:String,b:String) -> String:
	var key = _link_key(a,b)
	match key:
		"watch|wounds":
			return "Walter holds the stop-watch beside the injury notes. 03:17 marks an exact minute, but the clean puncture above Judge Wexford's brow offers no powder burn or caliber to match it. A timestamp and a wound are two cards on the same table, but the hand that pulled the trigger remains absent between them."
		"knife|wounds":
			return "The knife beneath the hedge is a heavy butcher's tool with a clean blade. The wounds in the rose garden are neat, circular punctures with no powder burn and no exit wound. A boning knife did not cause these deaths, and tying them together would only mislead the inquiry."
		"register|watch":
			return "Five names inscribed for six places, and a watch filed blank. Both hint at an absent sixth man, but neither supplies the identity. Tying an omission to an erased serial number only doubles the blank without filling in a letter."
		"naomi|shoes":
			return "The resoled shoes belonged to the child found behind the birches. While Naomi Freeman is likely the woman beside him, the child's footwear does not establish their legal relationship or explain why either died in the garden."
		"gas|wounds":
			return "The intact terrace windows disprove an explosion, while the puncture wounds demonstrate deliberate, targeted violence. Pointing twine between a ruled-out accident and an execution only restates what didn't happen."
		"knife|watch":
			return "A butcher's knife and an erased pocket watch. Both were found at the estate, but they belong to different hands and different moments. Walter lets the twine drop; an investigator cannot forge a murder weapon out of an unexplained timepiece."
		"intake|wounds":
			return "The precinct's intake ledger accepts the field report, but it cannot explain how the six men died. Filing paperwork alongside ballistics notes does not solve the lack of powder burns."
		"crew|gardener":
			return "The gardener and the groundskeeper work the same grounds under different instructions. One reported the bodies; the other avoids the kitchen door. Their duties do not connect without the steward between them."
		"behan_name|naomi":
			return "Father Behan spoke of the town's founding families, not of a boarder on Pickman Street. Naomi Freeman's presence in town has no record in the parish register."
		"lodging|old_woman":
			return "Mrs. Almy rents clean rooms to quiet visitors; the woman outside Kessler's shop speaks of deep covenants and old sea gods. Their accounts do not cross."
		_:
			if (a in ["wounds","eight","knife","watch","gas","shoes"] and b in ["naomi","lodging","lay_lead","municipal_foundation"]) or (b in ["wounds","eight","knife","watch","gas","shoes"] and a in ["naomi","lodging","lay_lead","municipal_foundation"]):
				return "Physical debris from the estate lawn cannot explain archival records or boardinghouse accounts from town. Walter steps back; tying twine between physical evidence and a town rumor invents a bridge where none exists."
			elif a in ["municipal_foundation","lower_foundation"] or b in ["municipal_foundation","lower_foundation"]:
				return "Architectural surveys mark stone and mortar beneath the foundation; this observation speaks to human testimony and motive. Until an entrance or passage is proven between them, the blue-prints and the witness cards remain separate."
			elif a in ["behan_name","old_woman"] or b in ["behan_name","old_woman"]:
				return "Theological warnings and civic lore speak in dread and metaphor, while the rest of the case demands cold facts and measurable dates. Forcing twine between them only clouds the board with speculation."
			else:
				return "Walter turns the two cards over in his fingers. The facts share the same morning, but neither explains or corroborates the other. Drawing twine between them would be a guess, not an observation."

func _link_result(g:Node,first_id:String,second_id:String) -> void:
	if first_id==second_id or not g.state.evidence.has(first_id) or not g.state.evidence.has(second_id): return
	var before = g.state.perception()
	var known = g.state.links.duplicate()
	var link = _try_link(g,first_id,second_id)
	var already = not link.is_empty() and known.has(link.id)
	var heading = "This link makes sense." if not link.is_empty() else "That link makes no sense."
	if already: heading = "This connection is already recorded."
	g._panel("board",heading,"THE CASE BOARD / CONNECTION RESULT")
	g._paragraph(str(g.facts[first_id][0])+"\n+\n"+str(g.facts[second_id][0]),21)
	if link.is_empty():
		var commentary = _negative_feedback(g,first_id,second_id)
		g._paragraph(commentary,22)
		g._paragraph("These observations do not establish a connection. The facts remain separate.",20)
		g._paragraph("Nothing changed. No evidence or Perception was lost.",18)
	else:
		g._paragraph(str(link.title)+"\n"+str(link.summary),24)
		if link.has("deduction") and str(link.deduction) != str(link.summary):
			g._paragraph(str(link.deduction),21)
		var after = g.state.perception()
		if not already: g._save_game()
		if after>before:
			g._paragraph("Connection recorded on the board and in the notebook.\nPERCEPTION: %d → %d" % [before,after],20)
		elif already:
			g._paragraph("No duplicate was added. Perception remains %d." % after,20)
		else:
			g._paragraph("Connection recorded on the board and in the notebook.\nPerception remains %d; its bonus from connections is already at its limit." % after,20)
	g._button("Back to the board",func(): _board(g))
	g._button("Compare another observation",func(): _link_picker(g,first_id))
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

