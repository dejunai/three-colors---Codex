# THREE COLORS OF MADNESS

## Technical Design Document — v46 (revised 2026-09-23, after commit `120a488`)

**Internal working document. Not for external distribution. Companion to the Design Bible (v18).**

Dejunai (founder, author/producer; lead on dialogue content specifically) · Claude Sonnet (co-author, co-designer — designed and built the dialogue grammar and interpreter with the author in VS Code, and separate VS Code Claude Sonnet sessions built the object-evidence and portal authoring systems under the author's lead; a Claude session in Cowork maintains this document and the Historical Change Log, and independently verifies claims against live source before they're recorded here) · Codex (core programmer — live integration of the dialogue/object/portal systems into play, interpreter fixes and extensions, world-building, and independent review of new systems against source) · Antigravity (dependency/gate auditing and dialogue-content execution under the author's lead; bug hunting is its designated specialty, not an exclusive lane) · DeepSeek V4 Pro in Bionic (logic-gating review of `.dialogue`/`.object`/`.portal` `GATE:` clauses) · Gemini, Drive-embedded (occasional second logic-gating check) · Manus AI (independent repository audit; the one reviewer able to play the game) · Perplexity (red-team review of docs and code; research support for dialogue content) · Grok-bot-minis (red-team the conceptual commercial release) · Lumo/MetaAI (occasional outside repo assessments) · Copilot 365 (ideation support for dialogue content) · Meshy.AI (3D asset generation under the author's artistic direction). Full role definitions: `AGENTS.md`.

---

## Contents

- Part One — What This Document Is
- Part Two — Current Build
- Part Three — Architecture As Built
- Part Four — Build vs. Bible v18: Alignment Work
- Part Five — Decisions Needed
- Part Six — Known Limitations and Technical Debt
- Part Seven — Narrative Canon (Settled)
- Part Eight — Next Steps

---

# Part One — What This Document Is

This is the Technical Design Document (TDD) for *Three Colors of Madness*. It is the companion to the Design Bible, not a replacement for any part of it. The Bible owns the what and the why: the thesis, the Design Laws, the narrative, and what every mechanic means. This document owns the how: engine architecture, data schemas, production sequencing, and the open questions a playtest still has to settle. Where the two disagree, the Bible is correct and this document is wrong until revised, never the reverse.

This file holds only the **current, settled state** of the build. How each item got here (who found it, what was tried, which claims were checked) lives in the Historical Change Log, outside this repository (see `AGENTS.md`, "Where things live"). The rule that keeps this document from drifting into a changelog again:

- **No dated narrative in this file.** A date appears only as the "as of" stamp on a measured figure. The story of how a figure or fix came about goes in the HCL.
- **Figures that move are stated with the command that re-derives them.** Treat every count here as a snapshot. When it matters, re-run the command instead of trusting the number.

**Naming rule (Bible v18, Part Two).** The trilogy sits next to Lovecraft's lore, not inside it. The only borrowed proper nouns are **Pickman** (the street) and **Miskatonic** (the county and its institutions). No other Lovecraft proper noun may appear anywhere: in source, content files, test fixtures, docs, or build output. A corpus-wide search for about fifty such names came back clean as of 2026-09-23.

# Part Two — Current Build

## Engine and Target

Godot 4.7 (the Web export identifies as 4.7.2.stable), using the GL Compatibility renderer (not Forward+), targeting broad hardware reach over cutting-edge rendering fidelity. Window target 1440×900, canvas-items stretch mode. No import dependencies beyond the engine itself.

## Scope of the Current Slice

The slice covers:

- the Ophion estate grounds (rose garden, service passage, tunnel entry);
- Pickman Street (boardinghouse, cobbler's shop/Walter's room, precinct, morgue);
- three neighborhood hubs (business district, upper-residential ridge, lower-residential quarter) and a post office;
- the waterfront: a playable outdoor hub with scheduled residents, its own travel time, full save restoration, and the offshore whaling station visible as unreachable scenery: a single mud mass with only a chimney tip, a roof ridge and one wall fragment showing, per Bible v18's "buried whole."

Geography is contiguous, not hub-and-spoke. Pickman Street, the business district, the upper ridge, the lower district and the full waterfront are one shared walkable exterior; only interiors are separate scenes.

The day/night clock drives scheduled-resident placement and, separately, the sun, directional lighting, fog color and street-lamp visibility, purely as presentation. It does not govern body removal; story progression does:

- The rose-garden bodies clear after the player's first departure to town.
- The birch victims (the woman and the boy) stay visible and unattended through at least a second estate visit, and clear only once Day 3 has begun.
- Neither clearing comes with a scene or a notification.

Content volume, as of 2026-09-23:

- **Dialogue:** 73 NPCs and 462 nonempty authored `TOPIC:` blocks (74 `.dialogue` files including the template). Re-derive with `tests/dialogue_catalog_flow.gd`.
- **Voice cues:** 739 NPC lines carry a wordless instrumental voice cue, drawn from a 144-entry cue manifest. Re-derive with `tests/instrument_voice_flow.gd`. Walter, narration, beats, objects, notebook entries and system text are intentionally silent by design, not by omission.
- **Objects:** all eleven scoped hotspots are migrated and live (estate seven, town three, tunnel one). Re-derive with `tests/object_content_flow.gd`.
- **Portals:** ten ids across five files are migrated and live. Re-derive with `tests/portal_content_flow.gd`.

**Not yet implemented:**

- the fatal-comprehension ending;
- Chapters Two and Three as playable slices;
- gamepad support and full key rebinding;
- a full encumbrance/leveling system;
- Ekon's later consumption of Walter's record.

This is a build-status list, not a lore gap. The reference novellas (`08`, `09`, `10`) fully dramatize Ekon's use of Walter's record. The glass-shattering ontological crack is implemented; see Part Three, "The Glass Break."

## Saves

`CaseState.VERSION` is 11, accepting save versions 1 through 11.

## Verification

