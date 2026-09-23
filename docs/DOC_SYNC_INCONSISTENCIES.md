# Bible and TDD inconsistencies with the live codebase

Audited 2026-09-19, re-checked 2026-09-20 against repository HEAD, refreshed 2026-09-23 against **TDD v45**. This is the separate discrepancy register requested during the documentation sync. The Design Bible and TDD were read but intentionally not edited in this register's original pass, and were again not edited on 2026-09-23 (this file only was refreshed; see the dated pass at the bottom). The Bible remains the narrative/design authority; the TDD is expected to describe the implementation and should be revised where its concrete claims have gone stale. Current TDD on disk: `docs/design/07) Three Colors of Madness — TDD v45.md`.

## Verified live baseline

- `CaseState.VERSION` is 11 and accepts save versions 1–11.
- `dialogue/` has 72 root files: 71 concrete NPC definitions plus one template. `tests/dialogue_catalog_flow.gd` passes with **71 NPCs and 449 nonempty runtime topics**. Raw source has 465 `TOPIC:` headers because documentation-only blocks are excluded.
- `tests/instrument_voice_flow.gd` passes with the 144-cue manifest and **723 NPC lines**, including default-cue fallback.
- `objects/` has three live content files plus one template; all eleven scoped hotspots remain migrated.
- `portals/` has five live content files plus one template; ten live portal ids remain migrated.
- The maintained 12-suite aggregate (`python tests/run_all_qa.py`) is clean in `qa_run_log.txt`.
- Focused checks run during this audit: dialogue catalog PASS; placement audit PASS (62 living NPCs, zero coordinate collisions across morning/noon/evening/night); speakeasy PASS; instrument voices PASS.
- Personal Effects now uses a state-driven paper doll for coat, badge, notebook, revolver, flask and boots. Its compact closed-watch icon opens the live analogue face, with exact text retained for accessibility, a 6 AM/6 PM sun–moon aperture, and a midnight ceiling. F3 toggles the development Shift pace between 4.0 and 10.5 for the current process.
- Telemetry accepts eight event types and dual-writes individual events to D1 plus raw request batches to R2. `watch_checked` is not one of those event types.

## TDD v43 items: superseded by TDD v44, then v45 (provenance retained; corrected 2026-09-20 / resolved further 2026-09-23)

The six items below were logged against **TDD v43** on 2026-09-19. The TDD was subsequently bumped to **v44**, which already carried the correct dialogue/instrument counts and marked items 4–6 RESOLVED and item 7's night-scheduling wording precisely. Item 3 (pocket-watch telemetry) remained a genuine open gap in v44. **TDD v45** (full rewrite from v44; current file on disk as of 2026-09-23) no longer credits a distinct `watch_checked` telemetry event, so item 3 is now RESOLVED as well. Retained below for provenance; do not treat items 1–7 as current TDD problems.

1. ~~Dialogue totals are stale.~~ Fixed in v44: "71 NPCs and 449 nonempty authored `TOPIC:` blocks... confirmed live 2026-09-20."
2. ~~Instrument-line count is stale.~~ Fixed in v44: "723 NPC lines."
3. ~~Pocket-watch telemetry is credited but does not exist.~~ **RESOLVED in TDD v45 (confirmed 2026-09-23).** Was still open in v44: Part Four listed `watch_checked` among captured metrics while neither `playthrough_log.gd` nor the Worker's `EVENT_FIELDS` contained `watch_checked`. TDD v45's Part Four playthrough-telemetry paragraph now states plainly that the pocket watch does not currently emit a distinct telemetry event (see also `docs/LOG_PLAYER_ASK.md`). Code, Worker allowlist, `docs/ARCHITECTURE.md`, and `docs/LOG_PLAYER_ASK.md` already agreed on that fact before this refresh; the former inconsistency was TDD wording only.
4. ~~Placement-audit failure.~~ v44 marks this RESOLVED with the same evidence (62 NPCs, zero collisions).
5. ~~Staging assertion failure.~~ v44 marks this RESOLVED via the integrated `--qa-staging` runner.
6. ~~Speakeasy failure.~~ v44 marks this RESOLVED, confirmed live 2026-09-20.
7. ~~Night scheduling wording too absolute.~~ v44's Part Three already names the `NIGHT_ACTIVE` exception list precisely (`speakeasy_bartender`, both night owls, `lamplighter`) rather than stating an absolute rule.

