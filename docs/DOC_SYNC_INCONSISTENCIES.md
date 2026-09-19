# Documentation sync inconsistencies

Reviewed 2026-09-19 against the current source tree. This is an issue register, not an authority over narrative design. The Design Bible and TDD were intentionally left unchanged.

## Bible and TDD: not edited

- `docs/design/0) Three Colors of Madness — Design Bible v17.md` remains the authority for narrative and design-law conflicts. Any implementation or documentation disagreement with it must be resolved by the author rather than silently rewritten here.
- `docs/design/07) Three Colors of Madness — TDD v43.md` remains the authority for the current technical record. Its snapshot claims were not rewritten during this pass; where they differ from the live tree, the discrepancy is listed for author review.
- The current TDD snapshot reports 70 NPCs and 438 nonempty topics, while the source tree currently contains 72 root `.dialogue` files, 71 non-template files, and 465 `TOPIC:` headers. These are not interchangeable measures: parser-reachable nonempty topics should be obtained from `tests/dialogue_catalog_flow.gd`, not from raw header counts.
- The TDD's portal inventory and historical migration counts should be checked against the current five authored portal files: `estate.portal`, `lounge.portal`, `lower.portal`, `town.portal`, and `tunnel.portal`.

## Historical QA records

- `docs/qa/DIALOGUE_LIVE_PASS.md`, `docs/qa/SESSION_HANDOFF_2026-09-09.md`, and similar dated pass notes contain deliberately frozen counts and schema numbers from their test date. They should not be rewritten to current values unless their purpose changes from historical record to current reference.
- `docs/qa/DAY_CLOCK_PASS.md` and `docs/qa/WATERFRONT_PASS.md` retain older schema references as historical snapshots. The live `case_state.gd` schema is 11.
- `docs/qa/TDD_PENDING_NOTES.md` is a shared holding-pen document maintained by another workflow. It was read for context and not edited.

## Current-facing items checked

- `README.md` was stale about the TDD version and save-migration wording; those current-facing references are now corrected. Its long dialogue and portal inventory lines still need a byte-accurate content update after the live parser count is confirmed.
- `docs/ARCHITECTURE.md` was stale in its schema acceptance sentence; it now reflects the explicit version-11 whitelist in `case_state.gd`.
- `docs/DIALOGUE_AUTHORING.md`, `docs/OBJECT_AUTHORING.md`, `docs/OBJECT_MIGRATION_HOWTO.md`, `docs/PORTAL_AUTHORING.md`, and `docs/LOG_PLAYER_ASK.md` were reviewed as current-facing references. No edit was made where their live behavior matched the source or where a statement was explicitly marked historical.