`python tests/run_all_qa.py` is the maintained aggregate runner. It had **38 suites** as of 2026-09-23 (count the `tests = [...]` entries to re-derive), and all 38 passed on a full run after commit `120a488`.

Standing rule: a suite that times out under the aggregate's process contention is re-run on its own before it is either dismissed or trusted. Leftover headless Godot processes produce false timeouts (`Kill headless tests.cmd` clears them). Genuine failures have also surfaced first as timeouts. The rule exists because it has caught both.

## Published vs. Development Build

The local Web export under `build/web/` is git-ignored and untracked. `.github/workflows/deploy-pages.yml` still triggers on `build/web/**`, but ordinary pushes can no longer fire it, so **the workflow is dormant**. GitHub Pages shows the last build published before `build/web/` was untracked. itch.io shows whatever was last uploaded by hand, independently of Pages.

The working branch (`feature/district-textures`) was **76 commits ahead of `origin/main`** as of 2026-09-23. Re-derive with `git rev-list --count origin/main..HEAD`. So the "current build" in this document means the development branch. "Published build" means only what is actually deployed to Pages or itch.io. Restoring a publish path is Part Eight's first item, because the top-priority cold playtest cannot happen without it.

Local Web testing uses `tools/serve_web.py`, with a Node fallback in `tools/serve.js`:

- It serves the export with the COOP/COEP headers Godot's Web export needs for a cross-origin-isolated context.
- It handles a client that disconnects without leaving the server in a bad state.
- `Build and serve web.cmd` runs it on port 5173.
- `tools/inspect_pck.py` inspects a built `.pck`'s contents directly.

# Part Three — Architecture As Built

## Story Actors vs. Catalog Residents

`chapter_one_dialogue.gd`'s `allowed(g, actor)` implements two genuinely different systems.

**Catalog-scanned residents** (`extra_actors`, populated by `catalog.scan()` in `setup()`) are placed through `dialogue_catalog.gd`'s `slot()`:

- `SCHEDULE:` is a fully deterministic `(npc, phase) → location` lookup with no chance element.
- Ordinary catalog residents return an empty placement at night, closing for that phase.
- A small, named exception list, `NIGHT_ACTIVE` (`speakeasy_bartender`, `night_owl_one`, `night_owl_two`, `lamplighter`), stays available through the night.

**Story actors** have bespoke, state-driven availability. None of these rules reads the day/night clock, and none of these actors hides at night:

- **Odell and the coroner's assistant (`assistant`):** available whenever `world == "estate"` and the estate isn't complete.
- **Abel Tavares, the groundskeeper (`crew`):** available once the lounge has been exited. Every one of his topics also gates on `lounge_exited`.
- **The old woman:** available in town, not yet recorded, and only after the estate report is filed (`intake_done`) and at least one of `evidence(behan_name)`, `evidence(quay_inquiry)` or `topic_done(local_historian, ship_origin)`. The same rule is applied in `chapter_one_dialogue.gd::allowed()` and `town.gd::sync_actors()`, which shows her figure only when she's available.
- **The intake clerk (`intake_clerk`)** and **the morgue coroner (`morgue_coroner`)** are dialogue-file story actors keyed by location (`precinct`, `morgue`).
- **The steward (`barman`):** keyed to the lounge and to whether Mrs. Almy has been spoken to.

A phase shift is deferred while a multi-topic conversation is open, so an interlocutor's slot can't move out from under the player mid-dialogue. The mechanism has three parts:

- `case_state.gd`'s `pending_dialogue_minutes`/`defer_dialogue_clock` accumulate a topic's `TIME:` cost instead of advancing the clock mid-conversation.
- `chapter_one_dialogue.gd` tracks a `session_actor` that `allowed()` always permits.
- The world re-schedules only when the conversation genuinely ends, via `end_session()` (called from `chapter_one.gd::_close()`).

Returning staff for later days are implemented. `odell_precinct` and `coroners_assistant_morgue` are live scheduled NPCs, recorded under their own topic-completion identity so they never merge with the original estate encounter.

## Three Separate Investigative Threads

These three threads have separate prerequisites and are not chained together.

**1. The historian/schoolteacher witness-count thread**

- `local_historian.dialogue`'s `crew_omission_followup` gates on `topic_done(local_historian, crew_omission_official) AND topic_count(crew_omission) >= 4`.
- `schoolteacher.dialogue` carries a related chain keyed off `evidence(naomi)` and `evidence(reader_omission_letter)`.
- The internal chain (historian → four witnesses → historian → schoolteacher) doesn't connect to either thread below.

**2. The steward appointment thread**

- `chapter_one_staging.gd`'s `sleep()` blocks sleeping while any of these holds: `steward_visits == 0`, `intake_done` is false, or `evidence.has("naomi")` is false. While blocked, the player gets a "Get up" panel.
- The lounge becomes reachable via `service_entrance` once `visited.has("almy")`. The steward is `allowed` only while `world == "lounge"`.
- Visit two is playable Day 2 content, ending on `THE STEWARD: "Come back tomorrow, and don't bring your badge."`. It sets `day = 3` and `steward_visits = 2`.
- The third encounter is gated by `case_state.gd`'s `steward_ready()`: `visited.has("almy")`, `day == 3`, `steward_visits >= 2`, and `coat == "Plain wool coat"`.

**3. The newspaper-correction thread** (gated on `filed()`, not `evidence()`)

- `gazette_editor.dialogue`'s `print_correction` requires `evidence(gazette_correction_terms) AND filed(eight) AND filed(naomi) AND filed(lodging)`, and awards `EVIDENCE: gazette_correction_printed`.
- `mrs_almy.dialogue`'s `show_printed_correction` gates on that evidence. Showing her the slip has her read Naomi's name aloud (`NOTEBOOK: correction_seen`).
- `gazette_editor.dialogue` carries repeatable mid-investigation and post-correction greetings for both coat states, plus a post-correction topic (`the_counter_slips`), so returning to the newspaper office is never empty.