## Working-tree note: an uncommitted TDD v44 edit exists, not made by this session *(historical — TDD on disk is now v45 as of 2026-09-23)*

As of 2026-09-20, `git status` shows one uncommitted modification to `docs/design/07) Three Colors of Madness — TDD v44.md` on top of the last commit (`72f159d`, "second attempt"). It updates one paragraph's status from "implemented but not yet committed" to "confirmed committed (`72f159d`) and independently re-verified live... full `python tests/run_all_qa.py` pass (all 13 suites) is clean." This reads like an in-progress TDD self-maintenance edit from a concurrent session, consistent with this project's documented multi-agent workflow. Per the working-tree discipline this repo already follows: this change was left untouched and is not evaluated further here — it is not this pass's edit to make or unmake.

**2026-09-23 note:** that uncommitted-v44 working-tree situation is provenance only. The live design file is now **TDD v45** (`docs/design/07) Three Colors of Madness — TDD v45.md`); no v44 file remains under `docs/design/`.


## Design Bible v17: implementation gaps, not proposed Bible edits

These are differences between the complete intended work and the present vertical slice. Most are declared scope gaps rather than violations.

1. **Continuous player-responsive presentation degradation is not built.** The Bible requires aspect ratio, color, sound and distortion to degrade continuously according to play, with different collapses across runs. The live slice has film settings and authored thresholds—the opening iris and the final frame/color/glass sequence—but `chapter_one_break.gd` is a fixed ending beat driven by flags, not the continuous hidden behavior-responsive system.
2. **Chapter One stops at the ontological crack, before fatal comprehension.** The Bible's Law 1 and Chapter One arc end Walter through understanding. The published slice deliberately stops after the glass breaks, before the entity, Constance's voice and Walter's death. This is a bounded-slice cutoff, not an alternate ending.
3. **Observer continuity is only represented in prototype form.** The Bible requires named individual Observers, including Abel Tavares recognizable across all three decades, with schedules and relationships and no reduction to generic interchangeable NPCs. Chapter One currently stages the groundskeeper/harbor color tell and precise refusal, but no Abel Tavares identity or cross-decade implementation exists yet.
4. **The full presentation baseline is incomplete.** The Bible treats Walter's sound/color baseline and later breakdown as a complete chapter system. The slice implements the instrumental pit-band convention, cough motif, Observer accents, selective red/amber return and glass crack, but full audio design and the later degradation/fatal sequence remain unfinished.
5. **The guaranteed minimum-comprehension floor cannot yet be validated.** Law 13 requires even the least-investigative route to reach the fatal understanding by a harder path. The current slice ends before that understanding, so its minimum route can prove progression to the crack but cannot yet prove the law's full-chapter guarantee.
6. **Cross-chapter consequence promises remain future work.** Walter's carried-forward case record, Ward/Ekon play, the six-to-ten persistent-state budget and the Post-Finish Archive are described by the Bible but are not implemented in this Chapter One slice.

## Documents synchronized in this pass

- `README.md`: corrected desk/bed progression, full slice route, catalog counts, pocket watch/F3 controls, D1+R2 telemetry, aggregate QA guidance and contiguous-waterfront wording.
- `docs/ARCHITECTURE.md`: corrected timing semantics, catalog totals, staging coverage, schedule terminology and telemetry architecture.
- `docs/PLAYTEST.md`: replaced the obsolete opening-only checklist with a current three-day/service-passage/glass-break cold-play protocol.
- `docs/LOG_PLAYER_ASK.md` and `docs/qa/PLAYER_LOG_ENDPOINT_HANDOFF.md`: corrected R2-only history to current D1+R2 dual-write, conversation events, duration normalization, ending hook and pocket-watch telemetry gap.
- Historical montage-era briefs and QA records were not rewritten as if they had always described the present build. They now carry a prominent current-status annotation and retain their original evidence beneath it.

## 2026-09-20 pass: additional fixes

