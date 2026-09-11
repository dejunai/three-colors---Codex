# Colored case presentation — 2026-09-11

Implemented by Codex at Dejunai's request. Visual reference: Grok's local three-colors-corkboard-sampler. Borrowed the presentation direction only; no sampler prose, clothing filters, inference thresholds, state logic, or code was imported.

- Warm paper, brown ink, cork texture, brass pins and red twine remain colored above the existing film presentation layer.
- Board cards show recorded titles, excerpts and current recorded source attribution. Opening a card still uses the existing observation detail and two-step Link picker.
- Threads represent confirmed LINKS only. Cards, threads and pins share one scrolling coordinate system; resize recalculates their layout. Thread decoration ignores mouse input and preserves keyboard buttons.
- Notebook uses ruled paper. Existing confirmed deductions appear before observations. Its renderer still receives detached snapshots and never changes CaseState. Coat changes do not filter recorded notes.
- The board's complete-notebook button now opens the notebook directly.
- No CaseState, Perception formula, save format, dialogue, world shader, web export or deployment changes.

Validation: tests/color_case_flow.gd passes, covering unchanged case snapshots on opening, confirmed threads, exclusion of self-links, and card bounds at 960x640 with text scale 1.3. Native Godot screenshots inspected at 1440x900 and 960x640; adjusted title/excerpt separation after enlarged-text inspection. Existing --qa-usability passes including the visible Link entry point and picker. Test runs were made in an isolated staged copy; user saves were not used as fixtures.

This is a first native Godot presentation pass. Cards remain automatically arranged, with full detail available on selection. It does not add freeform card dragging or a simultaneous side-by-side notebook editor.