## Montage Removal / Day 2 Enactment

The montage sequence (`scripts/chapters/montage_still.gd`) is disconnected from the active flow of a new playthrough. It is unwired, not deleted. The days now run like this:

- **Day 1:** intake, Naomi ID, the first steward visit.
- **Day 2:** sleeping ends Day 1 and returns control on Day 2 at 6:00 a.m., with real content culminating in the steward's second visit in the smoking lounge. Sleeping before that visit is blocked with a redirect back to the lounge.
- **Day 3:** after the second visit, sleeping advances to Day 3 at 6:00 a.m.

Old-save resume is preserved: `chapter_one.gd::_load_game()`'s `elif state.montage_index >= 0: staging.draw_montage(self)` is reachable only from an old save that already carries a set `montage_index`.

## `$84,000` Formatting — resolved

This was a plain text-rendering defect. The `$` character did not render in the wage-claim dialogue. The amount is now spelled out ("eighty-four thousand dollars"), with no numerals or symbol anywhere in the corpus. An AI-generated podcast's "leaked design docs" account of this as an intentional UI glitch is fabricated and is not a source for anything about this project.

## Instrumental Voice Cue System

The wordless instrumental voice pack is wired into every authored NPC line:

- **Authoring:** `VOICE: cue_id` is placed immediately before an NPC's spoken line. The parser attaches the cue to that line at compile time.
- **Playback:** the runtime emits a `[speaker, text, voice]` triple per line. The WAV plays when the card appears and stops when the player advances past it.
- **Validation:** a 144-entry manifest checks cue names during dialogue loading and content validation.
- **Mixing:** instrument voices have their own independent mixer control.
- **Silence by design:** Walter, narration, beats, object descriptions, notebook entries and system text carry no cue.

The ElevenLabs delivery contains 228 source recordings. `tools/build_elevenlabs_voice_library.py` maps them onto all 144 stable cue IDs, so every `VOICE:` assignment stays valid without source changes. The same parser and runtime is the planned foundation for Chapters Two and Three. Each of those chapters still needs a chapter-provided protagonist identity (replacing the hardcoded Walter label) and its own audio contract (Part Five).

## `WEIGHT:` on `TOPIC: default`

Ships in `dialogue_lang.gd`/`dialogue_runtime.gd`, covered by `tests/dialogue_lang_flow.gd`.

- **Parse rules:** `WEIGHT: n` (positive) is line-level metadata inside a `TOPIC: default` block. It is a parse error on any other topic, and a non-positive value is a separate parse error.
- **Selection:** the first eligible default block controls selection.
  - If it is unweighted, it wins deterministically.
  - If it is weighted, the runtime draws only from eligible defaults that carry `WEIGHT:`, and later unweighted defaults stay as deterministic fallbacks.
- **No immediate repeats:** the winning default's source line is tracked per NPC for the session (not saved) and excluded from the next draw, unless that would leave the pool empty.
- **Menus:** defaults never appear as menu entries. Non-`default` topic IDs stay unique per NPC. Sharing a topic ID across NPCs still intentionally supports `topic_count()`.

## `FORK:`/`OUTCOME:` Resolution With Recap

Ships in `dialogue_lang.gd`/`dialogue_runtime.gd`/`dialogue_state.gd`, covered by `tests/dialogue_template_flow.gd`.

- **Recording a decision:** any `CHOICE:` inside a `FORK:` may carry `OUTCOME: decision_id = value_id`. The value is held as pending for the session and committed to `dialogue_state.gd`'s `outcomes` only once the branch finishes. `set_outcome()` refuses to overwrite an existing key, so a decision is immutable for the rest of the playthrough.
- **Replaying a resolved fork:** `topic_available()` is pure `GATE:` evaluation, so a resolved fork's topic stays in the menu. `render()`/`_locked_fork_options()` narrow the fork to the branch actually taken. The rejected branch can't be reached again.
- **Replay is free:** `record_fact()`, `discover()`, `complete_topic()` and `set_outcome()` are idempotent, and `commit_through()`'s `TIME:` charge is gated on `first_completion`. This is opt-in per fork. Forks using only `CHOICE:` stay plainly repeatable.
- **The one exception:** Captain Odell's automatic intake conversation stays fully one-shot. It lives inside `odell.dialogue`'s `TOPIC: default` and retires with the ordinary default-topic mechanism.

`FORK:` choices hardcode Walter as the player speaker and are silent; `VOICE:` immediately before `FORK:` is a parse error. The interpreter is extended for Chapters Two and Three rather than replaced (settled). `OUTCOME:` already supplies the persistent, once-only choice residue all three chapters need.

## Revisitable Topics

No menu topic disappears permanently. A completed topic stays in the NPC's menu so the player can revisit it to check for a missed clue. The runtime needed no interpreter change for this: effects are idempotent, `TIME:` is charged only on first completion, and a committed `OUTCOME:` locks a replayed `FORK:` to its chosen branch.

- **Authoring rule:** never gate a topic behind its own completion (`AND NOT topic_done(this_npc, this_topic)`). `docs/DIALOGUE_AUTHORING.md` and `dialogue/background_npc_template.dialogue` both teach this. As of 2026-09-23 the live corpus has zero self-referencing guards; checked by script across every `.dialogue` file.
- **Exceptions that stay as they are:** `NOT topic_done(npc, default)` greeting cascades (greetings stay one-time), and cross-NPC gates of the form `topic_done(other_npc, other_topic)`.
- **Day-gated beats** keep their `day >= N` gate and are revisitable within their window.
- **Menu presentation:** `dialogue_runtime.gd::menu()` sinks topics marked "· recorded" to the bottom. `chapter_one.gd::_style_recorded_topic_button()` also restyles them in a muted tan/brown palette with a "Previously recorded; select to review." tooltip. The text marker stays authoritative for players who can't tell the colors apart.

## Dialogue Gate Hardening

These gates are live and are there on purpose. Loosening any of them reopens a premature trigger.

