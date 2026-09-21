# Walter model — Phase 1 implementation

Date: 2026-09-20  
Branch: `feature/district-textures`  
Scope authority: `docs/qa/MODELING_PASS_PHASE_ONE.md`

## Result

Walter's procedural primitive avatar has been replaced in Chapter One by a reproducible Blender-authored GLB while retaining the existing Godot player controller as the sole authority for movement, collision, camera position, interaction range, saves, and coat state.

The first asset is deliberately angular and early-2000s in construction. It contains 4,460 rendered triangles: above the original *Gothic*-era character density while remaining conservative for Web. It uses one generated 512×512 full-color atlas. Chapter One's film treatment still determines how much color reaches the player.

## Reproducible source

- `tools/modeling/generate_walter_phase1.py` creates the model, atlas, armature, named outfit hierarchy, and animation actions under Blender 5.2.
- `assets/models/walter_phase1.glb` is the game asset.
- `assets/models/walter_phase1_atlas.png` is the generated source atlas retained for inspection and regeneration.
- `scripts/shared/walter_model.gd` instantiates the model, maps imported animation names, and applies the existing coat/badge state.

The generator is the source of truth for this phase; no undocumented local `.blend` file is required.

## Model and outfit

The model includes a shaped head and features, hair, hat, shirt, tie, belt, buckle, boots, coat lapels, pockets, buttons, badge, and holster. It exposes named `PoliceCoat`, `PlainCoat`, and `Badge` groups. Runtime visibility follows `CaseState.coat` and the existing `badge_lost` flag. Compatibility markers retain the direct `Badge` node expected by older integration checks.

The imported model is rotated inside its visual wrapper to reconcile Blender's authored +Z face direction with the controller's established -Z forward direction. The controller and gameplay coordinates were not changed.

## Animation

The imported clips are:

- `Idle`
- `Walk`
- `Brisk`
- `Interact`
- `Pickup_Ground`

`main.gd` selects idle/walk/brisk from the already-existing movement calculation. These are visual clips without root motion. If the rendered animation player is unavailable, the former procedural limb-swing path remains as a fallback.

### Knife and stopped watch

The first examination of the estate knife or stopped watch now plays `Pickup_Ground` before opening its object cards. Walter faces the hotspot, player input locks, and the knife prop disappears at the reach point. Control is released and the existing object runtime then presents and commits the authored content. Tests bypass the delay when `test_mode` is active so unrelated scripted suites remain deterministic; a dedicated live-timing test exercises the real animation path.

The animation cannot own evidence state. The `.object` runtime remains authoritative, and the pickup has completion fallbacks through the existing callback path.

## Glass-break checkpoint

The required checkpoint found and corrected two presentation defects before waterfront work:

1. Walter initially faced the camera and away from the board because imported forward was reversed.
2. His first arm rest pose flared too widely and weakened the silhouette.

After regeneration, the camera sees Walter from behind, he faces the board, his arms rest naturally, the board remains legible, and the broken glass and protected caption remain visible to his right. The complete steward-to-glass test passes with the rendered model, and a live `glass_break` capture was visually inspected at the authored three-meter camera push.

## Verification

- `tests/walter_model_flow.gd`: GLB, hierarchy, coat/badge switching, and five animation clips.
- `tests/walter_pickup_flow.gd`: real knife reach timing, watch pickup, control lock/release, and unchanged evidence commits.
- `--qa`: opening minimal/full routes and physical estate traversal pass.
- `tests/break_flow.gd`: complete steward/pantry/tunnel/retreat/glass/debrief path passes.
- Live captures inspected: `walter`, `walter_pickup`, and `glass_break`.

The maintained aggregate runner completed its first eight grammar/content suites, then timed out at `qa_flow` while using its hard-coded repository runtime directory; its PowerShell/CIM cleanup also could not terminate the timed-out process in the sandbox. The same `--qa` flow passed directly in about three seconds with a clean writable runtime directory. This is recorded as a runner/environment limitation rather than a verified gameplay regression.

The glass-break checkpoint is complete. The bounded waterfront modeling slice may begin without changing the Chapter One island beyond its provisional atmospheric silhouette.

## Meshy replacement and custom-action addendum — 2026-09-21

The initial procedural avatar described above has since been replaced by the textured Meshy Walter while retaining the same controller, outfit, evidence, and save-state boundaries. Two custom actions arrived in the GLB under opaque Meshy UUIDs. Runtime and the reproducible Blender integration script now expose stable semantic names:

- `Examine`: Walter bends slightly at the waist and works with both hands at desk height. Authored object interactions start this action when their cards open and restore `Idle` when the interaction finishes.
- `Surprise`: Walter moves from idle through a startled reaction and touches his ear. The final glass break triggers this action at the crack and restores `Idle` when the ending beat releases.

The model audit also confirmed that Walter's short-arm appearance is structural rather than a camera illusion. On the 1.70 m source rig, each upper-arm bone is about 0.15 m and each forearm about 0.22 m; the shoulder joint is only about 0.03 m below the neck base. The upper arm is the larger proportional error. This remains a source-model/weighting correction for a separate visual pass: the runtime must not scale animated bones as a cosmetic workaround because that would distort the custom actions and every inherited Mixamo clip.
