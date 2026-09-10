# Day One: earn the next question

9 September 2026. Codex review requested by Dejunai following the live dialogue integration and arrival polish. **Assessment and proposed changes only; no gameplay or authored dialogue changed in this pass.**

**Update, same day (GitHub Copilot):** All four findings implemented and regression-tested
(`--qa-phase2`, `--qa-staging`, `--qa-town`, `--qa-usability`, `--qa`, plus the dialogue catalog/live
suites). Finding 4's actual fact (the steward heard secondhand of a colored woman asking about
work, no name, won't say who told him) was decided with Dejunai before writing it.

## Recommendation

The opening already has a strong investigation: eight deaths, an official account that privileges six, and a woman whose name Walter can recover through ordinary police work. Make that work rewarding before the game explains its horror.

First fix premature conclusions on the board. Then improve the handoff from Naomi's identification to a chosen follow-up, and give the required first steward visit a modest investigative payoff. Do not add districts, art, another investigation system, or enough mandatory reading to manufacture thirty minutes.

## Basis and limits

Reviewed the current design bible v15; the live Chapter One controller, archive, staging and clock; original scene/record content; and the authored gatehouse, gardener, assistant, Odell, Almy, steward, Gazette editor, clockmaker, historian, old woman and Kessler conversations. These are the principal opening spine and several readily accessible detours, not an editorial review of every resident.

This is a source-based route and knowledge audit, not a timed cold playtest. The minute ranges below are proposed player-experience targets. The existing `tests/pacing_probe.gd` assumes older menus and scripted choices; its estimate must not be presented as a current measurement without updating it. Numeric TIME is in-world time, not a prediction of how long a player reads. Current hub travel costs thirty in-world minutes; travel within a district is free; wandering advances at 5x; authored conversation budgets apply on first completion.

## What should happen in the first thirty minutes

| Target window | Player action | Earned payoff | Question carried forward |
| --- | --- | --- | --- |
| 0–5 minutes | Enter, examine the rose-garden victims, notice the second scene or hear its count | A specific physical mystery, followed by a disturbing discrepancy in attention | What happened here, and who is being left out? |
| 5–12 minutes | Compare the grounds with the assistant and Odell; prepare the report | Walter can preserve exact observations despite an inadequate official explanation | Will the precinct retain what I actually found? |
| 12–20 minutes | Submit the report; ask Almy for the woman's name; inspect the ledger if desired | Naomi Freeman has a name, a recorded visit, and a life beyond the scene | What brought her here, and whom should I ask next? |
| 20–30 minutes | Follow one lead and optionally compare records on the board | One corroboration or attributable contradiction that the player earned | A concrete next inquiry, rather than a general instruction to visit everyone |

This is a spine to support, not a forced itinerary. A fast player may finish it sooner; an attentive player may still be at the estate. Both should feel an investigation developing. The ledger/name connection and the official-heading/count connection are good early successes. Neither should become a mandatory linking puzzle.

## Findings, in implementation order

### 1. The board can disclose the chapter's explanation before its evidence exists

**Resolved.** `chapter_one_archive.gd::_board()` now builds the spine's clauses from actual evidence
(`register`/`ophion_myth_classical`/`insurance_fraud_record`/`behan_name` for the fortune clause,
`lower_foundation`/`tunnel_complete`/`municipal_foundation` for the passage clause,
`club_devotion`/`maternal_delusion`/the `chosen_delusion`/`same_maternal_words` links for the
presence clause) instead of asserting all four unconditionally at Perception 5. The tier headers
(UNRESOLVED/FORMING/COMPLETE) still key off Perception, per the bible's own "window onto the
mechanic, never the mechanic's gate" rule; only the *content* of each tier is now evidence-gated.

`case_state.gd::perception()` returns `2 + min(3, evidence_count / 3) + min(3, link_count)`. `chapter_one_archive.gd::_board()` displays the COMPLETE causal-spine paragraph at Perception 5, without checking the underlying discoveries or tunnel progress. Eight opening observations plus `intake` give nine records and Perception 5 with zero manual links. Opening the board then announces an undersea passage and a summoned presence. At six observations, its FORMING paragraph can already assert an inherited fortune and unexplained passage.

