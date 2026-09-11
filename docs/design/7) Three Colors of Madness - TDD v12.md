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

**This revision consolidates two days of rapid, parallel work — a Chapter One restaging pass, a town-expansion and day/night clock pass, and a full dialogue-authoring-and-integration pass — into the document's normal structure. Most of this material previously existed only as dated addenda inside `docs/ARCHITECTURE.md` and a scattered set of `docs/qa/` reports; nothing here is new fact so much as it is that material folded into Parts Two through Four properly, so a reader doesn't have to reconstruct the current state from five separate files.**

**A note on this revision's own verification method, in the spirit of this document's established practice of never crediting a claim it hasn't checked: this pass is grounded in the project's own dated `ARCHITECTURE.md` sections and its `docs/qa/` reports (`STAGING_PASS.md`, `TOWN_EXPANSION_PASS.md`, `DIALOGUE_LANG_PASS.md`, `DIALOGUE_LIVE_PASS.md`, `SESSION_HANDOFF_2026-09-09.md`), plus this reviewer's own direct, line-by-line reading of the authored `.dialogue` content files across several rounds of review with the author. It does *not* include running the Godot build, executing the test suite, or a live browser session — the verification standard the document's own Codex-authored passes hold themselves to. Where a claim below rests only on a QA document's own self-report rather than something this reviewer read directly, that is noted in place rather than presented with equal confidence.**

**A note on provenance, extending the practice already established for Codex/Antigravity/Claude Code: the dialogue grammar and interpreter (`dialogue_lang.gd`, `dialogue_runtime.gd`, `dialogue_state.gd`) were designed and built separately, in VS Code, by the project's author working with a Claude Sonnet instance — not by Codex, and not as an Antigravity delivery. Codex's own role begins at integration: connecting that interpreter to the authored `.dialogue` corpus and wiring it into live play. Both pieces are real and both are credited to the agent that actually built them, per Part Three below.**

# **Part Two — Current Build**

## **Engine and Target**

**Godot 4.7 (the Web export identifies as 4.7.2.stable), using the GL Compatibility renderer (not Forward+), targeting broad hardware reach over cutting-edge rendering fidelity. Window target 1440×900, canvas-items stretch mode. No import dependencies beyond the engine itself. Unchanged since v1.**

## **Scope of the Current Slice**

**The build now covers substantially more of Chapter One's opening stretch than any prior revision recorded. The playable area is: the Ophion estate grounds (rose garden crime scene, service passage, tunnel entry), Pickman Street (boardinghouse, cobbler's shop/Walter's room, precinct, morgue), and three newly built neighborhood hubs reached as separate pocket spaces off Pickman Street — a business district, an upper-residential ridge, and a lower-residential quarter — plus a post office. This is a deliberate hub-and-spoke compression, not a continuous town map: each neighborhood is self-contained, reached through a door rather than a walkable street connection, and nothing currently commits the project to building continuous geography later.**

**Body timeline, corrected from the version this document's prior revisions assumed: the six rose-garden bodies clear on the player's first departure to town, unchanged. The woman and boy in the birches do *not* clear with them — this was previously a bug (both groups cleared together) and is now fixed as a deliberate narrative beat. They remain visible and unattended through at least a second estate visit, clearing only once Day 3 has begun, with no accompanying scene, notification, or on-screen actor performing the removal. This is intentional per the author's own direction: the disparity between the six men's formal coroner's-table treatment and the two victims' continued neglect is the point, not an oversight to smooth over.**

**A real day/night clock now exists.** A single clock (360–1200 minutes, morning through night) advances by a fixed amount per cross-district travel and, separately, by an authored per-topic numeric cost (see the Dialogue Authoring System below) the first time any given conversation topic completes — repeats are free. Once night falls it persists — there is no automatic day-advance or forced sleep — until the player chooses to sleep, at which point a new day begins. Presentation only: a sun disk repositions, directional light and fog color shift, and street lamps toggle, all read from the clock's current phase with no gameplay effect of their own.

