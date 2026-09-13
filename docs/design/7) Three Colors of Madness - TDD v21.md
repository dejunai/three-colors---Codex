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

**This revision (v26), 2026-09-13, is a stopping-point checkpoint — Codex is on a 2-hour cooldown, so this is the literal end of today's Phase 1 work, confirmed against source rather than taken from the report alone. Branch `dev/contiguous-town-phase-1`, six steps landed: (1) a walkable stone incline replaces the flat Pickman-to-business portal; (2) the existing business-street geometry now sits at the top of that incline in the same exterior, interiors unchanged, exit positions transformed to the correct storefront via `business_return()`; (3) a second climb reaches toward the upper quarter, silhouette-only at first; (4) the upper quarter itself is folded in the same way, via a new shared `upper_street.gd` builder also used by the old flat hub; (5) a return loop (a second climb and a second descent) closes the walk into a full loop instead of a dead end, plus a self-corrected retaining-wall pass after a playtest made the raised business ground read as an unsupported bridge; (6) scheduled business/upper NPC positions are now translated into the shared exterior's real coordinates via a new `ContiguousTown.shared_spot()`, closing the "NPCs still at old coordinates" gap flagged after the first three steps. One regression was found and fixed mid-session (Step 1-3 pass only): the `eight_identified` birch-grove-placard key remap in `chapter_one.gd` had been silently deleted; restored. The second diff pass (Steps 4-6) introduced no regressions. Remaining, per Codex's own doc: profile the complete exterior on desktop and Web before any streaming/LOD/model-upgrade work. No Web export has been produced for any step so far.**

**This revision (v25), 2026-09-13: first attempt at contiguous exteriors began today, on a new branch — Phase 1 (upper ridge, business district, Pickman Street, lower quarter, waterfront, estate, offshore island). Spatial relationship study produced; no implementation yet.**

