# Captain Odell model — Phase One integration

Date: 2026-09-21  
Branch: `feature/district-textures`

## Result

Captain Odell's procedural figure has been replaced by the animated Meshy character supplied by Dejunai. One reusable model now serves both live appearances while preserving their separate narrative identities:

- `odell` remains the one-shot opening consultation at the estate;
- `odell_precinct` remains the scheduled Day 2/3 precinct NPC with its own topic history.

No dialogue gate, schedule, interaction target, save identifier, or departure rule changed. Estate completion still removes opening Odell with the other cleared-scene staff. The precinct catalog still decides whether returning Odell exists.

## Asset and pipeline

- Archived source: `archive/Meshy_Captain-ODell-Animations.glb`
- Reproducible Blender integration: `tools/modeling/integrate_odell.py`
- Runtime asset: `assets/models/captain_odell.glb`
- Godot adapter: `scripts/shared/captain_odell_model.gd`

The source contains 15,172 rendered triangles and three native 2048×2048 JPEG texture maps. The integration removes the stray Icosphere, grounds the rig, gives the hierarchy stable Odell names, and exports only the character presentation needed by the game.

The source stands about 1.80m in its idle pose. Runtime scale `1.18` makes Odell imposing while keeping him visibly below Walter's deliberately heightened silhouette. The model faces Walter's approach at both placements.

## Animation

The static NPC has three restrained standing clips:

- `Idle`, sourced from `Idle_11`;
- `Idle_Alt`, sourced from `Idle_3`;
- `Confer`, sourced from `Idle_12`.

`Idle` loops during ordinary staging. Beginning either Odell conversation blends to `Confer`; leaving the conversation returns him to `Idle`. Mid-conversation save restoration also restores the active conversational animation. The animations are presentation only and never own dialogue progress.

## Verification

- `tests/odell_model_flow.gd` verifies model import, accepted scale, the three semantic clips, and dialogue animation switching.
- `tests/odell_model_integration_flow.gd` verifies that both live Odell identities use the rendered model and enter/leave the conversational animation.
- `tests/dialogue_live_flow.gd` verifies the existing mid-card/fork save flow and Odell topic completion with the rendered model.
- `tests/returning_staff_flow.gd` verifies that estate and precinct Odell retain distinct topic identities and scheduled content.
- `odell` and `odell_precinct` renderer captures were inspected for materials, scale, facing, and placement.

No Web export or publication was performed.
