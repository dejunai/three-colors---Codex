**THREE COLORS OF MADNESS**

***Technical Design Document***

**Internal working document. Not for external distribution. Companion to the Design Bible.**

**Dejunai**

## **Contents**

**Part One — What This Document Is**

**Part Two — Current Build**

**Part Three — Architecture As Built**

**Part Four — Architecture Decisions Needed**

**Part Five — Open Production Questions**

**Part Six — Next Steps**

# **Part One — What This Document Is**

**This is the Technical Design Document (TDD) for Three Colors of Madness. It is the companion to the Design Bible, not a replacement for any part of it.**

**The division between the two documents is simple. The bible owns the what and the why — thesis, Design Laws, narrative, the meaning of every mechanic. This document owns the how — engine architecture, data schemas, production sequencing, and the specific open questions a playtest still needs to settle before a mechanism the bible describes gets its final shape. Where a passage in the bible states a mechanism rather than just a rule, that is deliberate: the mechanism itself is what's enforcing a Design Law, and this document does not relitigate it. Where the two documents ever appear to disagree, the bible is correct and this document is wrong until revised — never the reverse.**

**This document is expected to change often and change fast. Unlike the bible, it has no standing rule against being provisional — an architecture decision made here can be wrong, discovered to be wrong, and replaced without that being a failure of the document. Its job is to stay honest about the current state of the build, not to be permanently settled.**

**This revision grounds the document in a fourth pass over the same lineage: the same Godot branch, now carrying a further Codex pass on top of Claude Code's bug-fix content — three new content/correctness fixes, a genuine automated regression-test suite for two of them, and the branch's first playable Web export, which this revision verifies directly through a live browser session rather than by trusting the build's own self-report. Everything in Parts Two and Three below is a description of what the build actually does, verified by reading its source and commit history directly, or by playing the shipped Web build directly. Where something described in an earlier revision has since changed, been resolved, been superseded, or been corrected, that is called out explicitly rather than silently overwritten, so the document's own history of decisions and mistakes stays legible.**

**This revision also corrects a verification gap from v6, and independently checks a build-review document produced by a second coding agent (Antigravity) working from the same lineage while Codex was rate-limited. Both are called out in place below (Part Three and Part Four) rather than silently folded in, per this document's own practice of keeping its history of mistakes legible.**

**A second Antigravity delivery followed, implementing a substantial portion of that review's own Phase 1 and Phase 2 roadmap. This document verifies that delivery the same way it verifies everything else — direct source reading, not the delivery's own claims — and the results are folded into Parts Two through Four below.**

**A note on provenance, since multiple coding agents now appear in this document's history: Codex is the project's core programmer of record, and this document's ordinary practice is to track Codex's own passes. Antigravity's work, and a separate Claude Code pass described below, are secondary and experimental by default — each earns a place in this document only pass by pass, only after the kind of direct, independent source verification this document already applies to everything else, and only where that verification finds real, working, wired-in code rather than a claim. The Phase 1–2 Antigravity delivery above cleared that bar: it is committed to the same git lineage Codex has been working from (confirmed by shared commit history, not a forked or divergent branch), it is reachable from the actual shipped scene rather than sitting in a dead prototype, and its test coverage asserts specific state this document read directly rather than took on faith. Being folded into this document is a statement that the work is real, not a statement that it is Codex's; where the two ever need distinguishing, Part Three names which agent produced which piece. When Codex resumes, its next pass should treat this delivery as its current baseline rather than reverting to an earlier checkpoint that doesn't know this work exists — the shared lineage makes that a continuation, not a merge.**

