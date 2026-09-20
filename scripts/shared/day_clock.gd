extends RefCounted

const MORNING = 360.0
const NOON = 720.0
const EVENING = 1020.0
const NIGHT = 1200.0
const MIDNIGHT = 1440.0
const MOONRISE = 1080.0
const CONVERSATION_MINUTES = 30.0
const CONVERSATION_COSTS = {} # Optional longer budgets keyed by conversation ID.
const TRAVEL_MINUTES = 30.0
const WANDER_RATE = 5.0 / 60.0
const Places = preload("res://scripts/chapters/town_places.gd")
# Explicit content budgets; descriptions, refusals and exhausted repeats are free.
const ESTATE_TALKS = {"boy":"boy","assistant":"assistant","gardener":"gardener","gardener_plain":"gardener_plain","odell":"odell","club_talk":"club_talk","club_devotion":"club_devotion","pantry_lead":"pantry_lead"}
const TOWN_TALKS = {"identify":"identify","lay_lead":"lay_lead","service_work":"service_work","behan":"behan","behan_invitation":"behan_invitation","behan_name":"behan_name","old_woman":"old_woman"}

static func phase(minutes:float) -> String:
	if minutes >= NIGHT: return "night"
	if minutes >= EVENING: return "evening"
	if minutes >= NOON: return "noon"
	return "morning"

static func display_time(minutes: float) -> String:
	if minutes >= MIDNIGHT: return "MIDNIGHT"
	var whole_minutes = clampi(floori(minutes), 0, 1439)
	var hour_24 = whole_minutes / 60
	var minute = whole_minutes % 60
	var suffix = "AM" if hour_24 < 12 else "PM"
	var hour_12 = hour_24 % 12
	if hour_12 == 0: hour_12 = 12
	return "%d:%02d %s" % [hour_12, minute, suffix]

static func phase_label(minutes: float) -> String:
	match phase(minutes):
		"noon": return "Midday"
		"evening": return "Evening"
		"night": return "Night"
		_: return "Morning"

static func watch_aperture(minutes: float) -> String:
	return "moon" if minutes >= MOONRISE else "sun"

static func advance(st,amount:float) -> void:
	if is_finite(amount) and amount>0: st.clock_minutes=minf(MIDNIGHT,st.clock_minutes+amount)

static func district(world:String) -> String:
	if world in ["estate","lounge","tunnel"]: return "estate"
	if world in ["town","precinct","boardinghouse","room","post_office","morgue"]: return "town"
	var parent=Places.parent_hub(world)
	return parent if not parent.is_empty() else world

static func travel_cost(origin:String,destination:String) -> float:
	return TRAVEL_MINUTES if district(origin)!=district(destination) else 0.0

static func conversation_key(g:Node,cards:Array) -> String:
	if cards.size()>=g.TownStory.SCENES.intake.size() and cards.slice(0,g.TownStory.SCENES.intake.size())==g.TownStory.SCENES.intake: return "intake"
	for id in ESTATE_TALKS:
		if cards==g.Story.SCENES[id]: return ESTATE_TALKS[id]
	for id in TOWN_TALKS:
		if cards==g.TownStory.SCENES[id]: return TOWN_TALKS[id]
	return ""

static func complete_conversation(st,key:String) -> bool:
	if key.is_empty() or st.timed_conversations.has(key): return false
	st.timed_conversations.append(key)
	advance(st,float(CONVERSATION_COSTS.get(key,CONVERSATION_MINUTES)))
	return true

static func migrate(st) -> void:
	# Preserve earned content in old saves without inventing elapsed investigation time.
	for id in ["boy","assistant","gardener","odell","behan"]:
		if st.visited.has(id): st.timed_conversations.append(id)
	for id in ["club_talk","club_devotion","pantry_lead","lay_lead","service_work","behan_name","old_woman"]:
		if st.evidence.has(id): st.timed_conversations.append(id)
	if st.intake_done: st.timed_conversations.append("intake")
	if st.statements.has("The gardener saw the woman at the service door. Ask the steward."): st.timed_conversations.append("gardener_plain")
	if st.evidence.has("naomi"): st.timed_conversations.append("identify")

