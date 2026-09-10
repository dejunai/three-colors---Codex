extends RefCounted

const VERSION = 9
var dialogue_state = preload("res://scripts/shared/dialogue_state.gd").new()
var evidence: Array[String] = []
var links: Array[String] = []
var statements: Array[String] = []
var visited: Array[String] = []
var report = ""
var copies: Array[String] = []
var report_evidence: Array[String] = []
var report_statements: Array[String] = []
var flask = 3
var coat = "Police coat"
var minutes = 0.0 # Real walking minutes retained for existing pacing probes.
var clock_minutes = 360.0
var timed_conversations: Array[String] = []
var position = Vector3(0, 0.1, 36)
var yaw = 0.0
var started = false
var finished = false
var world = "estate"
var estate_complete = false
var intake_done = false
var supplement_filed = false
var county_dispatched = false
var supplement_evidence: Array[String] = []
var county_evidence: Array[String] = []
var inquiry_topics: Array[String] = []
var supplement_history: Array = []
var tunnel_complete = false
var county_statements: Array[String] = []
var report_sources: Dictionary = {}
var county_sources: Dictionary = {}
var ammo = 6
var flask_spilled = false
var flask_spill_amount = 0
var drowned_dead = false
# Staging milestones are explicit; re-entering a room never advances a day.
var rose_bodies_removed = false
var birch_bodies_removed = false
var estate_visits_completed = 0
var day = 1
var steward_visits = 0
var lounge_exited = false
var montage_index = -1

func steward_ready() -> bool:
	return visited.has("almy") and day == 3 and steward_visits >= 2 and coat == "Plain wool coat"

func strength() -> int:
	return 2

func discover(id: String) -> void:
	if not evidence.has(id): evidence.append(id)

func record(id: String) -> void:
	if not statements.has(id): statements.append(id)

func record_link(id: String) -> void:
	if not links.has(id): links.append(id)

func has_link(id: String) -> bool:
	return links.has(id)

func perception() -> int:
	# A deliberate connection is worth more than raw collection: full evidence
	# credit needs volume (9+ observations); full link credit needs only three
	# meaningful ones drawn by hand. Chapter-specific validity of a link pair
	# lives with the chapter's own content, not here — this just counts what
	# was confirmed.
	return 2 + mini(3, evidence.size() / 3) + mini(3, links.size())

func complete_report(mode: String, sources:Dictionary={}) -> void:
	if intake_done: return
	report = mode
	report_evidence.assign(evidence)
	report_statements.assign(statements)
	report_sources=sources.duplicate(true)
	copies.assign(["Walter's notebook", "Precinct intake"])
	if mode == "Full inquest requested": copies.append("County registrar — outgoing copy")

func receive_report() -> void:
	intake_done = true
	if report == "Full inquest requested":
		county_dispatched = true
		county_evidence.assign(report_evidence)
		county_statements.assign(report_statements)
		county_sources=report_sources.duplicate(true)
		copies.erase("County registrar — outgoing copy")
		if not copies.has("County registrar — dispatched copy"): copies.append("County registrar — dispatched copy")

func file_supplement(send_county: bool, sources:Dictionary={}) -> void:
	supplement_filed = true
	supplement_evidence.assign(evidence)
	supplement_history.append({"evidence":evidence.duplicate(),"statements":statements.duplicate(),"sources":sources.duplicate(true),"county":send_county,"sequence":supplement_history.size()+1})
	if not copies.has("Precinct — dated supplement"): copies.append("Precinct — dated supplement")
	if send_county:
		county_dispatched = true
		if not copies.has("County registrar — dated supplement"): copies.append("County registrar — dated supplement")

func pack() -> Dictionary:
	return {"version":VERSION,"dialogue_state":dialogue_state.pack(),"clock_minutes":clock_minutes,"timed_conversations":timed_conversations,"rose_bodies_removed":rose_bodies_removed,"birch_bodies_removed":birch_bodies_removed,"estate_visits_completed":estate_visits_completed,"day":day,"steward_visits":steward_visits,"lounge_exited":lounge_exited,"montage_index":montage_index,"report_sources":report_sources,"county_sources":county_sources,"tunnel_complete":tunnel_complete,"county_statements":county_statements,"evidence":evidence,"links":links,"statements":statements,"visited":visited,
		"report":report,"copies":copies,"report_evidence":report_evidence,"report_statements":report_statements,"flask":flask,"coat":coat,"minutes":minutes,
		"position":[position.x,position.y,position.z],"yaw":yaw,"started":started,"finished":finished,
		"world":world,"estate_complete":estate_complete,"intake_done":intake_done,
		"supplement_filed":supplement_filed,"county_dispatched":county_dispatched,
		"supplement_evidence":supplement_evidence,"county_evidence":county_evidence,"inquiry_topics":inquiry_topics,"supplement_history":supplement_history,
		"ammo":ammo,"flask_spilled":flask_spilled,"flask_spill_amount":flask_spill_amount,"drowned_dead":drowned_dead}

