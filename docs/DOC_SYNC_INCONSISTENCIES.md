# Bible and TDD inconsistencies with the live codebase

Audited 2026-09-19 against repository HEAD. This is the separate discrepancy register requested during the documentation sync. The Design Bible and TDD were read but intentionally not edited. The Bible remains the narrative/design authority; the TDD is expected to describe the implementation and should be revised where its concrete claims have gone stale.

## Verified live baseline

- `CaseState.VERSION` is 11 and accepts save versions 1–11.
- `dialogue/` has 72 root files: 71 concrete NPC definitions plus one template. `tests/dialogue_catalog_flow.gd` passes with **71 NPCs and 449 nonempty runtime topics**. Raw source has 465 `TOPIC:` headers because documentation-only blocks are excluded.
- `tests/instrument_voice_flow.gd` passes with the 144-cue manifest and **723 NPC lines**, including default-cue fallback.
- `objects/` has three live content files plus one template; all eleven scoped hotspots remain migrated.
- `portals/` has five live content files plus one template; ten live portal ids remain migrated.
- The maintained 12-suite aggregate (`python tests/run_all_qa.py`) is clean in `qa_run_log.txt`.
- Focused checks run during this audit: dialogue catalog PASS; placement audit PASS (62 living NPCs, zero coordinate collisions across morning/noon/evening/night); speakeasy PASS; instrument voices PASS.
- The pocket watch is a live analogue face in Personal Effects, with exact text retained for accessibility, a 6 AM/6 PM sun–moon aperture, and a midnight ceiling. F3 toggles the development Shift pace between 4.0 and 10.5 for the current process.
- Telemetry accepts eight event types and dual-writes individual events to D1 plus raw request batches to R2. `watch_checked` is not one of those event types.

## TDD v43: concrete stale claims

1. **Dialogue totals are stale.** Part Two says 70 NPCs/438 topics twice. Live parser-authoritative totals are 71 NPCs/449 nonempty topics. The TDD should avoid substituting the 465 raw header count.
2. **Instrument-line count is stale.** Part Two says 705 voiced NPC lines. The current focused audit reports 723.
3. **Pocket-watch telemetry is credited but does not exist.** Part Four says the captured metrics include whether the player checks the Tab-menu pocket watch. The watch UI exists, but neither `playthrough_log.gd` nor the Worker's `EVENT_FIELDS` contains `watch_checked`.
4. **Placement-audit failure is resolved.** Part Five still calls `tests/test_placement_audit.gd`'s truncated `pri` parse error open. The identifier is repaired; the suite now passes with 62 living NPCs and zero coordinate collisions across all phases.
5. **Staging assertion failure is resolved.** Part Five still calls `tests/staging_flow.gd`'s gatehouse-boy assertion open. The test now checks authored weighted return dialogue, restored steward repeat chatter, the live sleep/debrief path, and passes through its integrated runner.
6. **Speakeasy failure is resolved.** Part Five still calls line 60's eavesdropping assertion open. `tests/speakeasy_flow.gd` now passes daytime lockout, coat rejection, evening/plain entry, five-card eavesdropping, evidence recording and return.
7. **Night scheduling wording is too absolute.** Part Three says catalog residents are empty at night regardless of authored schedule. `dialogue_catalog.gd` explicitly permits the four `NIGHT_ACTIVE` actors (`speakeasy_bartender`, both night owls and `lamplighter`) and then applies their authored schedule. Ordinary residents do close at night.

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

## Historical snapshots retained intentionally

Files under `docs/qa/` often state counts, schema versions and pass results that were true on their named date. A synchronization pass should not falsify that provenance by replacing every historical number with today's number. The new banners distinguish those records from live guidance. Current implementation authority is now `README.md`, `docs/ARCHITECTURE.md`, the three authoring guides, `docs/PLAYTEST.md`, live source, and live tests.
