**THREE COLORS OF MADNESS**

***Technical Design Document***

**Internal working document. Not for external distribution. Companion to the Design Bible.**

**Dejunai (founder, author/producer; lead on dialogue content specifically) · Claude Sonnet (co-author, co-designer — designed and built the dialogue grammar and interpreter with the author in VS Code, and separate VS Code Claude Sonnet sessions built the object-evidence and portal authoring systems under the author's lead) · Codex (core programmer — live integration of the dialogue/object/portal systems into play, interpreter fixes and extensions, and independent review of new systems against source) · Antigravity (dependency/gate auditing and dialogue-content execution under the author's lead) · Manus AI (independent outside source-backed repository audit) · Perplexity (research support for dialogue content) · Copilot 365 (ideation support for dialogue content)**

## **Contents**

**Part One — What This Document Is**

**Part Two — Current Build**

**Part Three — Architecture As Built**

**Part Four — Architecture Decisions Needed**

**Part Five — Open Production Questions**

**Part Six — Next Steps**

# **Part One — What This Document Is**

**This is the Technical Design Document (TDD) for Three Colors of Madness. It is the companion to the Design Bible, not a replacement for any part of it.**

**The division between the two documents is simple. The bible owns the what and the why — thesis, Design Laws, narrative, the meaning of every mechanic. This document owns the how — engine architecture, data schemas, production sequencing, and the specific open questions a playtest still needs to settle before a mechanism the bible describes gets its final shape. Where the two documents ever appear to disagree, the bible is correct and this document is wrong until revised — never the reverse.**

**This is v43. As of this revision, the document is split in two: this file holds only the current, settled state of the build — what's implemented, how it works, what's still open — and a separate Historical Change Log (`docs/design/TCM_Historical_Change_Log.md`) holds the revision-by-revision record of how the project got here. Update this document going forward to state the current truth plainly; log the story of the change in the HCL instead of in this file's prose.**

# **Part Two — Current Build**

## **Engine and Target**

**Godot 4.7 (the Web export identifies as 4.7.2.stable), using the GL Compatibility renderer (not Forward+), targeting broad hardware reach over cutting-edge rendering fidelity. Window target 1440×900, canvas-items stretch mode. No import dependencies beyond the engine itself.**

## **Scope of the Current Slice**

**The Ophion estate grounds (rose garden, service passage, tunnel entry), Pickman Street (boardinghouse, cobbler's shop/Walter's room, precinct, morgue), three neighborhood hubs (business district, upper-residential ridge, lower-residential quarter), a post office, and the waterfront: a playable outdoor hub with scheduled residents, its own travel time, full save restoration, and the offshore whaling station visible as unreachable scenery.**

**Geography is contiguous, not hub-and-spoke. Phase 1 (Pickman Street, business district, upper ridge) and Phase 2 (lower district, full waterfront) are one shared walkable exterior; only interiors remain separate scenes. Desktop baseline for the complete town: 113.56 ms construction, 2,284 nodes, 71.84 MiB static memory.**

**The day/night clock drives scheduled-resident placement, and separately drives the sun, directional lighting, fog color, and street-lamp visibility, purely as presentation. The clock does not govern body removal. Story progression does: the rose-garden bodies clear after the player's first departure to town; the birch victims (the woman and boy) remain visible and unattended through at least a second estate visit and clear only once Day 3 has begun, with no accompanying scene or notification either time.**

**The live dialogue system spans 70 NPCs and 438 nonempty authored `TOPIC:` blocks (`tests/dialogue_catalog_flow.gd`). This figure moves as content authoring continues; re-derive rather than trust this snapshot indefinitely. Real cross-NPC and paperwork-gated content exists beyond simple witness menus — see Part Three.**

**Wordless instrumental voice cues are implemented across every authored NPC line. 705 NPC lines currently carry a voice cue (`tests/instrument_voice_flow.gd`), drawn from a 144-entry cue manifest (a cue is reused across every line tagged with it — this is not one recording per spoken line). See Part Three for the architecture. Walter, narration, beats, objects, notebook entries, and system text are intentionally silent by design, not by omission.**

**The completed ElevenLabs Sound Effects delivery contains 228 source recordings; a documented compatibility build (`tools/build_elevenlabs_voice_library.py`) maps the broader trombone vocabulary and supplied violin mood takes onto all 144 stable game cue IDs, so every `.dialogue` file's `VOICE:` assignments remain valid without source-file changes. Trombone takes map to complementary delivery styles; violin length variants use pitch-preserving cadence changes from the supplied mood takes. Output is normalized mono 44.1 kHz 16-bit PCM, with a generated manifest preserving source-to-cue provenance. The broader ElevenLabs source vocabulary remains available for later selective expansion without forcing dialogue changes now.**