**This revision (v24) records three items from 2026-09-12. First, a diagnosed but unresolved pacing defect, no solution chosen: see Part Four, "Conversation-time/travel-time scale mismatch" (four confirmed contributing factors — the `CONVERSATION_MINUTES`/`DEFAULT_MINUTES` scale mismatch against `TRAVEL_MINUTES`, the passive `WANDER_RATE` real-time tick, and the author's dev-only brisk-speed multiplier skewing their own playtesting read). Second, closed: the "Fork revisit-with-recap pattern," reported by the author mid-session as Codex quietly "on it," then confirmed against real source and test — see Part Three, "`FORK:`/`OUTCOME:` Resolution With Recap," which supersedes this document's own prior "auto-retirement" description and its own unbuilt "companion recap topic" proposal. All eight previously one-shot-protected forks are confirmed migrated to the new mechanism. Third, unresolved and reported only, not source-confirmed: Captain Odell is said to retain one deliberately one-shot fork (his automatic intake conversation) whose actual source location was not found this pass.**

**This revision (v23) records two items from a live dialogue-review pass with Claude (Cowork), per Dejunai, 2026-09-12. First, closed: eight `FORK:`-bearing topics across `post_office_clerk.dialogue`, `county_clerk.dialogue`, `gazette_editor.dialogue`, `local_historian.dialogue`, `mr_vale.dialogue` (NPC id `quay_bookkeeper`), `mr_whitehouse.dialogue`, `school_parent.dialogue`, and `widow_kessler.dialogue` had no repeat-protection at all — no `NOT topic_done(...)` in their `GATE:`, and no `OUTCOME:` on their `CHOICE:` branches to trigger the auto-retirement Part Three already documents for that mechanism. Each was fully replayable, letting the player harvest every `CHOICE` branch's evidence across separate visits instead of committing to one, defeating the "mutually exclusive" intent `dialogue_lang.gd`'s own authoring comments describe for `FORK:`. Fixed by adding `NOT topic_done(npc, topic_id)` to each `GATE:`, matching the convention already used correctly elsewhere (`quay_docker.dialogue`'s `estate_freight_carts`, `schoolteacher.dialogue`'s `the_slain_boy`). Second, opened and deliberately deferred: see Part Four, "Fork revisit-with-recap pattern."**

**This revision (v22) resolves the `$84,000` formatting item, per Dejunai, 2026-09-12. It was never a bug in the sense outside accounts of this project have assumed — a circulating "leaked design docs" narration (an AI-generated podcast working from that fictional premise) dramatized it as a deliberate, expensive UI glitch simulating real-time save-file corruption. That account is fabricated. The actual issue was a plain text-rendering defect: the `$` character did not display correctly in the wage-claim dialogue script (see Part Five, The Wage Claim). The fix removed the currency symbol from the source entirely and spelled the amount out in words — "eighty-four thousand dollars" — with no numerals or symbol left anywhere in the line. This is also exactly why the item was previously unreproducible by searching for `$84,000` or any numeral form: that string does not exist in the corpus in that shape. Closed below in Parts Three, Four, and Six.**

**Prior revision (v21) reconciled this project-doc copy against the real repository, per Dejunai, 2026-09-12. The two features this document's v20 had specified as "not yet implemented, ready for Codex" — `WEIGHT:` on `TOPIC: default`, and `FORK:`/`OUTCOME:` one-time resolution — were in fact already implemented by Codex by the time v20 was written here; Codex had also already carried the repository's own TDD forward to its own v18, independently of this project-doc lineage. This revision was built by pulling the real repository directly (`scripts/shared/dialogue_lang.gd`, `dialogue_runtime.gd`, `dialogue_state.gd`, `tests/dialogue_lang_flow.gd`, `docs/DIALOGUE_AUTHORING.md`, and the repository's own `docs/design/7) Three Colors of Madness - TDD v18.md`) rather than from a description of them, so the specifics below are confirmed against source and test, not reported secondhand. Three things changed as a result:**

* **`WEIGHT:` on `TOPIC: default` is implemented, confirmed against source and test. It works exactly as this document's v20 speculated, with two real details v20 could not have known: repeat-avoidance is tracked by the winning topic's source line number, not its text (so two differently-worded lines still count as "the same line" only if they're literally the same authored entry), and misuse is actually two separate parser errors, not a silent no-op as v20 assumed — see Part Three and the correction below. Repository v18 does not document this feature at all; it is documented here for the first time against real source.**  
* **`FORK:`/`OUTCOME:` one-time resolution is implemented, confirmed against source and test, and materially matches this document's v20 spec, with the real mechanism now recorded precisely: `OUTCOME: decision_id = value_id`, gated to auto-retire every topic containing that decision once any of its branches is taken. Repository v18 already documents this feature (as of its own v16–v18 passes); this revision folds that documentation in accurately rather than duplicating v20's speculative version of it.**  
* **One correction to v20's own WEIGHT spec, made in place: v20 stated that authoring `WEIGHT:` outside `TOPIC: default` is "ignored silently rather than erroring." Source shows the opposite — it is a hard parse error (`"WEIGHT is only valid on TOPIC: default"`). v20 also implied a bare no-repeat rule; source additionally falls back to allowing repetition only when excluding the previous line would leave the pool empty, which v20 got right, and weights are read as a positive float, not restricted to integers, which v20 did not specify either way. Corrected below; no design intent changes as a result of any of this, since the feature already ships and already works — this is a documentation-accuracy fix, not a behavior change.**

**This pass also folds in real changes present in the repository's own v18 that this project-doc copy had not yet recorded on its own thread: the waterfront hub, updated dialogue-catalog figures (now 35 NPCs, 217 topics, 455 voiced lines after the September 12 dialogue expansion), and — materially — that the ElevenLabs voice-pack replacement is now complete and mapped into the shipping 144-cue manifest, superseding this document's own earlier "still being assembled, not a strict drop-in" language. See Part Two, Three, and Four.**

**Prior revision (v20) specified two new dialogue-grammar extensions proposed by Dejunai, 2026-09-12, believing them not yet implemented. They were already implemented by the time this was written — see the reconciliation above. v20's spec language is retained in spirit (nothing about the feature intent was wrong) but its "not yet implemented, ready for Codex" framing is now corrected throughout.**

**Prior revision (v19) records that the `odell_precinct` topic-gate defect is fixed, per Dejunai, 2026-09-12. The gate now resolves correctly rather than remaining repeatable — see the updated Part Three, Part Four, and Part Six entries below. This closes an item that had been independently confirmed by four separate methods (Codex's direct source read, Grok's dialogue-file pass, AntigravityIDE's AST audit, and "Antigravity (noIDE)"'s raw-file pass) before the fix landed.**

**Prior revision (v18) corrects v17 against Codex's direct check of source and live test output, approved with corrections, 2026-09-12. v17 was right in direction — dialogue audio is real and wired in — but wrong or premature in several specifics, all fixed below:**

* **The waterfront was missing from Part Two's scope list. It's a real playable outdoor hub with scheduled residents, travel time, save restoration, and the offshore whaling station visible as unreachable scenery. Added.**  
* **The dialogue-count figures in v16/v17 (30 files, 148 topics, 135 nonempty) are stale. Current catalog test reports 35 live NPCs, 217 nonempty topics, and 455 voiced NPC lines. Updated throughout.**
* **v17's audio caveat ("the specific integration mechanism... has not been independently confirmed against source") is now resolved, not merely reported. The architecture is confirmed: `VOICE: cue_id` is authored immediately before an NPC's spoken line; the parser attaches that cue to the line; the runtime emits `[speaker, text, voice]`; Chapter One plays the matching WAV when the card appears and stops it on advance; a 144-entry manifest validates cue names; instrument voice volume is independently adjustable; Walter, narration, beats, objects, notebook entries, and system text intentionally remain silent. v17's phrase "every dialogue line plays a clip" overstated this — corrected throughout to "every authored NPC line has an instrumental voice cue."**  
* **The dialogue interpreter is now the shared foundation planned for all three chapters. `FORK:` choices still hardcode Walter as the player speaker and remain silent in Chapter One; protagonist identity must become chapter-provided before Chapter Two content is integrated. `OUTCOME: decision_id = value_id` now records immutable, branch-local decisions, retires the source fork automatically, and exposes `outcome()` / `outcome_is()` gates for downstream consequences. Existing forks remain replayable until explicitly authored with an outcome.**  
* **v17's "\~500-file library" scope language is removed. The shipped game uses 144 reusable cue IDs, not one unique recording per spoken line — a cue is shared across every line tagged with it, not generated per-line. The completed ElevenLabs source delivery contains 228 recordings; a compatibility build now produces the 144 stable game cues from them — this project-doc copy's own earlier "still being assembled" language for that library is now stale and is corrected below.**  
* **Returning staff are now correctly recorded as implemented rather than hypothetical: `odell_precinct` and `coroners_assistant_morgue` exist as live scheduled NPCs for later days. A namespace defect found during review was fixed without a version bump: all three Odell precinct topics now test completion under `odell_precinct`, the identity under which the runtime records them. The returning-staff regression test covers each topic.**  
* **Verification is updated: a real Godot 4.7.2 standard executable is now available (not just the mono editor used for the native staging-suite pass), and the current authoritative checks pass — dialogue catalog (35 NPCs, 217 topics), instrument voices (144 cues, 455 NPC lines), live dialogue flow, and usability/object interactions.**
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

**The Ophion estate grounds (rose garden, service passage, tunnel entry), Pickman Street (boardinghouse, cobbler's shop/Walter's room, precinct, morgue), three neighborhood hubs (business district, upper-residential ridge, lower-residential quarter) reached as pocket spaces off Pickman Street, a post office, and the waterfront: a playable outdoor hub with scheduled residents, its own travel time, full save restoration, and the offshore whaling station visible as unreachable scenery. Geography is hub-and-spoke, not continuous, by current design (the author's stated eventual preference is a contiguous town, subject to feasibility — see Part Five). The day/night clock drives scheduled-resident placement, and separately drives the sun, directional lighting, fog color, and street-lamp visibility, purely as presentation. The clock does not govern body removal. Story progression does — the rose-garden bodies clear after the player's first departure to town; the birch victims (the woman and boy) remain visible and unattended through at least a second estate visit and clear only once Day 3 has begun, with no accompanying scene or notification either time.**

**The live dialogue system spans 35 live NPCs and 217 nonempty authored `TOPIC:` blocks, per the current catalog test. Real cross-NPC and paperwork-gated content exists beyond simple witness menus — see Part Three.**

**Wordless instrumental voice cues are implemented across every authored NPC line. 455 NPC lines currently carry a voice cue, drawn from a 144-entry cue manifest (a cue is reused across every line tagged with it — this is not one recording per spoken line). See Part Three for the confirmed architecture. Walter, narration, beats, objects, notebook entries, and system text are intentionally silent by design, not by omission. Corrected this pass: the ElevenLabs voice-pack replacement is complete, not still being assembled. This document's own v18–v20 language calling it a work-in-progress, not-a-strict-drop-in library is stale. The completed ElevenLabs Sound Effects delivery contains 228 source recordings; a documented compatibility build (`tools/build_elevenlabs_voice_library.py`) now maps the broader trombone vocabulary and supplied violin mood takes onto all 144 stable game cue IDs, so every existing `.dialogue` file's `VOICE:` assignments remain valid without any source-file changes. Trombone takes map to complementary delivery styles; violin length variants use pitch-preserving cadence changes from the supplied mood takes. Output is normalized mono 44.1 kHz 16-bit PCM, with a generated manifest preserving source-to-cue provenance. The sub-par/regressed Grok MIDI placeholder batch has been removed from the playable build entirely. The broader ElevenLabs source vocabulary remains available for later selective expansion without forcing dialogue changes now.**

**Not yet implemented, unchanged from prior revisions: the glass-shattering ontological break, the fatal-comprehension ending, Chapters Two and Three as playable slices, gamepad support, full key rebinding, a full encumbrance/leveling system, and Ekon's later consumption of Walter's record.**

## **Saves**

**Unchanged from prior revisions (schema 9). Not independently re-verified this pass beyond the waterfront's save-restoration behavior noted above.**

## **Verification**

**A real Godot 4.7.2 standard executable is available (distinct from the mono-only editor used for the earlier native staging-suite pass, which could run gameplay tests but not export Web builds). Current authoritative checks, run against it, pass:**

* **Dialogue catalog: 35 NPCs, 217 topics.**
* **Instrument voices: 144 cues, 455 NPC lines.**
* **Live dialogue flow: PASS.**  
* **Usability and object interactions: PASS.**

**This pass's WEIGHT/OUTCOME reconciliation is independently confirmed by direct source read of `dialogue_lang.gd` (parser), `dialogue_runtime.gd` (selection/commit logic), and `dialogue_state.gd` (persisted outcome storage), plus `tests/dialogue_lang_flow.gd`'s existing coverage: a weighted-default no-immediate-repeat assertion, a two-error assertion for misused `WEIGHT:` (non-default topic *and* non-positive value in the same fixture), and a two-error assertion for malformed `OUTCOME:` (used outside a `FORK:` choice, and an incomplete assignment). This is source-and-test confirmation, not a description accepted on report.**

**Earlier direct source reading covered `chapter_one_dialogue.gd` (the live dialogue adapter, its `allowed()` function specifically) and `chapter_one_staging.gd` (the steward's three-visit progression). The voice-cue architecture described in Part Three is confirmed against source, not merely reported. Separately, per the author and Codex: the author has played the build repeatedly and external testers have already surfaced real issues (an exit problem, a ledger problem, a linking problem) against the frozen Web build specifically. What remains unverified is a cold playthrough of the newest development revision, including its voice cues and the waterfront hub — and per Part One's constraint, confirming that revision plays correctly is a diagnostic step, not grounds to replace the frozen build.**

# **Part Three — Architecture As Built**

## **Story Actors vs. Catalog Residents**

**Direct reading of `chapter_one_dialogue.gd`'s `allowed(g, actor)` function shows two genuinely different systems:**

* **Catalog-scanned additional residents (`extra_actors`, populated by `catalog.scan()` in `setup()`) are placed exclusively through `dialogue_catalog.gd`'s `slot()`, which does return an empty placement at night regardless of authored schedule.**  
* **Story actors — Odell, the coroner's assistant (`assistant`), the groundskeeper (`crew`), the old woman, and the steward (`barman`) — have their own bespoke availability rules in the same `allowed()` function, none of which reference the day/night clock at all: Odell and the assistant are available whenever `world == "estate"` and the estate isn't complete; the groundskeeper once the lounge has been exited; the old woman while in town and not yet recorded as evidence; the steward keyed to the lounge and whether Mrs. Almy has been spoken to. These are chapter-authored, state-driven staging rules, entirely separate from `dialogue_catalog.gd`'s time-of-day system, and none of them hide their actor at night.**

**Returning staff for later days are implemented, not hypothetical. `odell_precinct` and `coroners_assistant_morgue` exist as live scheduled NPCs, giving both figures a presence beyond their initial estate encounter. The Odell precinct namespace defect found during review is resolved: `day_two_check`, `day_two_pressure`, and `day_three_final` test `topic_done(odell_precinct, ...)`, matching the identity used by dialogue completion. A regression test verifies that each topic disappears after completion without conflating precinct Odell with the estate encounter.**

## **Three Separate Investigative Threads**

**Three separate threads, each with its own prerequisites, confirmed independently rather than chained together:**

1. **The historian/schoolteacher witness-count thread. `local_historian.dialogue`'s `crew_omission_followup` topic gates on `topic_done(local_historian, crew_omission_official) AND topic_count(crew_omission) >= 4 AND NOT topic_done(...)` — a real "ask enough people, consistently tagged, before the historian goes further" mechanic, confirmed in source. `schoolteacher.dialogue` carries a related chain keyed off `evidence(naomi)` and `evidence(reader_omission_letter)`. This thread's own internal chain (historian → four witnesses → historian → schoolteacher) is real; it does not connect to either thread below.**  
2. **The steward appointment thread. `chapter_one_staging.gd`'s `sleep()` blocks *sleeping* — not the first conversation — when `steward_visits == 0`, `intake_done` is false, or `evidence.has("naomi")` is false; while blocked, the player just gets an "Get up" panel. Reaching the steward at all is gated separately, through `chapter_one_dialogue.gd`'s `allowed()`: the lounge itself only becomes reachable via the `service_entrance` travel action once `visited.has("almy")` is true, and the steward's dialogue is only `allowed` while `world == "lounge"`. So the real first-visit gate is "spoken to Almy, then travel to the lounge," not the sleep-block conditions. Visit two occurs inside a Day 2 montage (`draw_montage()`, a deliberately temporary "pacing bridge... replace the montage with enacted investigation later" per the source's own comment); completing it sets `day = 3` and `steward_visits = 2`. The substantive third encounter is gated by `case_state.gd`'s `steward_ready()`, which requires all four of `visited.has("almy")`, `day == 3`, `steward_visits >= 2`, and `coat == "Plain wool coat"` — the plain coat specifically, not just the day, is a real and separate requirement for the steward to open up. This thread does not depend on the historian/schoolteacher thread or the newspaper thread.**  
3. **The newspaper-correction thread, gated on a distinct mechanism: `filed()`, not `evidence()`. `gazette_editor.dialogue`'s `print_correction` topic requires `evidence(gazette_correction_terms) AND filed(eight) AND filed(naomi) AND filed(lodging)` and awards `EVIDENCE: gazette_correction_printed` on completion. `filed()` checks received report pages specifically, not the current evidence inventory, per `background_npc_template.dialogue`'s own comment — meaning this thread depends on paperwork actually having been filed and received, separate from simply having collected the underlying evidence. `mrs_almy.dialogue`'s `show_printed_correction` topic gates directly on `evidence(gazette_correction_printed)`; once available, showing her the slip has her read Naomi's name aloud and acknowledge Walter's effort ("You brought back something I can read. Thank you."), recorded via `NOTEBOOK: correction_seen`. The connection between the correction thread and Almy's response is implemented and confirmed, not merely gated in principle.**

## **`$84,000` Formatting Item — resolved, closed**

**Resolved, per Dejunai, 2026-09-12. This was a plain text-rendering defect, not a deliberately engineered glitch: the `$` character failed to render correctly in the wage-claim dialogue script. The fix removes the currency symbol from the source entirely — the amount is spelled out in words ("eighty-four thousand dollars"), with no numerals or symbol present anywhere in the line. This is also exactly why the string was never reproducible by searching for `$84,000` or any numeral form: it does not exist in that shape anywhere in the corpus. This is unrelated to, and far less dramatic than, an external "leaked design docs" account (an AI-generated podcast) describing this as an intentional, expensive UI glitch that simulates real-time save-file corruption. That account is fabricated and should not be treated as a source for anything about this project.**

## **Instrumental Voice Cue System — confirmed architecture**

**The wordless instrumental voice pack (originally briefed to Grok — see `voice_pack_brief_grok.md`) is wired into every authored NPC line, and the mechanism is confirmed against source rather than inferred:**

* **`VOICE: cue_id` is authored immediately before an NPC's spoken line in the `.dialogue` source.**  
* **The parser attaches that cue to the line as part of compilation.**  
* **The runtime emits a `[speaker, text, voice]` triple per line (extending the prior `speaker`/`text`\-only shape).**  
* **Chapter One plays the matching WAV when the dialogue card appears on screen, and stops it when the player advances past that line.**  
* **A 144-entry manifest validates cue names during dialogue loading and automated content validation, catching typos or unregistered cue IDs.**  
* **Instrument voice volume has its own independent mixer control, separate from music/SFX.**  
* **Walter, narration, beats, object descriptions, notebook entries, and system text are intentionally silent — this is deliberate scope, not an oversight, and matches the design intent that the voice layer characterizes NPCs the player interrogates, not the protagonist or the game's own narration.**

**This resolves what earlier revisions (through v17) treated as an open or unconfirmed integration question. The same parser and runtime is the shared foundation for Chapters Two and Three; the remaining work is to provide protagonist identity per chapter and support their full spoken-audio manifests — see Part Four.**

## **`WEIGHT:` on `TOPIC: default` — implemented, confirmed against source and test**

**Ships in `dialogue_lang.gd`/`dialogue_runtime.gd` and is covered by `tests/dialogue_lang_flow.gd`. Confirmed mechanism:**

* **`WEIGHT: n` (a positive number, not restricted to integers) is authored as line-level metadata inside a `TOPIC: default` block, alongside `GATE:`/`LABEL:` on that topic.**  
* **Authoring on any topic other than `default` is a hard parse error — `"WEIGHT is only valid on TOPIC: default"` — not a silent no-op. A non-positive value (`WEIGHT: 0` or negative) is a second, separate parse error. This document's v20 draft, written before this reconciliation, guessed the misuse case would fail silently; source shows it is caught at parse time instead, which is the safer of the two behaviors and requires no further work.**  
* **Multiple `TOPIC: default` blocks are allowed, and the first eligible block controls selection. If it is unweighted, it wins deterministically, preserving specific-before-fallback gate cascades. If it carries `WEIGHT:`, the runtime draws only from eligible defaults that explicitly carry `WEIGHT:`; later eligible unweighted defaults remain outside the pool as deterministic fallbacks. This prevents ambient chatter from displacing required default conversations such as the gardener's plain-coat testimony.**
* **No-immediate-repeat rule, confirmed exactly as v20 specified: the runtime tracks the winning default's source line per NPC and excludes it from the next draw's pool, falling back to allowing a repeat only when excluding it would leave the pool empty (i.e., a single-candidate default). This tracking is by source line, not by line text, session-scoped, and explicitly not saved — `docs/DIALOGUE_AUTHORING.md` calls this "cosmetic."**  
* **Defaults never appear as menu entries, weighted or not. Non-`default` topic IDs must stay unique per NPC as before; sharing a topic ID across different NPCs still intentionally supports `topic_count()`.**  
* **Authoring guidance (from `docs/DIALOGUE_AUTHORING.md`, not a parser requirement): use weighted defaults for interchangeable exhausted/ambient remarks, and keep required evidence, notes, progression, and unique information in deterministic (non-default) topics instead.**  
* **Scope discipline holds exactly as intended when this was proposed: this is presentation/repetition variety only. No new evidence, gates, topics, or narrative content is implied or required — existing single-line defaults remain fully legal and behave exactly as they did before this feature shipped.**

**This closes the "specified, not yet implemented" status this document's v20 gave the feature. `docs/DIALOGUE_AUTHORING.md` already documents it for authors; this is its first appearance in this TDD.**

## **`FORK:`/`OUTCOME:` Resolution With Recap — implemented, confirmed against source and test, 2026-09-12 (supersedes this section's prior "auto-retirement" description)**

**Ships in `dialogue_lang.gd`/`dialogue_runtime.gd`/`dialogue_state.gd`, covered by `tests/dialogue_template_flow.gd` (the earlier `tests/dialogue_lang_flow.gd` predates this behavior and does not exercise it). Codex implemented this independently, reported to the author as "on it" with no spec handed over; this section is written from direct source and test reading, not from that report. Confirmed mechanism, and it is materially different from — and simpler than — both this document's prior "auto-retirement" description and its own speculative "companion recap topic" proposal below:**

* **Inside a `FORK:` block, any `CHOICE:` branch may additionally contain `OUTCOME: decision_id = value_id` — both sides must be a simple identifier, or the parser raises a parse error, exactly as before. The chosen value is held as a pending outcome for the session and only committed to `dialogue_state.gd`'s `outcomes` dictionary once the branch finishes playing; `set_outcome()` still refuses to overwrite an existing key, so a decision is immutable for the rest of the playthrough.**  
* **`topic_available()` no longer inspects `outcome_keys` at all — it is now pure `GATE:` evaluation. A topic with a resolved `OUTCOME:` fork is NOT excluded from the NPC's menu. This replaces the auto-retirement mechanism this section previously documented (that mechanism no longer exists in source).**  
* **Instead, `render()` computes which of a topic's `outcome_keys` already have a recorded value (`locked_outcomes`), and when playback reaches a `FORK:` step, `_locked_fork_options()` filters the presented `CHOICE:` options down to only the one(s) whose authored `OUTCOME:` matches what was already chosen — so reopening a resolved fork's topic shows the full conversation again, with the fork menu itself narrowed to one option: the branch actually taken. The rejected branch is not offered and cannot be reached again.**  
* **Replay is genuinely free: `dialogue_state.gd`'s `record_fact()`, `discover()`, `complete_topic()`, and `set_outcome()` are all idempotent (guard on existing keys/values), and `commit_through()`'s `TIME:` charge is gated on `first_completion`, so replaying the locked branch fires no duplicate `NOTEBOOK:`/`EVIDENCE:` effects and charges no additional day-clock time. Confirmed directly by `tests/dialogue_template_flow.gd`: "Committed OUTCOME must leave its source topic available for review," "Replay must expose only the previously committed branch," and "Replaying a resolved decision must not charge time again."**  
* **No separate authoring is required to get recap behavior — unlike this document's own prior speculative design (a companion `TIME: 0` recap topic per branch), the same original topic replays itself, filtered. Net authoring cost for a fork opting into this is exactly `OUTCOME:` on each `CHOICE:` and nothing else; the `GATE:` does not need `NOT topic_done(...)` or `NOT outcome(...)` for this purpose.**  
* **Forks using only `CHOICE:` (no `OUTCOME:`) are unaffected and keep their plain repeatable behavior, as before — this stays opt-in per fork.**  
* **Not independently confirmed this pass: the author reports Captain Odell has one fork that deliberately stays fully one-shot (no recap), because it is his automatic opening/intake conversation and replaying it would interrupt every later Odell visit. No `FORK:` was found in `odell_precinct.dialogue` itself during this reconciliation — that conversation likely lives in a different, non-`.dialogue`-file scripted flow (e.g., the hardcoded intake sequence). Recorded as reported, not source-confirmed; worth tracing if it ever needs to change.**

**This supersedes the former "Unprotected Forks — resolved, closed" section below and the "auto-retirement" framing this section previously gave `OUTCOME:`. It also closes Part Four's "Fork revisit-with-recap pattern" — see there.**

## **Unprotected Forks — superseded, see above**

**A live dialogue-review pass, 2026-09-12, found eight `TOPIC:` blocks whose `FORK:` had no repeat-protection at all: no `NOT topic_done(npc, topic_id)` in the `GATE:`, and no `OUTCOME:` on any `CHOICE:` branch. Affected: `post_office_clerk.dialogue` (`ophion_club_mail`), `county_clerk.dialogue` (`wage_claim_inquiry`), `gazette_editor.dialogue` (`press_the_arithmetic`), `local_historian.dialogue` (`dr_fenn_library`), `mr_vale.dialogue`/`quay_bookkeeper` (`missing_cart`), `mr_whitehouse.dialogue` (`name_the_dead`), `school_parent.dialogue` (`the_estate_talk`), and `widow_kessler.dialogue` (`butcher_parcels`). The interim fix (that day) added `NOT topic_done(npc, topic_id)` to each `GATE:`, making all eight permanently one-shot. Confirmed this pass: Codex has since migrated all eight to the resolution-with-recap mechanism above — each `CHOICE:` now carries its own `OUTCOME:`, and the interim `NOT topic_done(...)` clause has been removed from every one of the eight `GATE:` lines, verified directly against the current source of all eight files. They are no longer permanently one-shot; each now recaps its chosen branch on revisit per the mechanism above.**

## **CHOICE:/FORK: Shared Interpreter and Consequential Outcomes**

**`FORK:` choices still hardcode Walter as the player speaker and remain silent in Chapter One — no voice cue plays for a fork prompt itself. `VOICE:` immediately before `FORK:` is deliberately rejected; spoken lines inside a branch can carry normal voice cues. The project extends this interpreter for Chapters Two and Three rather than replacing it, so protagonist labeling and full spoken-audio playback must become chapter-provided concerns before their dialogue is integrated — see Part Four. `OUTCOME:` (above) now supplies the persistent, once-only choice residue needed across all three chapters; existing `CHOICE:`\-only forks keep their current replay behavior.**

## **Presentation Frame — current state**

**Dialogue cards, NPC topic menus, and Walter's response menus share the warm wood-and-brass conversation frame. Physical examinations use a separate blue-gray archival frame — a deliberate visual split between "talking to someone" and "examining something," rather than one generic panel style for all player-facing text. The shared card renderer keeps the Continue control anchored to the bottom of the presentation frame regardless of text length, so a short line and a long line don't shift where the player's eye goes to advance.**

## **Background NPC Template Extension — resolved, closed**

**Codex confirms `background_npc_template` is back to the correct `.dialogue` extension; this document's own read of the delivered zip already showed no `.dialogue.txt` anywhere in the corpus. No further action needed.**

## **Dialogue Authoring System — provenance**

**The dialogue grammar and interpreter (`dialogue_lang.gd`, `dialogue_runtime.gd`, `dialogue_state.gd`) were designed and built by the project's author working with a Claude Sonnet instance in VS Code. Codex's role extends beyond integration: live-wiring the interpreter into actual play, subsequent fixes and extensions to the interpreter itself — including the schedule-alias handling in `dialogue_catalog.gd`'s `slot()`, the `VOICE:`/cue-manifest extension, and the `WEIGHT:`/`OUTCOME:` extensions confirmed above — and authoring `docs/DIALOGUE_AUTHORING.md` (September 10, kept current since) as a writer-facing reference, confirmed substantively accurate against the interpreter's actual behavior. Codex also maintains its own parallel copy of this document directly against source (currently at its own v18); this revision reconciles this project-doc copy against that source of truth rather than letting the two drift further apart.**

# **Part Four — Architecture Decisions Needed**

**CHOICE:/FORK: the shared-interpreter decision is settled. Chapters Two and Three will extend the same parser/runtime. Before Chapter Two dialogue lands, the hardcoded Walter choice label must move to chapter-provided protagonist identity, and its full-voice asset contract must be added without breaking Chapter One's instrumental cues. `OUTCOME:` now supplies the persistent, once-only choice residue needed across all three chapters — this part of the decision is closed, see Part Three.**

**Odell-precinct topic-gate namespace defect — resolved, closed. All three precinct topics now gate on `topic_done(odell_precinct, ...)`, with regression coverage for location-specific completion.**

**Story-actor vs. catalog-resident staging — clarified, not a defect. See Part Three. Two legitimately separate systems, not one system applied inconsistently.**

**`$84,000` formatting — RESOLVED, closed 2026-09-12. See Part Three. Plain text-rendering defect caused by the `$` character; fixed by spelling the amount out in words with no currency symbol or numerals.**

**Revelation pacing — resolved as policy. Invent freely now, prune deliberately later, per the author.**

**`WEIGHT: n` on `TOPIC: default` — IMPLEMENTED, confirmed 2026-09-12 against source and test. See Part Three for the full confirmed mechanism. No further work needed on the feature itself; `docs/DIALOGUE_AUTHORING.md` already documents it for authors.**

**`FORK:`/`OUTCOME:` one-time resolution — IMPLEMENTED, confirmed 2026-09-12 against source and test. See Part Three. Closes the former "repeatable forks" item below.**

**Fork revisit-with-recap pattern — IMPLEMENTED, confirmed 2026-09-12 against source and test. See Part Three, "`FORK:`/`OUTCOME:` Resolution With Recap." Raised while fixing the eight unprotected forks (Part Three): the original one-shot fix (`NOT topic_done(npc, topic_id)`) retired the whole topic permanently, so a player who picked `CHOICE` A could never revisit that NPC to be reminded what A said. This document's own first proposal (a companion `TIME: 0` recap topic per branch, tripling topic count) was never built. Codex instead built a cheaper, simpler mechanism directly in the runtime: `topic_available()` no longer excludes a topic once its outcome resolves, and `_locked_fork_options()` narrows the `FORK:` to only the chosen branch on replay — no companion topics, no extra `decision_id` bookkeeping beyond the `OUTCOME:` already on each `CHOICE:`. Confirmed by direct source reading (`dialogue_runtime.gd`) and by `tests/dialogue_template_flow.gd`'s explicit assertions. All eight of the originally-unprotected forks have been migrated to this mechanism (confirmed against their current source — see Part Three). Reported but not independently source-confirmed this pass: Captain Odell has one fork left deliberately one-shot, because it's his automatic opening/intake conversation; no `FORK:` was found in `odell_precinct.dialogue` itself, so that conversation likely lives elsewhere (a hardcoded intake flow, not a `.dialogue` file) — worth tracing if it ever needs to change.**

**Tunnel exhausted-resources fail state — still open, unchanged.**

**Conversation-time/travel-time scale mismatch — open, diagnosed, no solution chosen, 2026-09-12.** **The author observed that talking to an entire district's worth of NPCs never advances `DayClock.phase()`. Root cause, confirmed against source: two separate time-charging mechanisms coexist. `day_clock.gd`'s `CONVERSATION_MINUTES = 30.0` only fires for a small enumerated list of legacy story-scene conversations (the `ESTATE_TALKS`/`TOWN_TALKS` dictionaries — `boy`, `assistant`, `gardener`, `identify`, `behan`, etc.), not for ordinary dialogue-file topics. Regular `.dialogue` file topics instead go through `dialogue_runtime.gd`'s `commit_through()`, whose real default is `const DEFAULT_MINUTES = 3.0` — matching the author's original recollection exactly. The author has already authored explicit `TIME:` overrides on 38 of the 42 current dialogue files (values mostly 3–10, some to 15, several deliberate 0s for pure description beats), so the grammar is not unused, contrary to this document's own initial (incorrect) read during this pass. The actual problem is scale: `TRAVEL_MINUTES = 30.0` is roughly 10x `DEFAULT_MINUTES = 3.0`, so almost all of a day's clock movement comes from crossing between districts, not from conversation length — a full local roster of NPCs can be exhausted for a fraction of what one district crossing costs, which is why `phase()` never moves during a district-local conversation binge. Two directions were named but neither chosen: raise conversation-time costs enough to rival travel (e.g., defaults closer to 10–15 rather than 3–5), or shrink the phase thresholds (`NOON`/`EVENING`/`NIGHT`) to match the scale conversations already operate at. **Third factor, confirmed against source, 2026-09-12: a passive real-time tick also runs independently of conversations and travel.** `chapter_one.gd`'s `tick_world(delta)` calls `DayClock.advance(state, delta*DayClock.WANDER_RATE)` every frame while `page == "play"`, where `WANDER_RATE = 5.0/60.0` — the clock advances 5 game-minutes per real-time minute regardless of what the player is doing, including standing still. At that passive rate alone, the full `MORNING`-to-`NIGHT` span (840 minutes) elapses in about 168 real minutes (2.8 real hours) of simply being in the free-roam world, with zero conversations or travel. So an idle or wandering player still eventually runs out of day on this passive tick alone — the scale mismatch above is specifically about conversation/travel activity failing to move the clock in proportion to what the player is doing, not about the clock being unable to move at all. **Fourth factor, confirmed against source, 2026-09-12: the author's own playtesting moves through the world at an inflated, dev-only speed.** `main.gd` sets `speed = 10.5` (accel `39.0`) when the `brisk` action (Shift) is held, versus `2.15` (accel `13.0`) normal walk — roughly 4.9x, and per the author this brisk value is itself already 3x whatever brisk speed is intended to ship at. Since `WANDER_RATE` accrues against real elapsed seconds, not distance travelled, moving between NPCs and exits at this speed sharply reduces the real time — and therefore the passive game-minutes — spent in transit compared to a normal-speed player. This means the author's own impression that "time isn't moving fast enough" is being formed at a movement speed no shipped player will ever use, on top of the conversation/travel scale mismatch already logged above — any tuning decision here should be re-checked at normal (non-brisk, or intended ship-speed) movement before being treated as representative. Not a priority while investigation logic is the focus — recorded for later tuning, by feel, once revisited. See Part Six.**

**Missable-NPC redundant-carrier pattern — open, audited, no backups authored yet, 2026-09-13.** **Design goal, stated by the author: NPCs should stop being schedule billboards you can look up and walk to with certainty. If a scheduled NPC is genuinely missed (their window passes, or a future revision adds real absence beyond `SCHEDULE:`'s current fully deterministic `(npc, phase) → location` lookup — confirmed against `dialogue_catalog.gd`'s `slot()`, which has no chance element of any kind today), the fact they would have supplied should still be reachable through a different NPC, differently worded — "the same info in a word salad." No new engine mechanism is needed for this: the existing `EVIDENCE:` / `GATE: ... AND NOT evidence(id)` idiom already does the whole job, the same idiom already used for `crew_omission`'s six-NPC worded-differently convergence, just aimed at redundancy instead of flavor (that pattern itself grants no `EVIDENCE:`, only a `NOTEBOOK:` note, so it doesn't appear in the audit below). The real work is authoring: deciding which facts need a backup carrier and writing one.**

**Audit performed this pass, direct source scan of all 42 `.dialogue` files (excludes `lodging`-style facts granted by examining an object rather than talking to an NPC, and excludes the `{generated}` authoring-template's example ids):**

- **88 distinct `EVIDENCE:` ids exist across live dialogue. 87 of them are granted by exactly one `(NPC, topic)` pair — a single point of failure each. Only one id, `eight`, has more than one source.**
- **15 of the 88 come from the game's 9 fixed-appointment NPCs (`almy`, `assistant`, `boy`, `crew`, `father_behan`, `gardener`, `odell`, `old_woman`, `steward` — identified structurally as the only dialogue files with no `SCHEDULE:` header at all). These are guaranteed encounters tied to case progression, not something a schedule-timing miss can cost the player, so they're lower priority for this specific pattern even though they're technically single-sourced too.**
- **The remaining 74 come from `SCHEDULE:`-driven town/business/lower/waterfront/upper NPCs — these are the real candidates, since they're the ones a future "you may not find them" mechanic would put at risk. All 74 currently have zero backup carrier.**
- **`eight`'s two sources (`odell`/`default` and `assistant`/`default`) are both fixed-appointment NPCs, not an example of the redundancy pattern working as intended — it's coincidental, not authored backup.**

| Evidence ID | Source NPC | Topic | Kind |
|---|---|---|---|
| `ancestral_sixth_coat` | `tailor` | `the_sixth_jacket` | Scheduled |
| `behan_name` | `father_behan` | `behan_name` | Fixed |
| `boy_century_slate` | `schoolteacher` | `the_slain_boy` | Scheduled |
| `boy_district_refusal` | `schoolteacher` | `the_slain_boy` | Scheduled |
| `boy_pebble_survey` | `salt_mender` | `naomi_and_the_boy` | Scheduled |
| `bulk_opium_spirits` | `apothecary` | `fenn_laudanum` | Scheduled |
| `cart_record_missing` | `quay_bookkeeper` | `missing_cart` | Scheduled |
| `cart_unsigned` | `quay_bookkeeper` | `missing_cart` | Scheduled |
| `cedar_camphor_buyer` | `chandlers_boy` | `cash_buyer_details` | Scheduled |
| `cellar_candles` | `stationer` | `fenn_orders` | Scheduled |
| `cellar_desiccation_practice` | `ropewalk_foreman` | `cellar_salt` | Scheduled |
| `cellar_speakeasy_revealed` | `lamplighter` | `cellar_whispers` | Scheduled |
| `chandlery_island_delivery` | `chandlers_boy` | `island_delivery` | Scheduled |
| `civic_arithmetic` | `mr_whitehouse` | `subscriptions_and_credit` | Scheduled |
| `claim_filed_inert` | `county_clerk` | `wage_claim_inquiry` | Scheduled |
| `claim_no_claimant` | `county_clerk` | `wage_claim_inquiry` | Scheduled |
| `club_devotion` | `steward` | `club_devotion` | Fixed |
| `club_foreign_freight` | `post_office_clerk` | `ophion_club_mail` | Scheduled |
| `club_talk` | `steward` | `club_talk` | Fixed |
| `crew` | `crew` | `default` | Fixed |
| `curated_history` | `miss_wexley` | `museum_story` | Scheduled |
| `curriculum_abridgment` | `local_historian` | `crew_omission_followup` | Scheduled |
| `displaced_god_doctrine` | `local_historian` | `dr_fenn_library` | Scheduled |
| `dory_night_crossing` | `ropewalk_foreman` | `island_confirmed` | Scheduled |
| `drafting_linen_diagram` | `stationer` | `naomi_supplies` | Scheduled |
| `eight` | `assistant` | `default` | Fixed |
| `eight` | `odell` | `default` | Fixed |
| `estate_conduit_map` | `local_historian` | `dr_fenn_library` | Scheduled |
| `estate_day_book` | `steward` | `day_book` | Fixed |
| `estate_freight` | `quay_bookkeeper` | `estate_freight` | Scheduled |
| `estate_private_driver` | `quay_docker` | `estate_freight_carts` | Scheduled |
| `eye_anchoring_discipline` | `net_seller` | `copper_rings` | Scheduled |
| `fabricated_foul_air` | `gazette_editor` | `gas_main_origin` | Scheduled |
| `fenn_camphor_taboo` | `school_parent` | `the_estate_talk` | Scheduled |
| `five_tailored_coats` | `tailor` | `cut_jackets` | Scheduled |
| `freeman_lineage_free` | `local_historian` | `the_free_crew` | Scheduled |
| `freeman_whisper` | `miss_wexley` | `freeman_claim` | Scheduled |
| `fused_hairspring_anomaly` | `clockmaker` | `the_stopped_watch` | Scheduled |
| `gazette_correction_printed` | `gazette_editor` | `print_correction` | Scheduled |
| `gazette_correction_terms` | `gazette_editor` | `correction_terms` | Scheduled |
| `gazette_leverage` | `gazette_editor` | `press_the_arithmetic` | Scheduled |
| `gray_salt_cakes` | `widow_kessler` | `butcher_parcels` | Scheduled |
| `harbor_children_discipline` | `schoolteacher` | `the_drowned_island` | Scheduled |
| `heavy_subterranean_tackle` | `ropewalk_foreman` | `estate_mooring_cable` | Scheduled |
| `inland_subsea_current` | `net_seller` | `harbor_currents` | Scheduled |
| `insurance_fraud_record` | `county_clerk` | `ophion_settlement` | Scheduled |
| `island_memory` | `harbor_observer` | `drowned_island` | Scheduled |
| `kelp_salt_preservative` | `fish_smoker` | `gray_salt_cakes` | Scheduled |
| `kessler_carriages` | `widow_kessler` | `club_standing` | Scheduled |
| `kessler_knife_confirmed` | `widow_kessler` | `the_knife` | Scheduled |
| `lay_lead` | `almy` | `lay_lead` | Fixed |
| `lay_publicity_refused` | `gazette_editor` | `press_the_arithmetic` | Scheduled |
| `lay_record_method` | `quay_bookkeeper` | `old_lay` | Scheduled |
| `legal_claim` | `sebastian_wick` | `claim` | Scheduled |
| `maternal_delusion` | `widow_kessler` | `the_mother` | Scheduled |
| `naomi` | `almy` | `identify` | Fixed |
| `naomi_moral_clarity` | `salt_mender` | `naomi_and_the_boy` | Scheduled |
| `naomi_quay_inquiry` | `quay_docker` | `naomi_sighting` | Scheduled |
| `naomi_unapologetic_presence` | `school_parent` | `the_stranger_woman` | Scheduled |
| `new_bedford_letters` | `post_office_clerk` | `naomi_letters` | Scheduled |
| `no_water_lungs` | `coroners_assistant_morgue` | `day_two_table` | Scheduled |
| `observer_color_tell` | `harbor_observer` | `the_ring` | Scheduled |
| `observer_stone_discipline` | `harbor_observer` | `estate_grounds_crew` | Scheduled |
| `old_woman` | `old_woman` | `default` | Fixed |
| `ophion_myth_classical` | `local_historian` | `ship_origin` | Scheduled |
| `overseer_deed` | `county_clerk` | `sixth_member_deed` | Scheduled |
| `pantry_lead` | `steward` | `pantry_lead` | Fixed |
| `postal_bureaucracy_refusal` | `post_office_clerk` | `holding_the_letters` | Scheduled |
| `postal_overseer_statements` | `post_office_clerk` | `ophion_club_mail` | Scheduled |
| `press_suppression` | `gazette_editor` | `the_omitted_two` | Scheduled |
| `quay_inquiry` | `quay_bookkeeper` | `unfamiliar_woman` | Scheduled |
| `reader_omission_letter` | `schoolteacher` | `reader_letter` | Scheduled |
| `ridge_haste` | `mrs_pell` | `servant_talk` | Scheduled |
| `ridge_sighting` | `miriam_ashcroft` | `naomi` | Scheduled |
| `sanitized_textbook` | `schoolteacher` | `town_founding` | Scheduled |
| `serpent_hem_motif` | `tailor` | `coat_lining` | Scheduled |
| `service_work` | `almy` | `service_work` | Fixed |
| `silence_is_choice` | `mr_whitehouse` | `name_the_dead` | Scheduled |
| `steward_heard_secondhand` | `steward` | `default` | Fixed |
| `stone_sinker_discipline` | `net_seller` | `stone_sinkers` | Scheduled |
| `sub_harbor_drag` | `salt_mender` | `night_sounds` | Scheduled |
| `sulfur_shell_perimeter` | `crew` | `perimeter_trench` | Fixed |
| `testimony` | `assistant` | `default` | Fixed |
| `tryworks_metal_patina` | `clockmaker` | `tryworks_instruments` | Scheduled |
| `tryworks_silt` | `widow_kessler` | `butcher_parcels` | Scheduled |
| `tryworks_timber_freight` | `quay_docker` | `estate_freight_carts` | Scheduled |
| `turned_mirrors` | `school_parent` | `the_estate_talk` | Scheduled |
| `unlit_night_cart` | `drayman` | `night_freight` | Scheduled |
| `water_corrosion_inquiry` | `apothecary` | `the_stranger_remedies` | Scheduled |

**Next step is triage, not authoring: the author decides which of the 74 "Scheduled" rows are case-critical enough to need a backup carrier versus which are fine to simply lose on a miss, then a specific pair (or small group) gets authored per chosen fact. Not started. See Part Six.**

**Voice-cue library replacement pipeline — complete for the present 144-cue architecture. The game uses reusable cue IDs, not one recording per line. `tools/build_elevenlabs_voice_library.py` converts the completed 228-file ElevenLabs source batch into the stable twelve-styles/three-lengths/two-takes game matrix. Trombone takes map to complementary delivery styles; violin length variants use pitch-preserving cadence changes from the supplied mood takes. The output is normalized mono 44.1 kHz 16-bit PCM, and the generated manifest preserves source-to-cue provenance. The broader source vocabulary remains available for later selective expansion without forcing dialogue changes now. This closes out this document's own earlier "not a strict drop-in, compatibility mapping planned but not yet built" language (v18–v20) — the mapping is built and shipping.**

# **Part Five — Open Production Questions**

**Ekon's fatal outcome and the preservation/denial archive mechanic are already fully specified in Bible v15; what remains open is narrower — whether his final action includes lighting a sealing fuse, as distinct from the archival "sealing" the bible already describes.**

**The per-protagonist presentation scheme remains unwritten and not currently being worked on. Chapter Two/Three audio is explicitly still deferred. Chapter One now has a confirmed, working instrumental-voice-cue architecture, but that is a Chapter One-scoped implementation, not a decision about Chapters Two or Three. Whether Chapter Two/Three dialogue extends the same cue system, adopts something else, or goes fully voiced for the player character remains open and untouched, and should stay off any "in progress" list until the author actually takes it up. The contiguous-town preference is no longer a stated long-term item only — see v25/v26 and Part Six: Phase 1 is an active branch with six steps landed as of 2026-09-13. This line is corrected in place rather than left stale. The HPLHS pitch remains a long-term aspiration only.**

# **Part Six — Next Steps**

**Unchanged production direction: *validate and improve the first 30 minutes of investigation — discovery, social consequences, evidence linking, and a compelling next lead — before expanding production toward the chapter's climax.***

**In priority order:**

1. **A cold playthrough of the newest development revision specifically, distinct from the frozen Web build, focused on whether the opening 30 minutes' three investigative threads (Part Three) — the historian/schoolteacher chain, the steward appointment progression, and the newspaper-correction thread — actually land for a first-time player and produce a compelling next lead, now including the waterfront hub, the confirmed voice-cue system, and the two dialogue-grammar extensions confirmed implemented this pass. This is a diagnostic step; per Part One, it does not authorize replacing the frozen Web build regardless of outcome.**  
2. **Address whatever that playthrough surfaces in the opening 30 minutes before touching anything past it.**  
3. **\~\~Fix the `odell_precinct` topic-gate namespace defect (Part Three/Four)\~\~ — RESOLVED, 2026-09-12. Precinct conversations now resolve once rather than remaining repeatable.**  
4. **\~\~Implement `WEIGHT:` on `TOPIC: default` and `FORK:`/`OUTCOME:` one-time resolution (Part Three/Four)\~\~ — RESOLVED — both were already implemented and confirmed this pass against source and test. No implementation work remains; only ordinary authoring use of them going forward.**  
5. **Migrate `mrs_ashcroft.dialogue`, `mrs_whitlock.dialogue`, and `mr_wick.dialogue` to the documented `morning/midday/evening/night` schedule vocabulary — still accurate and unchanged: these three files continue to use `dawn` and placeholder destinations. A consistency cleanup for the catalog-resident system specifically, with no night-placement consequence either way (Part Three).**  
6. **~~Confirm or rule out the `$84,000` rendering item live.~~ — RESOLVED, 2026-09-12. Text-rendering defect from the `$` character; fixed by spelling the amount out in words, with no numerals (Part Three).**  
7. **Playtest the completed ElevenLabs compatibility library in context and hand-tune individual `VOICE:` assignments only where delivery clashes with the written line. The stable 144-cue replacement and source mapping are complete.**
8. **~~Fork revisit-with-recap pattern (Part Three/Four)~~ — RESOLVED, 2026-09-12. Codex implemented resolution-with-recap directly in the runtime (`_locked_fork_options()`), confirmed against source and `tests/dialogue_template_flow.gd`; all eight previously one-shot-protected forks are migrated. Remaining loose end: Odell's reported one-shot intake fork is not yet traced to its actual source location — low priority, note only.**
9. **Conversation-time/travel-time scale mismatch (Part Four) — diagnosed, no solution chosen. Not a priority while investigation logic is the focus; revisit and pick a direction (raise conversation costs, or shrink phase thresholds) once ready to tune day-clock pacing.**
10. **Missable-NPC redundant-carrier pattern (Part Four) — audited, no authoring done. 74 candidate facts identified (schedule-driven NPCs, single-sourced). Next step is author triage of which facts need a backup carrier, not further auditing.**

**Active, not a future item: contiguous-town Phase 1 (see v25/v26, and Part Six item 11).**
11. **Contiguous-town Phase 1 — active branch `dev/contiguous-town-phase-1`, six steps landed 2026-09-13 (see v26). Remaining, per Codex: profile the complete exterior on desktop and Web before any streaming/LOD/model-upgrade work. No Web export produced yet for any step.**

**Explicitly not current priorities: the ontological break and fatal-comprehension ending; Chapter Two's playable slice and trinket/procedural-geometry pipeline; the Chapter Two/Three audio-pipeline architecture decision (Chapter One's completed voice-cue work does not change this — see Part Five); the per-protagonist presentation scheme; Ekon's sealing-fuse staging detail; the Part Seven difficulty screen and achievement registration; gamepad support and full key rebinding; and any further work toward the HPLHS pitch.**

&nbsp;

&nbsp;
