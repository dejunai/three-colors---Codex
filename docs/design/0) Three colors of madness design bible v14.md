**THREE COLORS OF MADNESS**

***Design Bible***

**Internal working document. Not for external distribution.**

**Dejunai**

## **Contents**

**Part One — Foundations**

**Part Two — The World**

**Part Three — Chapter One: 1920s, "No Exit Wound"**

**Part Four — Chapter Two: 1930s, "The Maw"**

**Part Five — Chapter Three: 1940s, "Ophion"**

**Part Six — Cross-Chapter Systems**

**Part Seven — The Meta Layer (Internal Only)**

# **Part One — Foundations**

## **What This Document Is**

**This is the design bible for Three Colors of Madness. It is written to be built from.**

**As of this revision, this document has a companion: the Technical Design Document (TDD), which owns engine architecture, data schemas, production sequencing, and open build-specific questions still pending playtest. The division is simple — this document is the what and the why; the TDD is the how. Where a passage here still states a mechanism rather than a rule (a specific stat formula, a save schema, a shader recipe), that is deliberate: it is there because the mechanism itself is the thing enforcing a Design Law, and moving it out would let the law be quietly reinterpreted. Anything that is purely a build decision — an open production question, a proposed but unconfirmed implementation, a concrete engine detail — lives in the TDD instead, cross-referenced from here rather than restated. If the two documents ever appear to disagree, this bible is correct and the TDD is wrong until revised, never the reverse.**

**Every decision below is settled. Where a rule has an edge case or an exception, the edge case is stated in place, not filed separately — there is no changelog to consult and no earlier draft that overrides what's written here.**

**Every short story demonstrating a chapter loop — canonical or alternate — is bound by every Design Law identically. An alternate draft is a second, equally canonical playthrough of a chapter's Player Orientation split, never a looser or more exploratory register than the default. If a Law would need to bend to make an alternate work, the Law is wrong and must be revised for every draft it governs, canonical included — it is never bent for one draft alone.**

## **The Thesis**

***Every chapter hands the player a familiar videogame competency — investigation, collection, combat — then reveals that cosmic horror is the one genre in which mastering the system only makes its protagonist better at approaching what should never be approached.***

**Insanity is never a UI element. It is the breakdown of the medium itself — aspect ratio, color, sound, and lens distortion, driven continuously by a value the player never sees as a number. No two playthroughs collapse identically, because the degradation responds to how the player actually plays, not to a script.**

**One design law holds beneath all three chapters: competence delays the end. It never prevents it.**

## **Design Laws**

**These are not style notes. They are load-bearing. Breaking one to serve a single good idea is the mistake this project has to keep refusing to make.**

1. **Understanding is fatal. Comprehension, not skill failure or resource depletion, is what ends each protagonist. Competence only ever delays the end.**

2. **No morality meter, no paragon/renegade system, no scored redemption arc, anywhere. Character traits (the cop's insularity, the archaeologist's ambition) are structural, never tracked or optimized.**

3. **Coping mechanisms are honest. The flask, the opium, the cigarettes and matches all do exactly what they claim, and fail cleanly when they run out. None of them secretly cause the effect they exist to hold off. A coping mechanism that betrays its own purpose is a broken design, not a twist.**

4. **The presentation can become unreliable; the underlying game state cannot become unfair. A case file can shift handwriting, tense, and emotional register — but its factual content must remain recoverable through redundant evidence. Players may doubt the narrator. They may never have reason to doubt the controls, the objective, or whether the game registered their input. This extends to every persistent-consequence system in the game, not only the case file's prose: whatever a chapter's stat investments and item choices leave behind must produce a visible, specific effect somewhere later — a changed lead, a missing object, an altered read — never only a cosmetic or lore-only difference. A consequence a player cannot perceive is, functionally, no consequence at all.**

5. **The game never explains its own bits. The bloodline secret, the meaning of the club's name, the Observers' throughline, the achievement rarity — all of it is discoverable, none of it is announced. No character delivers an exposition line that does a player's realizing for them.**

