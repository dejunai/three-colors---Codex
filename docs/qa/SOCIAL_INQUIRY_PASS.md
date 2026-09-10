# Questions travel — historian and teacher

10 September 2026. Implemented by Codex with Dejunai's explicit authorization to revise dialogue and connect witnesses. Builds on Dejunai's authored residents and the original Claude dialogue language. This supersedes the earlier statement that all authored dialogue was untouched: this pass intentionally edits the files listed in its diff.

## Playable thread

1. Hear Almy's wage inquiry (`lay_lead`) or the teacher's public account of the town (`sanitized_textbook`).
2. Ask Abernathy why the town's history omits the crew names. He defends the official account and declines to explain the editorial decision.
3. Ask that same question of any four of six witnesses: Pence (county clerk), Halleck (editor), Crump (postmaster), Finch (stationer), Krebs (tailor), Wexley (museum committee). Each has a distinct evasion. Their existing schedules apply.
4. Return to the museum. The new question is available; Abernathy begins, “I hear you've been asking why the crew's names are missing.” He admits preparing the school abridgment and refers Walter to its covering letter at the school.
5. Hallowell produces the letter. It corroborates Abernathy's admission, and she becomes willing to discuss her personal observations about Naomi's boy and the island. Her public curriculum topic remains available beforehand. An early personal inquiry receives a specific refusal and a museum lead.
6. The historian's admission and the letter can be linked manually. Linking is not required to unlock the teacher or continue the main chapter.

The count measures completed conversations with **distinct NPCs**, using existing `topic_count(crew_omission)` and `topic_done` data. It counts neither clicks, general visits nor partial conversations. Repeating a source cannot advance it. All six sources are alternatives; four is the threshold, not a requirement to exhaust the town. The thread is optional for main progression and works in either coat. The historian changes his account to control attribution, not because a morality or intimidation meter rose. No progress counter is exposed to the player.

## Authoring another shared inquiry

Use the exact same TOPIC identifier across the participating witnesses. Give each a unique TAG and a gate preventing replay when appropriate. A consequence topic can read `topic_count(shared_topic) >= 4` and `NOT topic_done(npc, consequence_topic)`. The interpreter already records distinct sources when the topic completes; no runtime change, new flag, save version or synthetic EVIDENCE reward is necessary for a refusal. Keep the consequence NPC's own opening topic under a different identifier if it must not count toward the threshold.

Normal saves preserve this history, including a live mid-conversation save. Content-signature recovery still applies to saves made inside dialogue that was changed during this pass: the older unread sequence may return to the witness menu instead of replaying obsolete text. Previously recorded notebook wording remains historical; the pass does not rewrite the player's old records.

## Other Day 1 corrections

- Board and notebook now say the cause remains unresolved rather than equating a Perception threshold with a solved cosmic explanation. Board references to the measured passage require that discovery. Perception and all progression calculations are unchanged. A final, evidence-supported causal-completion presentation remains future chapter work; this pass removes the prototype's unsupported summary rather than claiming to implement that finale.
- Corrected the six older successful-link explanations to stay within their source records. No satchel claim, invented breakfast schedule, proven supernatural covenant or terrified Observer is supplied by a successful link. Duplicate summary/deduction prose is not printed twice.
- Objective guidance acknowledges optional investigation and the historian/teacher follow-up instead of implying nothing remains except sleep. Sleep and montage gates are unchanged.
- The first steward visit gives a limited lead: staff day book, distinct from the dining-room seating list. On the third plain-coat visit, a new topic makes good on that lead if Walter has heard Almy's estate-work account. The entry is N. Freeman, day work, kitchen wing; its evidentiary limits are explicit. Added a corroboration link to Almy's account.
- Historian's public ship-name account stays conventional. Fenn's more explicit research topic additionally requires the steward's `club_talk`; the candid crew-history topic follows the historian's admission. Clockmaker describes the joined hairspring without diagnosing local inertia or immediately announcing a matching earlier maritime event.
- Teacher's boy question no longer assumes an unestablished arrival date; the slate recollection does not turn a child's ambiguous wording into proof of the wage claim.
- During this pass, a newer user commit completed the Whitehouse rename, including his NPC ID and tags. That version is preserved; the catalog now assigns `mr_whitehouse` the same home as before. Existing evidence survives the rename, but prior `mr_vane` conversation-history tags are not migrated by this pass. The clockmaker remains Mr. Vane.

Rebased against the concurrent edits through `7f33a34` before application: preserved the clerk/postmaster corrections, renamed stationer topic, Whitehouse content and new secondhand steward testimony. Retained the objective helper while incorporating the new social follow-up. The board and link changes overlap the newer source-fidelity edits; the final version keeps the stricter limit that testimony or a numeric threshold cannot establish a summoned presence. TDD v12 receives the current implementation addendum.

No Grok code, assets or UI have been imported. Its case-file layout and the previously discussed intro remain visual references for a later pass.

## Validation

`tests/social_inquiry_flow.gd` checks all 15 possible four-of-six witness groups; threshold remains closed at three; repeated/partial conversations do not count; saved state retains the unlock; an actual live mid-refusal save resumes; historian evidence opens the letter and the letter opens the teacher; the new letter corroboration works; the staff-book payoff respects day/coat gates; and early board/notebook displays do not invent a cause. The notebook remains read-only.

The catalog check passes with 29 concrete NPCs and 131 nonempty topics, checking parsing, timing, repeat costs, registered evidence, interaction targets and all links. Opening physical traversal, live dialogue/save/branch integration, staging/montage/body timeline, dialogue language and phase-two mechanics checks passed in the isolated current-project copy. Existing board assertions were updated to require honest uncertainty rather than the removed premature reveal.

This is functional validation, not proof that a cold player will find the entire new thread or that it occupies a particular number of real minutes. The next playtest should watch whether the initial historian refusal naturally sends Walter to other witnesses and whether returning feels like a consequence of his questions.

Rebased verification repeated social, catalog, live dialogue, staging and phase-two checks successfully. This sandbox run also emitted a Windows root-certificate-store warning at shutdown; no script assertion failed. No network feature was tested.
