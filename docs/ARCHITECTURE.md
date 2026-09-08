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

## Dialogue trees from the short-story drafts

`docs/design/1) no_exit_wound_expanded.md.pdf` (canonical) and `docs/design/4) no_exit_wound_alternate_resistance.md.pdf` (alternate) are prose treatments of the same events the build already dramatizes — the same six victims, the same Odell exchange, the same Almy and gardener beats, the same tunnel encounter. Both end in Walter's fatal disappearance, which stays future work per the chapter's own scope; nothing from either ending was pulled into the build. What both drafts share, verbatim in places, is investigative material the build had not yet dramatized: the Ophion Club barman's testimony ("They stopped speaking of power, toward the end... She'll have us home... She's no different from any mother") and the boarded pantry door behind it, present near-identically in both versions. That shared material became the barman thread (`_barman_menu()` in chapter_one.gd, "barman"/"club_talk"/"club_devotion"/"pantry_lead" in story.gd) — a revisitable menu on the same model as `_witness_menu()`, unlocking one topic per prior topic answered.

Where the two drafts diverge is tone, not event: the canonical draft's Walter absorbs Odell's dismissal and lets his own file carry the disagreement silently; the alternate's Walter answers him to his face in the doorway. That divergence became `_odell_response()` — a genuine two-way player choice (not a state check) with a distinct recorded statement per option, surfaced the first time in this build where the player picks which of Walter's two documented reactions actually happened. Neither option is scored, gated, or referenced elsewhere; the choice is characterization, not a branching plot.

Father Behan (canonical-only material — the club's naming, the two declined invitations, "men inherit money and then invent a reason they deserved it") is a third revisitable menu, `_behan_menu()`, on the town street rather than the estate. `_town_observation()` now accepts a generalized `return_target: Variant` (supporting any `Callable` as well as backward-compatible booleans), allowing `_behan_menu()` to cleanly route its second topic through `_town_observation("behan_name", _behan_menu)` without duplicating card sequences or hardcoding witness returns.

The woman outside Kessler's shuttered shop (canonical-only) is deliberately not a fourth menu. In the source she leaves before Walter can ask a second question, so the build treats her as a single `_town_observation()`-driven scene like `gazette` or `exemption` rather than forcing a revisitable structure onto a witness who, by the story's own logic, doesn't stay. Her presence and departure are managed via the generalized conditional actor system (`register_actor`, `sync_actors`, `dismiss_actor`) inherited across `estate.gd` and `town.gd`. Her card and Behan's `behan_name` card cross-reference on the board once both are recorded — the same "two halves of an argument neither speaker knew the other was making" the source states outright.

## Review corrections

Observer color preservation currently uses a screen-wide red-pixel threshold, not an object mask. A controlled palette supports the intended prototype effect; true object isolation remains future work. The `tests/capture_views.gd` rig can stage a dedicated "observer" capture (`qa_observer.png`), but no such image exists in `docs/qa/` yet — the shader's real-world legibility against the groundskeeper's accent is still unconfirmed by any rendered output. The groundskeeper observation is available without a Perception gate. Perception reveals tunnel route information, not exclusive physical access. Odell answers are locked by their saved statement; older contradictory records are preserved rather than silently rewritten. The woman disappears after her warning and remains absent on load and travel, enforced through the declarative actor lifecycle. Barman dialogue now describes the present daytime portico encounter. Observation returns are generalized to arbitrary Callables.

## Movement latch and click-to-move (TDD v8 correction + one item TDD v8 missed)

TDD v6 hypothesized an input-latch fix for `main.gd`'s movement, found no supporting commit, and declined to credit one. TDD v8 corrects this: the fix is real, just uncommitted at the time — `main.gd` carries a `MOVE_LATCH_MIN = 0.15` constant and a `move_latch_timer` dict, set from `_unhandled_input`'s action-pressed events rather than polled, so a keydown/keyup pair that resolves within a single physics frame (synthetic/automated input) still registers as held for at least that long. `main.gd` also carries a second, related addition TDD v8's source read did not mention: click-to-move (`move_target`). A left click raycasts the world (layer 1) and steers the player toward the hit point, clamped into `movement_bounds`, until arrival or a keypress — an accessibility fallback for players who can't sustain a held key, and incidentally a working path for automated/scripted input. Neither gates on `Input.mouse_mode == MOUSE_MODE_CAPTURED`, since pointer lock is unreliable in some browser embeddings and gating on it would silently disable the fallback.

## Phase 2 Mechanics: Forced Spill, Combat Stagger, and Causal Spine

1. **Forced Spill Mechanic**: Entering the deep descent past the foundation triggers a rock-spur snag that tears Walter's flask loose into the dark below. Per Design Laws 3 & 4, this punishes hoarding without lying: the exact amount hoarded is recorded in `state.flask_spill_amount`, the flask is set to 0, and subsequent inspection of the flask in personal effects clearly details how many pours were lost and why.
2. **Tunnel Combat & Stagger Architecture**:
   - Walter carries a 6-round service revolver (`state.ammo`) and Kessler's boning knife.
   - Revolver shots expend ammunition and inflict non-lethal staggers center-mass.
   - Knife melee attacks scale stagger duration with Walter's Strength (`2.0 + strength * 1.5` for drowned, `1.5 + strength * 1.0` for cultist), honoring Design Law 11 (Strength modifies landed staggers, never accuracy or instant kills).
   - Enemy asymmetry: Drowned sailors are mortal and can be permanently put down with a brutal finishing blow once staggered (`state.drowned_dead = true`). Fully transformed cultists cannot be permanently killed ad infinitum; staggering them buys time to retreat or navigate around them.
3. **Diegetic Corkboard Causal Spine**:
   - The case board diegetically reflects Walter's accumulated Perception.
   - At Perception >= 5, the board displays the completed causal spine ("SIX MEN IN EVENING DRESS = THE OPHION'S SINKING = AN UNDERSEA PASSAGE = A SUMMONED PRESENCE"), showing that the shape closes itself when sufficient evidence is linked, rather than gating progression behind an arbitrary puzzle.
   - Automated regression test `tests/phase_two_mechanics.gd` (`--qa-phase2`) verifies all Phase 2 mechanics.