6. **Local victories carry permanent consequences. Every chapter needs at least one specific, player-authored consequence — whether an accumulated state (Walter's case file, Ward's Codex and inventory) or an explicit chosen action (Ekon's final act) — that survives the protagonist's death or breakdown, even though it never changes the ultimate ending. Competence needs somewhere to point, not just an abstract claim that it mattered.**

7. **Nothing is targeted by identity. The cult's victim selection is opportunistic — whoever is easiest to disappear — never a targeted act of racial or ethnic violence. The horror is that certain people are already easier to disappear than others, and that mechanism runs through the town's ordinary institutions (whose testimony gets weighed, whose disappearance gets investigated), not through the cult's stated motive.**

8. **Visual language for the incomprehensible stays inside the established film-grammar vocabulary — distortion, color, aspect ratio, sound — never generic horror iconography. When the entity in Chapter One wears Constance Corwin's shape, it must read as a distortion of the medium, not a witch, hag, or vengeful-ghost trope.**

9. **Accessibility is not optional. Flicker reduction, distortion-intensity controls, protected subtitles, and preserved clue-legibility ship from day one. The style that makes this project distinctive cannot be the setting players are forced to turn off. Accessibility options live on their own menu, reachable independently of and before the difficulty screen (see Part Seven) — the two must never be presented together or in proximity.**

10. **The bounds are immutable. Once a rule like this is set, it does not get broken later because a specific idea is good on its own terms. (See: the WarGames quote that nearly went into the difficulty menu, and didn't.)**

11. **Stat builds are honest, and failure is always survivable. No fuel or infrastructure stat may be secretly compensated for if a player neglects another — the system never rubber-bands a weak build toward success behind the player's back. But a bad build must never strand a living player with no path forward: wherever a stat build produces a genuine fail state, that failure resolves as death, never an unwinnable-but-alive state, so a reload is always the answer. (A bad build need not itself produce a fail state — Ward's Strength and Agility, for instance, only ever worsen his physical odds and what he can carry; neither can kill him outright. See Part Four.) Hidden coping or decay values (a coping resource's remaining supply, a presentation's stability) may only ever affect presentation — frame, sound, stability — never a probability. Visible stats may affect plainly described probabilities, durations, or capabilities instead, because the player chose to invest in them knowingly. No coping or fuel system may ever be represented as a hidden numeric meter — no sanity bar, no decay percentage, no secret probability shift. What changes odds must always be visible stat investment the player can see and chose.**

12. **The convergence is legible to the player, never to the world. No character may recognize, name, or react to the improbability connecting Walter, Ward, and Ekon — the shared tunnel, the passed book, the bloodline, the transited case file. The universe's indifference has to survive exactly the moments where the audience finds the pattern most meaningful, or Law 7 breaks exactly where it needs to hold hardest. The density of connection between the three protagonists is real and intentional — it's what makes Chapter Three land as synthesis and payoff — but it must remain dramatic irony the player alone perceives.**

13. **Every chapter guarantees an unavoidable floor beneath its fatal comprehension. A player who investigates nothing beyond what a chapter's required beats demand, skips every optional witness, discovery, or find, and moves straight at objectives still reaches the same fatal understanding — later, and by a harder, more exposed path (Design Law 11), but never a path that avoids arriving. Optional engagement only ever changes two things: how much harder or slower that path is, and how complete the record a player leaves behind turns out to be (Design Law 6). It never changes whether the end is reached, and the game must never force exposition into a protagonist's head to compensate for a player who has genuinely engaged with nothing optional — the floor has to be low enough that minimal engagement is a real, playable, harder path, not a contradiction the game quietly papers over.**

14. **Save and load restore game state completely; player knowledge is never restored alongside it, and is never punished for persisting anyway. A player who reloads minutes after a death often knows something their protagonist, at that earlier point in the reloaded timeline, does not yet know — the game accepts this without comment. It never rewinds a discovery back out of the player's head, and it never invents a fourth-wall device that has the protagonist "remember" a prior attempt, however tempting that trick might look in isolation — doing so would quietly convert a fairness principle (Design Law 4\) into a narrative gimmick. Metaknowledge belongs entirely to the player, never to the character, and the two are allowed to diverge freely.**

# **Part Two — The World**

## **Widow's Bight**

**A coastal New England town whose founding story it tells about itself, and whose actual founding story, are two different things. Roughly a century before Chapter One, a whaling fleet went out and never fully came home. The survivors who did return could never tell the same account of what happened twice. A great deal of insurance money nonetheless found its way into a small number of hands, and those hands became the town's ruling families.**

**The town has never had to examine any of this. That insularity is not a personality quirk applied to individual characters — it is the town's baseline condition, and it is why Walter Corwin, its beat cop, has no mental category for what he encounters. He is a native product of a place that has never once been asked to look past its own coastline.**

## **What the Mud Took**

**The drowned island carried more than the Ophion's wreck. Before the fleet's loss, it held the whaling station itself — try-works, warehouses, a small permanent crew's quarters, the working heart of the operation rather than merely its home port. On the same night the fleet went out and didn't come back, the station was buried whole: not silted over gradually the way a harbor forgets a dock across a generation, but taken all at once, complete, in a single event no county record ever settles on a cause for. The town's own version, when it bothers to have one, calls it a tidal surge, a storm, a slide — the same reflexive, physical, examine-no-further vocabulary it already applies to the fleet's own loss, because it is, structurally, the identical impulse: a bare fact stated and connected to nothing.**

**What doesn't fit that version is what Ward Kohistani actually finds when he digs. Ordinary burial leaves ordinary evidence — collapse, decay, the slow disorder of a structure losing a fight with time. What the mud left instead is preserved past what any natural process should have allowed: tools mid-use, a table still set, nothing crushed, nothing scattered, nothing rotted the way a century underground should rot it. It reads less like something the earth did to the station and more like something that wanted the station kept exactly as it was — total recovery achieved, perfectly, by whatever did this, a full generation before Ward ever coined the phrase for himself. He can log the stratigraphy as anomalous and move on, the same way he logs the tunnel's wrong geometry; neither he nor any document in the game is ever permitted to conclude more than that.**

**This is the catastrophe the Observers' own discipline already traces back to (see The Observers, below) — not a separate event alongside the fleet's loss, but the same one, seen from the ground instead of from the water. Whatever they know about what actually took the station under, in a single night, without leaving a mark a shovel would recognize as damage, they have never once said aloud, in any chapter, to anyone. The game does not say it either.**

## **The Prologue**

**Before Chapter One begins, the game opens on Widow's Bight's own official history, staged the way the town would present it about itself — a civic reel, not a confession. It states the fleet's disappearance, the contradictory survivor accounts, and the arrival of the insurance money as bare facts, and connects none of them to anything. It never mentions a bloodline.**

## **The Bloodline Secret**

**Walter Corwin, Chapter One's cop, is descended from the drowned crew of the Ophion. The wealthy families he investigates — the cult — are descended from the men who profited from the insurance payout on that same loss. Neither man ever learns this about the other. The game does not tell the player either. It is present in records, names, and inference, and it waits to be found.**

## **The Ophion**

**The lost flagship of the vanished whaling fleet. Named, most likely, by an educated 1820s owner drawing on classical mythology — a common enough practice among New England whaling merchants of real classical education. In Orphic cosmogony, Ophion is a primordial serpent who ruled before being overthrown and cast down, not destroyed. The name's resonance with the Old Gods is coincidence, not original intent: the owner picked a respectable classical flourish, and only later generations, already steeped in something they didn't understand, retroactively decided the name had always meant something. This is deliberately the colder reading: the universe was never paying attention. People just badly want it to have been. No character or document may ever assert otherwise, even ambiguously — the club's belief that the name was prophetic is their delusion to hold, not a fact the game confirms.**

**Decades after the wreck, the insurance-enriched families founded a private society and named it after the ship — an ostensible honorific to the fleet, which is in practice a slight on the memory of the men who actually died, since none of the club's founders paid anything but money for their fortune. The club is elite and exclusive on the premise that everyone in it paid a price with their lives — a claim that was true only of the crew, never of the club.**

**A player who becomes curious enough to look up what "Ophion" actually means has done, in miniature, the exact thing every protagonist in this trilogy is destroyed for doing: looked directly at something that was easier left alone.**

## **The Observers**

**Not a generic term for a mystical population — a classification, applied by outsiders, for a specific, named group of laborers who work the Ophion estate grounds, the quarry, and the drowned island's ruins across all three chapters. They are not mystics. They are working people who have learned, the way a miner learns to respect gas, that this ground carries a hazard, and that looking directly at it is how you die. Their fires and icons render in grayscale; only their jewelry and reflections carry impossible color — a tell that they see what the protagonists are blind to, and know better than to stare at it.**

**The miner-and-gas framing above is for this document, not for the player — Design Law 5 forbids anyone ever saying it on screen. That leaves the first beat where a player actually watches an Observer refuse ground carrying all of that weight on staging alone, and staging is exactly where this collapses into a trope if it isn't held to a rule: an Observer who startles, pleads, or crosses himself reads as spooked household staff giving the master's basement a wide berth, and this project cannot afford that reading even once. The refusal has to be precise and unbothered instead — the same spot marked every time rather than a general skittishness, delivered with the flat, unhurried competence of someone who priced this exact hazard long ago and finished being afraid of it, then returns to unrelated work in the same breath rather than lingering on the moment. The color tell in jewelry and reflection is the only thing allowed to carry the "why" — the flatness of the refusal itself is what has to carry the "this is expertise, not fear."**

**One figure is present and recognizable across all three decades — a young laborer in Chapter One, visibly aging and shown teaching someone younger in Chapter Two, elderly but still present, working alongside that same apprentice, in Chapter Three. This is not a handoff structure in which one individual replaces another; it is both payoffs at once, and neither may be sacrificed for the other. An attentive player recognizes the same face surviving twenty years no one else in the trilogy survives, and separately recognizes that same figure visibly passing the discipline on rather than holding it alone. A pure generational-relay version — one laborer simply replaced by the next — is the easier version to default to and loses the continuity beat that makes the device work; it is not an acceptable substitute.**

**Their discipline traces back to the same catastrophe that made the founding families rich. The Ophion's loss is one event with two inheritances — one side received an insurance payout and built a club on the memory of men they never mourned; the other side, the laboring community tied to the men who actually drowned, learned in that same loss the price of looking straight at what took the ships, and has passed that lesson down ever since. This is never stated in dialogue or text. It surfaces only as a glimpse — a detail a very attentive player can connect, never a scene that explains it. They are not protagonists and do not carry an arc the way the three leads do. They are also never generic NPCs with interchangeable lines. A third category, distinct from both.**

## **The Tunnel Beneath the Water**

**Beneath the Ophion estate and beneath the ruins on the drowned island, decades and miles apart, lies the same tunnel. It runs under open ocean, connecting a private cellar to an offshore ruin with no explanation geology permits. Walter finds its mouth on the estate side in 1923; Ward reaches it from the island side a decade later, walking stone that feels wrong to him in a way he cannot place and never resolves — he can only record, in his own hand, that it should not be possible and is. The game never explains the connection further, per Design Law 5\. Neither man ever learns the other walked the same passage.**

## **The Drowned**

**Two kinds of remains inhabit the tunnel, and the difference between them matters. The first are cultists from a generation before Chapter One's six, who went looking beneath the estate decades earlier and found something that did not kill them cleanly — near-immortality as disfigured, deranged things is what looking cost them, a punishment the game never states as such but that reads as one. Their gift for having asked is immortality ad infinitum: no force in the game, of any kind, ever permanently ends a fully transformed cultist — they may be staggered and left behind, never destroyed. A cultist whose transformation has not yet completed — still recognizably, mostly human, a state that exists only closer to the surface — has not yet inherited the curse and is not an exception to the rule; it is simply not yet a member of the cursed population, which is why it alone can be ended outright by precision force (see Part Five). Deeper in, the fully transformed remain exactly as absolute as ever. This three-way asymmetry — cursed, not-yet-cursed, and never-cursed — should read as the difference between a curse, an in-progress transformation, and a body, never as an arbitrary difficulty gate.**

**The second are the Ophion's own drowned crew: sailors with no fatal flaw of their own, preserved and moved by the same indifferent forces, bodies bloated the way any drowned body bloats rather than reshaped into invented monster anatomy — meat in the churn, per Design Law 7's rule that the horror here is indifference, never a targeted judgment. Unlike the cultists, the drowned crew carry no curse and can be permanently put down by a costly, brutal finishing blow.**

**What a downed member of either population sounds like as it rises again is a deliberate, diegetic warning with no on-screen timer attached — a groan, a shifting of weight, a change in breath, always the same for the same population so an attentive player can learn to read it. The drowned crew rise to a plain, impersonal groan. The cultists rise to something closer to a thin, wet cough — an unplaceable, uncomfortable echo of the same sound Walter will not understand the significance of until his chapter's ending, planted here, hours earlier, entirely undiscussed. This is Design Law 5 in its purest form: nothing tells the player this sound means anything, and nothing needs to.**

**Walter, per the Bloodline Secret, is himself descended from that same drowned crew. Whether any remains he encounters or avoids are, unknowably, his own kin is never stated and never resolved — discoverable only by a player who has already connected his ancestry to the wreck.**

# **Part Three — Chapter One: 1920s**

***Working title: No Exit Wound · Genre: dialogue- and evidence-driven investigation***

***The chapter loop is demonstrated in prose in the short story "No Exit Wound," written to the same title.***

## **Protagonist: Walter Corwin**

**A rigid Widow's Bight beat cop, shaped by a closed, insular town that has never had reason to look past its own coastline. Descended, unknowingly, from the drowned crew of the Ophion. Stayed home from the war on a compassionate exemption to care for his mother, Constance Corwin — an abusive, controlling presence whose care he gave out of duty long before he understood it as a wound. His arc across the chapter runs from dutiful son to, in retrospect, abused caretaker — revealed backward, the way everything in this trilogy is revealed, never announced as a twist. The register is closer to Ethan Frome than to any horror-genre "monstrous mother" trope: a slow erosion inside total isolation, not a jump scare.**

**His central failure, and the hinge Chapter Three turns on: he gave more weight to the town's elite men than to a housemaid's own account and disappearance. This is ordinary, human bias — the same limited epistemic bubble that later fails him against the entity — not supernatural interference. His death cuts an investigation short that his own prejudice was already failing before he ever died.**

## **Supporting Cast**

* **Constance Corwin — Walter's late mother. Abusive, controlling. "No wire hangers" by way of Night of the Hunter as touchstones for register, not literal reference.**

* **Judge Absalom Wexford — cultist.**

* **Dr. Aldous Fenn — cultist. It is his personal library the scholarly book on Ophion comes from (see Part Four and the Physical Archive in Part Six).**

* **Miles Corliss — District Attorney, cultist.**

* **Josiah Pruitt — landowner, cultist.**

* **Otto Kessler — butcher, cultist.**

* **Father Behan, Captain Odell — supporting figures from the town.**

**The club numbers six; the rose garden holds six dead men in evening dress. Five members are named above. The sixth is deliberately never identified — no name, no line, no scene lingers on him — consistent with Design Law 5\.**

**The Ophion estate's grounds crew — harbor-side men and women who do the work no club member would touch himself — are this chapter's Observers, and the first the player meets anywhere in the trilogy: Chapter One plays first, so whatever the player learns to read in an Observer's refusal here is the only education they get before Chapters Two and Three assume it. The estate crew gives the tunnel mouth beneath the kitchen wing the same wide, unhurried berth their counterparts on the drowned island give its ruins a decade and two decades later, and the beat that shows this must be staged to the same rule as every other Observer scene in the game (Part Two, The Observers) — precise, unbothered, back to work in the same breath, never startled or pleading. Nothing marks them as the same continuing community the player will meet again in Chapters Two and Three; that recognition belongs entirely to a returning or attentive player, per Design Law 5\.**

## **The Crime**

**The cult — six men in total, of whom the doctor, judge, D.A., landowner, and butcher are known to Walter's investigation — sacrifice whoever is easiest to disappear, believing they are courting a benevolent, protective, maternal power. They have done this before Chapter One and would have done it again. Instantaneous death by materialized bullets; no powder burns, no exit wounds. The victims of the specific murder Walter investigates are officially recorded as transients.**

**In truth: a mother and her young son, in town because she had located, and hidden, documentation of wages owed to a whaling ancestor connected to the Ophion — a lay never paid out, a real and well-documented historical injustice against Black and Cape Verdean whalemen. She may have taken domestic work in a wealthy household while pursuing the claim, which put her inside the very world responsible for the debt. They were not targeted for being Black; they were targeted for being outsiders no one would miss — the horror is the indifference of the selection, not a hate crime dressed as ritual. The cult had no awareness the claim existed and no knowledge of who she was beyond a convenient, unmissed stranger. Her selection carries no causal connection whatsoever to the claim she carried — victimhood by pure opportunity is the bleakest available reading, and the only one the game endorses. That said mother and son are Black is what connects them, by blood, to Chapter Three's protagonist, Ekon Freeman — their surviving other son (see Design Law 12 on how this connection must be handled).**

**After Walter's death, his successor files the case as an accident — a gas leak, or similar — and the victims are not mentioned in the official record at all. This produces the first of several dishonest documents that recur across the trilogy (see Part Six).**

## **Mechanics**

**Clue-linking and non-linear questioning, recorded in a case file that will not hold still — witness statements shift tense, addresses drift, and Walter's own hand begins describing details he never wrote down. Per Design Law 4, this instability is presentation only: every factual signal the case actually needs remains recoverable through a second, redundant source, so a player is never punished for a bug that isn't one.**

**Opens iris-masked, the Expressionist device Caligari made famous; the iris opens to full frame for the first time at the rose garden crime scene. A single sustained auditory motif — a faint, subtle cough — carries Pavlovian dread across the whole chapter, structured as the frame's only sound until the ontological crack: the first time Walter hears glass shatter, and realizes, without being told, that sound should not exist in his world and just did.**

**Coping mechanism: a flask. Can be rationed; cannot be outlasted. A forced-spill mechanism punishes players who try to hoard or ration it past its natural point — an anti-optimization beat aimed specifically at the min-max instinct. Like any other loss of a resource the player didn't choose, the spill needs its own visible tell (a stumble the player caused, a beat of overheard dialogue noting it, anything legible in the moment it happens) and a way to confirm afterward how much was lost and why — per Design Law 4, a player must never be left wondering whether an unrationed flask emptying itself was a bug rather than the game acting with intent.**

***Strength and Perception***

**Walter carries two stats, shared in form with both later protagonists — Strength, governing carried weight rather than a slot count, and Perception, his fuel stat, which sharpens his ability to link distant statements and notice what a case file omits. Perception is not a coping mechanism and has no hidden cost — it does exactly what it says, and the fatal outcome it produces is Design Law 1 operating in the open: understanding is fatal, and perception is the stat that produces understanding. The more of the case a player actually pieces together, the more complete and legible the file that reaches Ekon twenty years later — perception is quietly the same system that satisfies Design Law 6\. Perception also governs literal visibility in the tunnel, expressed as revealed detail rather than a screen-wide brightness change — additional silhouettes, reflective edges, and environmental information becoming visible as it rises, never simply the same pixels lifted with a gamma slider. This keeps the effect a genuine stat reward rather than something an accessibility brightness setting could reproduce for free — one stat, one honest effect expressed two ways, never two systems pretending to be one.**

**The corkboard is the diegetic display of accumulated Perception, not a manual puzzle a player must correctly solve to progress — this distinction matters enough to state plainly, since it is the single most common misreading this document has produced across outside review. Perception rises through ordinary, unavoidable contact with the case (the beats the chapter requires regardless of playstyle), and the causal spine "goes whole" once it crosses its threshold, whether or not the player has ever opened the board and physically dragged a card. A player who never touches it is not stalled; he simply carries a thinner, later-completing version of the same accumulation a diligent player builds faster and more richly (Design Law 13). The board rewards engagement with a more legible, more complete record — for the player's own reading, and for what survives into Ekon's inheritance — but it is a window onto the mechanic, never the mechanic's gate.**

**Design Law 13 guarantees that a player who skips every optional beat still reaches the fatal understanding, but it does not by itself say how that understanding is staged for a player carrying none of the optional evidence a thorough playthrough would have handed him — the causal spine "going whole" can never mean handing that player an articulate theological summary he has no basis to have assembled, since that reads as an unearned script injection rather than his own realization, breaking the show-don't-tell posture Design Law 5 holds everywhere else. How this beat is staged for a minimal-engagement player is an open production question (TDD: Chapter One, Minimal-Engagement Staging).**

**Strength stays mostly slack for Walter — his evidence rarely demands it, which is itself a small, unremarked tell: an interface built for a man who needs far less of it than the chapter provides. It matters only at a handful of specific, heavy objects that force a real choice between what he carries and what he leaves behind, a different rhythm from the constant pressure Chapter Two runs on. It also governs melee — his sole exception, and a narrow one: it never improves his accuracy or turns a stagger into a kill, it only extends how long a landed stagger holds before whatever he hit starts breathing again. His revolver holds six rounds and perhaps one reload, period-accurate and inadequate by design, and years spent tending his dying mother left him with incidental medical knowledge rather than any trained skill at violence. A player who tries to shoot or fight his way through will run out of ammunition, or simply lose — he is capped by what little he has, not by a number he chose badly. Strength is a trap, not a lie: it rewards a player for investing in the one stat that will never make him good at this, only marginally luckier about what happens after he already got lucky once.**

***Stealth***

**Stealth exists for Walter first as a tool for eavesdropping rather than survival — a way to overhear what a room would never say to a badge. It is unexpectedly repurposed in the tunnel, where the same mechanic that let him listen his way to information becomes the only reliable way to get past the bloated dead alive. Its higher-stakes form fully arrives in Chapters Two and Three (see Part Six); Walter is the chapter where the player first learns the tool can do more than it originally seemed to.**

## **Player Orientation: Compliance and Resistance**

**Chapter One's grammar does not encode a playstyle choice — there is no toggle, no dialogue-tone system, no separate resistance track. But the same verbs (examine, collect, link, consult) that let a passive, curious player accumulate a case can equally be pointed at the town's institutions themselves, and the chapter must support this without inventing anything new to do it.**

**A player who plays Walter as a man actively refusing the town's arithmetic — pressing Odell for a full inquest rather than accepting "transients," filing in triplicate rather than once, taking a wage claim to the county registrar though no living claimant stands in the room, pressing the *Gazette*'s editor after a story runs half-true, asking Father Behan to say from the pulpit what he'll only say behind the rectory — is not playing a different game. Every one of those beats is "consult" and "collect" run against a witness or an institution rather than a suspect, and every refusal the town hands back is the same reasonable-men-add-to-an-absence machinery the bible already describes for Odell and the club (Part Three, His Central Failure; Design Law 7). None of it requires a new stat, a new fail state, or a new NPC category — a registrar's clerk and a newspaper editor are witnesses like any other, consulted with the tools the chapter already has.**

**What this orientation changes is not the system but the shape of the record it leaves. A compliant, curious Walter builds a case file that is more complete because he followed the evidence further. A resistant Walter builds one that is more *contested* — the same Perception-driven completeness (Design Law 6), but weighted toward what he refused to let the town erase rather than what he merely found. Both are the same mechanism; only the emphasis differs, and both are equally canonical. The triplicate file's stubborn "eight" against the town's official "six" is not a new consequence system — it is Design Law 6's existing case-file-survives-death mechanism, expressed at its clearest, and belongs in the game as one of the concrete states the Post-Finish Archive can surface (Part Six).**

**This orientation changes nothing about the ending. Walter still cannot out-argue an arithmetic; Odell is still not lying to him; the case's causal spine still completes on the same schedule regardless of how many doors he refused to let close quietly (Design Law 1). Resistance buys him nothing against the fatal understanding — it only decides what specific, stubborn fact is still sitting in a drawer when it arrives.**

## **The Entity**

**As Walter's grip erodes, the incomprehensible thing he has unknowingly summoned takes the shape of Constance — not a refuge he chooses, and not protection of any kind. It is simply the largest, most totalizing shape his mind has available to hold something it cannot otherwise process. This mirrors the cult's own theological error at a personal scale: they sought a benevolent maternal power and got indifference; he reaches for the one maternal figure he has and gets the same lesson twice, at two very different sizes. On screen, she must render as a distortion consistent with the established film grammar — never a witch or hag silhouette, never generic horror iconography for a menacing woman.**

## **The Descent**

**Cut off from his flask at the worst possible moment — stranded, not simply run dry — Walter follows the case as far as it will take him, through the tunnel mouth beneath the estate and part of the way into the dark before it beats him back. He is not equipped for what waits there. The bloated dead (see Part Two, The Drowned) can be eavesdropped on and slipped past using stealth, which remains the correct, lower-cost answer. Forcing the fight instead is not an automatic death, but it is never a clean win either: the revolver only ever staggers what it hits, never kills it. Once the cylinder is empty, whatever he finds lying around — a baton, a length of pipe, a nail-studded board — falls back to the same stagger-only rule; no found weapon is ever more lethal than the one before it, because nothing down here is any less immortal than it was a room ago. Against the drowned crew alone, a desperate, close, brutal finishing blow can end the fight outright rather than merely stagger it — but it costs him dearly, leaving him winded and loud enough that it draws more of them rather than fewer, so it is never free and rarely worth repeating. Against the cultists, no amount of force ever ends the fight; staggering one and running is the only outcome available, always. A player who empties every option without a stagger already banked, or without a nearby way out, dies for it. A fight that goes well should read as a scare that cost him everything he was carrying — ammunition, his composure, sometimes the last of his coping mechanism — never as a repeatable tactic. Per Design Law 11, a fight that goes badly resolves as death and a reload, never a stranding.**

## **Ending**

**He goes some distance into the abyss, not far, and is physically turned back before he reaches whatever waits at its end — the tunnel beats him back rather than killing him there. By the time he retreats, he has already pieced together enough — through Perception, through what the case has shown him — to know the cultists were never reaching for a person, that something cosmic occurred beneath their town, and that whatever wears his mother's shape is neither his grief nor his imagination. Knowing this much does not kill him outright. The fatal understanding completes later, once the case file's critical, causal spine goes whole — enough for Walter himself to grasp what happened, not the same thing as the file's full evidentiary completeness — and finds him wherever he happens to be when it does. Design Law 1 with nothing standing between the stat and the ending, just delayed past the descent itself. What becomes of him afterward is never established on the record; what little survives to be found are traces only Ward, ten years later, will disturb without understanding (see Part Four).**

**Chapter One does not need a bespoke final-action beat, and should not get one. The clue-linking case file, already the chapter's core system, is doing this work by default — whatever state Walter has actually compiled at the moment of his death is what survives and is what Ekon eventually finds, twenty years later, missing whatever Walter never got to record. Perception is the stat that drives this state directly — the more of the case a player has actually linked, the more complete the file Ekon finds. No decision screen, no authored last act; the consequence is emergent from ordinary play, not a scene the game stages. This keeps Walter's ending confused and unresolved, the way it has to read, rather than accidentally granting him a moment of clarity he never gets.**

# **Part Four — Chapter Two: 1930s**

***Working title: The Maw · Genre: collector-platformer***

***The chapter loop is demonstrated in prose in the short story "Total Recovery," Ward's own governing doctrine and the chapter's working alternate title.***

## **Protagonist: Ward Kohistani**

**Half-British, half-Afghan archaeologist, born of a wartime liaison he does not carry his father's name from. His mother's family carries real standing — in the vein of the historical pattern of Anglo-Afghan noble houses that secured British colonial favor by collaborating against their own people (a real, documented pattern; this project invents its own family rather than using an actual lineage). Surname Kohistani, a real, common Pashtun geographic surname tied to no single dynasty. First name anglicized to Ward — a legal and social term for someone under another party's protection, chosen by a man trying so hard to belong to an institution that never fully grants him that protection in return.**

**Sent to Widow's Bight by the British Archaeological Society, ostensibly as a lesser posting to keep him clear of the more prestigious Egypt digs of the era's Tutankhamun-driven Egyptomania. He reads the assignment as opportunity rather than exile, determined to prove his methodology superior.**

## **Setting**

**The ruins on the drowned island off Widow's Bight — what remains of the Ophion and the fleet lost with it. The Observers work this ground and appear throughout, in grayscale but for their jewelry and reflections.**

**Deep enough into the ruins, the excavation meets a tunnel that has no business existing — a passage running beneath open ocean to somewhere Ward has no way of knowing is a private cellar on the mainland (see Part Two, The Tunnel Beneath the Water). He can only record in his Codex that the geometry is wrong and move on. Somewhere in that stretch of tunnel he disturbs small, decontextualized traces — a corroded flask, a police whistle half-buried in silt, scuff marks that read as a struggle to someone who'd know what a struggle looks like, which he doesn't. He never learns whose they were. A returning player might.**

## **Mechanics**

**A collector-platformer built as a trap disguised as genre satisfaction. Small, perilous leaps — skinned knees and a broken toe that never heals, not stunt-driven traversal. Thousands of worthless trinkets, roughly two hundred artifacts of real value, ten inventory slots. A Codex logs everything regardless of what actually makes it out.**

**The fiction needs thousands of trinkets; production does not — the felt abundance is meant to be a systemic effect, not an asset-count commitment, and only the roughly two hundred artifacts of real value need individual, bespoke authorship (TDD: Chapter Two, Procedural Trinket Generation).**

**The Codex is not a triumph and the escape it implies was never real — that is the chapter's lie. It is not that individual player decisions never mattered. What gets cataloged, hidden, returned, or destroyed along the way carries real, felt consequences (what Ekon later finds of him, which specific hazard gets encountered, what survives to be misread by history), even though the ultimate outcome — no rescue, no recovery of the Codex within Ward's lifetime or by the Society that sent him — stays exactly as dark as it needs to. Ekon's private discovery of it, years later, is a separate, later event (see the Ending below), not a walk-back of this. This does not require a dedicated final-choice mechanic. The ten-slot inventory and the Codex are already a running record of trade-offs; whatever configuration exists at the moment Ward is lost — which artifacts he kept over supplies, which Codex sections he'd filled in versus left blank — is simply what Ekon finds. The consequence is a byproduct of how the chapter was already played, never a special scene asking the player to choose Ward's legacy on his behalf.**

**Coping mechanism: field-grade opium, first used for the injuries, migrating to psychological dependency as the chapter progresses. It is finite, and honest — per Design Law 3, it never causes hallucination or distorted color perception itself. It simply runs out, and the gameplay shifts from exploration to a rail-driven, inevitable slide into the maw.**

***Strength and Agility***

**Ward carries the same two-stat shape as Walter and Ekon — Strength, governing carried weight, and Agility, his fuel stat, earned through successful jumps and traversal. Agility only ever mitigates the chapter's physical toll — a twisted ankle or a broken toe becomes less likely, never impossible — because letting it be eliminated entirely would let a sufficiently practiced player build their way out of paying any price at all for the descent — against the thesis's core promise that competence reduces the cost of approaching the horror, but never abolishes it. Neither Agility nor Strength can kill him: pouring everything into one and starving the other only means worse odds against the physical toll and less he can carry without setting something down, never a death the game charges to a bad build. Ward's fail state is singular and unconditional, and lives entirely outside the stat system: choosing to confront the tunnel's inhabitants directly, rather than find the way around, kills him regardless of anything invested in either stat. Strength governs what he can carry, not how many objects fit: ten slots is the ceiling, but a handful of artifacts weigh enough on their own that reaching it in practice means choosing what to set down well before the tenth slot is full. Per Design Law 11, that one fail state resolves as death and a reload, never a stranding.**

**Whatever configuration exists in his pack and his Codex at the moment he is lost — which artifacts, which pages filled in, which left blank — is exactly, and only, what Ekon finds.**

***Stealth***

**Ward's encounter with the bloated dead is where the stat system's honesty is least forgiving. Overhead ledges offer a real, playable route past them; stealth is not flavor here, it is the correct answer. Choosing to confront them instead is a fail state, not a harder fight — Ward has no combat capability of any kind, and the attempt should read, and function, as fatal. This is the Observers' own discipline, forced onto a player who has spent the whole chapter accumulating rather than avoiding.**

**The inhabitants Ward must avoid key off light, not sound or motion — the actual skill this chapter is teaching is reading a space and identifying the route around them, closer to a puzzle-platformer's spatial logic than to crouch-and-wait stealth tension. The chapter's sound design runs its own arc in support of this: early galleries play in the muddled, cluttered register of early cinema sound, resolving gradually into clean, exceptional foley as Ward descends. That clarity is a reward, not a threat — the better the space sounds, the more precisely he can place the inhabitants and their light sources, and the safer his routing gets. The trap is what that same clarity buys him: a player hearing the world this well has every reason to keep going, and no mechanical reason left to stop, which is exactly what carries him past the point of turning back. Competence is never punished here — it simply removes the only excuse he had left to quit.**

## **Player Orientation: Acquisition and Documentation**

**As with Walter (Part Three), Chapter Two's grammar does not encode a playstyle choice — there is no toggle, no separate track. But the same split that already exists between the Codex (a written record of everything found) and the ten-slot pack (what physically comes out) already supports two distinct, equally canonical ways to play Ward, without any new system.**

**A player who fills every slot, hauling out relics over supplies, is playing acquisition — the version demonstrated in "Total Recovery," where the pack matters as much as the page. A player who instead logs thoroughly but carries little — who treats *observed, not recovered, location marked for return* as a satisfying outcome in its own right rather than a consolation, who marks a find and moves on rather than risking the ledge or the ten-slot ceiling for it — is playing documentation. Both produce a complete Codex if the player is diligent; they differ in what physically survives to be found. An acquisition-run Ekon inherits a pack heavy with relics and a thinner late-game Codex, because time spent hauling is time not spent recording. A documentation-run Ekon inherits a near-empty pack and a Codex whose entries run further and more completely toward the end, including detail on pieces an acquisition player would simply have carried out and never described in writing at all.**

**Neither path changes Ward's ending. He is lost in the depths regardless, exactly as fatally, on exactly the same schedule (Design Law 1). What changes, per Design Law 6, is the shape of the one archive he leaves — pack-heavy or page-heavy — which is exactly the same kind of distinction Walter's resistant and compliant files already model in Part Three. This is not a second mechanic. It is the existing pack/Codex split, read all the way through.**

**The split above is legible on the page; it still needs its own mechanical texture in play, or looting and documenting collapse into the same button press wearing two different flavor texts, and the distinction stops being felt (TDD: Chapter Two, Acquisition/Documentation Mechanical Distinction).**

## **His Fatal Realization**

**The Observers are not primitive. They are correct. Curiosity is not rewarded in this design — it is punished. To know the horror is to succumb to it, and no one survives that moment. He digs because he wants meaning, finds because he wants glory, persists because he wants significance, and understands because he can no longer stop himself. Understanding is the moment he dies.**

## **Ending**

**He is lost in the depths. His remains, and the Codex, are found roughly a decade later by Ekon Freeman — the only person who will ever validate that Ward existed and reached as far as he did, in a private moment neither man gets to share directly. (Walter to Ekon is the trilogy's twenty-year span; Ward sits roughly a decade after Walter and a decade before Ekon.)**

**Other consequences of how Ward played — which hazard he met, what the Observers or the ruin itself register as disturbed — surface elsewhere in Chapter Three's world (a changed lead, an altered read, an absent find), distinct from the pack and Codex Ekon finds directly.**

**Among his effects: a scholarly book containing a passage defining Ophion's actual mythological meaning. The book itself once belonged to Dr. Aldous Fenn, one of Chapter One's cultists, and passed out of his estate after his death; Ward acquired it secondhand, never knowing whose hands held it before his. Fenn's own underlining reflects a man flattering his own delusion; Ward's added annotations, written in the margins beside Fenn's without either man aware of the other, reflect real historical rigor chasing the same question honestly. Neither man meets the other, and neither man meets Ekon, who inherits both sets of handwriting without being told which is which. This becomes the seed of Chapter Three's central discovery beat, and the third and strongest instance of the trilogy's object-passed-hand-to-hand device.**

# **Part Five — Chapter Three: 1940s**

***Working title: Ophion · Genre: tactical survival, synthesizing Chapters One and Two***

***The chapter loop is demonstrated in prose in the short story "Scorched Earth," the chapter's working alternate title, for the tactical doctrine of denying ground rather than holding it.***

## **Protagonist: Ekon Freeman**

**A Black WWII veteran. First name Ekon — Efik/Ibibio Nigerian in origin, meaning "strong," chosen deliberately by his mother as an act of naming her son what she wanted the world to have to reckon with, consistent with the real, if still uncommon, pan-African naming currents of the 1910s–1920s (Garveyism-adjacent). Surname Freeman — a real, documented surname pattern adopted by formerly free or newly emancipated Black Americans to state their legal status outright. His own family line, however, traces not to formerly enslaved ancestry but to a free Black whaling lineage: Massachusetts abolished slavery through its own courts and constitution in the 1780s, decades before the Ophion's loss in the 1820s, and coastal Massachusetts had substantial, well-documented free Black maritime communities well before the Civil War. The ancestor who sailed and died with the Ophion was free by law from the start — which makes the town's later dismissal of his mother and brother as rootless transients not just cruel, but a specific, disprovable lie: this family's claim to that coastline predates the wealthy families' fortune by a full generation.**

**Both names — strength and freedom — are stated as plain fact on the surface and disproven underneath, in the same register as Ward's name in Chapter Two.**

## **The Wage Claim**

**His mother had gone in search of documentation proving wages owed to the whaling ancestor — a lay never paid — found it, and hid it before her death. It was not among her listed belongings in the official record: a third dishonest document, alongside the original case file (unreliable but true) and the sanitized replacement file (orderly but false). Ekon knows the document exists and makes serious effort to find it across the chapter. It is held by a local lawyer his mother had engaged — a morally grey figure who has no compulsion to fight for the document but knows better than to destroy any document at all, giving Ekon a real, present-day relationship to work through rather than only inherited grief and artifacts from the past. Ekon does recover it physically, and this is the chapter's clearest Design Law 6 beat — a specific, real, non-cosmic victory. It proves the claim; it does not collect it. The town will not honor a debt this old regardless of proof, and nothing about recovering it changes what happens to Ekon in the caverns. The exact wording of the document — the ship it names, the sum, the ancestor's name as recorded on it — is a content-writing task for the asset pass, not a design decision, and stays open for that reason alone.**

**Walter Corwin's original case file reaches Ekon through this same lawyer, folded in among his mother's own papers by the time Ekon comes looking for the wage claim. The lawyer can gesture at how it ended up there and no further, and does not offer to try explaining it twice. How it actually got there — whether the mother acquired it herself, whether it passed through other hands first, whatever chain of custody a curious player might start to imagine — is deliberately never explained, per Design Law 5, and no scene, present or future, may close that gap. A scene is allowed to gesture at the fact of arrival; it is never allowed to resolve the mechanism.**

## **Mechanics**

**Not a third, unrelated genre. Chapter Three synthesizes Chapter One's investigation grammar and Chapter Two's descent-and-hazard grammar, run by a protagonist who is actually trained and competent at both. This is what makes the "I'm going to win this time" illusion land as something the player has to reckon with rather than a mood the game asserts — the player has already failed at these exact systems twice, and now watches them handled with real skill.**

**Weapons function flawlessly against physical threats. Against the Old Gods, there is nothing to kill, so his training pivots from assault to containment: severing cables, collapsing tunnels, sealing apertures. Rubble and walls are a delay, not protection — the Old Gods are immutable, and nothing built to stop a man can stop them.**

**Among the tunnel's cultist remains, Ekon can encounter one whose transformation never finished (see Part Two, The Drowned) — a precision headshot can end it outright, a shot Walter, in an earlier generation, was never equipped, trained, or positioned to attempt against anything down there. Deeper in, the fully transformed are exactly as absolute as Walter found them: staggered and left behind, never ended. Nothing on screen explains this distinction; it is discoverable only by a player who has already learned, from Walter's chapter or from failure in his own, that the fully transformed never go down for good.**

**Coping mechanism: cigarettes, which never run out, and matches, which do — the actual scarcity, and the only light in the encroaching dark. Matches are a physically countable, inspectable inventory item — the player can always check how many remain — but no persistent numeric HUD counter or predictive display accompanies them; scarcity is read off the object itself, consistent with Design Law 11's ban on hidden values affecting outcomes. This is Ekon's version of the honest, finite coping resource that the flask and the opium perform for his predecessors (Design Law 3); Chapter Three is not missing an escalating scarcity, it simply declines to attach a player-visible number to it, because his arc is about competence meeting a problem competence cannot solve, not about a build succeeding or failing. This is deliberately the chapter's single riskiest mechanical bet: whether dread carried by writing, pacing, and the matches' physical scarcity alone reads as strongly as the visible-stat-driven dread of Chapters One and Two. It should be an early playtest priority, and should not be "fixed" by adding a fuel stat without playtest data showing the tension is actually reading thinner in practice. Whether a match burns in real time once struck or is spent only at discrete, player-initiated moments is an open production question (TDD: Chapter Three, Match Consumption Model), not one fixed here. What is fixed here, because it is a fairness guarantee rather than a tuning question: if Ekon reaches zero matches before reaching the charges, the encroaching dark is not a wall or a stall, it is exactly as lethal as any other unlit hazard in the tunnel (see Part Two, The Drowned) — running out of light resolves as an ordinary Design Law 11 fail state, death and a reload, never a stranding in the dark waiting for a resource that will not return.**

***Strength and Combat***

**Ekon shares the same Strength stat as his predecessors, governing carried weight rather than slot count, and a Combat stat that is infrastructure rather than fuel — it keeps him alive against physical, mundane threats without ever bringing him closer to what actually ends him. He has no interest in the artifacts Ward left scattered through the ruins; he is here to demand answers, not to collect. A player who invests Strength into hauling out relics anyway is optimizing for exactly the thing the story says he doesn't want, and pays for it in the Combat investment he didn't make instead — a fail state with the same honesty rule as his predecessors: no silent correction, and per Design Law 11 any resulting death resolves as death and a reload.**

***Stealth***

**For Ekon, stealth governs how much of a fight he gets to choose rather than whether he fights at all — how close he closes the distance before an engagement begins, and how much of it he can end before it starts. It is the only version of the mechanic available to him that resembles an advantage rather than a requirement, consistent with his being the one protagonist competent enough to have options at all.**

## **Player Orientation: Preservation and Denial**

**As with Walter (Part Three) and Ward (Part Four), Chapter Three's grammar does not encode a playstyle choice — there is no toggle, no separate track. But the same final authored action described in the Ending below already supports two distinct, equally canonical readings of what Ekon does with what he's carrying, without any new system.**

**A player who plays Ekon as a preserver — sending the wage claim home, sealing the ledger and the case file somewhere they might someday surface, choosing deliberately what burns and what doesn't — is playing preservation: the version demonstrated in "Scorched Earth," where the act stays curatorial even at the very end. A player who instead concludes, across the chapter, that a true thing written down is not the same as a true thing kept, and empties the fire on everything he carries rather than leave one more correctly filed, perfectly true, permanently unread document behind — is playing denial: the version demonstrated in the alternate draft of the same title. Neither reading requires a new stat, a new prompt, or a new fail state; both are the same final authored action the Ending already specifies, pointed at a different outcome.**

**Neither path changes Ekon's ending. He dies in the collapse regardless, exactly as fatally, on exactly the same schedule (Design Law 1). What changes, per Design Law 6, is what the Post-Finish Archive has left to show — specific documents sent home and specific ones sealed, or an explicit entry recording that nothing survived and why (Part Six). This is not a second mechanic. It is the one final action Chapter Three already grants him, read all the way through.**

## **The Ophion Discovery**

**Reading Ward Kohistani's annotated book, Ekon encounters the actual mythological definition of Ophion — rendered as plain, undramatized found text on screen. No reaction shot, no line of dialogue states the connection to the club or the Old Gods outright. The player, who has already encountered the club's name multiple times by this point, is left to draw the line themselves, at the same moment Ekon does or slightly before. This gives him a discovery that belongs entirely to him — not inherited, not handed to him, found through his own initiative and reading.**

## **Ending**

**He finds Ward's remains and the Codex, and gets his single private moment of validating a dead stranger's work. He reaches the abyss to confront the Old Gods directly. He gets one final, authored, player-chosen action immediately before the end — sealing something, placing the ledger somewhere it might someday surface, choosing what evidence burns — that cannot save him but does define him. Whatever he chooses must produce a distinct, legible difference in the Post-Finish Archive, per Design Law 4; the exact menu of what can be sealed, placed, or burned is a content-pass decision, not fixed here. This is a Chapter Three exclusive: Walter's and Ward's final consequences are emergent, read only in hindsight through what they leave behind, because neither man is lucid enough at the end for a conscious choice to be honest. Ekon is. He is the only protagonist still fully himself in his final moment, which is exactly what makes the scene earned rather than borrowed — the one explicit choice in the trilogy belongs to the one man capable of actually making it.**

**The film stock does not simply glitch; it burns, melts, and dissolves — the medium itself refusing to depict what it cannot hold. The camera abandons him, pulling back through the caverns, through the earth, and settling on the estate's manicured, oblivious lawn.**

# **Part Six — Cross-Chapter Systems**

## **The Physical Archive**

**A chain of documents and objects runs the length of the trilogy, functioning as the shared interaction grammar and the connective tissue between three protagonists who never meet:**

* **Walter Corwin's original case file — unreliable in presentation, true in substance.**

* **The sanitized replacement file, filed after Walter's death — orderly, false, omits the victims entirely.**

* **The belongings inventory of Ekon's mother — incomplete by omission, does not list the wage claim she hid.**

* **The wage claim / lay documentation itself — hidden by her, preserved (if reluctantly) by the lawyer she'd engaged, and physically recovered by Ekon.**

* **Ward Kohistani's Codex — a grave marker mistaken, by the player, for a manifesto, until it isn't.**

* **The Ophion book — Fenn's library copy, underlined by Fenn, annotated by Ward, read by Ekon; three men, three decades, none of whom ever meet, chasing the same page.**

**Cross-chapter persistent consequence state is capped to a small, deliberate budget — roughly six to ten meaningful states total across the trilogy (of the kind already established above: what Ekon finds of Ward, which hazards were encountered, what survived to be misread by history). This is a ceiling, not a target to fill; the number exists so that persistence stays authored and legible rather than sprawling into untracked combinatorial state.**

**Persistent consequence compounds across a run; it does not reset with each protagonist. A later protagonist's choice about a document only ever governs the specific copy that reached him — it can never retroactively undo whatever an earlier protagonist already did with copies that never reached him. If a resistant Walter files his case in triplicate, only the one copy that later finds its way to Ekon is ever his to seal, place, or burn; the other copies persist, are lost, or are found by someone else entirely off-screen, exactly as unknowable to Ekon as everything else about the men before him (Design Law 12). No ending is entitled to claim total erasure of a fact the player caused to be duplicated earlier in the same run — an ending may only speak to what its own protagonist actually held.**

## **Runtime**

**Target: roughly 15–21 hours total. A sprawling runtime gives a genre-savvy player time and room to pattern-match each chapter's twist well before it lands, which works directly against the trilogy's central device. Density of dread, not length of playtime, is what should outpace the player. Chapter One targets roughly 5–7 hours, Chapter Two roughly 4–6 hours, and Chapter Three roughly 6–8 hours, still the longest chapter but by a deliberately smaller margin, holding just enough extra room to push its twist past a genre-savvy player's pattern recognition without asking for a second act's worth of hours to do it.**

## **Common Interaction Grammar**

**Rather than three unrelated systems, the trilogy runs on one underlying grammar — examine, collect, manage a scarce resource, navigate a hazard, consult a shared archive — with each chapter emphasizing a different corner of it. Chapter Three is the explicit synthesis of Chapter One's investigation mode and Chapter Two's hazard-navigation mode.**

**This is a claim about player-facing legibility, not about shared engineering. It means a player who has learned Walter's "examine and consult" and Ward's "assess and navigate" recognizes both vocabularies at work in what Ekon does, and reads Chapter Three as a synthesis rather than a new game bolted onto two finished ones. It is not a claim that non-linear evidence-linking, platform traversal, and firearm ballistics share an underlying implementation — they don't, and a production plan that assumes this grammar collapses engineering scope is planning against a document it has misread. Budget Chapter One, Two, and Three as three distinct interaction sub-systems; the shared grammar is what makes playing all three feel like one game, not what makes building all three cost like one system.**

**"Consult" is not limited to a fixed roster of named suspects. Any witness or institution a protagonist's investigation can plausibly reach — a clerk, an editor, a clergyman, a widow — is consulted with the same tools and produces the same kind of result: information, a partial answer, or a refusal that itself becomes case-file content. Widening who gets consulted, including in service of a more actively resistant playstyle (see Part Three, Player Orientation), is content, not a new system, and needs no separate design sign-off.**

## **The Shared UI**

**No persistent HUD. The interface exists only when summoned — a single key opens it in all three chapters, revealing inventory, a sparse paperdoll, and stats. A HUD sitting on screen at all times would compete with the thing actually doing the chapter's work: aspect ratio, grain, distortion. The paperdoll has little to change on it in practice, and it stays in the design anyway, because the UI has to read as an RPG's shell even where the systems beneath it refuse to reward the player the way one normally would. That mismatch — full apparatus, thin content — is deliberate, and truest for Walter, whose ten inventory slots he rarely needs at all.**

## **The Stat System**

**Every protagonist carries exactly two stats, not a bespoke set per chapter — Strength, shared in mechanical function across all three (it governs carried weight, never slot count, and in Walter's case also governs stagger duration in melee), and one chapter-specific signature stat. Perception and Agility are fuel stats: each only ever modulates the pace and difficulty of an unavoidable end — and, in Perception's case, also the completeness of what's left behind for the next protagonist to inherit — never gating whether that end arrives. Combat is an infrastructure stat: it keeps Ekon alive longer against physical, mundane threats without ever changing where his story ends. Ekon deliberately has no fuel stat of his own — his path to the abyss runs on inherited narrative, the wage claim and the case file, not on anything a player invests points in, and that asymmetry is intentional (see Part Five).**

**Every stat is honest: it does exactly what it claims, with no hidden second effect, the same principle Design Law 3 already holds coping mechanisms to. The system never secretly rescues a bad build (Design Law 11), but every failure a bad build produces resolves as the protagonist's death, never a permanent stranding, so a reload is always available.**

**A fuel stat never gates whether a chapter can resolve — it only modulates the difficulty and pace of the path to that resolution. A player who refuses to engage a fuel mechanic — declining to build the case, avoiding jumps — is not stopped and is not soft-locked; the chapter simply gets harder, slower, and more exposed to reach the same, unavoidable end. Coping delays; refusing to engage never shortens the inevitable, but it is not punished for its own sake either — this is a harder game, never a worse one.**

**The same holds, for a different reason, where a stat is infrastructure rather than fuel: a player who underinvests in Ekon's Combat makes his physical encounters more dangerous and more costly, never mandatory-and-unbeatable. Stealth remains available regardless of how Combat was built, and any resulting death is an ordinary Design Law 11 fail state — death and a reload — never a stranding.**

**Combat outcomes, wherever combat is an available choice for a protagonist (Walter, Ekon — not Ward, who has none), are locked to a costly-hybrid model: force can buy an opening — a stagger, a half-second, a door — but never a clean kill against anything that matters, and a fight that goes well should read as a near-miss that spent something real (ammunition, composure, a coping resource), never as a repeatable tactic. A fight that goes badly is a real fail state and resolves as death and a reload, per Design Law 11\.**

**The stagger-only rule protects the player's tools against a fully transformed cultist; it never protects the cultist's tools against the player in return, and it must never produce a stalemate. A protagonist who is cornered by one with nothing left to spend — no ammunition, no stagger banked, no route out — does not enter a war of attrition against something that cannot be worn down. The threat closes the distance and ends it outright. This is not a new fail state; it is the same Design Law 11 death-and-reload that any other exhausted-resources encounter produces, made explicit here because "staggered, never destroyed" could otherwise be misread as symmetrical, and an immortal thing that also cannot finish what it starts is the one way this system could quietly soft-lock a player instead of killing them.**

## **Stealth**

**A fourth shared mechanic, present in every chapter with a different function — information-gathering for Walter (eavesdropping), the correct, non-negotiable answer to a threat with no other solution for Ward, and control over engagement terms for Ekon. Like Strength, it is one mechanic doing three different jobs depending on who is using it and what they actually need from it.**

## **Unreliable Presentation, Fair Game State**

**Any chapter's unreliable presentation (shifting case file text, distorting frame, degrading audio) must never obscure factual game state without a redundant, recoverable path to the same information. QA should explicitly test for the difference between intended unreliability and accidental unfairness. This is Design Law 4 restated as a systems requirement, and it extends to every persistent-consequence system in the game, not only the case file's prose.**

## **The Post-Finish Archive**

**After the credits, a menu compiles what actually happened across a single playthrough — Walter's case file as he left it, Ward's Codex and inventory as he left it, the wage claim's fate, what Ekon chose to seal or burn — assembled entirely from what the game already generated, not new content built for the purpose. It exists to make the persistent-consequence systems legible after the fact for a player who wants to see the shape of what they built, and to give the trilogy replay value that doesn't depend on branching endings it was never going to have.**

**A run that leaves behind unusually little — Ekon choosing to preserve nothing at all, for instance — is rendered the same way as any other: an explicit entry stating what's missing and why (a claim marked unfiled, a file marked lost, a ledger marked burned), never a blank space or an omitted row. Absence is itself a legible outcome, per Design Law 4, and must never be mistakable for a save error or a broken unlock.**

## **Accessibility Suite**

**Non-negotiable, present from the first playable build: flicker reduction, distortion-intensity controls, protected and always-legible subtitles, contrast controls, and a guaranteed path to clue readability under any decay state. The goal is that no player is excluded from the game's signature effects by circumstances outside their control, and that no player who can experience the raw version has to.**

**Flicker reduction and distortion intensity set fully to their floor cannot simply mean the medium stops degrading — Design Law 8 still has to read as something breaking down, just through a different vocabulary, or the accessible version of the game quietly stops being the same game. What that alternate vocabulary looks like is an open production question (TDD: Cross-Chapter, Accessible-Mode Degradation Vocabulary), but the requirement itself is not optional: whatever it turns out to be must preserve the dread the accessibility settings exist to protect a player from having to endure through flicker or distortion, never replace it with a flatter, unaffected version of the game underneath.**

## **Tonal Contrast**

**Each protagonist receives at least one genuine, non-ironic moment of pleasure or competence — Walter's clean read of a witness, Ward's clean jump and a find that pays off exactly as hoped, Ekon's clean, competent kill early in Chapter Three — before the chapter's horror undercuts it. The undercutting is what makes the horror land; without an honest pleasure first, there is nothing for it to undercut, and the bleakness has no contrast to work against.**

# **Part Seven — The Meta Layer (Internal Only)**

**Everything in this Part exists for the build team. None of it is ever referenced in marketing copy, a store page, press materials, interviews, or any other forward-facing communication, at any point, for any reason. This is a hard rule, not a preference (Design Law 10).**

## **Difficulty Selection**

**A standard-looking difficulty menu: Easy, Normal, Hard, Impossible. Easy, Normal, and Hard render in a normal disabled-state grey, exactly as any real disabled menu item would, with no tooltip, no strikethrough, no explanatory text. Only Impossible is selectable. Repeated attempts to select a greyed-out option produce a brief UI glitch and nothing else — no escalation, no message, no easter egg, forever. That glitch has to read as the interface acting with intent, not as broken software — the same aspect/grain/audio vocabulary the rest of the game uses, never a freeze or a blank stall a player might mistake for a crashed build or an uncalibrated input device; the specific cue is a production decision (TDD: Meta Layer, Difficulty-Menu Glitch Cue). This is the one place in the entire project where the literal, unadulterated truth is stated — the game is, without exaggeration, impossible — and it is stated once, flatly, and never explained or referenced again anywhere in the experience.**

**Accessibility options live on their own menu, reachable independently of and before this screen ever appears (see Design Law 9). The two must never be presented together or in proximity — flicker reduction and contrast controls sitting next to a joke about impossibility risks the joke reading as an accessibility insult instead of the flat truth it's meant to be.**

## **Achievements**

**Exactly three, corresponding to the three chapters' outcomes, in chapter order:**

* **Died — Chapter One.**

* **Died Again — Chapter Two.**

* **Died Knowing — Chapter Three.**

**Descriptions should read like flat case-file or coroner's-note language, never wink at the player. Ekon's description in particular should state plainly that he dies — comprehension is what ends him, per Design Law 1, a half-step ahead of the collapse he engineers, but the collapse still kills him. Nothing in the game grants him the fully transformed cultists' immortality; he is never an exception to that rule, and the achievement title names what he understood before the end, not a state he persists in afterward. No hidden fourth achievement, no secret "true ending" unlock, ever — the absence of a victory condition must be legible as an absence, not mistakable for an unsolved puzzle. The menu and the achievement set never cross-reference or explain each other.**

