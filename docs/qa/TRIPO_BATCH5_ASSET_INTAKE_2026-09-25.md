# Tripo Batch 5 asset intake — 2026-09-25

This is the verified intake record for the 36 lounge and upper-class parlor props that arrived at repository root. `TRIPO_BATCH5_REVIEW_2026-09-25.md` was treated as an advisory checklist; every model was independently loaded, measured, rendered, and judged in the game’s current presentation.

## Result

- 20 models were admitted to the active prop library.
- 16 models remain preserved as source material in `archive/tripo_batch5/`.
- All 36 original GLBs and their 36 source texture JPGs were removed from repository root after intake.
- The active assets import as grounded, textured, single-mesh `PackedScene` resources. The focused asset test covers all 20.
- The lounge and upper residence parlor were dressed with the strongest pieces. Corwin’s room received the plain rug, and the precinct desk received the imported book stack.

## Active library

| Source model | Active asset | Use |
|---|---|---|
| `low+poly+chair+3d+model.glb` | `assets/models/props/domestic/club_armchair.glb` | Lounge/parlor armchair |
| `low+poly+sofa+3d+model.glb` | `assets/models/props/domestic/club_sofa.glb` | Lounge/parlor sofa |
| `bar+counter+3d+model.glb` | `assets/models/props/estate/lounge_bar_counter.glb` | Smoking-lounge bar |
| `wooden+round+table+3d+model.glb` | `assets/models/props/domestic/round_table_low.glb` | Lounge side table |
| `stone+fireplace+3d+model.glb` | `assets/models/props/domestic/stone_fireplace.glb` | Lounge/parlor fireplace |
| `stone+ashtray+3d+model.glb` | `assets/models/props/common/ashtray.glb` | Lounge table detail |
| `low-poly+books+3d+model.glb` | `assets/models/props/common/book_stack.glb` | Precinct desk clutter |
| `wooden+picture+frame+3d+model.glb` | `assets/models/props/common/picture_frame.glb` | Retained for later wall dressing |
| `wooden+sideboard+3d+model.glb` | `assets/models/props/domestic/sideboard.glb` | Lounge/parlor sideboard |
| `wooden+cabinet+3d+model.glb` | `assets/models/props/domestic/kitchen_dresser.glb` | Retained for domestic interiors |
| `low+poly+lamp+3d+model.glb` | `assets/models/props/common/table_lamp_a.glb` | Lounge lamp |
| `low-poly+lamp+3d+model (1).glb` | `assets/models/props/common/table_lamp_b.glb` | Parlor lamp |
| `geometric+rug+3d+model.glb` | `assets/models/props/common/rug_patterned.glb` | Lounge/parlor rug |
| `rug+3d+model.glb` | `assets/models/props/common/rug_plain.glb` | Corwin-room rug |
| `wooden+table+3d+model.glb` | `assets/models/props/domestic/side_table_drawer.glb` | Retained for domestic interiors |
| `wooden+coffee+table+3d+model.glb` | `assets/models/props/domestic/low_table.glb` | Parlor table |
| `wooden+table+3d+model (1).glb` | `assets/models/props/domestic/low_table_plank.glb` | Retained as alternate low table |
| `wooden+stool+3d+model.glb` | `assets/models/props/common/bar_stool_square.glb` | Retained for bar/service dressing |
| `faceted+pillow+3d+model.glb` | `assets/models/props/domestic/throw_pillow_burgundy.glb` | Sofa cushion; retextured |
| `faceted+pillow+3d+model (1).glb` | `assets/models/props/domestic/throw_pillow_green.glb` | Sofa cushion; retextured |

The two admitted pillow silhouettes were useful but their generated surface treatment read as hard material. Their geometry was retained, normals were smoothed, and their materials were replaced with quiet burgundy and deep-green woven cloth. At their small in-scene scale, they read as intentionally angular cushions and add color without becoming focal objects.

## Archive-only models

The following are preserved under `archive/tripo_batch5/`: `dark+textured+rug`, `faceted+bowl`, `geometric+ashtray`, `geometric+hanging+lamp`, `geometric+pillow`, `geometric+rug (1)`, `low+poly+landscape`, `low+poly+vase`, `low-poly+armchair`, `low-poly+chair`, `low-poly+clock`, `low-poly+lamp`, `low-poly+landscape+frame`, `low-poly+sofa`, `polygonal+pillow`, and `vase`.

These lost out to stronger same-batch alternatives, duplicated an existing role, or had proportions/materials that would require more repair than their distinctiveness justified. Archive status is reversible; it is not a deletion verdict.

## Verification

- `tests/interior_prop_assets_flow.gd` checks all 20 active assets for loadability, one placement mesh, grounded origin, and a retained material.
- `tests/interior_prop_dressing_flow.gd` checks the new lounge and upper-parlor nodes, pantry state, steward placement, and gameplay targets.
- Renderer captures were reviewed for `lounge`, `upper_parlor`, `room`, and `precinct` after placement.
- `archive/.gdignore` remains present, keeping archived source files outside Godot’s importer.
