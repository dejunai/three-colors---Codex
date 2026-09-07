extends RefCounted

const FACTS = {
	"municipal_foundation":["THE MUNICIPAL FOUNDATION SHEET","The municipal sheet ends the kitchen-wing foundation at the same support as the service plan. Walter's measured passage continues beyond both recorded limits. Agreement between two drawings corroborates the discrepancy; it does not establish the date, purpose, or maker of the extension.","Precinct survey drawer - municipal foundation sheet compared with service plan and Walter's measurement"],
	"lower_foundation":["BEYOND THE FOUNDATION","The lower passage continues beyond the estate's recorded foundation. Walter measured the final support against the service plan. The cause remains unestablished.","Lower passage · service plan and direct measurement"],
	"service_recess":["A RECESSED WALK","Pale wear marks continue behind the right-hand stone screen. The recess joins the far side of the central passage without crossing its open floor.","Service passage · reflected wear marks"],
	"county_foundation_request":["A SECOND FOUNDATION RECORD","The county examiner requests the municipal foundation sheet after reading the wounds and intact-window observations together. The request names the survey drawer to consult. It supplies a second documentary lead for Walter's lower-passage measurement, not an explanation of the passage.","County examiner · reply to the dispatched observations"]
}

const ENTRY = [
	["THE SERVICE STAIR","The next morning, Walter returns to the estate's kitchen wing.\nA service plan lies on a packing case beside the stair."],
	["BELOW THE ESTATE","Beyond the first landing, a figure stands in the central passage.\nA thin, wet cough. Its head rises. Then, after a while, it turns back to the wall.\n\nA marked service walk bends around the outside of the stonework."],
	["WALTER'S NOTEBOOK","Compare the lower support with the service plan.\nReturn with the measurements.\n\nWalter checks the flask's familiar weight before he starts down."]
]

# Hazard cue text, held here rather than inline in tunnel.gd's cue(), matching the
# rest of the codebase's data-table convention (Design Law 4).
const CUES = {
	"exposed":"It sees Walter. Get behind stone.",
	"warning":"[A thin, wet cough.] Its head lifts toward the central passage.",
	"watching":"It watches the central passage.",
	"turned":"It turns toward the wall."
}
