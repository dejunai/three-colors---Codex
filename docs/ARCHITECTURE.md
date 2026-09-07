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

## TDD v2 clarifications

The Observer color-preservation device is restored in film.gdshader as `preserve_color`, a narrow red-dominance band on the rendered screen texture rather than the legacy shader's looser blanket filter. This is deliberately scoped, not merely reintroduced: every material color used anywhere in estate.gd, town.gd, and tunnel.gd is a desaturated gray, green, or brown with no red-channel dominance, so the band only ever fires on geometry deliberately given a warm-red accent. estate.gd's `person()` gained an optional `accent` parameter for exactly this — a small chest detail (matching Walter's badge in scale and placement) that is the one thing in a given figure allowed to read as colored. This resolves the concrete build gap the v2 TDD flagged and unblocks the estate grounds crew beat below.

The estate grounds crew (estate.gd, the kitchen wing yard west of the terrace, "crew" in story.gd) is Chapter One's Observer beat per the bible's Part Two material — the first Observer the player meets anywhere in the trilogy. It is built as a standard optional observation: examine it, get a factual notebook entry, nothing more. The dialogue never explains the refusal; it only describes it precisely and returns the groundskeeper to unrelated work in the same breath, per the bible's staging rule. Design Law 5 stays intact — no line of text acknowledges why the door gets a wide berth, or that the accent even has a color; only the render does that, and only for a player who happens to look.

The corkboard/link-mechanic question (Part Four) is left unresolved on purpose rather than rebuilt this pass: `case_state.gd`'s flat `perception()` formula is the only implementation this codebase actually exercises, it already gates the service passage's third route, and it now also gates discovery of the grounds crew observation itself (perception grows with evidence count, and the crew is one more piece of evidence to find). Migrating in the legacy `GameState` link mechanic is a bigger, separate decision and should stay that way rather than being absorbed into a content pass.

`tunnel.gd`'s `cue()` now reads from `tunnel_story.gd`'s `CUES` table instead of returning inline string literals, resolving the TDD's "hazard cue text lives in code" item ahead of any second timed encounter reusing the pattern.

The procedural-geometry pipeline question (blockout convention vs. production pipeline) is unchanged and still open; this pass added to the estate using the same `box`/`person`/`cylinder`/`sphere` helpers rather than deciding it, since a content addition is the wrong place to relitigate the pipeline.