**Proposed first fix:** retain Perception rewards and progression; make board prose evidence-aware. An early, well-supported case can be described as well corroborated while its cause remains unresolved. Only display relationships supported by the player's actual records. Do not solve this by arbitrarily raising the stat threshold or requiring manual linking. Bible v15 explicitly rejects forcing an unearned theological summary into a minimally engaged player's head.

Acceptance: open the board with (a) six estate records, (b) eight estate records plus intake, and (c) early records plus valid links. None may introduce a passage, summoned presence, or historical causal claim absent from those records. Later supported discoveries must still appear, and the minimal progression route must remain playable.

### 2. Several older successful-link paragraphs invent facts or upgrade testimony into certainty

**Resolved.** All six flagged `deduction` texts (`naomi_lay`, `naomi_address`, `count_disagreement`,
`chosen_delusion`, `same_door`, `two_drawings`) in `chapter_one_archive.gd`'s `LINKS` table were
rewritten to match only what their two linked observations actually establish — no invented
documents, no upgraded witness counts, no confirmed supernatural covenant, no terrified staging.

The connection-result screen renders both `summary` and `deduction`. This is player-facing text, not dormant commentary.

- `naomi_lay` describes a handwritten claim found in a satchel. The two linked inputs are Naomi's identification and Almy's recollection; Almy expressly says she did not see the document.
- `naomi_address` adds breakfast at seven every morning for a week, a diner, and two completely independent witnesses. The actual meal ledger records two meals and a carried balance at Almy's establishment. It corroborates her testimony but is not another independent witness.
- `count_disagreement` attributes deliberate omission to the precinct more strongly than the records alone establish. Preserve the exact mismatch and source; do not silently infer each clerk's intent.
- `chosen_delusion` turns the old woman's warning into confirmation of a covenant with an ancient hunger.
- `same_door` calls the groundskeeper terrified, conflicting with the bible's precise, unbothered Observer staging. This is a later link, but correct it in the same source-fidelity pass.
- `two_drawings` adds a precise distance and a conclusion about civic permission/underwater destination beyond its short comparison summary. Audit against its actual inputs before retaining those claims.

**Proposed fix:** write one concise, source-faithful result per link, retaining uncertainty. Existing short summaries are generally closer to the evidence, although their independence claims also need scrutiny. A successful link should make a fact stronger, not manufacture the next clue. This is a correction to existing archive text, not a rewrite of the user's new conversations.

### 3. The objective text rushes past the best new investigation

**Resolved.** `chapter_one.gd` gained `_open_lead()`, appended to the two objective lines the review
flagged. It only ever names a lead the player has already opened (`service_work` → the steward's
staff records, `lay_lead` → the registrar, `press_suppression` → the Gazette editor), falling back
to a generic pointer at Almy's ledger/account when none of those are in evidence yet — never naming
a fact or witness Walter hasn't actually learned.

After Naomi is identified, `_objective()` directs Walter straight back to the steward. After that first visit it says there is nothing more from him tonight and directs Walter to sleep. This bypasses the ledger, wage inquiry, estate-work question and most new residents as far as the main guidance is concerned. The content remains available, but the guidance suggests that the day's useful work is over.

**Proposed fix:** show a short, evidence-dependent open lead alongside the required appointment. Prioritize Almy's ledger, the source of the official account, or the estate-work inquiry according to what the player has heard. Name no witness or fact Walter has not learned. Keep a clear route to the steward and sleep; do not turn optional witnesses into a checklist or add another gate.

A compliant player can follow records and identify Naomi. A resistant player can challenge the heading or editor and preserve a contested account. A mixed player can do either in either order. These are emphases of the same investigation, not moral categories or separate locked tracks.

### 4. The required first steward trip currently ends with a near-empty refusal

