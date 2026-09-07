extends RefCounted

# Prototype adaptation of the supplied v10 bible and opening stories.
# Entries are factual. Film effects never modify these canonical strings.
const FACTS = {
	"wounds": ["NO EXIT WOUND", "Six men in evening dress. A small wound above the bridge of each nose. No corresponding wound behind the skull. No powder marks on the collars.", "Rose garden · direct examination"],
	"eight": ["EIGHT PEOPLE", "Six men in the rose garden. A woman and a boy beyond the birches. Eight dead at two adjacent scenes. Their relationship and identities remain unconfirmed.", "Birch grove · direct observation; assistant's count"],
	"knife": ["KESSLER'S KNIFE", "A butcher's knife beneath a hedge root. The blade has been wiped. Its presence is recorded; its use has not been established.", "Hedge root · bagged physical evidence"],
	"watch": ["03:17", "The unidentified man's watch is stopped at seventeen minutes past three. The maker's plate has been filed smooth. This alone does not establish the time of death.", "Sixth man · pocket watch"],
	"gas": ["NO BLAST DAMAGE", "Windows facing the garden remain intact. Neither the nearby stone nor the clothing shows scorching. The proposed gas accident is unsupported by the visible scene.", "Terrace windows · assistant's examination"],
	"register": ["FIVE NAMES", "The steward's seating list names Wexford, Fenn, Corliss, Kessler, and Pruitt. A sixth place is set without a name. A missing name is a missing fact, not an explanation.", "Club terrace · seating list"],
	"shoes": ["EXPECTED TO GO ON", "The boy's shoes have been resoled. The woman's coat is too light for the season. A boardinghouse inquiry may identify them; clothing cannot establish that nobody will miss them.", "Birch grove · belongings inspection"],
	"testimony": ["BOTH SCENES", "The assistant counted eight and saw no evidence of an explosion. He was told to prepare the six club members first. His observations corroborate the separate scene notes.", "Coroner's assistant · statement"]
}

const INTROS = [
	["WIDOW'S BIGHT", "A civic history\n\nA fleet put out from this coast a century ago.\nNot every ship returned."],
	["THE YEARS AFTER", "Those who came home disagreed about what they had seen.\n\nInsurance settlements were paid.\nThe town prospered."],
	["1923", "Before dawn.\nThe Ophion estate.\n\nOfficer Walter Corwin has been called to the rose garden."]
]