**Three visible sun states (morning/midday/evening) plus a static night state were the original design target; confirm against current source whether the shipped implementation's period names match this exactly, since at least one authored `.dialogue` file's `SCHEDULE:` block used `morning`/`midday`/`evening`/`night` while early design conversation used `dawn`/`midday`/`dusk`/`night` — the parser accepts either without validation, so a silent mismatch between what content authors write and what the runtime's schedule-lookup code queries for is possible and would not produce an error, only an NPC who fails to resolve to any location at the wrong moment. This is flagged here rather than asserted resolved, since this reviewer has not directly checked `day_clock.gd`'s or `daylight.gd`'s own period vocabulary against the `.dialogue` corpus's.**

**Dialogue is now live and authoritative, not a parallel prototype.** This corrects the prior revision's own addendum, which described the dialogue system as connected but did not yet reflect the scale of the corpus behind it: 30 authored `.dialogue` files, 29 concrete NPCs, and 119 nonempty authored topics are wired into `chapter_one.gd`'s real `_interact()` dispatch via `chapter_one_dialogue.gd` and `dialogue_catalog.gd`. The previously-authoritative hand-coded menus are superseded by this system, not run alongside it. Numeric `TIME:` values (minutes, author-set per topic, typically 3–10) drive the day clock's per-conversation advance described above.

**Not yet implemented, unchanged in substance from prior revisions: the glass-shattering ontological break, the fatal-comprehension ending, Chapters Two and Three as playable slices, gamepad support, full key rebinding, a full encumbrance/leveling system, and Ekon's later consumption of Walter's record. The Part Seven difficulty screen and achievement registration remain deferred. None of this pass's work touches the chapter's actual climax.**

## **Controls and Accessibility**

**Unchanged from v2.**

## **Saves**