**A third agent, Claude Code, then independently built a real corkboard/causal-spine mechanic — the single most consequential open item this document has carried since v5 — plus a resolution of the procedural-geometry pipeline question and a first Chapter Two asset generator, as genuine committed history on the same shared lineage. Antigravity then integrated that work into its own delivery and added a further piece on top of it (the corkboard's staged Causal Spine display). Both passes are verified directly against source below, with which agent built which piece kept distinct, per this document's own provenance practice.**

# **Part Two — Current Build**

## **Engine and Target**

**Godot 4.7 (the Web export identifies as 4.7.2.stable), using the GL Compatibility renderer (not Forward+), targeting broad hardware reach over cutting-edge rendering fidelity — confirmed directly in the Web build's own console output, which reports WebGL 2.0 via the Compatibility backend. Window target 1440×900, canvas-items stretch mode. No import dependencies beyond the engine itself. Unchanged since v1.**

## **Scope of the Current Slice**

**The build still covers the opening movement of Chapter One ("No Exit Wound") — the Ophion estate grounds, Pickman Street, the precinct, the boardinghouse, Walter's room — and the service-passage encounter beneath the estate's kitchen wing described in this document's v2. This pass fixes three concrete correctness issues in content added by the prior pass, rather than adding new scenes.**

* ***Odell's answer can no longer be silently re-litigated.*** **`_odell_response()` now checks whether either of Odell's two recorded statements already exists before presenting the choice again; if one does, it shows an "Already answered" panel instead of the original two-button choice, so a player revisiting the captain after answering can't produce a second, contradictory statement. The prior build allowed the choice to be asked again indefinitely.**  
* ***The woman outside Kessler's shop now actually leaves.*** **Her scene already stated, narratively, that she disappears after her warning; the code did not previously enforce that. A new `estate.gd`/`town.gd` method, `dismiss_old_woman()`, removes her interaction point and her figure once her scene is discovered, and is now called from every path that could otherwise re-show her — first discovery, save/load, and travel back into town. This is verified by new assertions in `tests/town_flow.gd` (see Verification, below) rather than left to observation.**  
* ***The barman's "club talk" scene is retimed to match its own staging.*** **The scene was written as an evening bar conversation but is reached, in the current build, during a daytime portico encounter; the dialogue and its framing text ("BENEATH THE PORTICO" rather than "AT THE FAR END OF THE BAR") now describe the encounter that actually happens, and the question Walter asks shifted from present tense ("what the members talk about") to past tense ("what the members used to talk about") to match.**

**The build's own `docs/ARCHITECTURE.md` documents these three fixes plus two clarifications that were not code changes at all, just corrections to how the mechanism should be understood: the grounds crew (groundskeeper) observation added in the prior pass has no Perception gate and is available to any player regardless of accumulated evidence; and Perception, throughout the current build, gates *route information* (specifically, the wear-marks paragraph behind the tunnel's service screens) rather than *physical access* — nothing in the current build blocks movement or a location outright behind a Perception check. Both are confirmed directly against source in this pass: `target("crew", ...)` in `estate.gd` is registered unconditionally alongside every other observation point, with no surrounding `if state.perception() >= N` guard, and the only `perception() >= 4` check in `scripts/chapters/chapter_one.gd` gates one paragraph of descriptive text, not a door, a route, or an interaction.**

**Not yet implemented, unchanged from v2: the glass-shattering ontological break, the fatal-comprehension ending, Chapters Two and Three as playable slices, gamepad support, full key rebinding, a full encumbrance/leveling system, and Ekon's later consumption of Walter's record. The Part Seven difficulty screen and achievement registration are deferred. None of this pass's work touches the chapter's actual climax.**

**Two items left the "not yet implemented" list two revisions ago: the forced-spill flask mechanic and the tunnel combat/stagger system, both wired into the live `chapter_one.gd`/`tunnel.gd` flow. Two more leave it this revision: the corkboard/causal-spine mechanic and the procedural-geometry pipeline decision, both real, both verified directly against source — see the new Part Three subsection below.**

