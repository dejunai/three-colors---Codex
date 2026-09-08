# Chapter One restaging — implementation and QA

September 8, 2026. Implemented in the native Godot project. Design Bible v15 wins over the TDD; the TDD itself has not been edited. Existing unrelated working-tree changes were preserved. This pass does not rebuild the Web export.

## Play the sequence

1. Complete the opening investigation and prepare the report. On departure, all eight body models and their direct-examination targets are removed, including on a same-day return. The knife is removed with the cleared scene; previously collected evidence remains in the notebook.
2. Speak to Mrs. Almy. The kitchen-wing service entrance at the estate becomes accessible. It leads to a separate smoking-lounge interior; there is no steward in the garden.
3. Speak to the steward on day one. He politely declines further conversation. This completed conversation is visit one, regardless of repeat entries or clothing.
4. Leave through the service entrance. The groundskeeper is now present nearby, without a Perception gate. On later estate visits the gardener is on the outer path west of the drive, outside the garden. His additional plain-coat testimony is optional.
5. Return to Walter's room and use the bed. The existing desk action also works as a compatibility entry to the same progression. Before the first steward conversation, sleep is blocked with “There’s still work to do.” The preexisting report-intake and Naomi-identification requirements also remain.
6. Day-two stills cover witness interviews, a provisional morgue visit, and the second smoking-lounge visit. The last intertitle reads “Come back tomorrow, and don't bring your badge.” The montage adds no unearned evidence or testimony.
7. Day three begins in Walter's room. Return in the plain wool coat: visit three unlocks the steward's existing, revisitable topics. Returning in uniform receives the badge reminder. Repeated day-one conversations cannot replace the montage.
8. The existing notebook-at-desk completion and service-passage continuation remain available after the third encounter. Previously visited areas remain accessible.

## Notebook and persistence

- Personal effects and the case file now offer “Read the notebook.” It renders a detached snapshot of evidence, source labels, confirmed links, statements, and the same UNRESOLVED / FORMING / COMPLETE thresholds as the board. Its only button closes it. The renderer receives neither CaseState nor a discovery, link, or save callback.
- The corkboard retains its linking interaction. No unreliable notebook text was introduced.
- Case-state version 5 stores `day`, `steward_visits`, `lounge_exited`, and `montage_index`. Loading during a montage resumes its current intertitle. Completion advances the day and second-visit milestone together.
- Versions 1–4 remain loadable. Earlier completed inquiries, tunnel saves, and saves already carrying steward testimony retain earned progress; earlier first conversations count as one visit. Migration grants no evidence. A lounge save without Mrs. Almy's visit is placed safely outside the entrance.
- Internal `barman` scene/evidence identifiers remain compatible. Player-facing references in the active steward content now say steward and smoking lounge.

## Verification

Godot 4.7.2 GL Compatibility import/parser check completed. All of these suites passed with explicit PASS output and no script errors:

- Opening: minimal progression, eight opening observations, locked Odell answer, snapshots, save/load, actual walking and hedge collision.
- Town: both report routes and copies, three-visit completion, witness menus, old-woman departure across save/load/travel, links, immutable supplements.
- Interaction loop: both tunnel routes, empty flask, consequences, death/load/retry, exact restore, accessibility relief.
- Phase two: forced spill, inspectable amount lost, combat/ammo/stagger, drowned finishing blow, board thresholds.
- New staging suite: locked entrance, all eight bodies removed across same-day return/load, optional relocated gardener, first-visit sleep restriction, real walking to the service entrance/interior steward/exit/groundskeeper, no repeat-visit farming, saved lounge state, montage resume, each steward gate independently, both direct interaction and observation-call bypass attempts, read-only notebook at all three thresholds, confirmed-link rendering, migration, later revisits and tunnel entry.

The staging and town suites were rerun after the final lounge geometry and gate changes. Native GL-renderer captures of the lounge, final montage intertitle, and notebook were visually inspected. These are renderer captures plus automated gameplay checks, not a manual human playtest. Automated QA used separate runtime data in the task workspace, not the player's normal save.

