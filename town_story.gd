extends RefCounted

# Provisional scene adaptation: no supernatural explanation is granted here.
const FACTS = {
	"intake": ["SIX IN THE HEADING", "The precinct intake heading names the six club members. Walter's incoming report records eight deaths. The heading is incomplete; it does not change the original report.", "Precinct intake sheet · Walter's submitted copy"],
	"naomi": ["NAOMI FREEMAN", "Mrs. Almy identifies the woman as Naomi Freeman. A boy accompanied her. His name is not yet established. The witness knew them before the deaths.", "Mrs. Almy · boardinghouse statement"],
	"lodging": ["A LOCAL ADDRESS", "The boardinghouse meal ledger records N. Freeman and a boy. Mrs. Almy confirms the entry. They were known locally; the record supplies a place from which to continue the inquiry.", "Pickman Street meal ledger · Mrs. Almy"],
	"lay_lead": ["AN UNPAID LAY", "Mrs. Almy recalls Naomi asking about wages owed to a whaling ancestor. She does not hold the wage document and cannot verify the claim. This is a lead, not proof of a debt or a motive for the killings.", "Mrs. Almy · account of Naomi's inquiry"],
	"service_work": ["THE SERVICE DOOR", "Mrs. Almy says Naomi sought domestic work at the estate. Neither the dates nor an employer's name is confirmed. Ask the steward for employment records.", "Mrs. Almy · boardinghouse statement"],
	"gazette": ["THE MORNING EDITION", "The paper names six club members and describes an apparent accident. It names neither the woman nor the boy. Its report supplies no independent explanation of the wounds.", "Gazette · morning edition"],
	"exemption": ["THE EXEMPTION NOTICE", "Walter's old exemption notice records the need to care for Constance Corwin. It concerns his life before the case. It supplies no evidence about the deaths at the estate.", "Walter's dresser · personal correspondence"],
	"behan_name": ["NAMED AFTER THE SHIP", "The Ophion Club was named for a vessel lost with its crew a century ago. Father Behan calls the members' belief that the ship had been chosen a delusion, not a fact: men inherit money, then invent a reason they deserved it.", "Father Behan · rectory conversation"]
}

const ARRIVAL = [
	["PICKMAN STREET", "By morning, the estate has become a headline.\n\nWalter carries the report into town.\nThe town has already begun shortening it."],
	["PRECINCT 4", "Submit the report at the intake counter.\nMrs. Almy keeps a boardinghouse farther along Pickman Street.\n\nWalter's room is above the cobbler's shop."]
]