**(A note on the earlier "not yet implemented" entry for the forced-spill mechanic: v7 found a working prototype of it sitting unwired in `scripts/chapter_one_demo.gd`, an orphaned scene the shipped game never loads, and flagged it as possible prior art. The implementation that actually shipped is a separate, fresh one built directly against `chapter_one.gd`; the orphaned demo prototype is untouched and still unwired. Worth a cleanup pass at some point, but it's dead code, not a duplicate system.)**

## **Controls and Accessibility**

**Unchanged from v2.**

## **Saves**

**Case-state schema is now VERSION 4, up from 3, with migration for versions 1–3 (see Part Three). The old woman's departure remains saved state via the actor-lifecycle system's own persistence, unchanged in mechanism from the last revision.**

## **Verification**

**This pass ships with genuine automated regression coverage for both of its behavioral fixes, not just its content. `tests/opening_flow.gd` now saves and reloads mid-test specifically to assert Odell's locked answer survives a save/load round trip, and separately asserts that none of the dialogue buttons shown afterward begin with the original "Say nothing" option — the test fails if the lock can be bypassed by reopening the conversation. `tests/town_flow.gd` asserts the old woman's interaction point is gone immediately after her scene, gone again after an explicit save/load cycle, gone again after traveling away from and back into town, and that attempting to re-trigger her observation directly does not open a dialogue page. `tests/phase_two_mechanics.gd` now also asserts the corkboard's causal-spine staging directly — see Part Three.**

# **Part Three — Architecture As Built**

**This section describes what the current codebase actually does, as read directly from the project and its commit history, plus what a live session against the shipped Web export actually showed. Where something differs from an earlier revision's Architecture As Built, that's noted explicitly; everything else in Part Three (autoloads, entry point/shared-module split, case-state shape, environment, the Observer color-preservation shader, dialogue architecture) is unchanged from v5 and not repeated here.**

## **Web Export and Live Browser Verification**

**This is the branch's first commit to include an actual Web/WebAssembly export (`build/web/`), and this revision is the first to verify a build of this project by playing it directly, in a live browser session, rather than by reading source alone. The verification found the title, accessibility-and-controls, chapter framing, and opening intertitle sequence all loading and reading exactly as source predicts; movement, camera control, examine, and the case file all functioning correctly once reached in gameplay, confirmed against the rose garden crime scene's exact examine text; and, per the correction below, a working input-latch fix for movement reliability.**

## **Correction to v6: the movement-latch fix does exist**

**v6 searched this pass's commit history for an input-latch fix and found nothing, concluding wrongly that none existed. `main.gd` — the script the live `main.tscn` scene actually runs — carries exactly that fix: a `MOVE_LATCH_MIN = 0.15` constant and a `move_latch_timer` dictionary. The fix isn't committed; the delivered zip's working tree carried a substantial set of uncommitted changes against its own `HEAD`, which git log alone can't see. Future verification of a zipped delivery should diff the working tree against `HEAD` in addition to reading commit history.**

## **Forced-Spill, Tunnel Combat, and Generalized Systems (Antigravity Phase 1–2)**

**A second delivery from Antigravity implemented most of its own review's Phase 1 and Phase 2 roadmap, checked directly against source:**

* ***`_town_observation()` is now genuinely generalized.*** **Its second parameter is `return_target: Variant`, accepting a `Callable`, a `bool` (backward-compatible shorthand for reopening `_witness_menu()`), or nothing. Father Behan's menu now passes `_behan_menu` itself as the return target. Resolves the item this document has carried since v5.**  
* ***A real, declarative NPC lifecycle system now exists*** **in the base `estate.gd` class: `register_actor(id, node, target_id, condition)` stores a per-actor `Callable`; `sync_actors(state)` evaluates every registered actor's condition and calls `dismiss_actor()` for any that resolve false. The old woman is migrated onto it. `town.gd`'s own `dismiss_old_woman()` still redundantly hides/frees `departing_woman` on top of the generic system's own call — harmless, vestigial, worth trimming.**  
* ***The forced-spill flask mechanic is implemented and wired into the real flow.*** **`_tunnel_descent()` in `chapter_one.gd` checks `state.flask_spilled`; on first entry it sets `flask_spill_amount`, zeroes the flask, and plays a diegetic card with matching narration. The inspectable case-file flask entry states the exact amount lost, satisfying Design Law 4\.**  
* ***Tunnel combat exists and matches the bible's asymmetry rule closely.*** **`_cultist_encounter()` and `_drowned_encounter()` in `chapter_one.gd`, backed by `cultist_stagger`/`drowned_stagger` timers in `tunnel.gd`. The cultist: six-round revolver plus knife, stagger-only, "No force can destroy it permanently" stated outright, the bible's "thin, wet cough" cue played on encounter. The drowned sailor: the same tools, a finishing blow once staggered that sets `drowned_dead = true` permanently, text explicitly contrasting the two populations, the bible's "low, impersonal groan" cue.**  
* ***A genuine death-and-reload fail state exists*****, tied to the stealth/exposure cycle: `tick_world()` calls `estate.advance()`, which triggers `_show_tunnel_death()` — a real "Walter died in the passage" panel with checkpoint restore. No separate fail state for "out of ammo, no stagger banked, no way out" was found; still open, see Part Four.**  
* **`tests/phase_two_mechanics.gd` asserts real, specific state — exact spilled amount, inspectable flask text, ammo decrementing correctly, stagger timers. The delivery's own QA log reporting all suites passing is self-reported, not independently executed (no Godot binary in this session's environment); the source-level checks above were read directly.**

## **The Observer QA Capture: Root Cause Found and Output Confirmed**