- `county_clerk.dialogue` `ophion_settlement` additionally requires `evidence(lay_lead)`.
- `post_office_clerk.dialogue` `ophion_club_mail` requires `evidence(club_talk)`.
- `school_parent.dialogue` `the_reader_lesson` grants `sanitized_textbook` only. `curriculum_abridgment` is the historian's hard-earned reveal, via `crew_omission_followup`.
- `school_parent.dialogue` `the_covering_letter` requires `evidence(curriculum_abridgment)`.
- `widow_kessler.dialogue` `club_standing` requires `coat = plain`.

**Must stay ungated:** `mrs_almy.dialogue` `identify` (which grants `EVIDENCE: naomi`) stays `GATE: always`. It is the topic that names Naomi, the canonical Day 1 route reaches Almy in the police coat, and `chapter_one_staging.gd` blocks sleep until `naomi` is held. Gating it behind the plain coat traps a normal playthrough on Day 1.

**Parser note:** `AND`/`OR`/`NOT` are consumed as operators in `dialogue_lang.gd`'s `_or_expr → _and_expr → _unary → _atom → _comparison` chain before any identifier reaches function dispatch. So `AND (` parses as an operator plus a group, never as a function call named `AND`.

## Object-Evidence Authoring System

Evidence is authored as a flat file per object, in the same declarative style as `.dialogue`. `GATE:` and `EVIDENCE:` use identical syntax, plus `TAKE: item_id` for pickups.

- **Code:** parser, runtime and state are `scripts/shared/object_lang.gd`, `object_runtime.gd` and `object_state.gd`. `case_state.gd` carries `inventory`/`object_state` additively.
- **Migrated hotspots:** all eleven scoped ids are live.
  - Estate: `wounds`, `eight`, `knife`, `watch`, `gas`, `register`, `shoes`.
  - Town: `gazette`, `lodging`, `exemption`.
  - Tunnel: `tunnel_record`.
  - Content lives in `objects/estate.object`, `objects/town.object` and `objects/tunnel.object`, dispatched through `scripts/chapters/chapter_one_objects.gd`.
  - NPC stand-ins stay in `.dialogue`. Tunnel game-logic ids belong in neither grammar.
- **Forks and labels:** FORK/OUTCOME present through `_present_fork()`/`_choose()`. `LABEL:` drives hover text via `sync_points()`.
- **Fail-loud:** `object_lang.gd::_evaluate_cmp()` fails loud (`push_error()`, returns false) on an unknown gate function or field.
- **Known limitation:** hotspot visibility is one-way. `sync_points()` erases a hotspot whose `GATE:` goes false, and nothing restores it if the gate later becomes true. No current content depends on a hotspot reappearing.
- **Docs and tests:** `docs/OBJECT_AUTHORING.md`, `docs/OBJECT_MIGRATION_HOWTO.md`; `tests/object_template_flow.gd`, `tests/object_content_flow.gd`.

## Portal Authoring System

A third sibling to `.dialogue` and `.object`, not built on either. A travel point's defining content is where it leads. Alongside the shared GATE grammar, its step vocabulary adds `GO: destination | x,y,z | yaw | flags`. Reaching a `GO` halts step processing and hands control back to the caller. Only `chapter_one_portals.gd` ever calls `_travel()`. Content after a `GO` renders as arrival narration via `Runtime.after_go()`.

- **Code:** `scripts/shared/portal_lang.gd`, `portal_runtime.gd`, `portal_state.gd`. `case_state.gd` carries `portal_state` additively.
- **Migrated portals:** ten ids across five files.
  - `service_entrance` and `exit` (`portals/estate.portal`).
  - `street_precinct`, `street_almy`, `street_room`, `street_estate`, `route_post` (`portals/town.portal`).
  - `lounge_exit` (`portals/lounge.portal`).
  - `route_speakeasy` (`portals/lower.portal`, phase/coat-gated).
  - `tunnel_exit` (`portals/tunnel.portal`, two destinations depending on `evidence(lower_foundation)`).
- **`TIME:` semantics, as built:**
  - An authored `TIME:` greater than 0 is charged on **every** completed traversal, not only the first. `estate.portal` `exit` and `town.portal` `street_estate` carry `TIME: 30`.
  - An omitted `TIME:` parses empty and delegates to `_travel()`. That charges 30 minutes when origin and destination are in different hubs and nothing within one hub. `nosave` suppresses the automatic charge unless `elapsed` is also present.
  - `portal_done()` is used for content and label gating only, never for charging.
  - `portal_lang.gd`'s header and `docs/PORTAL_AUTHORING.md` state this correctly.
- **Cross-system sharing:**
  - `OUTCOME`/`flag()` read and write the shared `dialogue_state`.
  - `evidence()`/`filed()` reuse `dialogue_runtime.gd`'s helpers.
  - `portal_done`/`portal_count` are in both the dialogue and object contexts.
  - `visited(id)` reads `case_state.gd`'s `visited` array. It is deliberately stricter than `spoken_to()`, and `service_entrance` needs it.
- **Escape hatch:** `_before_travel()`/`_extra_cards()` handle the rare travel point with dynamic post-arrival content: `tunnel_exit`'s custody-result card and `lounge_exit`'s `state.lounge_exited` flag. This is a settled limitation, documented in `docs/PORTAL_AUTHORING.md`.
- **Tests:** `tests/portal_lang_flow.gd`, `tests/portal_template_flow.gd`, and `tests/portal_content_flow.gd`. The last drives every migrated route through the live `chapter_one.gd` adapter, including `route_speakeasy` from the contiguous town, and asserts charging on every trip.

## Fail-Loud Guards

The guards stop broken gate logic from leaving an NPC or object silently unresponsive; instead an obvious on-screen developer error appears. There is one centralized check per system.