- `README.md`: the portal-system paragraph incorrectly said an omitted `TIME:` "preserves the travel system's automatic charge" (a leftover from an earlier code path). Direct read of `portal_lang.gd` (default `timing = "3"`) and `chapter_one_portals.gd::_perform_go()` (the `is_valid_float()` branch is always taken) confirms an omitted `TIME:` always defaults to 3 minutes, charged once per portal identity on first completion — corrected to match `docs/ARCHITECTURE.md` and `docs/PORTAL_AUTHORING.md`, which already had this right.
- `docs/DIALOGUE_AUTHORING.md`: still said a substantive topic with no authored `TIME:` falls back to 3 minutes. `dialogue_runtime.gd`'s `DEFAULT_MINUTES` moved to `5.0` on 2026-09-20 (see `docs/qa/PACING_AND_CONSISTENCY_AUDIT_2026-09-20.md` and the TDD v44 pacing-tuning paragraph); corrected.
- `docs/qa/TDD_PENDING_NOTES.md`: one deep "Still open, carried forward (unchanged by v42)" bullet still literally named `town_expansion_flow.gd`/`staging_flow.gd`/`test_placement_audit.gd`/`speakeasy_flow.gd` as unresolved, even though the same file's own top banner and TDD v44 both mark them resolved. This exact staleness was flagged by `docs/qa/PACING_AND_CONSISTENCY_AUDIT_2026-09-20.md` as something the 2026-09-19 sync pass didn't catch (it only diffed Bible/TDD against source, not this holding-pen file). Struck through in place with a resolved annotation rather than deleted, preserving provenance.
- `docs/ARCHITECTURE.md`: added a new dated section, "Day-clock pacing tuning and bridge cooldown (September 20, 2026)," documenting the `DEFAULT_MINUTES` 3→5 change, the corpus-wide +2 minute `TIME:` adjustment, and the new `BRIDGE_COOLDOWN_SECONDS = 60.0` per-bridge cooldown in `chapter_one.gd::on_bridge_crossed()` — none of which any current-facing doc described before this pass.
- `docs/qa/PACING_AND_CONSISTENCY_AUDIT_2026-09-20.md` (not written by this session) is a thorough, source-verified answer to "why does the slice now run 45–60 minutes instead of the ~30 originally scoped" — its conclusion (retired opening-only target, not a regression) and its one flagged doc staleness were both independently confirmed and acted on above.

## Historical snapshots retained intentionally

Files under `docs/qa/` often state counts, schema versions and pass results that were true on their named date. A synchronization pass should not falsify that provenance by replacing every historical number with today's number. The new banners distinguish those records from live guidance. Current implementation authority is now `README.md`, `docs/ARCHITECTURE.md`, the three authoring guides, `docs/PLAYTEST.md`, live source, and live tests.

## 2026-09-21 pass: character/landmark model integration was undocumented in README/ARCHITECTURE

A large batch of same-day commits (`fc0c02d` through `f84277f`, roughly 10:36-19:14) integrated rendered Meshy-generated GLB models for Walter, Captain Odell, the coroner's assistant, the club steward, Father Behan, the gatehouse boy, six background-resident archetypes, the estate's murder victims, the covered bodies of Naomi Freeman and her son, and five hero quay props. None of this was reflected in `README.md` or `docs/ARCHITECTURE.md` before this pass, and README's opening line still called the whole build "primitive art," which had gone stale. Verified directly (not just relayed): all nine `scripts/shared/*_model.gd` adapter files exist, and the three docs/qa passes that do exist (`WALTER_MODEL_PHASE_ONE.md`, `ODELL_MODEL_PHASE_ONE.md`, `QUAY_PROP_AUDIT_2026-09-21.md`) were read in full. The coroner, steward, Father Behan, gatehouse boy, cast-archetype, victim and covered-body models have no written QA pass doc — only their `tests/*_model_flow.gd`/`*_model_integration_flow.gd` suites, which were spot-run directly (not assumed) as part of the discovery below.

**Fixed**: `README.md` (opening line qualified, new "Character and landmark models" section, quay props added to the Waterfront district section, file inventory updated, suite count corrected) and `docs/ARCHITECTURE.md` (new "Character and landmark model integration (September 20-21, 2026)" section) now describe this work, mirroring each doc's own established style (README as player/feature-facing prose, ARCHITECTURE as a dated technical section).

**Also found and fixed, a real code/aggregate-runner gap, not just a doc gap**: `tests/run_all_qa.py`'s "maintained aggregate" was missing three test files that exist on disk and pass cleanly — `tests/walter_model_flow.gd`, `tests/odell_model_integration_flow.gd`, and `tests/waterfront_prop_assets_flow.gd` — left out when their sibling entries were added. Ran all three directly against the Mono console engine to confirm a clean pass before adding them (`WALTER MODEL PASS`, `ODELL MODEL INTEGRATION PASS`, `WATERFRONT PROP ASSETS PASS`, no assertion failures). The aggregate is now 33 suites, not 30; `README.md`'s "Verification and source" section is corrected to match. This was not something the TDD or any `docs/qa/*.md` pass had flagged.