**The capture rig has existed since v5 and never produced output because it was being run under headless Godot, which does not execute this project's rendering path. Running non-headless produces real output — worth stating explicitly in the build's own test documentation so a future pass doesn't rediscover it from scratch. A capture produced this way was reviewed directly, image in hand: an Observer figure and its entire surroundings render in flat grayscale except a small, distinctly reddish-brown accent on the figure's chest, matching the bible's "grayscale except jewelry and reflections" rule exactly. The shader color-preservation item is closed; see Part Four.**

## **The Corkboard / Causal-Spine Mechanic (Claude Code, integrated by Antigravity) — new**

**The single most consequential open item this document has carried since v5 is resolved, in two verified stages by two different agents.**

***Claude Code's base mechanism*****, checked directly against a delivered zip carrying it as genuine committed history (not working-tree-only changes, unlike the Antigravity deliveries above — a real difference worth noting): `case_state.gd` gains a `links: Array[String]`, `record_link()`, `has_link()`, and bumps to schema `VERSION = 4` with migration from 1–3. `perception()` reshapes to `2 + mini(3, evidence.size() / 3) + mini(3, links.size())`. Which pairs mean anything lives in `chapter_one_archive.gd`'s new `LINKS` table — six specific, chapter-authored pairs (e.g. `lodging|naomi` → "TWO RECORDS, ONE WOMAN," `crew|pantry_lead` → "THE GROUNDSKEEPER AND THE BARMAN") — surfaced through a genuine two-step `_link_picker()`: choose one recorded observation, then a second to test against it. A wrong pair costs nothing ("The line does not hold. The facts remain separate."); a right one records a specific card and persists under "CONNECTIONS DRAWN" on the board. Critically, the formula still lets evidence alone reach the existing Perception-4 gate without any linking (`evidence >= 9` alone reaches 5\) — the board accelerates a diligent player to a higher ceiling (up to 8\) but is never a required gate, exactly as the bible's "window onto the mechanic, never the mechanic's gate" line demands.**