func restore(d: Dictionary) -> bool:
	if int(d.get("version",0)) not in [1,2,3,4,5,6,7,8,VERSION]: return false
	for key in ["evidence","links","statements","visited","copies","report_evidence","report_statements","supplement_evidence","county_evidence","inquiry_topics","supplement_history","county_statements","timed_conversations"]:
		if not d.get(key,[]) is Array: return false
		if key!="supplement_history":
			for value in d.get(key,[]):
				if not value is String: return false
	for key in ["report_sources","county_sources"]:
		if not d.get(key,{}) is Dictionary: return false
	for item in d.get("supplement_history",[]):
		if not item is Dictionary: return false
		for key in ["evidence","statements"]:
			if not item.get(key,[]) is Array: return false
			for value in item.get(key,[]):
				if not value is String: return false
		if not item.get("sources",{}) is Dictionary: return false
	var p = d.get("position",[0,0.1,36])
	if not p is Array or p.size() != 3: return false
	for value in p:
		if not (value is float or value is int) or not is_finite(float(value)): return false
	evidence.assign(d.get("evidence",[]))
	links.assign(d.get("links",[]))
	statements.assign(d.get("statements",[]))
	visited.assign(d.get("visited",[]))
	copies.assign(d.get("copies",[]))
	report_evidence.assign(d.get("report_evidence",[]))
	report_statements.assign(d.get("report_statements",[]))
	report = str(d.get("report",""))
	flask = clampi(int(d.get("flask",3)),0,3)
	coat = str(d.get("coat","Police coat"))
	minutes = float(d.get("minutes",0))
	position = Vector3(float(p[0]),float(p[1]),float(p[2]))
	yaw = float(d.get("yaw",0))
	started = bool(d.get("started",false))
	finished = bool(d.get("finished",false))
	world = str(d.get("world","estate"))
	if world not in ["estate","town","precinct","boardinghouse","room","tunnel","lounge"] and not preload("res://scripts/chapters/town_places.gd").valid(world): world = "estate"
	estate_complete = bool(d.get("estate_complete",false))
	intake_done = bool(d.get("intake_done",false))
	supplement_filed = bool(d.get("supplement_filed",false))
	county_dispatched = bool(d.get("county_dispatched",false))
	supplement_evidence.assign(d.get("supplement_evidence",[]))
	county_evidence.assign(d.get("county_evidence",[]))
	inquiry_topics.assign(d.get("inquiry_topics",[]))
	ammo = clampi(int(d.get("ammo",6)),0,6)
	flask_spilled = bool(d.get("flask_spilled",false))
	flask_spill_amount = int(d.get("flask_spill_amount",0))
	drowned_dead = bool(d.get("drowned_dead",false))
	supplement_history=d.get("supplement_history",[]).duplicate(true)
	for item in supplement_history:
		if not item is Dictionary: return false
		var entry_evidence:Array[String]=[]
		entry_evidence.assign(item.get("evidence",[]))
		item["evidence"]=entry_evidence
		if item.has("statements"):
			var entry_statements:Array[String]=[]
			entry_statements.assign(item.statements)
			item["statements"]=entry_statements
		if item.has("sequence"): item.sequence=int(item.sequence)
	tunnel_complete=bool(d.get("tunnel_complete",false))
	county_statements.assign(d.get("county_statements",[]))
	report_sources=d.get("report_sources",{}).duplicate(true)
	county_sources=d.get("county_sources",{}).duplicate(true)
	if int(d.version) == 1 and finished:
		estate_complete = true
		finished = false
		world = "town"
		position = Vector3(0,0.1,17)
		yaw = 0
	day = clampi(int(d.get("day",1)),1,3)
	steward_visits = clampi(int(d.get("steward_visits",0)),0,3)
	lounge_exited = bool(d.get("lounge_exited",false))
	montage_index = clampi(int(d.get("montage_index",-1)),-1,3)
	if int(d.version) < 5:
		# Retain earned testimony and completed older inquiries without inventing evidence.
		if finished or world == "tunnel" or evidence.has("club_talk"):
			day = 3
			steward_visits = 3
			lounge_exited = true
		elif visited.has("barman"):
			steward_visits = 1
	if world == "lounge" and not visited.has("almy"):
		world = "estate"
		position = Vector3(-10,0.1,-17)
	rose_bodies_removed = bool(d.get("rose_bodies_removed",estate_complete))
	birch_bodies_removed = bool(d.get("birch_bodies_removed",false))
	estate_visits_completed = maxi(0,int(d.get("estate_visits_completed",1 if estate_complete else 0)))
	var clock_value=d.get("clock_minutes",360.0)
	if not (clock_value is float or clock_value is int) or not is_finite(float(clock_value)): return false
	clock_minutes=clampf(float(clock_value),360.0,1200.0)
	timed_conversations.assign(d.get("timed_conversations",[]))
	if int(d.version)<7: preload("res://scripts/shared/day_clock.gd").migrate(self)
	var dialogue_payload=d.get("dialogue_state", {})
	if not dialogue_payload is Dictionary: return false
	dialogue_state=preload("res://scripts/shared/dialogue_state.gd").new()
	if not dialogue_payload.is_empty():
		if not dialogue_state.restore(dialogue_payload): return false
	if dialogue_payload.is_empty() or int(d.version) < 9:
		# Version 8 could save an empty dialogue store while the legacy UI was live.
		# Import earned milestones idempotently; never invent evidence.
		for id in visited:
			var npc="father_behan" if id=="behan" else ("steward" if id=="barman" else id)
			dialogue_state.visit_counts[npc]=maxi(1,dialogue_state.visit_count(npc))
			if id != "odell": dialogue_state.complete_topic(npc,"default")
		for statement in statements:
			if statement.begins_with("Walter told Odell to his face") or statement.begins_with("Walter wrote EIGHT"):
				dialogue_state.complete_topic("odell","default")
		if inquiry_topics.has("behan_invitation"): dialogue_state.complete_topic("father_behan","club_invitation")
		if inquiry_topics.has("almy_trust"): dialogue_state.complete_topic("almy","almy_trust")
		if steward_visits>=3: dialogue_state.complete_topic("steward","steward_open")
		for id in ["club_talk","club_devotion","pantry_lead"]:
			if evidence.has(id): dialogue_state.complete_topic("steward",id)
	return true