**Case-state schema has advanced substantially since the last full revision. Chapter One restaging brought it to schema 5 (day, steward visits, lounge exit, montage index, migrated from 1–4). The town-expansion pass brought it to schema 6 (independent `rose_bodies_removed`/`birch_bodies_removed` flags, `estate_visits_completed`, migrated from 1–5) and then schema 7 (`clock_minutes`, `timed_conversations`, migrated via `day_clock.gd`'s own back-fill logic rather than inventing elapsed time for old saves). The dialogue integration pass brings it to schema 9, migrating legacy dialogue progress and spent timing tags, with invalid or changed playback descriptors recovering to a playable state rather than failing to load. This reviewer has not independently re-verified each migration path; all of the above is taken from the project's own dated architecture notes and QA reports, consistent with this section's stated verification method.**

## **Verification**

**Per-pass automated coverage, as reported in the project's own QA documents rather than independently re-run by this reviewer: `tests/staging_flow.gd` for the restaging pass (gates, repeat visits, exact montage resume, source-call bypasses, body removal, legacy migration, notebook immutability); `tests/town_expansion_flow.gd` for the town pass (every neighborhood interior, the morgue and post office, the body-removal timeline, v5 migration); and, for the dialogue integration, a stated pass across dialogue language/content/playback/live/catalog tests, the day clock, opening/town/staging/loop/checkpoint/phase-two/usability QA, plus a local Web export rebuild that booted successfully in Chromium with no browser errors. That last item is explicitly described in the project's own handoff document as a startup smoke check, not a full browser playthrough, and GitHub Pages had not been updated as of this revision.**

# **Part Three — Architecture As Built**

**This section describes what the current codebase does, per the project's own dated architecture notes and QA documents, plus this reviewer's direct reading of the authored dialogue corpus. Everything not restated here (autoloads, entry point/shared-module split, the Observer color-preservation shader, the corkboard/causal-spine mechanic, the procedural-geometry pipeline, forced-spill and tunnel combat) is unchanged from the prior revision and not repeated.**

## **Chapter One Restaging (Codex) — new**

**A temporary three-visit progression governs the steward: visit one is a real, playable conversation in the smoking lounge; sleep is blocked before it occurs, with an explicitly temporary placeholder line ("There's still work to do"); visit two occurs inside a day-two montage (stills and intertitles) ending on the steward's line, "Come back tomorrow, and don't bring your badge"; visit three, on Day 3, in the plain coat, is where he opens up. `chapter_one_staging.gd` owns this progression, the sleep restriction, and staged interaction guards. `Estate.sync_staging()` controls cleared bodies, the gardener's relocated (optional, plain-coat) later encounter, the service-entrance gate (unavailable until Mrs. Almy has been spoken to), and the groundskeeper's availability, which now triggers on leaving the smoking lounge rather than appearing in the opening scene. A read-only notebook (`chapter_one_notebook.gd`) mirrors the corkboard's evidence, links, and causal-spine display with no write path back into `case_state.gd` — linking remains exclusively a corkboard action, keeping the board itself as the fair, factual "controls" Design Law 4 requires, with the notebook reserved as the future home of any presentation-layer unreliability, deliberately not built yet.**

## **Town Expansion, Morgue, Post Office, and Day/Night Clock (Codex) — new**

**`scripts/chapters/town_places.gd` is the stable, save-safe registry of 18 buildings (six per neighborhood hub) and their depth — `occupied` (a placeholder resident with a single dismissive line), `light` (enterable, undressed), or `exterior`\-only (no entry prompt). `scripts/chapters/business_street.gd` builds the business district's storefront geometry from that registry; root-level `town_expansion.gd` (extending `town.gd`) is instantiated by `chapter_one.gd` in place of the base `Town` scene whenever `Places.valid()` recognizes the destination, without touching the existing estate/precinct/boardinghouse/room scenes. The morgue is a precinct-attached room, not a standalone building, per the default this document's own build brief proposed and the author accepted. The day/night clock (`scripts/shared/day_clock.gd`, `scripts/shared/daylight.gd`) is described under Part Two above; its schema and migration are described under Saves.**

## **The Dialogue Authoring System (Dejunai and Claude Sonnet, VS Code) — new**

**A custom flat-file dialogue grammar and interpreter, authored rather than adopted from an existing Godot dialogue plugin, on the explicit reasoning that this project's gating vocabulary — coat state, day/night phase, cross-NPC topic-saturation tallies, a hard permanent-exclusion gate — needs to read `case_state.gd`/`day_clock.gd`/`town_places.gd` directly rather than be reimplemented inside a plugin's own graph format. `dialogue_lang.gd` is the grammar/GATE-expression parser (pure text in, structured data out, no engine references); `dialogue_runtime.gd` is the game-facing loader/renderer; `dialogue_state.gd` is a persistent store deliberately kept separate from `case_state.gd`, so new topic ids and gate conditions never require a schema bump. Confirmed fields, read directly from source across two review passes: `NPC:`, `LOCATION:`, `SCHEDULE:` (free-form period keys, no fixed vocabulary enforced — see the flag under Part Two), `TOPIC:` (repeatable per NPC, first-matching-`GATE:`\-in-file-order wins — an ordering-dependent pattern worth a parser-level safeguard, not yet built, against a future edit silently reordering blocks), `GATE:` (boolean expressions over `evidence()`, `topic_done()`, `coat`, comparison operators including `!=`, and the literal `never`, which always evaluates false and is the mechanism protecting permanently excluded content), `TAG:`, `TIME:` (originally a free-text label, now — following an explicit format-and-content update — a numeric minute cost, described under Part Two), `LABEL:`, `CHOICE:`/`FORK:` for branching, `EVIDENCE:` as a write (companion to the `evidence()` read), and `NOTEBOOK: id | "text"` (extended from an earlier free-text-only form; backward compatible with files that omit the id).**

**One known defect, confirmed by direct source reading and not yet fixed as of this revision: `CHOICE:`/`FORK:` lines are stamped with the literal string `"WALTER CORWIN"` as their speaker at parse time, in two places in `dialogue_lang.gd`. This works for Chapter One by coincidence and will silently mislabel Chapter Two's or Chapter Three's protagonist the moment either writes a `.dialogue` file using `CHOICE:`, with no error to catch it. The fix is straightforward and already scoped: drop the hardcoded name, mark the line `"player": true` (already present) with no fixed speaker, and let `dialogue_runtime.gd` — which already resolves live `case_state` context — substitute the correct protagonist's name at render time. Recommended before any Chapter Two content is authored, not urgent before then.**

**The authored content itself, per this reviewer's own direct review, was strong on craft and largely disciplined about the one rule that matters most (Design Law 5, the sixth man's permanent unidentifiability) despite being produced across at least three independent tools with no visibility into each other's output or this document's own conversation history. Two genuine violations were caught and corrected: an ancestral "sixth coat" backstory in `tailor.dialogue` (cut), and an "Overseer of the Line" title with a deed history and a named bank in `county_clerk.dialogue`, which the author elected to keep as written but hard-gate behind `GATE: never` rather than delete — a legitimate resolution, since the literal `never` gate is confirmed to make the content permanently unreachable regardless of file content, though it is a different, lower kind of safety than an empty topic body: the scene is fully written and one gate-flip from live, rather than simply absent. A protective comment marking the block as a deliberate, permanent exclusion (not merely unfinished) was recommended and, per the author, added.**

