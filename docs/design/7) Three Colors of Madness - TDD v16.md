**THREE COLORS OF MADNESS**

*Technical Design Document*

Internal working document. Not for external distribution. Companion to the Design Bible.

Dejunai (author/producer) · Claude Sonnet (original designer and builder of the dialogue grammar and interpreter, in VS Code with the author; sole author and maintainer of this document) · Codex (core programmer — live integration of the dialogue system into play, subsequent fixes and extensions to the interpreter and its documentation, and direct review of this document against source)

## **Contents**

Part One — What This Document Is

Part Two — Current Build

Part Three — Architecture As Built

Part Four — Architecture Decisions Needed

Part Five — Open Production Questions

Part Six — Next Steps

# **Part One — What This Document Is**

This is the Technical Design Document (TDD) for Three Colors of Madness. It is the companion to the Design Bible, not a replacement for any part of it.

The division between the two documents is simple. The bible owns the what and the why — thesis, Design Laws, narrative, the meaning of every mechanic. This document owns the how — engine architecture, data schemas, production sequencing, and the specific open questions a playtest still needs to settle before a mechanism the bible describes gets its final shape. Where a passage in the bible states a mechanism rather than just a rule, that is deliberate: the mechanism itself is what's enforcing a Design Law, and this document does not relitigate it. Where the two documents ever appear to disagree, the bible is correct and this document is wrong until revised — never the reverse.

This document is expected to change often and change fast. Its job is to stay honest about the current state of the build, not to be permanently settled — including this document's own mistakes, corrected in place rather than smoothed over.

**This revision (v16) is a further tightening pass following Codex's third review, this time of v15, directly against source.** Three targeted corrections, each verified independently below rather than accepted on report — Codex's own framing, confirmed: these are not grounds for another broad rewrite.

* v15's steward paragraph mistook the conditions that block *sleep* for the conditions that gate the *first steward conversation*. They're different checks on different functions. Corrected in Part Three, with the third encounter's actual coat/day requirement restored.  
* v15 proposed a "dedicated tracing pass" to connect the newspaper-correction thread to Almy's response. Unnecessary — Codex traced it directly and it's confirmed implemented. Documented in Part Three; the follow-up item removed from Parts Four and Six.  
* v15 said the day/night clock drives scheduled-resident placement "only." Too restrictive — it also drives the sun, lighting, fog, and street lamps. The word is removed; the underlying distinction from story-driven body removal stands.

**Prior tightening pass (v15), following Codex's second review of v14:**