- **Objects:** `chapter_one_objects.gd::interact()`/`_fail_loud()` fires when a clickable hotspot resolves to no eligible `GATE:` block. It lives in the adapter, because an object file having nothing eligible is often correct, and only the adapter knows the hotspot is clickable.
- **Dialogue:** `chapter_one_dialogue.gd::interact()` fires when `Runtime.enter()` returns an empty session, the NPC's menu has zero eligible entries, and the actor isn't `"odell"` (whose intake is one-shot by design).
- **Documentation:** `docs/OBJECT_AUTHORING.md`, `docs/DIALOGUE_AUTHORING.md`, `README.md`.

## The Glass Break

`scripts/chapters/chapter_one_break.gd::_play()` stages the ontological crack as a held, uninterruptible page. No world tick, prompt or menu can interrupt it. The order:

1. The frame widens and color begins to return (`widen_frame`, `return_color`); the case-board threads redden.
2. The cough plays twice, once after the threads redden and once after the glass turns amber.
3. Two seconds of total silence.
4. The glass breaks (`_break_glass`): `FLAG_DONE` is set, `state.finished = true`, the glass sound plays, and color returns further.
5. The beat ends. No dialogue card follows.

A save made from the break point onward resumes at the ending, never inside the beat. **This order matches Bible v18** (Part Three, Mechanics): the crack falls at the climax, and the cough is the only sound allowed before the glass.

## Tunnel Retreat and Walter's Lost Effects

The descent and the retreat now match Bible v18:

