# Tripo Batch 6 asset intake — 2026-09-25

This batch contained 14 compact working-waterfront and utility props delivered as root-level GLBs. Every model was independently imported into Blender, rendered, measured, renamed for stable use, imported by Godot, and checked as a runtime `PackedScene`.

## Result

- All 14 models were admitted to the active prop library under `assets/models/props/common/`.
- All 14 original GLBs were moved to `archive/tripo_batch6/` after processing.
- Repository root contains no loose GLBs from the batch.
- Each active asset is one grounded mesh with one retained material surface and roughly 2,000–2,400 triangles.
- The tall rope coil was retained after a material repair; its original pale surface made the usable stacked-rope silhouette read like stone.

## Active library

| Original | Active asset |
|---|---|
| `fish+3d+model (1).glb` | `fish_pile.glb` |
| `fish+3d+model.glb` | `fish_single.glb` |
| `rope+3d+model (1).glb` | `rope_coil_flat.glb` |
| `rope+3d+model.glb` | `rope_coil_tall.glb` |
| `rope-wrapped+bundle+3d+model.glb` | `cargo_bundle_roped.glb` |
| `rustic+wooden+stool+3d+model.glb` | `stool_rustic.glb` |
| `sack+3d+model.glb` | `sack_tied.glb` |
| `wooden+barrel+3d+model (1).glb` | `barrel_upright_hd.glb` |
| `wooden+barrel+3d+model.glb` | `barrel_side_hd.glb` |
| `wooden+bucket+3d+model.glb` | `bucket_wooden.glb` |
| `wooden+crate+3d+model.glb` | `crate_slatted_hd.glb` |
| `wooden+stump+3d+model.glb` | `stump_seat.glb` |
| `wooden+table+3d+model (1).glb` | `work_table_rustic.glb` |
| `wooden+table+3d+model.glb` | `bench_plank_low.glb` |

## Tall rope coil repair

The coil’s concentric stack and hollow center are readable, but the generated off-white texture erased the distinction between strands. The repaired asset keeps the original 2,334-triangle mesh, smooths its normals, and substitutes a high-roughness warm hemp material with restrained diagonal fiber relief. It now works as medium- or background-scale quay clutter. The flat coil remains the stronger close-view asset.

## Verification

- `tests/batch6_prop_assets_flow.gd` validates all 14 active paths, runtime loading, mesh count, grounded pivots, and material retention.
- Godot imported all 14 without errors.
- The contact sheet and repaired-coil review render are stored in `archive/screenshots/`.
- `archive/.gdignore` remains present, so archived source GLBs stay outside Godot’s importer.
