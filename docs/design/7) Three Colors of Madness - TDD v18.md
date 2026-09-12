**THREE COLORS OF MADNESS**

***Technical Design Document***

**Internal working document. Not for external distribution. Companion to the Design Bible.**

**Dejunai (author/producer) · Claude Sonnet (original designer and builder of the dialogue grammar and interpreter, in VS Code with the author; sole author and maintainer of this document) · Codex (core programmer — live integration of the dialogue system into play, subsequent fixes and extensions to the interpreter and its documentation, and direct review of this document against source)**

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

**This document is expected to change often and change fast. Its job is to stay honest about the current state of the build, not to be permanently settled — including this document's own mistakes, corrected in place rather than smoothed over.**

**This revision (v18) corrects v17 against Codex's direct check of source and live test output, approved with corrections, 2026-09-12. v17 was right in direction — dialogue audio is real and wired in — but wrong or premature in several specifics, all fixed below:**

* **The waterfront was missing from Part Two's scope list. It's a real playable outdoor hub with scheduled residents, travel time, save restoration, and the offshore whaling station visible as unreachable scenery. Added.**  
* **The dialogue-count figures in v16/v17 (30 files, 148 topics, 135 nonempty) are stale. Current catalog test reports 35 live NPCs, 165 nonempty topics, and 403 voiced NPC lines. Updated throughout.**  
* **v17's audio caveat ("the specific integration mechanism... has not been independently confirmed against source") is now resolved, not merely reported. The architecture is confirmed: `VOICE: cue_id` is authored immediately before an NPC's spoken line; the parser attaches that cue to the line; the runtime emits `[speaker, text, voice]`; Chapter One plays the matching WAV when the card appears and stops it on advance; a 144-entry manifest validates cue names; instrument voice volume is independently adjustable; Walter, narration, beats, objects, notebook entries, and system text intentionally remain silent. v17's phrase "every dialogue line plays a clip" overstated this — corrected throughout to "every authored NPC line has an instrumental voice cue."**  
* **The CHOICE:/FORK: hardcoded-speaker question is no longer mysterious, though still open. `FORK:` choices still hardcode Walter as the player speaker and remain silent; `VOICE:` immediately before `FORK:` is deliberately rejected by the parser; NPC lines inside a fork can carry normal voice cues. Chapter One's audio work neither resolves nor obstructs the Chapter Two speaker-architecture question — it simply doesn't touch it. Updated in Parts Three, Four, and Five.**  
* **v17's "\~500-file library" scope language is removed. The shipped game uses 144 reusable cue IDs, not one unique recording per spoken line — a cue is shared across every line tagged with it, not generated per-line. The completed ElevenLabs source delivery contains 228 recordings; a compatibility build now produces the 144 stable game cues from them.**
* **Returning staff are now correctly recorded as implemented rather than hypothetical: `odell_precinct` and `coroners_assistant_morgue` exist as live scheduled NPCs for later days. A namespace defect found during review was fixed without a version bump: all three Odell precinct topics now test completion under `odell_precinct`, the identity under which the runtime records them. The returning-staff regression test covers each topic.**
* **Verification is updated: a real Godot 4.7.2 standard executable is now available (not just the mono editor used for the native staging-suite pass), and the current authoritative checks pass — dialogue catalog (35 NPCs, 165 topics), instrument voices (144 cues, 403 NPC lines), live dialogue flow, and usability/object interactions.**  
* **Part Six's closing paragraph is corrected: Chapter One's completed placeholder voice integration does not mean an architectural choice has been made for Chapters Two/Three. That decision stays explicitly deferred; v17 implied otherwise.**  
* **The Ashcroft/Whitlock/Wick schedule-cleanup item is reconfirmed accurate and unchanged: those three files still use `dawn` and placeholder destinations.**  
* **Four refinements after this revision's initial approval, still 2026-09-12, no version bump: the cue manifest validates names during dialogue loading and automated content validation, not "at author time" (see Part Three); a short current-state note on the shared dialogue/examination UI frame is added to Part Three; the completed ElevenLabs source delivery is mapped into the stable 144-cue interface; and the Grok MIDI placeholder WAVs are removed from the playable build.**