**Not evaluated further this pass**: whether the missing per-character QA pass docs (coroner/steward/Behan/boy/cast/victim/covered-body) should be written. That is additional documentation work, not a sync of existing docs against existing code, and was left for a session explicitly asked to produce them.

**TDD note (not an edit, not a claimed inconsistency)**: TDD v44 (`docs/design/07) Three Colors of Madness — TDD v44.md`, last modified 2026-09-20) predates all of this same-day work and does not mention it. This is not a disagreement between the TDD and source — the TDD simply hasn't been revised since — but is noted here so the next TDD revision has a pointer to what needs folding in: the character/landmark models above, and the 30→33 aggregate suite-count correction. *(Superseded pointer: the 2026-09-22 pass below folded this into v44, and TDD v45 later restated the settled model state. Not re-opened 2026-09-23.)*

## 2026-09-22 pass: TDD v44 updated for the model-integration/telemetry pointer above; one ARCHITECTURE.md figure found stale against live source

Following through on the pointer left in the entry immediately above, TDD v44 gained a new Part Three subsection ("Character and Environment Models") covering the same character/cast/corpse/prop/exterior-building model work this document's 2026-09-21 pass already documented in `README.md`/`docs/ARCHITECTURE.md`, plus a Part Four entry for a separately-found telemetry gap (`debrief`/`session_end` events not landing — zero `session_end` rows and one `debrief` row across the D1 table's full 36-session history, confirmed live against `three-colors-db`, including the author's own verified-progression speedrun test), and an updated Part Six note on the placeholder-model playtester-deterrent item (narrowed, not resolved, now that most named/cast/corpse/prop models are real).

Cross-checking the new TDD entry against `docs/ARCHITECTURE.md`'s own 2026-09-21 "Character and landmark model integration" section surfaced one real, live-source-confirmed discrepancy: ARCHITECTURE.md listed Captain Odell's model scale as `1.18x`. Direct read of `scripts/shared/captain_odell_model.gd` (not taken on report) shows `const SCALE_FACTOR: float = 1.30`, with the script's own comment confirming this was a deliberate tuning pass ("Odell is commanding and imposing, visibly standing above Walter") landed in commit `2101743` — the same commit this session's HCL entries and the new TDD section already cite for this figure. ARCHITECTURE.md's 1.18x reads as Odell's original pre-tuning integration value, left stale when the later scale pass landed. Fixed directly in `docs/ARCHITECTURE.md`: Odell's bullet now reads 1.30x/~2.34m with the tuning-commit note, and the coroner's adjacent bullet had its now-inaccurate "peer height with Odell" phrase corrected, since Odell is no longer that height. TDD v44's figure needed no correction — it already had this right from independent verification earlier the same day.

## 2026-09-23 pass: DOC_SYNC refreshed against TDD v45; watch_checked marked RESOLVED

Scope of this pass: refresh this register against the current TDD on disk (**v45**, a full rewrite from v44 — file `docs/design/07) Three Colors of Madness — TDD v45.md`). Design Bible and TDD were **not** edited. Living docs were spot-checked only.

- **Framing:** TDD pointers in this file that still spoke as if v44 were current were updated to name **TDD v45**. Historical v43/v44 provenance blocks were kept (struck-through / annotated), not deleted.
- **Item 3 (`watch_checked`) — RESOLVED.** Direct read of TDD v45 Part Four ("Playthrough telemetry") confirms: "The pocket watch does not currently emit a distinct telemetry event." Spot-check of `docs/LOG_PLAYER_ASK.md` (allowlist omits `watch_checked`; proposed event remains unimplemented) and this file's own verified baseline ("`watch_checked` is not one of those event types") already agreed with code/Worker. The former inconsistency was TDD-v44-and-earlier wording that credited the event; living docs did **not** disagree with source, so they were left untouched.
- **Design Bible v17 scope gaps (items 1–6 under that heading):** still open as declared scope gaps, not TDD wording bugs. Unchanged this pass.
- **Not invented:** no new inconsistency rows were added. Model-integration / Odell-scale / aggregate-suite history above remains provenance; this pass did not re-audit those against v45 beyond confirming the watch telemetry claim that was the open TDD wording gap.