Run `Test staging.cmd`, or the engine with `--headless --path . --fixed-fps 60 -- --qa-staging`. Existing opening, town, interaction-loop and phase-two launch arguments remain usable.

## Pacing results and limitation

These are measured scripted normal-speed walking times plus a transparent reading model: 180–240 words per minute and one second per dialogue/intertitle card. They exclude player hesitation, searching, extra notebook reading, and engine loading time. They must not be presented as stopwatch-measured human playtimes. The probes use actual movement/collision and existing dialogue, with no content removed.

| Route | Movement | Text | Estimated total |
| --- | ---: | ---: | ---: |
| Minimal opener: framing, boy, Odell, report, departure | 84.8 s | 345 words / 15 cards | 3.10–3.58 min |
| Opener with all eight existing opening observations | 141.1 s | 864 words / 38 cards | 6.59–7.79 min |
| Minimal opener + town + visits + all three steward topics + tunnel entry | 427.2 s | 1,389 words / 57 cards | 13.86–15.79 min |
| All opening observations + town + visits + all three steward topics + tunnel entry | 483.6 s | 1,895 words / 80 cards | 17.29–19.92 min |

The gardener's second encounter, optional town topics, supplements and board use are excluded from these timings. Both longer routes include all steward topics; they are not absolute minimum full-route times. `tests/pacing_probe.gd` and `tests/pacing_minimal.gd` reproduce the two route models when run using `--script` and `--fixed-fps 60` (with a separate APPDATA folder).

The minimal opener meets the 3–5 minute target. The comprehensive opener still exceeds it: 38 existing cards and movement between the garden, birches, terrace and gates account for the difference. Repeated room/estate trips add substantial time later, including the retained return home before the existing tunnel-continuation screen. No dialogue or investigation content was cut to force a target time.

## Explicit placeholders and future work

- The sleep restriction and compressed second day are placeholders. Replace them as worthwhile enacted investigations, including the morgue interview, become available.
- Steward rebuffs are presently fixed lines. They are intended to become consequences of earlier conversations.
- Existing individual report and Odell choices remain. No permanent canonical/resistance alignment or morality score was added. Broader mixed dialogue routes and downstream response consequences remain future work.
- Mrs. Almy has an existing coat variation; the current scripts do not implement the source story's town-clerk/Kessler-widow coat encounters.
- The break, fatal ending, unreliable notebook text, new wardrobe system, and Web export remain outside this pass.


## Return-visit follow-up (September 8)

Odell and the coroner's assistant now leave with the cleared dawn scene; their models and interaction targets remain absent after save/load. The gardener was previously placed too far west to find readily. His later location is now beside the approach drive, below the garden hedge (`-4, 0, 12`), still outside the rose garden. His plain-coat testimony remains optional. The boy has a shortened repeat response during the dawn visit and a separate return response noting the departures and pointing out the gardener. These use the existing completed-opening flag, so existing saves pick up the changes without a migration.

The staging regression now checks staff presence before departure and absence after return/load, blocks remote interaction with departed staff, checks all three boy-dialogue states, and walks from the gate to the returning gardener before taking the plain-coat testimony.


## Linking feedback follow-up

Click a board observation, read it, press Link, then select a second observation from a notebook-style comparison list. The first observation is excluded. A persistent result panel now confirms a valid connection with its authored explanation and actual Perception change, rejects an invalid pair without a cost, or identifies a previously recorded connection without a duplicate award. The portable notebook remains read-only. The existing Perception rule is unchanged: the first three distinct confirmed connections contribute one point each, capped at three. The board's literal `%d` display was corrected to show its actual Perception value.

The town test follows these real buttons and checks positive/negative feedback, self-exclusion, duplicate immunity, cancellation, rejection of uncollected evidence, and save/load persistence.