## **Live Dialogue Integration (Codex) — new**

**Following the authoring pass above, Codex connected the interpreter to the full authored corpus and wired it into live play: `scripts/chapters/chapter_one_dialogue.gd` and `scripts/chapters/dialogue_catalog.gd` are the primary new integration surfaces, with supporting changes to `case_state.gd`, the Chapter One controller/archive/staging scripts, the shared dialogue runtime, and the day-clock test. Per the project's own session handoff document: all 30 authored files were preserved byte-for-byte; NPC menus, branches, acknowledged-card effects, evidence, notebook entries, saved choices, and mid-conversation resume are connected; numeric `TIME:` advances the day once per first completion, with repeats free and no double-charging against any legacy conversation-duration system; seven explicit corroboration links were added connecting authored observations (evidence is not linked automatically); and scheduled, reachable residents were added, some using provisional existing interiors or storefronts pending fuller placement. This reviewer has not independently re-verified this integration against live source or a running build; it is recorded here per the document's stated method, as reported in `docs/qa/DIALOGUE_LIVE_PASS.md` and `docs/qa/SESSION_HANDOFF_2026-09-09.md`.**

# **Part Four — Architecture Decisions Needed**

**Items resolved since the prior revision are marked as such rather than deleted, so the decision history stays visible.**

**Dialogue system not yet wired into live `_interact()` dispatch — resolved.** The prior revision's own addendum explicitly called this out as still-pending; the live integration pass above closes it.

**NPC scheduling/staging trigger system — previously marked resolved for the actor-lifecycle system generally; now substantially extended** by the `SCHEDULE:` field and the day/night clock, giving named dialogue NPCs real time-of-day placement rather than only conditional presence.

**Tunnel exhausted-resources fail state — still open, unchanged.** Untouched by any pass described in this revision.

**Two "Mr. Vane"s (the wealthy banker and the business-district clockmaker sharing a surname) — reported resolved by the author, not independently re-verified by this reviewer against a final build.** The project's own session-handoff document flagged this as an open review item at time of writing; the author subsequently reported renaming the banker to "Mr. Whitehouse" and confirmed the internal NPC id and every spoken line were updated to match (an earlier attempt had renamed only the file, leaving the id and dialogue unchanged — this was caught and corrected in the same exchange). Worth a source-level confirmation next time either file is touched.

**A formatting defect in `county_clerk.dialogue`'s `ophion_settlement` notebook entry (the `$84,000` figure rendering as `,000`) — status unconfirmed.** Flagged by this reviewer; not confirmed fixed or unfixed as of this revision.

**A private auditory-motif collision — resolved.** `salt_mender.dialogue`'s original `night_sounds` topic described a "wet cough" rising from beneath the harbor, which would have compromised the bible's design of a single sustained cough as exclusively Walter's private, escalating auditory signature. Confirmed by direct comparison of two file versions: the topic now describes "a dragging sound... something enormous being shifted through wet sand," distinct from the cough in every respect.

**Revelation pacing in the clockmaker and historian material — open, not a defect.** `clockmaker.dialogue`'s fused-hairspring, time-frozen watch is a second, independently invented physical impossibility alongside the trilogy's established one (materialized bullets, no exit wounds). It is well-written and properly restrained on its own terms; whether the trilogy wants exactly one unexplainable physical signature or can support a small family of them without diluting the original is a real authorial question, not yet decided either way.

**Repeatable forks where permanent exclusivity may eventually be desired — open, per the project's own session-handoff document.** Not further specified there or independently investigated by this reviewer; worth a follow-up pass to identify which specific topics this refers to.

# **Part Five — Open Production Questions**