const SCENES = {
	"intake": [
		["THE INTAKE CLERK", "Ophion Club. Six members. Apparent accident.\n\nThe captain's heading, Officer.\nYour report goes underneath."],
		["WALTER CORWIN", "Eight deaths.\nCause unestablished."],
		["THE INTAKE CLERK", "Then that is what your report will say.\n\nI'm receiving it, not deciding it."]],
	"intake_county": [
		["THE OUTGOING TRAY", "The county copy Walter prepared at the estate is stamped for dispatch.\n\nThe clerk makes no promise about who will read it."],
		["WALTER'S NOTEBOOK", "County copy dispatched with the observations recorded at the estate.\n\nA later discovery will need another page.\nIt cannot have been in a letter already sent."]],
	"intake_thin": [
		["THE INTAKE CLERK", "You have the count.\nWhat else did you establish?"],
		["WALTER'S REPORT", "The clerk leaves room for observations Walter did not make.\n\nThe blank space is accurate.\nThere is work left to do."]],
	"intake_rich": [
		["THE INTAKE CLERK", "Wounds without powder marks. Intact windows.\nYou want both observations attached?"],
		["WALTER CORWIN", "They already are.\nKeep them together."]],
	"almy_badge": [
		["MRS. ALMY", "If you've come to tell me what the paper says, Officer,\nI have already read it."],
		["WALTER CORWIN", "I'm asking about the woman and the boy."],
		["MRS. ALMY", "The paper wasn't.\n\nWhat is it you intend to write down?"]],
	"almy_plain": [
		["MRS. ALMY", "The coat changes the room before Walter says a word.\nMrs. Almy sets a second cup beside the first."],
		["MRS. ALMY", "You came to ask about Naomi.\n\nSit, then. Ask properly."]],
	"identify": [
		["WALTER CORWIN", "I counted eight people.\nI would like to put a name beside each of them."],
		["MRS. ALMY", "Naomi Freeman.\n\nShe ate here. The boy too.\nHe waited for her to begin before touching his own plate."],
		["WALTER'S NOTEBOOK", "NAOMI FREEMAN.\nIdentified by Mrs. Almy, Pickman Street.\nBoy accompanying her: name still to be established."],
		["MRS. ALMY", "You can ask me again tomorrow.\nHer name will still be Naomi."]],
	"lay_lead": [
		["MRS. ALMY", "She was looking for something owed.\nA whaler's wages. A share, she called it. A lay.\nFrom her family's time, long before hers."],
		["WALTER CORWIN", "Did you see the document?"],
		["MRS. ALMY", "No. She spoke of finding it.\nYou mustn't write that I saw it."],
		["WALTER'S NOTEBOOK", "Possible wage claim. Document not examined.\nSource: Mrs. Almy's recollection.\n\nA question to pursue.\nNo conclusion about why Naomi died."]],
	"service_work": [
		["MRS. ALMY", "She asked about work at the estate.\nCleaning, perhaps. They always need someone who can leave by the other door."],
		["WALTER CORWIN", "Who engaged her?"],
		["MRS. ALMY", "I don't know.\nThe steward has books enough.\nAsk him for one that contains her."]],
	"lodging": [
		["THE MEAL LEDGER", "N. FREEMAN — TWO MEALS.\n\nA small balance carried forward.\nA line in a book kept for an ordinary purpose."],
		["MRS. ALMY", "Hers. And the boy's.\n\nThe balance can wait."],
		["WALTER'S NOTEBOOK", "Copy the entry and record its source.\nThe name and the address corroborate her statement.\n\nFor once, a question has produced exactly what the work needed."]],
	"gazette": [
		["THE GAZETTE", "TRAGEDY AT THE OPHION CLUB\n\nSix names. Six professions.\nA paragraph about service to the community."],
		["WALTER CORWIN", "The birches do not appear in the account.\nNeither does a source for the word accident."]],
	"exemption": [
		["THE DRESSER", "An exemption notice, folded along the same worn crease.\nConstance Corwin's name beneath his own.\n\nWalter puts it back.\nThere are other papers requiring him tonight."]],
	"behan": [
		["FATHER BEHAN", "Wexford's temper. Fenn's vanity. Kessler's grudges. Corliss's ambitions.\n\nI'll discuss any of it. None of it explains a hole above the bridge of a nose."],
		["WALTER CORWIN", "You knew all six."],
		["FATHER BEHAN", "I knew what men tell a priest, which is not the same as what they are.\n\nAsk your question, Officer. I've answered worse."]],
	"behan_invitation": [
		["WALTER CORWIN", "You were invited to the club. Twice. You declined both times."],
		["FATHER BEHAN", "I did."],
		["WALTER CORWIN", "Why?"],
		["FATHER BEHAN", "[He says nothing further. The silence is not evasive. It is final.]"],
		["WALTER'S NOTEBOOK", "A refusal offered without excuse.\nWalter has learned to trust a plain no more than a decorated one.\n\nHe does not press it a second time."]],
	"behan_name": [
		["WALTER CORWIN", "Do you know the meaning behind the club's name?"],
		["FATHER BEHAN", "They named the club after the ship."],
		["WALTER CORWIN", "Known."],
		["FATHER BEHAN", "They came to believe the ship had been chosen.\n\nIt wasn't. Men inherit money, and then invent a reason they deserved it."],
		["WALTER'S NOTEBOOK", "A shipowner's classical flourish, nothing more, by the priest's own account.\n\nThe club's fortune has a human explanation. Walter intends to find it."]],
	"supplement": [
		["THE INTAKE COUNTER", "Walter files the witness's name, the source of the identification, and only the additional observations he has actually recorded.\n\nThe original report remains as received."],
		["THE INTAKE CLERK", "Received as a supplement.\n\nI can stamp it.\nI can't make the captain read it."]],
	"county_supplement": [
		["THE OUTGOING TRAY", "A second envelope. A later date.\n\nWalter sends what he knows now.\nWhatever was sent earlier remains what he knew then."]],
	"close_day": [
		["PICKMAN STREET · EVENING", "Walter has brought a name home.\nThe case is larger for having become more exact."],
		["THE NEXT INQUIRY", "The estate's records. The club's staff.\nThe men the town had already decided to trust.\n\nTomorrow, he will ask again."]]
}