const SCENES = {
	"boy": [
		["THE GATEHOUSE BOY", "THEY'RE IN THE ROSE GARDEN, OFFICER.\nWHAT'S LEFT OF THEM."],
		["WALTER CORWIN", "Who found them?"],
		["THE GATEHOUSE BOY", "The gardener. He sent me for the police.\n\nStraight up the drive. Through the opening in the hedge.\nThe captain is waiting on the terrace."]],
	"wounds": [
		["THE ROSE GARDEN", "Six men in evening dress, arranged in a half-circle.\n\nWalter knows five of the faces. Judge Wexford. Dr. Fenn. Corliss, the district attorney. Pruitt. Kessler.\n\nThe sixth means nothing to him."],
		["EXAMINE · JUDGE WEXFORD", "A wound above the bridge of the nose.\nNo powder scorching.\n\nWalter turns the head.\nThere is no exit wound."],
		["WALTER'S NOTEBOOK", "The other five present the same condition.\n\nNo weapon in any visible hand.\nCause and sequence unestablished.\n\nThe observation is exact. It is the explanation that is missing."]],
	"eight": [
		["BEYOND THE BIRCHES", "A woman and a boy lie apart from the club members.\n\nSomeone has brought two more sheets. These deaths were not clean. Walter leaves the coverings in place."],
		["WALTER CORWIN", "No names yet.\n\nThat is a fact about the investigation.\nIt is not a fact about their lives."],
		["WALTER'S NOTEBOOK", "Unidentified female. Unidentified male, minor.\nRelationship unconfirmed.\n\nEight people. Two scenes. One investigation."]],
	"knife": [
		["BENEATH THE HEDGE", "A knife with a butcher's grip. Walter has seen its like in Kessler's shop.\n\nThe blade is too clean for the earth around it."],
		["EVIDENCE ENVELOPE", "He wraps the handle before lifting it.\n\nLocation recorded. Blade preserved for examination.\nAn object can be useful before it has agreed to explain itself."]],
	"watch": [
		["THE SIXTH MAN", "No calling card. No monogram. No wallet.\n\nA watch, stopped at 03:17. Its maker's plate has been filed smooth."],
		["WALTER'S NOTEBOOK", "Unknown male, approximately fifty to sixty.\nClub dress. Identity unrecovered.\n\nAsk the steward. Then the tailor. A blank is still something to investigate."]],
	"gas": [
		["THE TERRACE WINDOWS", "The panes facing the garden are intact.\nWalter runs a finger along the sill. Dust, damp, no soot."],
		["WALTER'S NOTEBOOK", "No blast damage visible.\nNo burns on the nearest bodies.\n\nIf this was a gas accident, the scene has kept remarkably little of it."]],
	"register": [
		["THE STEWARD'S TABLE", "Five names on the seating list. Six places.\n\nThe last line has not been crossed out. It was never filled."],
		["WALTER'S NOTEBOOK", "Copy the five names. Preserve the blank.\n\nWEXFORD · FENN · CORLISS\nKESSLER · PRUITT\n\nAn omission is worth keeping in its original shape."]],
	"shoes": [
		["THE BELONGINGS", "The boy's shoes have been resoled twice.\nThe woman's coat is too light for this hour.\n\nThese are the possessions of people who expected to need them again."],
		["A POSSIBLE INQUIRY", "Ask at the boardinghouses on Pickman Street.\nSomeone may have given them a room or a meal.\n\nWalter writes it down before the thought can become somebody else's responsibility."]],
	"assistant": [
		["THE CORONER'S ASSISTANT", "I've counted them twice. Eight.\n\nThe captain wants the identified men prepared first."],
		["WALTER CORWIN", "Any sign of an explosion?"],
		["THE CORONER'S ASSISTANT", "None I can find. No burns. No broken glass.\n\nI can't tell you what happened. I can tell you what isn't here."],
		["A CLEAN READ", "Two independent observations agree.\nFor a moment the work is simple.\n\nWalter knows what to ask next."]],
	"gardener": [
		["THE GARDENER", "I keep the roses. I don't keep the hours of the men who walk among them."],
		["WALTER CORWIN", "You found both scenes?"],
		["THE GARDENER", "Yes.\n\nI sent for eight sheets.\nThey brought six the first time."]],
	"gardener_plain": [
		["THE GARDENER", "You took the badge off."],
		["WALTER CORWIN", "I'm still asking."],
		["THE GARDENER", "Then write this down as well. I saw the woman here before. Walking to the service door.\n\nI don't know her name. The steward might.\nAsk him as though an answer is required."]],
	"odell": [
		["CAPTAIN ODELL", "A gas-main tragedy.\nOr something close enough for the morning edition."],
		["WALTER CORWIN", "There are eight bodies. Six club members. A woman and a boy beyond the birches.\n\nNobody has established an accident."],
		["CAPTAIN ODELL", "Six members, Corwin.\nThe other two are a filing matter."],
		["WALTER CORWIN", "Eight people are dead."],
		["CAPTAIN ODELL", "Then put your observations in writing.\n\nI need a preliminary report.\nI do not need a quarrel before breakfast."]],
	"report_routine": [
		["PRELIMINARY REPORT", "Walter records all eight deaths and the observations he has actually made.\n\nThe precinct receives the report.\nHe retains his own notebook."],
		["WALTER CORWIN", "An investigation begins with what can be established.\nI can pursue the rest from the precinct."]],
	"report_inquest": [
		["FULL INQUEST REQUESTED", "Both scenes. All eight dead.\nWalter requests that neither scene be closed as an accident before examination.\n\nHe prepares an additional copy addressed to the county registrar."],
		["CAPTAIN ODELL", "You can request it.\nDon't mistake a request for an agreement."],
		["WALTER'S NOTEBOOK", "A copy for the precinct. A copy to send out of town.\nOne kept in his own hand.\n\nIt has not persuaded anyone.\nIt has made one fact harder to lose."]]
}