**Unchanged in method from the prior revision's own note: nothing in this pass's Chapter One work bears directly on Chapter Two's or Chapter Three's open questions. However, a substantial amount of real design decision-making for both later chapters happened in conversation over the same period this revision covers, and none of it has yet been written into either this document or the bible. Recorded here so it isn't lost: a per-protagonist presentation-as-sanity-meter scheme (Walter starting monochrome, Ward starting muted, Ekon starting vivid-and-natural before curdling vivid-and-wrong); full voice acting planned for Chapters Two and Three, with Ward's audio specifically meant to move from muddled early-talkie quality to clear as his palette moves from early Technicolor toward Oz-style saturation, via a real-time filter on a single clean recording per line rather than two separate voice passes; a specific non-rendering sequence for the Old Gods in Chapter Three (mismatched/stretched geometry, then collateral z-fighting on what can render, then a brief celluloid burn) with an explicit in-fiction reason (the entity does not exist in this reality and nothing could render it) that must never be stated on screen; and an still-undecided final beat for Ekon's ending, including whether he lights the sealing fuse at all. None of this is build-ready; all of it is worth a dedicated bible/TDD pass before Chapter Two production begins in earnest.**

# **Part Six — Next Steps**

**In rough priority order: build the ontological break — glass-shatter cue, aspect-ratio widening, color bleed, and the entity's manifestation — and the fatal-comprehension ending. This has been the single largest remaining piece of Chapter One for several revisions running, and none of this revision's work touches it. A genuine human playthrough of the expanded neighborhoods and the new dialogue corpus is the next most useful validation available — the project's own handoff document is explicit that a browser startup check is not a substitute for this, and none has yet happened. Fix the `CHOICE:`/`FORK:` hardcoded-speaker defect in `dialogue_lang.gd` before any Chapter Two `.dialogue` content is authored. Confirm the `Mr. Vane` rename and the `$84,000` formatting defect against actual current source. Decide the clockmaker/historian revelation-pacing question. Identify the specific "repeatable fork" topics the project's own handoff flagged as candidates for permanent exclusivity. Sweep the barman→steward, bar→smoking lounge terminology correction through this document and `ARCHITECTURE.md` themselves — player-facing text and most of the dialogue corpus already use the corrected terms, but this document's own Part Two/Three prose above and its prior revisions still say "barman." Confirm the day-clock's period-name vocabulary (`dawn`/`midday`/`dusk`/`night` vs. `morning`/`midday`/`evening`/`night`) is consistent between authored `SCHEDULE:` content and the runtime that reads it. Rebuild and publish the Web export once the above is settled — GitHub Pages has not been updated since before this pass's work. Give the Part Five material (per-protagonist presentation scheme, Chapter Two/Three audio plan, Ekon's ending) an actual bible/TDD pass before it's needed for production rather than after.**  


## Implementation addendum — 10 September 2026: questions travel

Dejunai authorized dialogue revision and cross-NPC consequences. Codex connected
the historian's crew-list refusal to four distinct witnesses out of six; returning
to him supplies the source for the schoolteacher's covering letter and unlocks her
personal accounts. This uses the existing saved topic-source tally, with no new
morality meter, time farming, save schema, or mandatory progression gate.

The same pass removes unsupported causal conclusions from the early board and
notebook, corrects older link results, improves optional-lead guidance, and gives
the first steward appointment a day-book lead with a third-visit payoff.
Full route, authoring convention, provenance, limitations and test results:
[Social inquiry pass](../qa/SOCIAL_INQUIRY_PASS.md).
The Grok case-file and intro remain visual references; no Grok code or assets
were imported. Perception calculations and the Day 2 montage remain unchanged.


## Development addendum — 10 September 2026: the printed correction

On dev/day-one-followups, Walter can bring received identification records back
to the Gazette editor and obtain a narrowly sourced correction slip. The original
edition remains intact; Almy responds when shown the slip. A read-only filed(id)
dialogue gate checks received report/supplement snapshots, not current inventory.
This optional consequence works with either filing choice and without manual links.
See [Day One follow-ups](../qa/DAY_ONE_FOLLOWUPS_PASS.md) for the route, provenance
and tests. The playtest Web artifacts remain frozen; no export or publication is
authorized by this development pass.