**Resolved.** `steward.dialogue` gained a `day < 3 AND evidence(service_work)` variant of the first
visit: brought Almy's estate-work lead, the steward confirms he'd heard, secondhand, that a colored
woman had asked about work at the estate — no name reached him, and he won't say who told him —
then the same brush-off as before. Gives a more precise next question (who told the steward)
without moving the pantry/maternal material earlier or granting any evidence Walter hasn't earned.

Sleep requires intake, Naomi's identification and a first steward visit. Yet the entire Day 1 steward exchange is currently: “Good evening, Officer. Nothing further tonight. I have the room to put in order.” It can occur before evening. The visit is counted and unlocks sleep, but the player receives almost no answer for the return walk. The groundskeeper becomes available afterward, which helps, but is optional and easy to miss.

**Proposed small authored beat for discussion:** Walter brings Almy's estate-work lead; the steward gives one limited, mundane response about the relevant staff record or who can account for it, then refuses further inquiry in uniform. Decide the actual fact with Dejunai before writing it. The player should leave with a more precise next question, even though the useful conversation is still deferred. Keep visit one / Day 2 montage / plain-coat visit three intact. Do not move the pantry or maternal revelations into the first visit merely to supply a reward. Make the greeting match the clock or be time-neutral.

### 5. Optional conversations can overtake the slow reveal

The historian's always-available ship-name topic immediately leads to Fenn's research, displaced gods or the missing conduit survey. The clockmaker's watch topic needs only the opening watch and supplies both an exotic physical hypothesis and a similar earlier maritime anomaly. Kessler's maternal account follows directly from identifying the knife. The old woman's explicit warning is available on Pickman Street.

These are not automatically wrong: optional diligence should pay off. Together, however, they can identify the genre and central imagery before the promised Day 3 steward conversation. Review the *order and evidentiary basis* before adding more exposition. Preserve concrete anomalies and attributable testimony; reserve explanatory language and corroborating late revelations for suitable discoveries. Use knowledge gates rather than an arbitrary thirty-minute lock. In particular, do not make the sixth man's identity a central investigative promise: bible v15 intentionally leaves him unidentified.

## Guardrails from the bible and the user's decisions

- Naomi's wage claim explains her presence in town, not why she was selected for murder. Do not turn the opening into proof that the cult killed her to suppress the debt; the bible explicitly rules out that causal connection.
- The six/eight discrepancy supports the theme of institutional indifference. It does not prove every citizen understands or coordinates the underlying crime.
- Keep the birches unattended on the second estate visit. That environmental consequence can say more than another speech about the town's values.
- Keep the montage until an enacted Day 2 earns its duration. No automatic clock rollover; retain sleep as the transition.
- Keep optional linking optional, useful, and honest. Do not alter the Perception formula to solve a prose/revelation problem.
- No art expansion is needed for this pass. Do not gate the entire town to manufacture a linear opening.

## Cold-test plan after the small pass

Use three orientations: a player following the displayed objective, one investigating broadly, and one questioning official accounts. Allow mixing. Observe without directions and record real elapsed time at first examination, report, identification and first deliberate corroboration. Record navigation stalls separately from reading and thought.

At roughly thirty minutes, ask: “What are you trying to establish?”, “What have you established yourself?”, and “What do you want to do next?” Avoid supplying names, locations or the expected theory in the questions.

Success is a specific earned fact and a specific desired next inquiry—not finishing a quota of conversations. If a player explains the cosmic cause because the board told them, the reveal failed. If they leave a required appointment feeling it was only a progress flag, that appointment still needs work. A player who declines linking must still understand what their investigation achieved.

## Proposed next implementation boundary

First implement the board and successful-link source-fidelity corrections, with focused early/late evidence checks. Then adjust objective guidance using existing leads. Present the steward's modest new exchange for wording review before inserting it. Evaluate optional revelation gates after this narrower pass, rather than simultaneously rewriting the whole town.

No code, dialogue, export, commit or publication was changed for this review.