* v14 incorrectly chained three separate dialogue threads into one dependency chain. Confirmed and split apart in Part Three.  
* v14's "every NPC disappears at night" was too broad. Confirmed wrong by direct reading of `chapter_one_dialogue.gd`'s `allowed()` function: the day/night placement rule in `dialogue_catalog.gd`'s `slot()` applies only to catalog-scanned additional residents (`extra_actors`). The chapter's story actors (Odell, the coroner's assistant, the groundskeeper, the old woman, the steward) have their own bespoke, state-based availability rules with no time-of-day gating at all. Corrected in Part Three.  
* v14 conflated the day/night clock with body removal. It doesn't govern it. Corrected in Part Two.  
* The `background_npc_template` extension item is closed — Codex confirmed the file is back to `.dialogue`; this document's own read of the delivered zip already showed the same thing. No further action.  
* v14 under-documented real implemented mechanics that matter for future work more than this document's own revision history does. Added below: the `filed()` gate (distinct from `evidence()`), the newspaper-correction thread's actual prerequisites, and the steward's three-visit/Day-2-montage progression.  
* Provenance needed adjusting to credit Codex's actual subsequent work on the interpreter and its documentation, not just integration and review, while keeping the original design credited correctly. Fixed in the byline above.

**One constraint made explicit this revision, per the author: validating and testing the newest development revision does not authorize replacing the frozen, already-tested Web build.** That build stays the release artifact until the author says otherwise; development-revision testing is diagnostic, not a release decision.

# **Part Two — Current Build**

## **Engine and Target**

Godot 4.7 (the Web export identifies as 4.7.2.stable), using the GL Compatibility renderer (not Forward+), targeting broad hardware reach over cutting-edge rendering fidelity. Window target 1440×900, canvas-items stretch mode. No import dependencies beyond the engine itself. Unchanged since v1.

## **Scope of the Current Slice**

The Ophion estate grounds (rose garden, service passage, tunnel entry), Pickman Street (boardinghouse, cobbler's shop/Walter's room, precinct, morgue), three neighborhood hubs (business district, upper-residential ridge, lower-residential quarter) reached as pocket spaces off Pickman Street, and a post office — hub-and-spoke, not continuous geography, by current design (the author's stated eventual preference is a contiguous town, subject to feasibility — see Part Five). The day/night clock drives scheduled-resident placement, and separately drives the sun, directional lighting, fog color, and street-lamp visibility, purely as presentation. **Corrected this pass:** the clock does not govern body removal. Story progression does — the rose-garden bodies clear after the player's first departure to town; the birch victims (the woman and boy) remain visible and unattended through at least a second estate visit and clear only once Day 3 has begun, with no accompanying scene or notification either time.

The live dialogue system spans 30 authored files and at least 148 authored `TOPIC:` blocks (135 nonempty per Codex's count, using the runtime's own definition; this document's own recount script was too permissive to independently reproduce that exact figure and defers to it). Real cross-NPC and paperwork-gated content exists beyond simple witness menus — see Part Three.

Not yet implemented, unchanged from prior revisions: the glass-shattering ontological break, the fatal-comprehension ending, Chapters Two and Three as playable slices, gamepad support, full key rebinding, a full encumbrance/leveling system, and Ekon's later consumption of Walter's record.

## **Saves**

Unchanged from prior revisions (schema 9). Not independently re-verified this pass.

## **Verification**

Direct source reading this pass added `chapter_one_dialogue.gd` (the live dialogue adapter, its `allowed()` function specifically) and `chapter_one_staging.gd` (the steward's three-visit progression) to the files already checked in v13/v14. No Godot binary is available in this environment, so nothing here substitutes for an actual playthrough. Separately, per the author and Codex: the author has played the build repeatedly and external testers have already surfaced real issues (an exit problem, a ledger problem, a linking problem) against the frozen Web build specifically. What remains unverified is a cold playthrough of the newest development revision — and per the constraint stated in Part One, confirming that revision plays correctly is a diagnostic step, not grounds to replace the frozen build.

# **Part Three — Architecture As Built**

## **Story Actors vs. Catalog Residents — corrected this pass**

v14's claim that every NPC disappears at night was too broad. Direct reading of `chapter_one_dialogue.gd`'s `allowed(g, actor)` function shows two genuinely different systems:

* **Catalog-scanned additional residents** (`extra_actors`, populated by `catalog.scan()` in `setup()`) are placed exclusively through `dialogue_catalog.gd`'s `slot()`, which does return an empty placement at night regardless of authored schedule — this part of v14's claim was correct, but only for this population.  
* **Story actors** — Odell, the coroner's assistant (`assistant`), the groundskeeper (`crew`), the old woman, and the steward (`barman`) — have their own bespoke availability rules in the same `allowed()` function, none of which reference the day/night clock at all: Odell and the assistant are available whenever `world == "estate"` and the estate isn't complete; the groundskeeper once the lounge has been exited; the old woman while in town and not yet recorded as evidence; the steward keyed to the lounge and whether Mrs. Almy has been spoken to. These are chapter-authored, state-driven staging rules, entirely separate from `dialogue_catalog.gd`'s time-of-day system, and none of them hide their actor at night.

## **Three Separate Investigative Threads — corrected this pass**

v14 incorrectly joined three independent dialogue threads into a single arrow-chain, implying dependencies between them that don't exist in source. They are three separate threads, each with its own prerequisites:

1. **The historian/schoolteacher witness-count thread.** `local_historian.dialogue`'s `crew_omission_followup` topic gates on `topic_done(local_historian, crew_omission_official) AND topic_count(crew_omission) >= 4 AND NOT topic_done(...)` — a real "ask enough people, consistently tagged, before the historian goes further" mechanic, confirmed in source. `schoolteacher.dialogue` carries a related chain keyed off `evidence(naomi)` and `evidence(reader_omission_letter)`. This thread's own internal chain (historian → four witnesses → historian → schoolteacher) is real; it does not connect to either thread below.  
2. **The steward appointment thread**, with its own separate prerequisites, corrected this pass after a genuine confusion between two different functions. `chapter_one_staging.gd`'s `sleep()` blocks *sleeping* — not the first conversation — when `steward_visits == 0`, `intake_done` is false, or `evidence.has("naomi")` is false; while blocked, the player just gets an "Get up" panel. Reaching the steward at all is gated separately, through `chapter_one_dialogue.gd`'s `allowed()`: the lounge itself only becomes reachable via the `service_entrance` travel action once `visited.has("almy")` is true, and the steward's dialogue is only `allowed` while `world == "lounge"`. So the real first-visit gate is "spoken to Almy, then travel to the lounge," not the sleep-block conditions. Visit two occurs inside a Day 2 montage (`draw_montage()`, a deliberately temporary "pacing bridge... replace the montage with enacted investigation later" per the source's own comment); completing it sets `day = 3` and `steward_visits = 2`. The substantive third encounter is gated by `case_state.gd`'s `steward_ready()`, which requires all four of `visited.has("almy")`, `day == 3`, `steward_visits >= 2`, and `coat == "Plain wool coat"` — the plain coat specifically, not just the day, is a real and separate requirement for the steward to open up. This thread does not depend on the historian/schoolteacher thread or the newspaper thread.  
3. **The newspaper-correction thread**, gated on a distinct mechanism: `filed()`, not `evidence()`. `gazette_editor.dialogue`'s `print_correction` topic requires `evidence(gazette_correction_terms) AND filed(eight) AND filed(naomi) AND filed(lodging)` and awards `EVIDENCE: gazette_correction_printed` on completion. `filed()` checks received report pages specifically, not the current evidence inventory, per `background_npc_template.dialogue`'s own comment — meaning this thread depends on paperwork actually having been filed and received, separate from simply having collected the underlying evidence. **Confirmed this pass, tracing the connection Codex identified:** `mrs_almy.dialogue`'s `show_printed_correction` topic gates directly on `evidence(gazette_correction_printed)`; once available, showing her the slip has her read Naomi's name aloud and acknowledge Walter's effort ("You brought back something I can read. Thank you."), recorded via `NOTEBOOK: correction_seen`. The connection between the correction thread and Almy's response is implemented and confirmed, not merely gated in principle.

## **`$84,000` Formatting Item — unconfirmed**

Unchanged from v14: not reproducible in source text, not diagnosed, belongs on a live-verification checklist.

## **CHOICE:/FORK: Hardcoded Player Speaker — open architecture question, unchanged from v14**

See v14's treatment, carried forward unchanged: the hardcoding is deliberate and Chapter One-scoped per the project's own architecture notes; whether Chapter Two's audio-driven dialogue extends this interpreter or replaces it is genuinely open, and this document does not claim the current system is unsuited to voiced dialogue in principle.

## **Background NPC Template Extension — resolved, closed**

Codex confirms `background_npc_template` is back to the correct `.dialogue` extension; this document's own read of the delivered zip already showed no `.dialogue.txt` anywhere in the corpus. No further action needed.

## **Dialogue Authoring System — provenance**

The dialogue grammar and interpreter (`dialogue_lang.gd`, `dialogue_runtime.gd`, `dialogue_state.gd`) were designed and built by the project's author working with a Claude Sonnet instance in VS Code. Codex's role extends beyond integration: live-wiring the interpreter into actual play, subsequent fixes and extensions to the interpreter itself (including the schedule-alias handling in `dialogue_catalog.gd`'s `slot()`), and authoring `docs/DIALOGUE_AUTHORING.md` (September 10\) as a writer-facing reference, confirmed substantively accurate against the interpreter's actual behavior. Codex now also reviews this document directly against source, which produced the corrections in this and the prior revision.

# **Part Four — Architecture Decisions Needed**

**CHOICE:/FORK: hardcoded speaker — open architecture question for Chapter Two, unchanged from v14.**

**Story-actor vs. catalog-resident staging — clarified, not a defect.** See Part Three. Two legitimately separate systems, not one system applied inconsistently.

**`$84,000` formatting — unconfirmed, no diagnosis.** Live-verification checklist item.

**Revelation pacing — resolved as policy.** Invent freely now, prune deliberately later, per the author.

**Repeatable forks where permanent exclusivity may eventually be desired — still open, unchanged.**

**Tunnel exhausted-resources fail state — still open, unchanged.**

# **Part Five — Open Production Questions**

Unchanged from v14: Ekon's fatal outcome and the preservation/denial archive mechanic are already fully specified in Bible v15; what remains open is narrower — whether his final action includes lighting a sealing fuse, as distinct from the archival "sealing" the bible already describes.

The per-protagonist presentation scheme and the Chapter Two/Three voice-acting plan remain unwritten and not currently being worked on. The Chapter Two/Three audio pipeline (extend the current interpreter or build fresh) is the open architecture question in Part Four, not something this document should present as leaning either way. The author's eventual preference for a contiguous town over the current hub-and-spoke geography is recorded as a stated long-term preference, not a current work item. The HPLHS pitch remains a long-term aspiration only.

# **Part Six — Next Steps**

Unchanged production direction from v14: *validate and improve the first 30 minutes of investigation — discovery, social consequences, evidence linking, and a compelling next lead — before expanding production toward the chapter's climax.*

In priority order:

1. A cold playthrough of the newest development revision specifically, distinct from the frozen Web build, focused on whether the opening 30 minutes' three investigative threads (Part Three) — the historian/schoolteacher chain, the steward appointment progression, and the newspaper-correction thread — actually land for a first-time player and produce a compelling next lead. **This is a diagnostic step; per Part One, it does not authorize replacing the frozen Web build regardless of outcome.**  
2. Address whatever that playthrough surfaces in the opening 30 minutes before touching anything past it.  
3. Migrate `mrs_ashcroft.dialogue`, `mrs_whitlock.dialogue`, and `mr_wick.dialogue` to the documented `morning/midday/evening/night` schedule vocabulary — a consistency cleanup for the catalog-resident system specifically, with no night-placement consequence either way (Part Three).  
4. Confirm or rule out the `$84,000` rendering item live.

Explicitly not current priorities: the ontological break and fatal-comprehension ending; Chapter Two's playable slice and trinket/procedural-geometry pipeline; the Chapter Two/Three audio-pipeline architecture decision; the per-protagonist presentation scheme and voice-acting plan; Ekon's sealing-fuse staging detail; the repeatable-fork exclusivity follow-up; a contiguous-town geography pass; the Part Seven difficulty screen and achievement registration; gamepad support and full key rebinding; and any further work toward the HPLHS pitch.

&nbsp;

&nbsp;