**Object-evidence content is authored in a parallel flat-file grammar rather than hardcoded in GDScript. All eleven scoped hotspots (estate's seven, town's three, tunnel's one) are migrated and live — see Part Three, "Object-Evidence Authoring System," and Part Four for the two known, accepted limitations carried forward as open items.**

**The Day 2 montage no longer plays on a new playthrough; Day 2 is now enacted, playable content culminating in the steward's second visit — see Part Three, "Three Separate Investigative Threads," item 2.**

**Not yet implemented: the glass-shattering ontological break, the fatal-comprehension ending, Chapters Two and Three as playable slices, gamepad support, full key rebinding, a full encumbrance/leveling system, and Ekon's later consumption of Walter's record.**

## **Saves**

**`CaseState.VERSION` is 11.**

## **Verification**

**A real Godot 4.7.2 standard executable is available (distinct from the mono-only editor used for the earlier native staging-suite pass, which could run gameplay tests but not export Web builds). Current authoritative checks, run against it, pass:**

* **Dialogue catalog: 70 NPCs, 438 topics.**
* **Instrument voices: 144 cues, 705 NPC lines.**
* **Live dialogue flow: PASS.**
* **Usability and object interactions: PASS.**

**The WEIGHT/OUTCOME mechanism is confirmed by direct source read of `dialogue_lang.gd` (parser), `dialogue_runtime.gd` (selection/commit logic), and `dialogue_state.gd` (persisted outcome storage), plus `tests/dialogue_lang_flow.gd`'s coverage.**

**Direct source reading also covers `chapter_one_dialogue.gd` (the live dialogue adapter, its `allowed()` function specifically) and `chapter_one_staging.gd` (the steward's three-visit progression). The voice-cue architecture described in Part Three is confirmed against source. The author has played the build repeatedly and external testers have already surfaced real issues (an exit problem, a ledger problem, a linking problem) against the frozen Web build specifically. What remains unverified is a cold playthrough of the newest development revision, including its voice cues and the waterfront hub — confirming that revision plays correctly is a diagnostic step, not grounds to replace the frozen build; the frozen Web build remains the release artifact until the author says otherwise.**

**A new Web export exists in-repo (`build/web/`): `index.wasm` (~39.5 MiB), `index.pck` (~35.8 MiB), `index.js`, `index.html`, and icon assets. This is the newest development revision — the complete contiguous town plus live telemetry and the debrief pairing — exported to the tester-distribution format. No profiling/measurement has yet been run against it (`docs/qa/PHASE_ONE_WEB_PROFILE_HANDOFF.md` is written but not executed).**

# **Part Three — Architecture As Built**

## **Story Actors vs. Catalog Residents**

**`chapter_one_dialogue.gd`'s `allowed(g, actor)` function implements two genuinely different systems:**

* **Catalog-scanned additional residents (`extra_actors`, populated by `catalog.scan()` in `setup()`) are placed exclusively through `dialogue_catalog.gd`'s `slot()`, which returns an empty placement at night regardless of authored schedule. `SCHEDULE:` is a fully deterministic `(npc, phase) → location` lookup with no chance element.**
* **Story actors — Odell, the coroner's assistant (`assistant`), the groundskeeper (`crew`), the old woman, and the steward (`barman`) — have their own bespoke, state-driven availability rules in the same `allowed()` function, none of which reference the day/night clock: Odell and the assistant are available whenever `world == "estate"` and the estate isn't complete; the groundskeeper once the lounge has been exited; the old woman while in town and not yet recorded as evidence; the steward keyed to the lounge and whether Mrs. Almy has been spoken to. None of these actors hide at night.**

**Returning staff for later days are implemented: `odell_precinct` and `coroners_assistant_morgue` exist as live scheduled NPCs. `day_two_check`, `day_two_pressure`, and `day_three_final` test `topic_done(odell_precinct, ...)`, matching the identity under which the runtime records them; a regression test verifies each topic disappears after completion without conflating precinct Odell with the estate encounter.**

## **Three Separate Investigative Threads**

**Three separate threads, each with its own prerequisites, not chained together:**

1. **The historian/schoolteacher witness-count thread. `local_historian.dialogue`'s `crew_omission_followup` topic gates on `topic_done(local_historian, crew_omission_official) AND topic_count(crew_omission) >= 4 AND NOT topic_done(...)` — ask enough people, consistently tagged, before the historian goes further. `schoolteacher.dialogue` carries a related chain keyed off `evidence(naomi)` and `evidence(reader_omission_letter)`. This thread's own internal chain (historian → four witnesses → historian → schoolteacher) does not connect to either thread below.**
2. **The steward appointment thread. `chapter_one_staging.gd`'s `sleep()` blocks *sleeping* — not the first conversation — when `steward_visits == 0`, `intake_done` is false, or `evidence.has("naomi")` is false; while blocked, the player gets an "Get up" panel. Reaching the steward at all is gated separately, through `chapter_one_dialogue.gd`'s `allowed()`: the lounge itself only becomes reachable via the `service_entrance` travel action once `visited.has("almy")` is true, and the steward's dialogue is only `allowed` while `world == "lounge"` — so the real first-visit gate is "spoken to Almy, then travel to the lounge." Visit two is enacted, playable Day 2 content (see "Montage Removal / Day 2 Enactment" below), culminating in the steward's second visit, relocated to the smoking lounge and ending on `THE STEWARD: "Come back tomorrow, and don't bring your badge."` Completing it sets `day = 3` and `steward_visits = 2`. The substantive third encounter is gated by `case_state.gd`'s `steward_ready()`, which requires all four of `visited.has("almy")`, `day == 3`, `steward_visits >= 2`, and `coat == "Plain wool coat"` — the plain coat specifically, not just the day, is a real and separate requirement. This thread does not depend on the historian/schoolteacher thread or the newspaper thread.**
3. **The newspaper-correction thread, gated on a distinct mechanism: `filed()`, not `evidence()`. `gazette_editor.dialogue`'s `print_correction` topic requires `evidence(gazette_correction_terms) AND filed(eight) AND filed(naomi) AND filed(lodging)` and awards `EVIDENCE: gazette_correction_printed` on completion. `filed()` checks received report pages specifically, not the current evidence inventory — this thread depends on paperwork actually having been filed and received, separate from simply having collected the underlying evidence. `mrs_almy.dialogue`'s `show_printed_correction` topic gates directly on `evidence(gazette_correction_printed)`; once available, showing her the slip has her read Naomi's name aloud and acknowledge Walter's effort ("You brought back something I can read. Thank you."), recorded via `NOTEBOOK: correction_seen`.**

## **Montage Removal / Day 2 Enactment**

**The montage sequence (`scripts/chapters/montage_still.gd`) is disconnected from the active flow of a new playthrough — its art and code are not deleted, just unwired. Day 1 is unchanged (intake, Naomi ID, first steward visit). Sleeping ends Day 1 and returns control on Day 2 at 6:00 a.m., which has real content culminating in the steward's second visit, relocated to the smoking lounge, ending on the verbatim line `THE STEWARD: "Come back tomorrow, and don't bring your badge."` (`dialogue/steward.dialogue`'s `steward_second` topic, `GATE: day >= 2 AND day < 3 AND (topic_done(steward, steward_first) OR topic_done(steward, steward_first_lead))`). Sleeping before that second visit is blocked with a redirect back to the lounge. After the second visit, sleeping advances to Day 3 at 6:00 a.m.; the existing plain-coat third steward visit is unchanged.**

**Old-save resume is deliberately preserved: `chapter_one.gd::_load_game()` reads `elif state.montage_index >= 0: staging.draw_montage(self)` — gated entirely behind an old save already carrying a set `montage_index`, so the montage-resume path is structurally unreachable from a fresh game while remaining fully intact for anyone mid-montage on an existing save. `chapter_one_staging.gd` still contains the full still-renderer/montage-index logic, untouched.**

**Test coverage: `tests/steward_sleep_flow.gd`, `tests/day_clock_flow.gd`, `tests/dialogue_live_flow.gd`, `tests/staging_flow.gd`, `tests/town_flow.gd`. Nothing in the montage granted evidence, so nothing needed to move to the new Day 2 content; the new content has its own `GATE:`-driven pacing rather than inheriting the old montage's timing.**

## **`$84,000` Formatting — resolved**

**This was a plain text-rendering defect, not a deliberately engineered glitch: the `$` character did not render correctly in the wage-claim dialogue script. The fix removes the currency symbol from the source entirely — the amount is spelled out in words ("eighty-four thousand dollars"), with no numerals or symbol present anywhere in the corpus. All three known instances are fixed: two lines in `county_clerk.dialogue`/`odell_precinct.dialogue`, and a separately-found `NOTEBOOK:` entry in `county_clerk.dialogue`'s `clerk_ophion_1`.**

**Note: an AI-generated podcast circulated a "leaked design docs" narration describing this as an intentional, expensive UI glitch simulating real-time save-file corruption. That account is fabricated and is not a source for anything about this project.**

## **Instrumental Voice Cue System**

**The wordless instrumental voice pack is wired into every authored NPC line:**

* **`VOICE: cue_id` is authored immediately before an NPC's spoken line in the `.dialogue` source.**
* **The parser attaches that cue to the line as part of compilation.**
* **The runtime emits a `[speaker, text, voice]` triple per line.**
* **Chapter One plays the matching WAV when the dialogue card appears on screen, and stops it when the player advances past that line.**
* **A 144-entry manifest validates cue names during dialogue loading and automated content validation, catching typos or unregistered cue IDs.**
* **Instrument voice volume has its own independent mixer control, separate from music/SFX.**
* **Walter, narration, beats, object descriptions, notebook entries, and system text are intentionally silent — the voice layer characterizes NPCs the player interrogates, not the protagonist or the game's own narration.**

**The same parser and runtime is the shared foundation for Chapters Two and Three; the remaining work is to provide protagonist identity per chapter and support their full spoken-audio manifests — see Part Four.**

## **`WEIGHT:` on `TOPIC: default`**

**Ships in `dialogue_lang.gd`/`dialogue_runtime.gd`, covered by `tests/dialogue_lang_flow.gd`:**

* **`WEIGHT: n` (a positive number, not restricted to integers) is authored as line-level metadata inside a `TOPIC: default` block, alongside `GATE:`/`LABEL:` on that topic.**
* **Authoring on any topic other than `default` is a hard parse error — `"WEIGHT is only valid on TOPIC: default"`. A non-positive value (`WEIGHT: 0` or negative) is a second, separate parse error.**
* **Multiple `TOPIC: default` blocks are allowed, and the first eligible block controls selection. If unweighted, it wins deterministically, preserving specific-before-fallback gate cascades. If it carries `WEIGHT:`, the runtime draws only from eligible defaults that explicitly carry `WEIGHT:`; later eligible unweighted defaults remain outside the pool as deterministic fallbacks.**
* **No-immediate-repeat rule: the runtime tracks the winning default's source line per NPC (by source line, not line text; session-scoped, not saved) and excludes it from the next draw's pool, falling back to allowing a repeat only when excluding it would leave the pool empty.**
* **Defaults never appear as menu entries, weighted or not. Non-`default` topic IDs must stay unique per NPC; sharing a topic ID across different NPCs still intentionally supports `topic_count()`.**
* **Authoring guidance (`docs/DIALOGUE_AUTHORING.md`): use weighted defaults for interchangeable exhausted/ambient remarks, and keep required evidence, notes, progression, and unique information in deterministic (non-default) topics.**

## **`FORK:`/`OUTCOME:` Resolution With Recap**

**Ships in `dialogue_lang.gd`/`dialogue_runtime.gd`/`dialogue_state.gd`, covered by `tests/dialogue_template_flow.gd`:**

* **Inside a `FORK:` block, any `CHOICE:` branch may additionally contain `OUTCOME: decision_id = value_id` — both sides must be a simple identifier, or the parser raises a parse error. The chosen value is held as a pending outcome for the session and only committed to `dialogue_state.gd`'s `outcomes` dictionary once the branch finishes playing; `set_outcome()` refuses to overwrite an existing key, so a decision is immutable for the rest of the playthrough.**
* **`topic_available()` is pure `GATE:` evaluation — it does not inspect `outcome_keys`. A topic with a resolved `OUTCOME:` fork is NOT excluded from the NPC's menu.**
* **`render()` computes which of a topic's `outcome_keys` already have a recorded value (`locked_outcomes`), and when playback reaches a `FORK:` step, `_locked_fork_options()` filters the presented `CHOICE:` options down to only the one whose authored `OUTCOME:` matches what was already chosen — reopening a resolved fork's topic shows the full conversation again, with the fork menu narrowed to one option: the branch actually taken. The rejected branch cannot be reached again.**
* **Replay is genuinely free: `dialogue_state.gd`'s `record_fact()`, `discover()`, `complete_topic()`, and `set_outcome()` are all idempotent, and `commit_through()`'s `TIME:` charge is gated on `first_completion`, so replaying the locked branch fires no duplicate `NOTEBOOK:`/`EVIDENCE:` effects and charges no additional day-clock time.**
* **No separate authoring is required to get recap behavior — the same original topic replays itself, filtered. Net authoring cost for a fork opting into this is exactly `OUTCOME:` on each `CHOICE:` and nothing else.**
* **Forks using only `CHOICE:` (no `OUTCOME:`) keep their plain repeatable behavior — this stays opt-in per fork.**
* **Captain Odell has one fork that stays fully one-shot (his automatic intake conversation): it lives inside `odell.dialogue`'s `TOPIC: default` block (`GATE: NOT topic_done(odell, default)`), so it retires via the ordinary default-topic mechanism rather than an explicit `OUTCOME:`.**

## **`CHOICE:`/`FORK:` Shared Interpreter and Consequential Outcomes**

**`FORK:` choices hardcode Walter as the player speaker and remain silent in Chapter One — no voice cue plays for a fork prompt itself. `VOICE:` immediately before `FORK:` is a parse error; spoken lines inside a branch can carry normal voice cues. The project extends this interpreter for Chapters Two and Three rather than replacing it, so protagonist labeling and full spoken-audio playback must become chapter-provided concerns before their dialogue is integrated — see Part Four. `OUTCOME:` supplies the persistent, once-only choice residue needed across all three chapters.**

## **Presentation Frame**

**Dialogue cards, NPC topic menus, and Walter's response menus share the warm wood-and-brass conversation frame. Physical examinations use a separate blue-gray archival frame — a deliberate visual split between "talking to someone" and "examining something." The shared card renderer keeps the Continue control anchored to the bottom of the presentation frame regardless of text length.**

## **Dialogue, Object, and Portal Authoring Systems — provenance**

**The dialogue grammar and interpreter (`dialogue_lang.gd`, `dialogue_runtime.gd`, `dialogue_state.gd`) were designed and built by the project's author working with a Claude Sonnet instance in VS Code. Codex's role extends beyond integration: live-wiring the interpreter into actual play, subsequent fixes and extensions to the interpreter itself — including schedule-alias handling in `dialogue_catalog.gd`'s `slot()`, the `VOICE:`/cue-manifest extension, and the `WEIGHT:`/`OUTCOME:` extensions above — and authoring `docs/DIALOGUE_AUTHORING.md` as the writer-facing reference.**

**Dialogue-content provenance, distinct from the interpreter/engine provenance above: the author leads dialogue content specifically — the `TOPIC:`/`NOTEBOOK:`/`EVIDENCE:` writing and editorial judgment. Antigravity executes dialogue-content work under that lead, including the Stage 2 scheduled-life population pass and missable-NPC/fork-lock audits and fixes. Perplexity provides research support for dialogue content; Copilot 365 provides ideation support. Codex's own role remains interpreter/engine-side, distinct from this dialogue-content track.**

**The object-evidence system was built by the author working with a separate Claude Sonnet session in VS Code, under the author's direct lead — the same working pattern that produced the dialogue grammar and interpreter. `docs/OBJECT_AUTHORING.md`'s own byline currently credits "Copilot," a GitHub-tooling attribution stamp applied regardless of which agent actually wrote the code, not real attribution — both the author and the implementing agent prefer it credited as Claude Sonnet (VS Code); this is a correction still owed to that doc.**

**The portal authoring system was built the same way, under the author's direct lead, mirroring exactly how the dialogue and object systems were each built.**

## **Object-Evidence Authoring System**

**Replaces the prior state, where evidence like `lodging` lived scattered across GDScript object-interaction scripts — outside the dialogue system, invisible to any dialogue-only audit, and requiring engine-scripting fluency to touch. The replacement is a flat-file-per-object grammar authored in the same declarative style as `.dialogue` files: `GATE:`/`EVIDENCE:` are identical syntax to dialogue's. It is not a 1:1 reuse of the dialogue grammar — object files carry `TAKE: item_id` for pickup/collection, a directive dialogue files don't have.**

* **Parser/runtime/state: `scripts/shared/object_lang.gd`, `object_runtime.gd`, `object_state.gd`. `object_lang.gd` has explicit `is_valid_identifier()` checks and parse-time errors for `TAG`, `TIME`, `EVIDENCE`, `TAKE`, `OUTCOME`, `NOTEBOOK`, and `OBJECT` ids.**
* **`case_state.gd` moved to schema version 10, additively: `inventory`/`object_state` fields added, old save versions 1–9 still validate.**
* **All eleven scoped hotspot ids are migrated and wired: estate's seven (`wounds`, `eight`, `knife`, `watch`, `gas`, `register`, `shoes`), town's three (`gazette`, `lodging`, `exemption`), and tunnel's one (`tunnel_record`) — deliberately excluding NPC-stand-in ids (which stay in `.dialogue` files) and tunnel's bespoke game-logic ids (which belong in neither grammar). Real content lives in `objects/estate.object`, `objects/town.object`, `objects/tunnel.object`. `chapter_one.gd::_interact()` calls `objects.interact(self, "estate", id)`; `_town_interaction()`/`_town_observation()` call `objects.interact(self, "town", id)`; `_tunnel_interaction()` calls `objects.interact(self, "tunnel", id)` — through `scripts/chapters/chapter_one_objects.gd`, mirroring the shape of `chapter_one_dialogue.gd`.**
* **FORK/OUTCOME presents live choices through `chapter_one_objects.gd::_present_fork()`/`_choose()`, which calls `ObjectRuntime.resume()`. `LABEL:` drives hotspot hover text through `sync_points()`, which overwrites `points[id]["title"]` from the label on every sync.**
* **Old hardcoded fallback content (e.g. `tunnel_record`'s prior `_cards([["THE LAST SUPPORT",...)` call) is left physically present in `chapter_one.gd` but dead/unreachable — the function returns before reaching it once the object call succeeds. Not a bug; matches the migration doc's documented pattern.**
* **Known, accepted limitations, open items in Part Four: hotspot visibility is one-way only (`sync_points()` erases a hotspot once its `GATE:` goes false, but nothing restores it if the `GATE:` later becomes true again — not a live bug today, since every current `GATE:` is one-directional by nature); and unknown `GATE:` fields/functions still silently parse instead of raising an error.**
* **Documentation: `docs/OBJECT_AUTHORING.md` (grammar/authoring reference), `docs/OBJECT_MIGRATION_HOWTO.md` (migration recipe), `docs/ARCHITECTURE.md` (cross-cutting). Test coverage: `tests/object_template_flow.gd` (grammar/template mechanism), `tests/object_content_flow.gd` (the real shipped `.object` files and a live FORK through the adapter).**

## **Portal Authoring System**

**A third sibling to `.dialogue` and `.object`, not built on either. A travel point's defining content is *where it leads*, not what it says: alongside the same shared GATE grammar and id-cascade convention the object system established, its step vocabulary adds `GO: destination | x,y,z | yaw | flags`. Reaching a `GO` halts step processing immediately and hands control back to the caller, exactly like `FORK`, just with no choice to make — only `chapter_one_portals.gd`, never the shared runtime, actually calls `_travel()`. Content authored after a `GO` renders as arrival narration once the caller resumes via `Runtime.after_go()`.**

* **Parser/runtime/state: `scripts/shared/portal_lang.gd`, `portal_runtime.gd`, `portal_state.gd`, mirroring the object system's shape.**
* **`case_state.gd` moved to schema version 11, additively: `portal_state` added, old save versions 1–10 still validate.**
* **Ten unique portal ids are migrated and wired across five live `.portal` files: `service_entrance` and `exit` (`portals/estate.portal`, the latter locked/unlocked on `visited(almy)`); `street_precinct`, `street_almy`, `street_room`, `street_estate`, and `route_post` (`portals/town.portal`); `lounge_exit` (`portals/lounge.portal`); `route_speakeasy` (`portals/lower.portal`, phase/coat-gated, three blocks — a blocked attempt always surfaces an authored dialogue card, morning/noon-locked `CELLAR BULKHEAD` or coat-mismatch-locked `THE VIEWING SLIT`, never a toast); and `tunnel_exit` (`portals/tunnel.portal`, two destinations depending on `evidence(lower_foundation)`). A sixth file, `background_portal_template.portal`, is a documented cookbook/template containing only non-canonical `example_*` placeholder ids and contributes no live portal.**
* **`TIME:` semantics: `portal_lang.gd` always fills an omitted `TIME:` with the string `"3"`, a valid float. Every portal, whether `TIME:` is omitted (defaulting to 3) or explicitly authored (including `TIME: 0`), takes the same branch in `_perform_go()`: the amount is applied once, the first time this portal identity completes (checked via `portal_done()` before charging) — exactly like `object_runtime.gd::commit_through()`'s own `first_completion` guard for the equivalent object case.**
* **Cross-system sharing: `OUTCOME`/`flag()` read/write through the shared `dialogue_state` instance; `evidence()`/`filed()` reuse `dialogue_runtime.gd`'s helpers; `dialogue_runtime.gd` and `object_runtime.gd` both have matching `portal_done`/`portal_count` entries in `make_context()`, and `object_runtime.gd` also has `spoken_to`/`taken`. A `visited(id)` GATE function (reading `case_state.gd`'s `visited` array directly) exists because it is subtly stricter than `spoken_to(npc_id)` (true the instant a conversation merely begins, not once it fully finishes) — `service_entrance`'s gate needs the stricter sense.**
* **A small, explicitly named escape hatch (`_before_travel()`/`_extra_cards()` in `chapter_one_portals.gd`) handles the rare travel point whose post-arrival content is genuinely dynamic — computed from live state, not static prose — rather than forcing it into the flat grammar: currently `tunnel_exit`'s custody-result card (branches on which supplement was sent) and `lounge_exit`'s `state.lounge_exited` flag. Documented as a known, accepted limitation in `docs/PORTAL_AUTHORING.md`, matching the same principle the object/dialogue systems established for their own dynamic content. This is a settled design decision, not an open question.**
* **Test coverage: `tests/portal_lang_flow.gd`/`tests/portal_template_flow.gd` (parser/runtime, via `commit_through()`/`after_go()` calls) and `tests/portal_content_flow.gd` (drives every migrated route through the actual `chapter_one.gd` adapter in a live `main.tscn` instance, including `route_speakeasy` reached via a real `_travel("town", ...)` into the contiguous exterior, and a synthetic `TIME:`-bearing portal proving the once-per-identity charge).**
* **Documentation: `docs/PORTAL_AUTHORING.md`, mirroring `docs/OBJECT_AUTHORING.md`'s structure, including its own "known limitation" section for dynamic post-arrival content. `docs/ARCHITECTURE.md` and `README.md` both updated to match.**

## **Fail-Loud Guards**

**Design intent: stop broken or incomplete gate logic from letting an NPC or object go silently unresponsive — an NPC turning into an "unresponsive totem pole" — instead surfacing an obvious on-screen developer error. Implemented as one centralized check per system rather than duplicated boilerplate per file.**

* **Object-side: `chapter_one_objects.gd::interact()`/`_fail_loud()`. Fires when a hotspot the player can actually click (already present in the location's `.points`) resolves to no currently-eligible `GATE:` block. `push_error()`s and shows an on-screen "EOF ERROR — PLEASE ALERT THE DEVELOPERS" panel naming the location and object id. Lives in the chapter adapter, not the shared `object_lang.gd`/`object_runtime.gd`, because an object file having nothing eligible is often *correct* (the hotspot may simply not exist yet) — only the adapter, which already knows the hotspot is clickable, can distinguish the two cases.**
* **Dialogue-side: `chapter_one_dialogue.gd::interact()`, in the chapter adapter rather than the shared `dialogue_runtime.gd`. Fires when `Runtime.enter()` returns an empty session *and* the NPC's menu has zero eligible entries *and* the actor isn't `"odell"` (the documented exception, matching Odell's one-shot intake conversation and post-answer notebook dismissal). `push_error()`s `"DIALOGUE FAIL-SAFE: NPC '%s' has no eligible default or menu topics! (EOF Error)"` and shows a `[DEVELOPER WARNING]` / `"EOF Error: NPC '<npc_id>' has no available dialogue state. Please alert developers."` card.**
* **Documented in `docs/OBJECT_AUTHORING.md` ("Fail-loud: an unresolved hotspot is an error, not silence"), `docs/DIALOGUE_AUTHORING.md`, and `README.md`.**

# **Part Four — Architecture Decisions Needed**

**`CHOICE:`/`FORK:` shared-interpreter decision is settled: Chapters Two and Three extend the same parser/runtime. Before Chapter Two dialogue lands, the hardcoded Walter choice label must move to chapter-provided protagonist identity, and its full-voice asset contract must be added without breaking Chapter One's instrumental cues. `OUTCOME:` already supplies the persistent, once-only choice residue needed across all three chapters.**

**Tunnel exhausted-resources fail state — still open, unspecified.**

**Conversation-time/travel-time scale mismatch — open, diagnosed, no solution chosen. `day_clock.gd`'s `CONVERSATION_MINUTES = 30.0` only fires for a small enumerated list of legacy story-scene conversations (`ESTATE_TALKS`/`TOWN_TALKS`), not ordinary dialogue-file topics. Regular `.dialogue` topics go through `dialogue_runtime.gd`'s `commit_through()`, whose default is `DEFAULT_MINUTES = 3.0` (38 of 42 dialogue files have explicit `TIME:` overrides, mostly 3–10, some to 15, several deliberate 0s). `TRAVEL_MINUTES = 30.0` is roughly 10x `DEFAULT_MINUTES`, so almost all of a day's clock movement comes from crossing between districts, not from conversation length — a full local roster of NPCs can be exhausted for a fraction of what one district crossing costs, which is why `phase()` never moves during a district-local conversation binge. Two directions are on the table, neither chosen: raise conversation-time costs to rival travel (defaults closer to 10–15 rather than 3–5), or shrink the phase thresholds (`NOON`/`EVENING`/`NIGHT`) to match. A passive real-time tick also runs independently: `chapter_one.gd`'s `tick_world(delta)` calls `DayClock.advance(state, delta*DayClock.WANDER_RATE)` every frame while `page == "play"`, where `WANDER_RATE = 5.0/60.0` — the clock advances 5 game-minutes per real-time minute regardless of player action, so the full `MORNING`-to-`NIGHT` span (840 minutes) elapses in about 168 real minutes of simply being in the free-roam world. `main.gd` defines three movement tiers — `WALK_SPEED = 2.15`, `BRISK_SPEED = 4.0` (the intended shipping Shift-sprint, ~1.9x walk), and `DEVELOPER_BRISK_SPEED = 10.5` (~2.6x shipping brisk, opt-in via `[F3]`'s `developer_brisk` toggle, false by default and not save-persisted). Ordinary Shift-held play now runs at the intended ship speed by default. Not a priority while investigation logic is the focus — revisit by feel once ready to tune day-clock pacing.**

**Playthrough telemetry — built and deployed. A unique per-playthrough session id (no personal data in the log payload) tags a local event log. Metrics captured: real minutes from session start to the first meaningful objective; real and in-game minutes per district-to-district transition; distinct NPCs spoken to before each `DayClock.phase()` change; whether the player checks the Tab-menu pocket watch; misses of scheduled NPCs (reconstructed offline from logged location/timestamp events replayed against the deterministic schedule table, rather than detected live); real time to return to the boardinghouse and sleep at the end of Day 3; and two subjective impressions captured via the debrief pairing below.**

* **Mechanically loggable events funnel through existing chokepoints: district transitions and time at `chapter_one.gd`'s `_travel()`/`tick_world()` and `DayClock`; NPCs spoken to via `state.visited`, appended once per completed conversation in `_segment_done()`; phase changes via `DayClock.phase()`; the Day-3 sleep milestone via `sleep`/`day_close` targets.**
* **Debrief pairing — built, verified, hardened, and deployed: two single-tap optional questions shown once, right after the Day 3 "close_day" narrative cards resolve and before the town is marked finished (`chapter_one_staging.gd`'s `sleep()`, the Day-3-success branch, via `_debrief_town_feel()`/`_debrief_time_natural()`). First: a five-way choice ("Alive, and hard to fully take in" / "Confusing" / "Too large for the time given" / "Easy enough to navigate" / "Skip"). Second: Yes / No / Skip on whether time felt natural while investigating. Both answers land in one `debrief` event (`town_feel`, `time_natural`, each including `"skipped"`) via `playthrough_log.debrief()`. A `debrief_sent` guard prevents double-logging, and a `state.finished` early-return at the top of `sleep()` sends a revisit straight to the ending screen instead of replaying the close_day cards and debrief a second time. `day3_bed_reached()` is wired at the Day-3-success branch. Covered by `tests/playthrough_log_flow.gd` and `tests/debrief_flow.gd`.**
* **Transport: automatic upload, not manual download-and-send — chosen because the Web export's `user://`-written log files sit inside browser sandbox storage the author cannot retrieve directly. Tradeoff accepted: the log payload itself carries no personal data, but an ordinary web server's own access logs typically record the caller's IP address by default at the infrastructure level, separate from anything this project writes into the payload, unless the hosting is deliberately configured to avoid persistent IP logging.**
* **Hosting: `https://three-colors-worker.dejunai.workers.dev`, a Cloudflare Worker, source at `cloudflare/three-colors-worker/`. The Worker dual-writes every accepted event batch to both D1 and R2 in one `Promise.all` (`env.DB.batch(statements)` alongside `env.BUCKET_ONE.put(...)`). D1 writes are idempotent: `INSERT OR IGNORE INTO game_events (event_key, ...)`, `event_key` a SHA-256 hash of the JSON-stringified event, so a retried or duplicate batch cannot double-count. A `conversation` event type is allowlisted (`npc_id`, `topic_id`, `coat_state`, `world`, `day`, `phase`), `coat_state` restricted to `["police", "plain"]`, `phase`/`new_phase` restricted to `["morning","noon","evening","night"]`. Privacy: strict per-event-type field allowlisting, UUID-v4 session-id format validation, batch/size limits, CORS restricted to the real distribution origins (GitHub Pages, itch.io), and no request headers, IP, or user-agent ever written anywhere.**
* **Field normalization: real-seconds fields (`real_seconds_elapsed`, `real_seconds_since_day3_start`, `total_real_seconds`) are computed via `roundi(...)` (whole seconds) in `scripts/shared/playthrough_log.gd`, while `game_minutes_elapsed` retains `snappedf(..., 0.1)` (one decimal minute) — two different granularities on sibling fields of the same event; all D1 columns are typed `REAL` regardless.**
* **`conversation` events fire only once a dialogue segment's complete authored path finishes, from `chapter_one_dialogue.gd::_segment_done()` — opening a topic menu, abandoning a card sequence, and intermediate `FORK` segments are not counted as completed conversations. Reached either as `dialogue.start()`'s completion callback or via the resume-from-save path once `offset == segment.cards.size()`.**
* **The game side is wired into `chapter_one.gd`: `begin()`/`resume()` on new-game/load, `observe()` ticking every frame in `tick_world()` for phase/first-objective/NPC tracking, `district_transition()` at every `_travel()`, `end()` on both quit and completion; disables itself automatically under `test_mode` so QA runs don't pollute the log. Not yet exercised: an actual real tester playthrough (as opposed to automated tests) confirming events land in the bucket end to end.**

**Missable-NPC redundant-carrier pattern — authored. A full audit of all 42 `.dialogue` files found 88 distinct `EVIDENCE:` ids; only 35 are ever checked downstream at all; twelve of those are schedule-driven, single-sourced, and load-bearing — three from the newspaper-correction thread, three from the historian/schoolteacher thread, five from the freight/quay/Naomi-sighting cluster, one standalone:**

| Evidence ID | Source NPC | Topic | Thread | Downstream refs |
| ----- | ----- | ----- | ----- | ----- |
| `gazette_correction_printed` | `gazette_editor` | `print_correction` | Newspaper correction | 3 (incl. a `filed()` ending gate) |
| `press_suppression` | `gazette_editor` | `the_omitted_two` | Newspaper correction | 3 |
| `gazette_correction_terms` | `gazette_editor` | `correction_terms` | Newspaper correction | 2 |
| `reader_omission_letter` | `schoolteacher` | `reader_letter` | Historian/schoolteacher | 3 |
| `sanitized_textbook` | `schoolteacher` | `town_founding` | Historian/schoolteacher | 2 |
| `ophion_myth_classical` | `local_historian` | `ship_origin` | Historian/schoolteacher | 2 |
| `quay_inquiry` | `quay_bookkeeper` | `unfamiliar_woman` | Freight/quay/Naomi-sighting | 3 |
| `new_bedford_letters` | `post_office_clerk` | `naomi_letters` | Freight/quay/Naomi-sighting | 2 |
| `naomi_quay_inquiry` | `quay_docker` | `naomi_sighting` | Freight/quay/Naomi-sighting | 2 |
| `estate_freight` | `quay_bookkeeper` | `estate_freight` | Freight/quay/Naomi-sighting | 2 |
| `chandlery_island_delivery` | `chandlers_boy` | `island_delivery` | Freight/quay/Naomi-sighting | 2 |
| `kessler_carriages` | `widow_kessler` | `club_standing` | (standalone) | 2 |

**All twelve rows have a committed second-source topic, each granting the identical `EVIDENCE:` id as the primary source, so every existing downstream `GATE:` opens regardless of route taken, with no `chapter_one_archive.gd` LINKS changes required. Each backup topic's `GATE:` mirrors its primary topic's own precondition with `NOT evidence(id)` in place of the primary's `NOT topic_done(...)`. The other 63 `SCHEDULE:`-sourced facts are audited and marked no-backup-needed — nothing downstream depends on them. Generic grammar/template tests pass and `dialogue_catalog_flow.gd` parses the full corpus clean, but none of those tests exercise these twelve topic IDs specifically. Confirmed: the twelve topic/evidence pairs exist in source and parse. Not yet confirmed: each one's individual `GATE:` and runtime reachability, via an actual manual playtest.**

**Pocket watch HUD button — shipped. The `[Tab]` "Personal Effects" panel shows a working pocket watch reading `DayClock`'s exact current day, twelve-hour time, and phase, free of `TIME:` cost. Open follow-up: the readout is text (day/time/phase as numerals and words), which the author considers anachronistic for a 1920s-set pocket watch. The fix is purely visual — a proper analog clock face with hands and a twelve-hour dial, driven by the same underlying `DayClock` data; `DayClock` and the panel logic itself don't change. Not yet started.**

**Object-evidence hotspot visibility is one-way only — open. `sync_points()` erases a hotspot once its `GATE:` goes false, but nothing restores it if the `GATE:` later becomes true again. Not a live bug today, since every current `GATE:` in the shipped `.object` files is one-directional (e.g. `rose_bodies_removed`); would need addressing before any future object content relies on a hotspot reappearing.**

**Object-evidence unknown `GATE:` fields silently parse — open. An unrecognized field or function name inside a `GATE:` expression does not raise a parse error today; it's accepted and presumably evaluates as false or is ignored, rather than failing loud the way a malformed `TAG`/`TIME`/`EVIDENCE`/`OBJECT` id already does. A typo'd or misspelled `GATE:` condition could silently produce an always-unreachable hotspot instead of an authoring-time error.**

**NPC-to-NPC eavesdropping — a "thought-bomb" concept the author has explicitly deferred, not a priority and not being scoped or built now. One fixed, deliberately atmosphere-only eavesdropping interaction already exists (the `speakeasy_bar` overheard exchange — see Part Six), but no *general* proximity/eavesdropping system exists. Real gaps that would need closing before any general system is built: (1) no proximity-detection system exists — NPCs are plain `Node3D` primitives with no `Area3D` or collision shape, and the only "in range" logic anywhere (`chapter_one.gd`'s `_find_focus()`) is player-to-point, not point-to-point between two actors; (2) `VOICE:` cues are one-shot stingers tied to a dialogue line's on-screen appearance, not continuous or looping positional audio; (3) an eavesdropped exchange is a new shape in the dialogue DSL — two NPCs speaking to each other with no player choices and no `GATE:` gating Walter's participation, distinct from every existing `TOPIC:` block; (4) scheduling has no way today to deliberately place two specific NPCs together at one location/phase. One shape floated for later: two NPC models adjacent, a subtle looping instrument cue (trombone and violin mixed low) as a proximity sound cue, then a player-triggered eavesdropping action overhearing a short scripted exchange with Walter absent. Mr. Whitehouse and the school parent both currently resolve to `upper_house_3` in the evening per `dialogue_catalog.gd`'s `slot()` — an accidental collision, not an authored pairing, though a plausible first test case if this is ever built.**

**Voice-cue library replacement pipeline — complete for the present 144-cue architecture. `tools/build_elevenlabs_voice_library.py` converts the 228-file ElevenLabs source batch into the stable twelve-styles/three-lengths/two-takes game matrix. The broader source vocabulary remains available for later selective expansion without forcing dialogue changes now.**

**`tests/test_placement_audit.gd` parse error — open. Running the script directly returns `SCRIPT ERROR: Parse Error: Identifier "pri" not declared in the current scope. at: (res://tests/test_placement_audit.gd:55)` — a truncated identifier. Needs a source fix; not yet handed to an implementing agent.**

**`tests/town_expansion_flow.gd` — open, root cause identified. Direct execution returns `SCRIPT ERROR: Invalid access to property or key 'route_lower' on a base object of type 'Dictionary'. at: run (res://tests/town_expansion_flow.gd:65)`. Line 64, `var id="route_"+hub`, dynamically builds the literal string `route_lower` when `hub=="lower"` and looks it up in `g.estate.points` — a key `contiguous_town_phase_two.gd::build()` deliberately erases (`for id in ["route_lower", "route_pickman"]: g.points.erase(id); g.routes.erase(id)`) as part of the Phase Two migration that replaced the lower district's separate hub-entry-point model with one contiguous walkable exterior. `g.estate.points` genuinely has no `route_lower` key by design once Phase Two construction completes. This is a real, stale, pre-Phase-Two-migration test — the `business`/`upper` branches already navigate correctly via direct `g._travel(hub,...)`, unaffected. Needs a source fix to drop the special-cased `lower` points lookup and enter the contiguous exterior the same way the other two hubs already do.**

**`tests/staging_flow.gd` stale assertion — open, confirmed failing. The test still asserts the pre-migration `Story.SCENES.boy`/`boy_repeat`/`boy_return` pattern against the now-migrated `gatehouse_boy.dialogue`. `tests/staging_flow.gd` is not a standalone `SceneTree` script — it runs only through an integrated `--qa-staging`-style mode. Needs a source fix to the assertion.**

**`tests/speakeasy_flow.gd` bar-eavesdropping assertion failure — open. A blocked `route_speakeasy` entry correctly shows a dialogue card, not a toast (`CELLAR BULKHEAD` at morning/noon, `THE VIEWING SLIT` at evening under a police coat — both assertions pass cleanly). The test's real, current failure is unrelated: `assert(g.page == "dialogue", "Interacting with speakeasy_bar should start eavesdrop cards")` fails at line 60, once inside the speakeasy. Root cause not yet diagnosed.**

**`docs/qa/` housekeeping — open, non-urgent. 30+ accumulated one-off pass-report files and several image/import pairs need a triage pass (keep as permanent record vs. archive/delete) whenever there's time.**

**Antigravity's coordinate-collision audit — reported, not independently confirmed. Three schedule fixes claimed (evening-slot collision fixes in `school_parent.dialogue`/`schoolteacher.dialogue`, a curfew-header normalization in `local_historian.dialogue`), plus a reported 61-living-NPC/0-collision full-suite pass. The 61-NPC figure is unreconciled against this document's own 70-NPC count.**

# **Part Five — Open Production Questions**

**Ekon's fatal outcome and the preservation/denial archive mechanic are already fully specified in Bible v15; what remains open is narrower: whether his final action includes lighting a sealing fuse, as distinct from the archival "sealing" the bible already describes.**

**Ward's book has two incompatible provenance stories, open, author's call needed. The Bible states it "passed out of [Fenn's] estate after his death; Ward acquired it secondhand." Both `Total-Recovery` tellings instead have Ward find it in situ in the ruins, "wedged with a stack of a dead predecessor's field notes" — an on-site find, not a secondhand purchase. Both stories agree with each other; the conflict is the Bible's account versus both stories' shared account for the object the Bible itself calls the trilogy's "object-passed-hand-to-hand device." Needs a decision: bring the Bible in line with the stories, or bring both stories in line with the Bible.**

**A minor, low-confidence inconsistency noted but not corrected: `1) No-Exit-Wound-canonical.md` has Walter pass "three of them" working the kitchen-wall hedge on arrival; the paired `the-fight` telling has him count "four of them" on a different specific afternoon ("the afternoon he finally located the pantry"). These may describe two different moments rather than the same one — left alone rather than silently changed on a guess.**

**The per-protagonist presentation scheme remains unwritten and not currently being worked on. Chapter Two/Three audio is explicitly still deferred. Chapter One has a confirmed, working instrumental-voice-cue architecture, but that is a Chapter One-scoped implementation, not a decision about Chapters Two or Three. Whether Chapter Two/Three dialogue extends the same cue system, adopts something else, or goes fully voiced for the player character remains open. The HPLHS pitch remains a long-term aspiration only.**

# **Part Six — Next Steps**

**Unchanged production direction: *validate and improve the first 30 minutes of investigation — discovery, social consequences, evidence linking, and a compelling next lead — before expanding production toward the chapter's climax.***

**In priority order:**

1. **A cold playthrough of the newest development revision specifically, distinct from the frozen Web build, focused on whether the opening 30 minutes' three investigative threads (Part Three) — the historian/schoolteacher chain, the steward appointment progression, and the newspaper-correction thread — actually land for a first-time player and produce a compelling next lead, now including the waterfront hub, the confirmed voice-cue system, and the WEIGHT/OUTCOME dialogue-grammar extensions. This is a diagnostic step; it does not authorize replacing the frozen Web build regardless of outcome.**
2. **Address whatever that playthrough surfaces in the opening 30 minutes before touching anything past it.**
3. **Playtest the completed ElevenLabs compatibility library in context and hand-tune individual `VOICE:` assignments only where delivery clashes with the written line.**
4. **Conversation-time/travel-time scale mismatch (Part Four) — pick a direction (raise conversation costs, or shrink phase thresholds) once ready to tune day-clock pacing, from a representative playtesting speed. Not a priority while investigation logic is the focus.**
5. **"More life" work, five-stage sequence:**
   - **Stage 1 — the contiguous town: complete (Phase 1 + Phase 2). Remaining: the Web-profile handoff task (`docs/qa/PHASE_ONE_WEB_PROFILE_HANDOFF.md`) is written but not yet executed against the in-repo Web export.**
   - **Stage 2 — populate the finished town in layers with scheduled life: in progress. 23 new scheduled ambient NPCs exist across four districts (six lower-district residents with domestic/labor routines, six waterfront workers present mornings/middays and gone before evening, plus the earlier six: `drayman`, `fish_smoker`, `lamplighter`, `night_owl_one`/`night_owl_two`, `speakeasy_bartender`). The broader layered population pass is further along than "not started" but not yet complete. Watch for overlap with `dialogue_catalog.gd`'s existing `SCHEDULE:`/`slot()` machinery when authoring the twelve backup routes below for any NPC this stage touches.**
   - **Stage 3 — the twelve backup routes (Part Four, "Missable-NPC redundant-carrier pattern"): authored. Revisit each backup topic's `GATE:`/`SCHEDULE:` interaction once Stage 2 lands for its source NPC, in case scheduling shifts when either route is reachable.**
   - **Stage 4 — ambient paired conversations and eavesdropping (Part Four): not built beyond the one fixed `speakeasy_bar` exception. Sequenced last so it layers onto a town whose density and investigative redundancy are already in place.**
   - **Stage 5 — the Tab-menu pocket watch: shipped. Open follow-up, not started: replace the text readout with an analog clock face (Part Four).**
6. **Open test failures needing a source fix (Part Four): `tests/test_placement_audit.gd` (parse error, line 55), `tests/town_expansion_flow.gd` (stale `route_lower` lookup), `tests/staging_flow.gd` (stale `gatehouse_boy` assertion), `tests/speakeasy_flow.gd` (bar-eavesdropping assertion, line 60, root cause undiagnosed).**
7. **Antigravity's coordinate-collision audit (Part Four) — reconcile the reported 61-NPC figure against this document's 70-NPC count, or otherwise confirm/reject the claimed schedule fixes.**
8. **`docs/qa/` housekeeping — non-urgent triage of accumulated one-off pass-report files.**

**Explicitly not current priorities: the ontological break and fatal-comprehension ending; Chapter Two's playable slice and trinket/procedural-geometry pipeline; the Chapter Two/Three audio-pipeline architecture decision; the per-protagonist presentation scheme; Ekon's sealing-fuse staging detail; the Part Seven difficulty screen and achievement registration; gamepad support and full key rebinding; the NPC-to-NPC eavesdropping mechanic (thought-bomb only, no systems built); and any further work toward the HPLHS pitch.**
