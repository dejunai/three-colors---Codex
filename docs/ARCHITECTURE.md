# Active architecture and interaction contract

The active scene is main.tscn. Its root main.gd owns the player and camera; its ChapterOne child owns chapter progression. New chapters can supply their own controller and world while reusing scripts/shared. The archive panels remain chapter-specific because their terminology and record semantics belong to Walter's case.

Shared modules: chapter_interface builds and scales UI; dialogue_sequence advances cards and invokes completion once; save_store performs full-precision JSON reads and atomic writes; accessibility_settings validates a versioned preference envelope and imports older flat settings; film_presentation applies the injected shader without changing case state. Chapter One currently assembles these modules and maps its settings controls to them.

CaseState schema 3 accepts versions 1 and 2. Received originals and dated supplements snapshot evidence, statements, and available source metadata. Old records without statement/source snapshots retain those omissions. Accessibility preferences remain separate from checkpoints. Save precision matters: checkpoint timers and camera floats must survive JSON round trips exactly.

The tunnel checkpoint is captured at entry. Death saves the dead state; retry restores the separate entry snapshot. Mid-encounter saves restore clock, exposure, position, flask relief, camera, and record. Reading pauses world time. No save operation should consume the player's live save during QA; automated checks select a separate slot.

## Provisional encounter

A deterministic 12-second cycle warns for 2 seconds, watches for 4, then turns away for 6. Continuous central exposure of 1.4 seconds while watching is fatal; leaving sight resets exposure. The outer route and right recess are physically safe regardless of Perception. Perception reveals additional route information. The flask narrows noncolliding shadow shapes even at zero screen distortion and never changes detection or movement.

The cough, primitive figure, wall shadows, exact timing, text, and geometry are blockout material. Playtesting must establish whether first-time players understand the warning before entering danger, recognize cover and retreat, and distinguish presentation relief from protection. Automated traversal cannot establish those judgments. The forced spill, glass rupture, combat, full audio, and fatal comprehension sequence remain future work.

## TDD v1 clarifications

The active shader is film.gdshader; shaders/film_1923.gdshader belongs to the retained legacy prototype. Preferences were already persisted before this refactor; they now have a shared validated schema and legacy import. Neither distinction requires a change to the bible's design laws.
