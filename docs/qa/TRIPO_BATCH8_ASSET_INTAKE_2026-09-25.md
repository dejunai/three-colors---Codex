# Tripo Batch 8 asset intake — 2026-09-25

Batch 8 supplied twelve lower-facet alternatives and domestic accents. All twelve were inspected from fresh Blender renders, imported through Godot, and retained as active assets. The raw downloads are preserved under `archive/tripo_batch8/`.

## Replacement decisions

Five visual roles now use the smoother Batch 8 geometry while keeping their stable runtime paths:

- `common/desk_lamp.glb`
- `common/table_lamp_a.glb`
- `domestic/stone_fireplace.glb`
- `domestic/throw_pillow_burgundy.glb`
- `domestic/throw_pillow_green.glb`

The two pillow meshes were retextured with the existing burgundy and green woven materials so their improved silhouettes did not change the established room palette. Obsolete extracted textures from the three direct GLB replacements were removed during reimport.

## Additions and placement

Seven assets were added under stable descriptive names:

- `common/oil_lamp_round.glb`
- `domestic/decorative_bowl_ceramic.glb`
- `domestic/vase_ceramic_tall.glb`
- `domestic/vase_ceramic_round.glb`
- `domestic/parlor_sofa_tufted.glb`
- `domestic/parlor_armchair_a.glb`
- `domestic/parlor_armchair_b.glb`

The smoking lounge retains its club sofa and club armchairs. The upper-quarter parlor now uses the new tufted sofa and the two upholstered wooden armchairs, with a ceramic bowl on the low table and the round vase on the sideboard. This makes the two affluent interiors read as related without duplicating the same furniture suite. The tall vase and round oil lamp remain available in the prop library for a later room rather than being forced into an already balanced layout.

## Verification

- `tests/batch8_replacement_assets_flow.gd` loads all twelve active assets and checks a single textured mesh, one material surface, and grounded bounds.
- `tests/interior_prop_dressing_flow.gd` verifies the revised parlor nodes alongside preserved gameplay targets and pantry states.
- Renderer captures for the upper parlor, smoking lounge, and precinct were inspected after integration and stored in `archive/screenshots/`.
- `archive/screenshots/prop_intake_batch8_replacements.png` records the twelve-model intake contact sheet.
- All twelve original root GLBs were moved to `archive/tripo_batch8/`; `archive/.gdignore` keeps source files out of Godot imports.