- **First `tunnel_descent` interaction:** plays `TunnelStory.ROCK_SPUR` (the spur catches Walter's coat, nothing is lost) and sets `tunnel_spur_seen`, exposed on `case_state.gd` as a property.
- **Later interactions** offer "Go on into the dark" or "Step back to the foundation support." Stepping back costs nothing.
- **Going on** plays the pressure and retreat cards. `_tunnel_turn_back()` then does the following at once:
  - empties the flask and records `flask_spill_amount`;
  - sets `flask_spilled`, `tunnel_retreated` and `badge_lost`;
  - grants `flask_spill`;
  - records "The badge and the whistle were lost on the retreat, with the flask torn away in the fall." to the case file (Law 4).
- **Personal effects:** `chapter_one_archive.gd` describes the badge as pocketed inside the plain coat before the loss and "lost below the estate, with the whistle and the flask" after. `paper_doll.gd` and `walter_model.gd` stop showing the badge.
- **Tests:** `tests/break_flow.gd` and `tests/phase_two_mechanics.gd` assert every step, including the plain-coat case and save/load of the loss state.

## Lounge Pantry Door

Before the steward names the pantry (`pantry_lead`), the door can be examined. The `portals/lounge.portal` `pantry_door` block, labelled "Examine the boarded pantry door," shows a flavor card and never travels. Once the lead is recorded, `town.gd::sync_pantry()` relabels the hotspot "Open the boarded pantry door" and it leads to the tunnel as before.

## Precinct Intake

The intake clerk is a required step before filing the estate report:

- `chapter_one.gd::_find_focus()` hides the "Submit the estate report" hotspot until `visited.has("intake_clerk")` or `intake_done`.
- `_town_interaction("intake")` repeats the check with a "Speak with the intake clerk" panel.
- When the clerk has been visited, `_intake()` skips the older scripted intake cards and falls back to a plain filing card if nothing else applies.
- `tests/town_flow.gd` walks to the clerk before filing.

Filing is on Day 1's critical path (sleep is blocked until `intake_done`), so watch this step in the cold playtest.

## Playthrough Telemetry

A per-playthrough session id (no personal data in the payload) tags a local event log. It captures:

- real minutes to the first meaningful objective;
- real and in-game minutes per district transition;
- distinct NPCs spoken to before each phase change;
- each completed conversation, including its `coat_state`;
- real time from Day 3's start to the final glass sequence (`day3_bed_reached` is a legacy name for this);
- an optional two-question debrief.

The pocket watch does not emit a distinct event.

**Transport and storage:**

- Events upload to one Cloudflare Worker (`three-colors-worker.dejunai.workers.dev`), which dual-writes to D1 (queryable) and R2 (raw batches). Writes are idempotent via a SHA-256 `event_key` under `INSERT OR IGNORE`.
- Ordinary batches are capped at 32 events. The client retires events only after `HTTPRequest.RESULT_SUCCESS` and a 2xx response. The Worker answers a successful write with HTTP 200 and `{"accepted": n}`.
- `debrief` and `session_end` go as one atomic final batch (plus up to 24 recently buffered pending events), sent via `navigator.sendBeacon` with a `text/plain` body on Web.
- A `pagehide` listener tells a genuine exit from a BFCache suspension.
- Return-to-title and quit offer the debrief early, with a Skip action.
- `session_end.dev_brisk_used` is sticky-true once the developer pace toggle (`F3`) is used. It is live in production D1.
- CORS is restricted to GitHub Pages, itch.io, and `:5173` for local development. Local builds served from any other port have their telemetry dropped, correctly.

See `docs/LOG_PLAYER_ASK.md` for the schema and privacy constraints. **Open defect:** client-side timestamps from the Web export have been observed off by about a day (Part Six).

## Character and Environment Models

All character, cast, corpse, prop and exterior-building models are Meshy-generated under the author's artistic direction. Two corrections are always needed after generation:

- **Scale.** Meshy normalizes every export to a roughly uniform bounding box, so each model is tuned against a known reference.
- **Texture size.** Raw exports ship with uncompressed 4K dual textures. Production assets are downsampled to 2K, or 1K where acceptable.

**Named characters**, each with a bespoke model and its own tuned `SCALE_FACTOR`:

| Character | Scale | Notes |
| ----- | ----- | ----- |
| Walter | 1.30x | `walter_model.gd`. Two rendered models share the wrapper: `walter_phase1.glb` (police coat, with a separate `Badge` node) and `walter_plain.glb` (plain clothes). `set_outfit()` shows one or the other and hides the badge when it's lost; coat swaps are confirmed live in both directions. |
| Captain Odell | 1.30x | Deliberately taller than Walter. |
| The gatehouse boy | 1.05x | |
| The club steward | 1.15x | Custom `Clean_Glass` idle. |
| Father Behan | 1.135x | `Idle`/`Idle_Alt`/`Listen`; `tests/behan_model_flow.gd`. |
| Coroner's assistant | 1.18x | `coroners_assistant_model.gd` (female model, `coroners_assistant.glb`), used for both the estate `assistant` and the scheduled `coroners_assistant_morgue`, which keep separate topic-completion identities; `tests/coroners_assistant_model_flow.gd`. The older `coroner_model.gd`/`coroner.glb` is no longer instantiated anywhere but its own test (Part Six). |

**Scale is settled.** Character heights are coherent with each other and with the doors, props and furniture around them, as confirmed by the author in play. This document tracks relative stature (Odell above Walter, the boy smallest) and each model's scale factor, not absolute heights in world units. Height figures in older revisions and in `.gd` header comments come from earlier scale passes and are not authoritative.

**Shared and generic models:**

- Six archetypes (`cast_upper_man/woman`, `cast_lower_man/woman`, `cast_observer_man/woman`) cover ambient NPCs. They are assigned by the deterministic `cast_model.gd::archetype_for_npc()`.
- A shared murder-victim model covers the six rose-garden dead.
- A shared covered-body model covers Naomi Freeman and her son, the son at a smaller child scale.

**Props and exteriors:**

- Five quay props (boat frame, cargo cluster, dock crane, dock shed, fishing boat) sit in `assets/models/waterfront/`, with 2K JPEG textures.
- Exterior building and landscape integration is complete across all five districts and the estate.
- Every pass keeps the original primitive shell hidden as the collision authority (`Legacy*CollisionVisuals`). The rendered model is presentation-only (`Rendered*Landmarks`/`Rendered*Frontage`).
- The estate's authored gate, rose garden and hedges are unchanged; only two tree/bush clusters were added, at the outer walls.
- The pass-by-pass records are in `docs/qa/*_MODEL_PASS.md`.

# Part Four — Build vs. Bible v18: Alignment Work

**Landed and verified** (commit `120a488`; all 38 suites passing):

- **The Ophion meaning is out of Chapter One.** `local_historian` `dr_fenn_library`'s annotations branch now describes Fenn's foreign catalogue citations and trips abroad for reading, granting `fenn_bibliographic_trail`. `displaced_god_doctrine` is gone. `ship_origin` and `tailor` `pruitt_family_naming` stay name-only.
- **Flask, badge and whistle are lost together on the retreat** (Part Three, Tunnel Retreat).
- **Observers are named:** Abel Tavares (groundskeeper, `crew`), Manuel Silva (harbor mason, `harbor_observer`), Enoch Vane (sail mender, `waterfront_sail_mender`), each with a colored-metal tell.
- **The old woman appears later** (Part Three, Story Actors).
- **The sixth man is investigable but unanswered.** Krebs now cut all six coats; the sixth was paid in cash to paper measurements, with no name and no fitting. `the_sixth_jacket` (the "grandfather's winter" line) stays `GATE: never`.
- **Offshore scenery** reads as buried (Part Two).

**Still open:**

1. **Law 5: two harbor-mason lines explain what the Bible allows only as a glimpse.**
   - `harbor_observer` `drowned_island`: "Our grandfathers learned in a single night what looking at that water costs… The insurance paid the big houses on the hill; the sea kept the men." This states the Observers' origin and the two inheritances outright.
   - `the_ring`: "To remind the eye what belongs to the daylight." This explains the color tell, which the Bible says only the tell itself may carry.
   - Rewrite both as refusals or glimpses. **(author call)**
2. **Scenery line out of date:** in `harbor_observer` `drowned_island`, Walter still says "The try-works buildings are still standing above the mud." The station now reads as buried.
3. **Abel's tell:** the build has "the dull copper band on his wrist." The Bible and the novellas have a colored **ring**. Align one to the other. **(author call)**
4. **The retreat card** (`tunnel_story.gd` `RETREAT`) says "The badge tears loose from its pin" even when the badge was pocketed under the plain coat. It needs coat-aware wording.
5. **Pronoun:** `story.gd`'s `testimony` fact still calls the coroner's assistant "He." The model is now female.
6. **Notebook labels:** two `harbor_observer` notebook lines (`observer_island_1`, `observer_pantry_refusal`) still call Manuel Silva "Mason"/"Harbor mason."
7. **Morgue coroner line:** `morgue_coroner.dialogue` puts stage directions ("The coroner spreads his hands…") in `THE CORONER`'s mouth, with a violin voice cue. It should be a bracketed stage direction or narration line, and silent.
8. **Birch victims and geography:** no change needed. Covered-body and case-file wording must never attribute the mother and son's deaths to the no-exit-wound method, and player-facing place references must fit Miskatonic County, Massachusetts, north of Boston.

**1918: optional content** (Bible v18, Part Two, "1918"). This is texture only. It follows the Bible's guardrails: never connected to the entity, no set piece, and no character naming the cough as influenza. Candidate places, all optional and all author calls:

- **Father Behan:** a parish burial list or register page with an October 1918 cluster, reachable through his existing topics.
- **County clerk / registrar:** the 1918 death register as a document Walter can consult. One or two entries of the cult's earlier victims can sit there under a cause that doesn't hold up. Only one lead may come from this, and it must be backed by a second source (Laws 4 and 13).
- **Dr. Fenn:** a run of death certificates from October 1918 in his hand, next to the certificate he signed for Constance. This is an object/record, not dialogue.
- **Set dressing:** a faded quarantine notice pasted under a newer bill on Pickman Street or at the post office; a churchyard corner with 1918 dates; masks at the back of a drawer in Walter's room or at Mrs. Almy's.
- **Ambient lines:** at most one or two residents' `default` lines touching the autumn of 1918 in passing (a lost child, a closed school), never explaining it.
  - Ready to place: *"Six in one night. Haven't seen the undertaker's wagon that busy since October of '18."*
    - Give it to one Pickman Street resident as a weighted `default`, gated to the first day or two after the deaths, so it plays as fresh news and then fades.
    - "Six" is deliberate. The townsperson repeats the town's count, not the true eight.
- **The morgue's six tables:** a town this size would normally keep one or two. The extra tables were added during the influenza, so the room built for the last catastrophe fits this one exactly. Nobody in the game points this out. It can surface through:
  - *Examine text on the tables* (a morgue object hotspot): *"Six tables. Four newer than the others, the enamel still bright. The county put them in during the autumn of '18 and never took them out."*
  - *One flat, work-detail line from the coroner's assistant* in a morgue topic: *"We ran two tables until '18. The county added the rest that October."*
  - *Optional, author call:* a small brass plate on the newer tables naming the Ophion Club as donor. It's the kind of civic gift the six would have made after 1918, and the kind the Gazette would have praised them for. It must only ever be findable, never remarked on, the same treatment as the Observers' color tell. It's close to too neat, so use it only if it still reads as coincidence in play.

# Part Five — Decisions Needed

These need an author decision before build work can proceed. Nothing else in this document is open in this sense.

1. **Chapter Two/Three audio contract.** The shared interpreter extension is settled; the audio it carries is not. The options are full spoken audio, an extension of Chapter One's instrumental-cue system, or something else. This also decides whether the player character is voiced in later chapters.
2. **`walter_certainty` (proposed, not decided).** A single tracked int, nudged (never gated) by the type of investigative choice:
   - Accept-at-face-value choices push toward "dutiful son."
   - Cross-referencing and pursuing discomfort push toward "trapped Ethan."
   - Both poles hit the same fixed beats; only the epilogue framing text differs, as a presentation-layer lookup (`beat_id, certainty_band → text_variant`) above the `GATE:` engine. That placement is the proposal's own claim and hasn't been verified against the engine.
   - Open sub-questions: does it persist across chapters? Can `.portal` encounters move it? Two poles, or a third variant at the extremes?
3. **Coping mechanisms vs. Design Law 11** (a Bible question, logged here because it blocks mechanical design).
   - Law 11 limits hidden coping values to presentation effects.
   - Ward's opium eases jump difficulty, which is mechanical, and Walter's flask "helps him function longer," which is undefined mechanically.
   - A possible resolution: coping supply is always inspectable as an object, so its mechanical relief counts as a visible effect the player chose to spend. That would amend a Law, so it's the author's call.
4. **Ekon's sealing fuse.** Bible v18 fully specifies his fatal outcome and the preservation/denial archive. The only open question is whether his final action includes lighting a sealing fuse as a staged beat, separate from the archival "sealing." The canonical novella `10` has him light one.

**Resolved since v45; do not re-open:** the tunnel exhausted-resources fail state. Bible v18 (Part Six, The Stat System) specifies it: a protagonist cornered by a fully transformed cultist with nothing left to spend is killed outright, death and reload, never a stalemate. That is now an implementation task for when the full tunnel is built, not a decision.

# Part Six — Known Limitations and Technical Debt

- **Publishing is dormant.** See Part Two. This blocks the cold playtest.
- **Telemetry timestamps.** Client-side timestamps from the Web export have been observed roughly a day off. `playthrough_log.gd` stamps with `Time.get_datetime_string_from_system(true)`, and the Worker stores the value verbatim. Root cause unconfirmed. Until it's fixed, telemetry dates can't be cross-checked against itch.io counts.
- **Backup routes.** `tests/backup_route_flow.gd` verifies that all 13 redundant-carrier backup topics are reachable, gate against the primary evidence being absent, and grant the intended evidence. A scripted check that the three investigative threads have no content-level soft locks is still open.
- **Orphaned coroner model.** `coroner_model.gd`/`coroner.glb` is still preloaded in `estate.gd` and `chapter_one_dialogue.gd` and still has its own suite (`tests/coroner_model_flow.gd`), but nothing instantiates it since the coroner's-assistant model replaced it. Either remove it or give it to the morgue coroner, who currently has no rendered figure (confirm that too).
- **Conversation/travel time scale.**
  - `DEFAULT_MINUTES` is 5.0, and every corpus `TIME:` carries a +2 adjustment.
  - `TRAVEL_MINUTES` is 30.0. `day_clock.gd`'s `CONVERSATION_MINUTES = 30.0` applies only to a small enumerated list of legacy story scenes.
  - The tuning feels better in spot tests but hasn't been validated by a full end-to-end playthrough.
  - A `WANDER_RATE` rise from 5x to 7x is gated on that validation.
- **Bridge cooldown test.** `chapter_one.gd::on_bridge_crossed()` enforces a 60-second real-time cooldown per bridge id. No test exercises it by name.
- **NPC-to-NPC eavesdropping is deferred by the author.** Only the fixed `speakeasy_bar` exchange exists. A general system would first need four things that don't exist today:
  - NPC proximity detection;
  - positional continuous audio;
  - a two-speaker, choice-less dialogue shape;
  - deliberate co-scheduling of two NPCs.
- **Items from the Perplexity/Manus review, not yet re-verified:**
  - a per-physics-frame `_find_focus()` raycast throttle;
  - uncached procedural meshes in `estate.gd`;
  - a travel-teardown-ordering runtime test;
  - `tests/audit_dialogue_ast.gd`'s field allowlist is missing five fields the runtime registers (`rose_bodies_removed`, `birch_bodies_removed`, `lounge_exited`, `report`, `report_filed`). This is latent: no current gate uses them.
- **Test harness isolation.** Some focused tests read and write a real `user://` save path, so state can leak between back-to-back runs. The aggregate sets `APPDATA` to `.runtime-data`; focused runs don't.
- **`docs/qa/` and repo-root housekeeping.** There are 30+ dated pass reports plus fifteen or more `qa_*.png` captures at the repo root, which Godot imports. Triage them into a keep/archive split.
- **`walter_certainty` engine placement is unverified** (see Part Five).

# Part Seven — Narrative Canon (Settled)

The Bible is the authority; this list is a build-facing index of canon points that content and code must respect. Revision history is in the HCL.

- **The night of the murders is in two acts** (Bible v18, The Crime).
  - First, the cult mutilates Naomi Freeman and her son past the birches as a sacrifice.
  - Then the six die in the rose garden, each by a materialized bullet with no exit wound.
  - "No exit wound" belongs only to the six; the mother and son are never counted among its dead.
- **The two official records.** The sanitized replacement file names the six (as a gas-main failure) and omits the mother and son. A separate, unconnected county record names them under "transients." Walter's investigation is what recovered their names.
- **The six are dead from the opening** in all three Chapter One tellings (`01`, `04`, `08`). The investigation is posthumous.
- **The sixth man is never named anywhere.** He can be investigated, but nothing implies a name exists. The tailor, Krebs, cut all six club coats; the sixth was paid in cash to paper measurements, with no name given.
- **Ekon Freeman** was born about 1902 and was 21 and living independently in 1923, working the New Bedford yards when his mother went north to Widow's Bight without him. He is about 40 in Chapter Three: a veteran who served and was discharged. His first name comes from his mother's free Black whaling line. The discharge's historical basis is a content-pass research task.
- **Ward's book** was bought secondhand from a Boston dealer before his posting. It is Fenn's copy, with Fenn's underlining and Ward's annotations.
- **The Ophion meaning:** Chapter One gets the name only; the myth reaches the player through the book.
- **The glass-shatter crack** falls at Chapter One's climax in every telling and in the build: the frame widens, color returns, then the glass breaks. The cough may sound before it; nothing else may. `08`'s earlier washstand moment is now a silent near-miss, not the crack.
- **Walter's effects:** badge, flask and whistle are lost together on the retreat in all three tellings, and found together by Ward and Ekon.
- **Abel Tavares** is the young estate-crew member with the colored ring in Chapter One, the continuity Observer across all three decades. In the build he is the groundskeeper (`crew`). Other named Observers: Manuel Silva (harbor mason) and Enoch Vane (sail mender).
- **Sarah Munn** is named in all three Chapter One tellings. The older vanished "kitchen maid" remains deliberately unnamed and distinct from her.
- **Walter lodges** in a rented room above the cobbler's shop on Pickman Street.
- **Constance's illness has two phases.** Before the war it was chronic and ambiguous, enough to earn Walter his 1917 exemption, and never settled as illness vs. control. From the autumn of 1918 she survived the influenza and was bedridden for the "four winters" until her death eleven months before Chapter One. The cough Walter remembers comes from 1918; nothing in the game says so.
- **1918** is shared background for everyone alive in the story. It is never connected to the entity, and no character names the cough as influenza.
- **Geography:** Widow's Bight is on the Massachusetts coast north of Boston, in Miskatonic County, and reached by packet north. The county registrar sits at the county seat, and the paper is the Miskatonic Gazette. New Bedford is a hundred-odd miles down the coast.
- **Ekon's death in `10`** is unambiguous: he has lit the fuse and chosen collapse over retreat, a choice neither Walter (turned back) nor Ward (kept by the tunnel) was lucid enough to make.

One low-confidence inconsistency is left uncorrected. `01` has Walter pass "three" crew at the hedge; `04` has him count "four" on a different afternoon. These may be two different moments.

# Part Eight — Next Steps

Unchanged production direction: *validate and improve the first 30 minutes of investigation (discovery, social consequences, evidence linking, and a compelling next lead) before expanding production toward the chapter's climax.* The 30-minute figure was always a target for that opening beat, not a ceiling on the three-day slice.

In priority order:

1. **Restore a publish path** (Part Two): a `workflow_dispatch` or artifact-upload step for Pages, plus a deliberate merge-and-publish checkpoint the author signs off. Nothing below can reach an outside tester without this.
2. **Scripted soft-lock pass across the three investigative threads.** The backup-route reachability test has landed (Part Six).
3. **A cold playthrough of the development build by someone confirmed not to be the author.** Focus it on whether the opening 30 minutes' three investigative threads land.
   - The placeholder-model deterrent that blocked a known candidate playtester is largely addressed on this branch.
   - Whether it changes that playtester's answer hasn't been re-tested.
4. **Remaining Bible v18 alignment** (Part Four, "Still open"), items 1–2 first, since the harbor mason is reachable in the opening.
5. **Address whatever the cold playthrough surfaces** in the opening 30 minutes before touching anything past it.
6. **Telemetry timestamp defect** (Part Six). Fix it before relying on telemetry dates from outside players.
7. **Web-profile comparison** of the district texture pass against the pre-texture baseline (load time and memory), on a published build.
8. **Validate the time scale** with a full playthrough, then decide on `WANDER_RATE`.
9. **Playtest the ElevenLabs cue library in context.** Hand-tune individual `VOICE:` assignments only where delivery clashes with the line.
10. **"More life" stages.**
    - Stage 1, the contiguous town: done.
    - Stage 2, scheduled population: in progress, with 23 scheduled ambient NPCs across four districts on top of the original six.
    - Stage 3, backup routes: authored.
    - Stage 4, ambient eavesdropping: deferred.
    - Stage 5, the pocket watch: shipped.
11. **Housekeeping:** the orphaned coroner model, the bridge cooldown test, `docs/qa/` and repo-root triage.

**Explicitly not current priorities:**

- the fatal-comprehension ending;
- Chapter Two's playable slice and trinket/procedural-geometry pipeline;
- the Chapter Two/Three audio decision;
- the per-protagonist presentation scheme;
- Ekon's sealing-fuse staging;
- the Part Seven (Bible) difficulty screen and achievement registration;
- gamepad support and key rebinding;
- NPC-to-NPC eavesdropping;
- further work toward the HPLHS pitch.
