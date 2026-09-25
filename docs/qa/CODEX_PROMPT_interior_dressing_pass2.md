# Codex handoff: interior dressing, pass 2

**Written:** 2026-09-25 by the Cowork session that maintains the TDD. **Basis:** Dejunai's 12 in-game screenshots of Corwin's room, the precinct, the post office and the smoking lounge, plus Codex's four preliminary shots in `archive/screenshots/`. Performance and loading are fine. Everything below is placement, transform or asset-choice work.

**Rules for this work** (see `AGENTS.md`):

- Check `git status` and `git branch` before editing and again before committing.
- Don't push, merge, export or publish.
- Collision stays with the primitive shells (`Legacy*CollisionVisuals`). Rendered props are presentation only.
- Hotspot, talk-point and `FIXED_STAFF`/`RETURNING_STAFF` coordinates are fixed contracts. Move props around them, not the other way round.

## 1. Stretching: scale uniformly

Several props have non-uniform scale:

- **Post office pigeonholes:** the model's cells are roughly square, but in game they render as wide, flat rectangles.
- **Post office counter:** the grille section is squashed, and the panel grain is smeared sideways.
- **Corwin's bed:** longer than the model's proportions.
- **The long desk in Corwin's room:** along the right wall.

**Rule:** every prop uses one scale factor on x, y and z. Size it by its real-world height against Walter (as the character adapters do). To fill a longer wall or counter run, place two or three instances end to end instead of stretching one. If a helper takes a `Vector3` scale, consider asserting or clamping it to uniform.

## 2. Rotation: fix facing on import

- **Chairs face away from their tables and desks:** in Corwin's room, at the precinct desk, and with at least one lounge armchair. The seat faces the table.
- **The three precinct waiting chairs face the side wall.** Turn them toward the intake counter.

This is probably the same +Z/−Z facing issue the character adapters correct. Please apply one consistent facing correction for all Tripo props (in the shared placement helper, or in the import settings) rather than fixing each instance by hand.

## 3. Clipping

- **Post office clerk:** standing inside the counter footprint; from above, his legs disappear into the countertop. Move him fully behind the counter, ideally behind the brass grille, so the grille reads as the service window. Keep the talk point on the public side.
- **Precinct NPC by the wide filing cabinet:** standing into its front face. Give him a clear spot.
- **Corwin's room:** the bed headboard overlaps the radiator. Move one of them.

## 4. Scale and grounding

- **Walter's dresser is too large.** It comes up to Walter's chest and reads as a sideboard. A 1920s chest of drawers should come to about his waist, so scale it down (uniformly).
- **The dresser looks lifted:** there's a shadow gap under its feet. Check that it's grounded at Y = 0, and set it against a wall.
- The `exemption` hotspot must still target the dresser after it moves.

## 5. Not yet swapped in

- **Pantry door:** still the primitive (a dark slab with three boards). Wire in the door GLBs:
  - boarded state before the tunnel;
  - unboarded state (door plus leaning and broken boards) after.
  - Both states keep the same frame position and size, so the swap doesn't pop.
  - The visible state follows the same flag as the `pantry_door` hotspot's label change in `sync_pantry()`.
  - Test the early-exit round trip (tunnel → precinct → lounge) and confirm the door doesn't re-board. Please add an assertion to the tunnel or break flow test.
  - Keep the leaning boards and debris clear of the hotspot at (-7.4, 0, -3.0).
- **Lounge bar and tall wardrobe:** still primitives.
- **Precinct desk binders:** the lever-arch binders are still there. Use only the book stack (cut from `blue_binder_stack`, or the separate books). Lever-arch binders are an anachronism in 1923.

## 6. Stray shadows

The ceiling lamp-shade meshes cast shadows onto the floor: the dark oval in Corwin's room and the octagon near the steward. Set `cast_shadow = off` on the lamp shades.

## 7. Carried over (asset choice, not transforms)

- **Smoking lounge register:** the rustic plank tables and slatted armchairs read as a farmhouse, not a gentleman's club.
  - Move the plank tables to the lower-quarter kitchen.
  - Until club leather armchairs, a small round table and a proper bar back exist, keep the lounge sparse rather than rustic.
- **Post office pigeonholes:** all empty. Scatter a few letters or bundles, as a texture on the backboard or as flat card meshes.
- **Heating rule:** radiators only in the upper quarter and public buildings; the lower quarter uses stoves.

## Definition of done

- Re-run `tests/dialogue_catalog_flow.gd`, `tests/test_placement_audit.gd` and `tests/staff_model_integration_flow.gd`, then the full `python tests/run_all_qa.py`.
- Replace the screenshots in `archive/screenshots/` with one wide shot per room from the default camera, plus one of the pantry wall in each state.
- Leave a short dated `docs/qa/` pass note listing what changed. The TDD maintainer will verify it and fold it into the TDD and HCL.
