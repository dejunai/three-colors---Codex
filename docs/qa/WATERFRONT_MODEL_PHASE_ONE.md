# Waterfront model — Phase 1 implementation

Date: 2026-09-20
Branch: `feature/district-textures`
Scope authority: `docs/qa/MODELING_PASS_PHASE_ONE.md`

## Result

The waterfront's visible blockout has been replaced by a reproducible Blender-authored art slice while the established Godot geometry remains collision authority. The asset contains 10,048 rendered triangles and one generated 512×512 color atlas beneath Chapter One's film treatment.

The bounded composition contains:

- a modeled quay, timber apron, stone seawall, and water surface;
- four distinct working fronts: chandlery, freight office, net loft, and fish stores;
- one low-poly fishing boat with hull, cabin, mast, boom, fenders, and gunwales;
- bollards, crates, barrels, drying-net frames, masonry courses, timber braces, windows, doors, signs, vents, and chimneys.

The intentionally authored working frontage is visually distinct from the still-procedural neighboring districts. It is also distinct from the unreachable island, which remains provisional atmospheric staging.

## Reproducible source

- `tools/modeling/generate_waterfront_phase1.py` creates the model and material atlas under Blender 5.2.
- `assets/models/waterfront_phase1.glb` is the imported visual asset.
- `assets/models/waterfront_phase1_atlas.png` is retained for inspection and regeneration.

The generator is the source of truth; no undocumented local `.blend` file is required.

## Gameplay boundary

`scripts/chapters/waterfront_district.gd` builds the original waterfront beneath `LegacyWaterfrontCollisionVisuals`, then hides that visual parent after instantiating `RenderedWaterfront`. Visibility does not disable the primitive meshes' child collision bodies. The old quay footprint, four solid building shells, seawall barrier, route targets, labels, lamps, schedule anchors, and interaction coordinates therefore remain authoritative.

The direct `waterfront` hub used by old saves and the continuous town exterior both instantiate the same model. The placement proxy now respects an explicit parent for cylinders so hidden legacy bollards, masts, and net poles stay with their compatibility container.

The imported asset does not contain the offshore whaling station. `OffshoreWhalingStation` remains a separate, unreachable low-detail silhouette created by Chapter One code. Chapter Two will establish the final island before Chapter One receives a reduced-detail distant derivative.

## Visual inspection

Two live captures were inspected through Chapter One's actual camera and film treatment:

- `town_waterfront` faces inland across the quay and verifies frontage scale, roofs, trim, residents, and the open return lane.
- `town_waterfront_seaward` faces across the apron and verifies the seawall, boat, water plane, and separate distant island silhouette.

The first capture pass caught a missing water plane after legacy presentation was hidden. The water surface was added to the rendered asset before acceptance.

## Verification

- `tests/waterfront_model_flow.gd`: rendered hierarchy, water, hidden compatibility visuals, retained collision, separate island, stable routes, and schedule anchors.
- `tests/waterfront_approach_flow.gd`: continuous downhill approach, walkable quay, shared schedule coordinates, and unreachable island.
- `tests/waterfront_flow.gd`: old-save direct hub, seven live interactions, clock/schedules, save restore, and return travel.
- `tests/contiguous_town_phase_two_flow.gd`: Pickman-to-lower traversal, interiors, and actors.
- `tests/contiguous_town_profile.gd`: `build_ms=247.28`, `nodes=3063`, `meshes=2535`, `bodies=107`, `collisions=107`, `targets=68`, `scheduled_actors=47`, `static_mb=82.05` on the development machine. The earlier district-texture snapshot reported `static_mb=78.97`; the rendered Walter and waterfront assets together add about 3.08 MB to that process measure.

The maintained aggregate again passed its first eight grammar/content suites, timed out at its 30-second `qa_flow` limit, and hung in its sandbox-blocked CIM process cleanup. A direct clean-runtime `--qa` invocation reached the minimal-route pass and exited successfully. This matches the runner/environment limitation recorded in `WALTER_MODEL_PHASE_ONE.md`; the waterfront-specific traversal suites above completed normally.

No Web export or publication was performed. The implementation is accepted on desktop; the phase brief's Web stall/memory check remains pending until the next explicitly authorized Web export.