***Antigravity's integration*** **added a further piece on top, confirmed present in Claude Code's own delivery *not* to have existed there (checked directly — Claude Code's `_board()` had no staged spine text at all): a three-state diegetic display keyed to `perception()` — "THE CAUSAL SPINE — UNRESOLVED" below 4, "— FORMING" at 4, "— COMPLETE" at 5 and above, each with its own specific in-fiction paragraph ("Walter did not choose the moment the board went whole; the shape closed itself"). `tests/phase_two_mechanics.gd` asserts this directly: 8 evidence with 0 links reads Perception 4 and displays "FORMING"; drawing one valid link from that state pushes Perception to 5 and flips the display to "COMPLETE" — read from the actual conditional (`if p >= 5: ... elif p >= 4: ...`) and the actual test assertions, not from either delivery's own report.**

## **The Procedural-Geometry Pipeline Decision and a Chapter Two Trinket Generator (Claude Code, integrated by Antigravity) — new**

**Also resolved, also checked directly against source: the "blockout convenience or intentional pipeline" question open since v2 is settled as intentional, on two converging grounds — the project's own no-download/no-external-dependency constraints are incompatible with an imported-asset pipeline, and the bible itself names Chapter Two's central mechanic "Procedural Trinket Generation," which only makes sense if \~200 artifacts get bespoke *data* authorship rather than bespoke *mesh* authorship. `scripts/shared/trinket_generator.gd` and `tests/trinket_generator.gd` exist in the delivered source, confirmed present: a seeded, deterministic generator composing small objects from the same primitive vocabulary the rest of the game already uses, with two tiers (common/artifact) distinguished only by an emission-glow flag — never color, since the Observer's red-dominance channel is reserved. The test file asserts determinism per seed, variation across seeds, the tier distinction, and specifically that generated geometry never trips the Observer hue across a stated 120-trinket sample. This is a first instance, not a finished system — Chapter Two doesn't exist as a playable scene yet.**

# **Part Four — Architecture Decisions Needed**

**Items resolved since v5 are marked as such rather than deleted, so the decision history stays visible. Items unchanged from v5 are restated briefly for continuity; see v5's fuller reasoning if needed.**

**Odell's answer could be silently re-litigated — resolved.**

**The old woman outside Kessler's shop did not actually leave — resolved.**

**The barman's club-talk scene was staged for the wrong time of day — resolved.**

**Shader color-preservation scope — resolved, image-confirmed. See Part Three. The underlying mechanism (a screen-wide red-dominance test over a controlled palette, no object-specific mask) is unchanged; true object-specific isolation remains a separate rendering decision only if later assets or lighting make palette-based selection unreliable, not something this capture found a need for.**

**`_town_observation()`'s hardcoded return-to-witness argument — resolved.**

**NPCs have no general scheduling or staging trigger system — resolved. `town.gd`'s `dismiss_old_woman()` retains a redundant explicit hide/free call on top of the generic system's own; worth trimming, not worth blocking on.**

**Perception gates route information, not physical access — clarified, not new.**

**The corkboard/causal-spine model — resolved. See Part Three. Built by Claude Code as a genuine committed delivery, then extended by Antigravity's own integration work; both pieces verified directly against source and test assertions, not against either agent's report. This closes the single most consequential open item this document has carried since v5.**

**Procedural geometry: blockout strategy or production pipeline? — resolved. See Part Three. Settled as intentional, on both production and content grounds, with a first working generator now in source.**

**Two coexisting case-tracking systems — resolved, same fix as the corkboard item. Claude Code's own commit message for the corkboard work identifies this as the same underlying problem this document tracked separately since v2: the legacy `GameState.try_link()` system (referencing an older, smaller evidence catalog) versus `case_state.gd`'s flat formula. The legacy system was not migrated as code — its data no longer matches the current evidence catalog — and `case_state.gd` is now the sole system, with the real link mechanic built directly against it. Worth folding these two Part Four items into one going forward, since they were never actually two problems.**

**Combat and the forced-spill mechanic — resolved.**

**No dedicated fail state for "exhausted resources, no way out" in tunnel combat — still open. Untouched by this pass. The only tunnel death path found is exposure during the stealth cycle.**

## **Verifying Build Reviews and Deliveries from Secondary Agents**

**While Codex was rate-limited, a build-review and roadmap document from Antigravity, and two subsequent Antigravity deliveries, were checked directly against source rather than accepted on report — see the prior revision's fuller account of what held up and what didn't (the review's claims about the corkboard formula, `_town_observation()`, the NPC lifecycle gap, and the missing combat/finishing-blow systems were all accurate at the time; its claim that the forced-spill mechanic needed new implementation overstated things, since an unwired prototype already existed; its citation of "Design Bible v14" against a bundled "v13.pdf" was never resolved either way and remains immaterial to every technical claim checked).**

**A third agent, Claude Code, then independently delivered the corkboard/causal-spine mechanic and the procedural-geometry resolution as genuine committed git history — a meaningfully different delivery shape from Antigravity's own working-tree-only changes, and one this document notes explicitly because it means Claude Code's work survives a plain `git log`, where Antigravity's requires the working-tree diff this document only started checking after the v6 correction. Antigravity then integrated Claude Code's work and added its own staged Causal Spine display on top, itself verified directly (Part Three) rather than credited on report.**

# **Part Five — Open Production Questions**

**Unchanged from v5 in substance; nothing in this pass bears directly on Chapter Two's or Chapter Three's open questions, though a first Chapter Two asset generator now exists (see Part Three).**

# **Part Six — Next Steps**

**In rough priority order: build the ontological break — glass-shatter cue, aspect-ratio widening, color bleed, and the entity's Constance-shaped manifestation — and the fatal-comprehension ending. With the corkboard, forced-spill, and tunnel combat now all resolved, this is the single largest remaining piece of Chapter One, and the one most worth holding for Codex given the stakes of getting the chapter's emotional payoff wrong. Settle whether tunnel combat needs its own exhausted-resources death state or whether the exposure-death mechanic already covers it (see Part Four) — bounded enough for a secondary pass. Trim `town.gd`'s redundant explicit hide/free call in `dismiss_old_woman()`. Build the Part Seven difficulty screen and achievement registration — self-contained, well-specified, low-risk for a secondary pass. Decide whether the palette-discipline convention for color isolation needs to become an actual object/material mask before more Observer content is added — the capture found no evidence this is currently necessary. Consolidate the two Part Four items that turned out to be one problem (see above) in the next revision's own bookkeeping. Wire the trinket generator into an actual Chapter Two scene once one exists, and give that slice its own Architecture As Built entry, held to the shared/chapter-specific template v2 established. Continue diffing a zipped delivery's working tree against `HEAD` in addition to reading commit history, and continue noting which agent delivers work as committed history versus working-tree-only changes — that distinction has mattered at least twice now.**

