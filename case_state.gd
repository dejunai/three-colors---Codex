extends RefCounted

const VERSION = 2
var evidence: Array[String] = []
var statements: Array[String] = []
var visited: Array[String] = []
var report = ""
var copies: Array[String] = []
var report_evidence: Array[String] = []
var report_statements: Array[String] = []
var flask = 3
var coat = "Police coat"
var minutes = 0.0
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

func discover(id: String) -> void:
	if not evidence.has(id): evidence.append(id)

func record(id: String) -> void:
	if not statements.has(id): statements.append(id)

func perception() -> int:
	return 2 + mini(4, evidence.size() / 2)

func complete_report(mode: String) -> void:
	if intake_done: return
	report = mode
	report_evidence.assign(evidence)
	report_statements.assign(statements)
	copies.assign(["Walter's notebook", "Precinct intake"])
	if mode == "Full inquest requested": copies.append("County registrar — outgoing copy")

func receive_report() -> void:
	intake_done = true
	if report == "Full inquest requested":
		county_dispatched = true
		county_evidence.assign(report_evidence)
		copies.erase("County registrar — outgoing copy")
		if not copies.has("County registrar — dispatched copy"): copies.append("County registrar — dispatched copy")

func file_supplement(send_county: bool) -> void:
	supplement_filed = true
	supplement_evidence.assign(evidence)
	supplement_history.append({"evidence":evidence.duplicate(),"county":send_county})
	if not copies.has("Precinct — dated supplement"): copies.append("Precinct — dated supplement")
	if send_county:
		county_dispatched = true
		if not copies.has("County registrar — dated supplement"): copies.append("County registrar — dated supplement")

func pack() -> Dictionary:
	return {"version":VERSION,"evidence":evidence,"statements":statements,"visited":visited,
		"report":report,"copies":copies,"report_evidence":report_evidence,"report_statements":report_statements,"flask":flask,"coat":coat,"minutes":minutes,
		"position":[position.x,position.y,position.z],"yaw":yaw,"started":started,"finished":finished,
		"world":world,"estate_complete":estate_complete,"intake_done":intake_done,
		"supplement_filed":supplement_filed,"county_dispatched":county_dispatched,
		"supplement_evidence":supplement_evidence,"county_evidence":county_evidence,"inquiry_topics":inquiry_topics,"supplement_history":supplement_history}

func restore(d: Dictionary) -> bool:
	if int(d.get("version",0)) not in [1,VERSION]: return false
	for key in ["evidence","statements","visited","copies","report_evidence","report_statements","supplement_evidence","county_evidence","inquiry_topics","supplement_history"]:
		if not d.get(key,[]) is Array: return false
	var p = d.get("position",[0,0.1,36])
	if not p is Array or p.size() != 3: return false
	evidence.assign(d.get("evidence",[]))
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
	if world not in ["estate","town","precinct","boardinghouse","room"]: world = "estate"
	estate_complete = bool(d.get("estate_complete",false))
	intake_done = bool(d.get("intake_done",false))
	supplement_filed = bool(d.get("supplement_filed",false))
	county_dispatched = bool(d.get("county_dispatched",false))
	supplement_evidence.assign(d.get("supplement_evidence",[]))
	county_evidence.assign(d.get("county_evidence",[]))
	inquiry_topics.assign(d.get("inquiry_topics",[]))
	supplement_history=d.get("supplement_history",[]).duplicate(true)
	if int(d.version) == 1 and finished:
		estate_complete = true
		finished = false
		world = "town"
		position = Vector3(0,0.1,17)
		yaw = 0
	return true