**Prior revision (v17), 2026-09-12: recorded the author's report that wordless instrumental voice audio had been wired into all dialogue using a sub-par/regressed Grok batch as placeholder, and flagged the underlying mechanism as unconfirmed against source. That mechanism is now confirmed — see above and Part Three.**

**Prior tightening pass (v16), following Codex's third review, this time of v15, directly against source. Three targeted corrections, each verified independently below rather than accepted on report — Codex's own framing, confirmed: these are not grounds for another broad rewrite.**

* **v15's steward paragraph mistook the conditions that block *sleep* for the conditions that gate the *first steward conversation*. They're different checks on different functions. Corrected in Part Three, with the third encounter's actual coat/day requirement restored.**  
* **v15 proposed a "dedicated tracing pass" to connect the newspaper-correction thread to Almy's response. Unnecessary — Codex traced it directly and it's confirmed implemented. Documented in Part Three; the follow-up item removed from Parts Four and Six.**  
* **v15 said the day/night clock drives scheduled-resident placement "only." Too restrictive — it also drives the sun, lighting, fog, and street lamps. The word is removed; the underlying distinction from story-driven body removal stands.**

**Prior tightening pass (v15), following Codex's second review of v14:**

* **v14 incorrectly chained three separate dialogue threads into one dependency chain. Confirmed and split apart in Part Three.**  
* **v14's "every NPC disappears at night" was too broad. Confirmed wrong by direct reading of `chapter_one_dialogue.gd`'s `allowed()` function: the day/night placement rule in `dialogue_catalog.gd`'s `slot()` applies only to catalog-scanned additional residents (`extra_actors`). The chapter's story actors (Odell, the coroner's assistant, the groundskeeper, the old woman, the steward) have their own bespoke, state-based availability rules with no time-of-day gating at all. Corrected in Part Three.**  
* **v14 conflated the day/night clock with body removal. It doesn't govern it. Corrected in Part Two.**  
* **The `background_npc_template` extension item is closed — Codex confirmed the file is back to `.dialogue`; this document's own read of the delivered zip already showed the same thing. No further action.**  
* **v14 under-documented real implemented mechanics that matter for future work more than this document's own revision history does. Added below: the `filed()` gate (distinct from `evidence()`), the newspaper-correction thread's actual prerequisites, and the steward's three-visit/Day-2-montage progression.**  
* **Provenance needed adjusting to credit Codex's actual subsequent work on the interpreter and its documentation, not just integration and review, while keeping the original design credited correctly. Fixed in the byline above.**

**One constraint made explicit since v16, per the author: validating and testing the newest development revision does not authorize replacing the frozen, already-tested Web build. That build stays the release artifact until the author says otherwise; development-revision testing is diagnostic, not a release decision.**

# **Part Two — Current Build**

## **Engine and Target**

**Godot 4.7 (the Web export identifies as 4.7.2.stable), using the GL Compatibility renderer (not Forward+), targeting broad hardware reach over cutting-edge rendering fidelity. Window target 1440×900, canvas-items stretch mode. No import dependencies beyond the engine itself. Unchanged since v1.**

## **Scope of the Current Slice**

**The Ophion estate grounds (rose garden, service passage, tunnel entry), Pickman Street (boardinghouse, cobbler's shop/Walter's room, precinct, morgue), three neighborhood hubs (business district, upper-residential ridge, lower-residential quarter) reached as pocket spaces off Pickman Street, a post office, and — added this pass — the waterfront: a playable outdoor hub with scheduled residents, its own travel time, full save restoration, and the offshore whaling station visible as unreachable scenery. Geography is hub-and-spoke, not continuous, by current design (the author's stated eventual preference is a contiguous town, subject to feasibility — see Part Five). The day/night clock drives scheduled-resident placement, and separately drives the sun, directional lighting, fog color, and street-lamp visibility, purely as presentation. The clock does not govern body removal. Story progression does — the rose-garden bodies clear after the player's first departure to town; the birch victims (the woman and boy) remain visible and unattended through at least a second estate visit and clear only once Day 3 has begun, with no accompanying scene or notification either time.**

**The live dialogue system spans 35 live NPCs and 165 nonempty authored `TOPIC:` blocks, per the current catalog test (updated this pass from the prior 30 files / 148 topics / 135-nonempty figures, which are stale). Real cross-NPC and paperwork-gated content exists beyond simple witness menus — see Part Three.**

**Confirmed this pass: wordless instrumental voice cues are implemented across every authored NPC line. 403 NPC lines currently carry a voice cue, drawn from a 144-entry cue manifest (a cue is reused across every line tagged with it — this is not one recording per spoken line). See Part Three for the confirmed architecture. Walter, narration, beats, objects, notebook entries, and system text are intentionally silent by design, not by omission. The sub-par/regressed Grok MIDI batch has now been replaced by the completed ElevenLabs Sound Effects delivery. A documented compatibility build maps the broader trombone vocabulary and the supplied violin mood takes onto all 144 stable game cue IDs, so existing `.dialogue` files remain valid. The original 228 source MP3s are external production inputs; the repository ships the 144 normalized WAVs used by the game and a manifest that records each source and transformation.**

**Not yet implemented, unchanged from prior revisions: the glass-shattering ontological break, the fatal-comprehension ending, Chapters Two and Three as playable slices, gamepad support, full key rebinding, a full encumbrance/leveling system, and Ekon's later consumption of Walter's record.**

## **Saves**

**Unchanged from prior revisions (schema 9). Not independently re-verified this pass beyond the waterfront's save-restoration behavior noted above.**

## **Verification**

**Updated this pass: a real Godot 4.7.2 standard executable is now available (distinct from the mono-only editor used for the earlier native staging-suite pass, which could run gameplay tests but not export Web builds). Current authoritative checks, run against it, pass:**

* **Dialogue catalog: 35 NPCs, 165 topics.**  
* **Instrument voices: 144 cues, 403 NPC lines.**  
* **Live dialogue flow: PASS.**  
* **Usability and object interactions: PASS.**

**Direct source reading in earlier passes covered `chapter_one_dialogue.gd` (the live dialogue adapter, its `allowed()` function specifically) and `chapter_one_staging.gd` (the steward's three-visit progression). The voice-cue architecture described in Part Three is now confirmed against source, not merely reported. Separately, per the author and Codex: the author has played the build repeatedly and external testers have already surfaced real issues (an exit problem, a ledger problem, a linking problem) against the frozen Web build specifically. What remains unverified is a cold playthrough of the newest development revision, including its voice cues and the new waterfront hub — and per Part One's constraint, confirming that revision plays correctly is a diagnostic step, not grounds to replace the frozen build.**

# **Part Three — Architecture As Built**

## **Story Actors vs. Catalog Residents**

**Direct reading of `chapter_one_dialogue.gd`'s `allowed(g, actor)` function shows two genuinely different systems:**

* **Catalog-scanned additional residents (`extra_actors`, populated by `catalog.scan()` in `setup()`) are placed exclusively through `dialogue_catalog.gd`'s `slot()`, which does return an empty placement at night regardless of authored schedule.**  
* **Story actors — Odell, the coroner's assistant (`assistant`), the groundskeeper (`crew`), the old woman, and the steward (`barman`) — have their own bespoke availability rules in the same `allowed()` function, none of which reference the day/night clock at all: Odell and the assistant are available whenever `world == "estate"` and the estate isn't complete; the groundskeeper once the lounge has been exited; the old woman while in town and not yet recorded as evidence; the steward keyed to the lounge and whether Mrs. Almy has been spoken to. These are chapter-authored, state-driven staging rules, entirely separate from `dialogue_catalog.gd`'s time-of-day system, and none of them hide their actor at night.**

**Confirmed this pass: returning staff for later days are implemented, not hypothetical.** `odell_precinct` and `coroners_assistant_morgue` exist as live scheduled NPCs, giving both figures a presence beyond their initial estate encounter. The Odell precinct namespace defect found during review is resolved: `day_two_check`, `day_two_pressure`, and `day_three_final` test `topic_done(odell_precinct, ...)`, matching the identity used by dialogue completion. A regression test verifies that each topic disappears after completion without conflating precinct Odell with the estate encounter.

## **Three Separate Investigative Threads**

**Three separate threads, each with its own prerequisites, confirmed independently rather than chained together:**

1. **The historian/schoolteacher witness-count thread. `local_historian.dialogue`'s `crew_omission_followup` topic gates on `topic_done(local_historian, crew_omission_official) AND topic_count(crew_omission) >= 4 AND NOT topic_done(...)` — a real "ask enough people, consistently tagged, before the historian goes further" mechanic, confirmed in source. `schoolteacher.dialogue` carries a related chain keyed off `evidence(naomi)` and `evidence(reader_omission_letter)`. This thread's own internal chain (historian → four witnesses → historian → schoolteacher) is real; it does not connect to either thread below.**  
2. **The steward appointment thread. `chapter_one_staging.gd`'s `sleep()` blocks *sleeping* — not the first conversation — when `steward_visits == 0`, `intake_done` is false, or `evidence.has("naomi")` is false; while blocked, the player just gets an "Get up" panel. Reaching the steward at all is gated separately, through `chapter_one_dialogue.gd`'s `allowed()`: the lounge itself only becomes reachable via the `service_entrance` travel action once `visited.has("almy")` is true, and the steward's dialogue is only `allowed` while `world == "lounge"`. So the real first-visit gate is "spoken to Almy, then travel to the lounge," not the sleep-block conditions. Visit two occurs inside a Day 2 montage (`draw_montage()`, a deliberately temporary "pacing bridge... replace the montage with enacted investigation later" per the source's own comment); completing it sets `day = 3` and `steward_visits = 2`. The substantive third encounter is gated by `case_state.gd`'s `steward_ready()`, which requires all four of `visited.has("almy")`, `day == 3`, `steward_visits >= 2`, and `coat == "Plain wool coat"` — the plain coat specifically, not just the day, is a real and separate requirement for the steward to open up. This thread does not depend on the historian/schoolteacher thread or the newspaper thread.**  
3. **The newspaper-correction thread, gated on a distinct mechanism: `filed()`, not `evidence()`. `gazette_editor.dialogue`'s `print_correction` topic requires `evidence(gazette_correction_terms) AND filed(eight) AND filed(naomi) AND filed(lodging)` and awards `EVIDENCE: gazette_correction_printed` on completion. `filed()` checks received report pages specifically, not the current evidence inventory, per `background_npc_template.dialogue`'s own comment — meaning this thread depends on paperwork actually having been filed and received, separate from simply having collected the underlying evidence. `mrs_almy.dialogue`'s `show_printed_correction` topic gates directly on `evidence(gazette_correction_printed)`; once available, showing her the slip has her read Naomi's name aloud and acknowledge Walter's effort ("You brought back something I can read. Thank you."), recorded via `NOTEBOOK: correction_seen`. The connection between the correction thread and Almy's response is implemented and confirmed, not merely gated in principle.**

## **`$84,000` Formatting Item — unconfirmed**

**Unchanged: not reproducible in source text, not diagnosed, belongs on a live-verification checklist.**

## **Instrumental Voice Cue System — confirmed architecture, new this pass**

**The wordless instrumental voice pack (briefed to Grok — see `voice_pack_brief_grok.md`) is now wired into every authored NPC line, and the mechanism is confirmed against source rather than inferred:**

* **`VOICE: cue_id` is authored immediately before an NPC's spoken line in the `.dialogue` source.**  
* **The parser attaches that cue to the line as part of compilation.**  
* **The runtime emits a `[speaker, text, voice]` triple per line (extending the prior `speaker`/`text`\-only shape).**  
* **Chapter One plays the matching WAV when the dialogue card appears on screen, and stops it when the player advances past that line.**  
* **A 144-entry manifest validates cue names during dialogue loading and automated content validation, catching typos or unregistered cue IDs.**  
* **Instrument voice volume has its own independent mixer control, separate from music/SFX.**  
* **Walter, narration, beats, object descriptions, notebook entries, and system text are intentionally silent — this is deliberate scope, not an oversight, and matches the design intent that the voice layer characterizes NPCs the player interrogates, not the protagonist or the game's own narration.**

**This resolves what earlier revisions (through v17) treated as an open or unconfirmed integration question. What it does not resolve — see the CHOICE:/FORK: entry below — is the separate hardcoded-player-speaker question for Chapter Two.**

## **CHOICE:/FORK: Hardcoded Player Speaker — open, but no longer mysterious**

**`FORK:` choices still hardcode Walter as the player speaker and remain silent — no voice cue plays for a fork prompt itself. `VOICE:` immediately before `FORK:` is deliberately rejected by the parser, which keeps the fork mechanism unambiguous rather than accidentally voiceable. NPC lines that appear *inside* a fork's branches can carry normal voice cues like any other NPC line — the restriction is specific to the fork prompt/player-choice moment, not to dialogue generally. Chapter One's completed voice-cue work neither resolves nor obstructs the future Chapter Two speaker-architecture question: whether Chapter Two extends this same interpreter (silent player choices, voiced NPC lines) or adopts something different for a voiced player character is still genuinely open and untouched by anything built for Chapter One.**

## **Presentation Frame — current state, added this pass**

**Dialogue cards, NPC topic menus, and Walter's response menus share the warm wood-and-brass conversation frame. Physical examinations use a separate blue-gray archival frame — a deliberate visual split between "talking to someone" and "examining something," rather than one generic panel style for all player-facing text. The shared card renderer keeps the Continue control anchored to the bottom of the presentation frame regardless of text length, so a short line and a long line don't shift where the player's eye goes to advance.**

## **Background NPC Template Extension — resolved, closed**

**Codex confirms `background_npc_template` is back to the correct `.dialogue` extension; this document's own read of the delivered zip already showed no `.dialogue.txt` anywhere in the corpus. No further action needed.**

## **Dialogue Authoring System — provenance**

**The dialogue grammar and interpreter (`dialogue_lang.gd`, `dialogue_runtime.gd`, `dialogue_state.gd`) were designed and built by the project's author working with a Claude Sonnet instance in VS Code. Codex's role extends beyond integration: live-wiring the interpreter into actual play, subsequent fixes and extensions to the interpreter itself (including the schedule-alias handling in `dialogue_catalog.gd`'s `slot()`, and the `VOICE:`/cue-manifest extension described above), and authoring `docs/DIALOGUE_AUTHORING.md` (September 10\) as a writer-facing reference, confirmed substantively accurate against the interpreter's actual behavior. Codex now also reviews this document directly against source, which produced the corrections in this and prior revisions.**

# **Part Four — Architecture Decisions Needed**

**CHOICE:/FORK: hardcoded speaker for Chapter Two — still open, clarified this pass. See Part Three: Chapter One's voice-cue system is fully confirmed and deliberately does not touch fork/player-choice moments, which stay silent and hardcoded to Walter. This tells us nothing new about whether Chapter Two should extend the interpreter with a similar silent-choice/voiced-NPC pattern or adopt a voiced player character — genuinely open, unaffected by Chapter One's completed work.**

**Odell-precinct topic-gate namespace defect — resolved, closed.** All three precinct topics now gate on `topic_done(odell_precinct, ...)`, with regression coverage for location-specific completion.

**Story-actor vs. catalog-resident staging — clarified, not a defect. See Part Three. Two legitimately separate systems, not one system applied inconsistently.**

**`$84,000` formatting — unconfirmed, no diagnosis. Live-verification checklist item.**

**Revelation pacing — resolved as policy. Invent freely now, prune deliberately later, per the author.**

**Repeatable forks where permanent exclusivity may eventually be desired — still open, unchanged.**

**Tunnel exhausted-resources fail state — still open, unchanged.**

**Voice-cue library replacement pipeline — complete for the present 144-cue architecture. The game uses reusable cue IDs, not one recording per line. `tools/build_elevenlabs_voice_library.py` converts the completed 228-file ElevenLabs source batch into the stable twelve-styles/three-lengths/two-takes game matrix. Trombone takes map to complementary delivery styles; violin length variants use pitch-preserving cadence changes from the supplied mood takes. The output is normalized mono 44.1 kHz 16-bit PCM, and the generated manifest preserves source-to-cue provenance. The broader source vocabulary remains available for later selective expansion without forcing dialogue changes now.**

# **Part Five — Open Production Questions**

**Ekon's fatal outcome and the preservation/denial archive mechanic are already fully specified in Bible v15; what remains open is narrower — whether his final action includes lighting a sealing fuse, as distinct from the archival "sealing" the bible already describes.**

**The per-protagonist presentation scheme remains unwritten and not currently being worked on. Chapter Two/Three audio is explicitly still deferred, corrected this pass. Chapter One now has a confirmed, working instrumental-voice-cue architecture, but that is a Chapter One-scoped implementation, not a decision about Chapters Two or Three — v17 implied the two were converging; they aren't. Whether Chapter Two/Three dialogue extends the same cue system, adopts something else, or goes fully voiced for the player character remains open and untouched, and should stay off any "in progress" list until the author actually takes it up. The author's eventual preference for a contiguous town over the current hub-and-spoke geography is recorded as a stated long-term preference, not a current work item. The HPLHS pitch remains a long-term aspiration only.**

# **Part Six — Next Steps**

**Unchanged production direction: *validate and improve the first 30 minutes of investigation — discovery, social consequences, evidence linking, and a compelling next lead — before expanding production toward the chapter's climax.***

**In priority order:**

1. **A cold playthrough of the newest development revision specifically, distinct from the frozen Web build, focused on whether the opening 30 minutes' three investigative threads (Part Three) — the historian/schoolteacher chain, the steward appointment progression, and the newspaper-correction thread — actually land for a first-time player and produce a compelling next lead, now including the waterfront hub and the confirmed voice-cue system. This is a diagnostic step; per Part One, it does not authorize replacing the frozen Web build regardless of outcome.**  
2. **Address whatever that playthrough surfaces in the opening 30 minutes before touching anything past it.**  
3. **Migrate `mrs_ashcroft.dialogue`, `mrs_whitlock.dialogue`, and `mr_wick.dialogue` to the documented `morning/midday/evening/night` schedule vocabulary — still accurate and unchanged: these three files continue to use `dawn` and placeholder destinations. A consistency cleanup for the catalog-resident system specifically, with no night-placement consequence either way (Part Three).**
4. **Confirm or rule out the `$84,000` rendering item live.**
5. **Playtest the completed ElevenLabs compatibility library in context and hand-tune individual `VOICE:` assignments only where delivery clashes with the written line. The stable 144-cue replacement and source mapping are complete.**

**Explicitly not current priorities: the ontological break and fatal-comprehension ending; Chapter Two's playable slice and trinket/procedural-geometry pipeline; the Chapter Two/Three audio-pipeline architecture decision (Chapter One's completed voice-cue work does not change this — see Part Five); the per-protagonist presentation scheme; Ekon's sealing-fuse staging detail; the repeatable-fork exclusivity follow-up; a contiguous-town geography pass; the Part Seven difficulty screen and achievement registration; gamepad support and full key rebinding; and any further work toward the HPLHS pitch.**

&nbsp;

&nbsp;
