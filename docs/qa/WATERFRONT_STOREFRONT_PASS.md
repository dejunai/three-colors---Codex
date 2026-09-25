# Waterfront storefront selection pass

Date: 2026-09-21
Branch: `feature/district-textures`

## Decision

The generated exterior filenames are treated as production inventory labels rather than placement authority. Two storefronts were selected for the waterfront after comparing their silhouettes with the existing four-building working frontage:

- `storefront_2.glb` replaces the chandlery presentation as `HarborSupplyChandlery`. Its textured Harbor Supply sign, barrels, awning, and broad shopfront directly support that use.
- `storefront_1.glb` replaces the fish-stores presentation as `FishStoresExterior`. Its wider awning and stacked working frontage suit the eastern end of the quay.

The existing freight office and net loft remain. `storefront_3.glb` remains unplaced because its narrow footprint would either leave misleading invisible collision at both sides or require an excessive horizontal stretch. Keeping two original fronts also preserves visual rhythm instead of making every waterfront building equally ornate.

## Gameplay boundary

`scripts/chapters/waterfront_district.gd` hides the original Chandlery and Fish Stores mesh groups inside `RenderedWaterfront/WorkingFrontage`, then instantiates the selected models under `RenderedWaterfrontLandmarks`. The established hidden primitive shells continue to provide collision for all four frontage lots. Route targets, NPC schedule positions, labels, the central return lane, the waterfront interior boundary, and the old-save direct hub are unchanged.

The imported models are presentation-only. Their placement scales fit the established twelve-unit frontage, approximate six-unit height, and nine-unit depth. Both rotate toward the quay. The remaining generated labels do not constrain where other exterior assets may be used later.

## Visual review

The live `town_waterfront`, `town_waterfront_workyard`, and new wide `town_waterfront_frontage` captures were inspected through the Chapter One camera and film treatment. The detailed storefronts anchor opposite ends of the row without blocking the central return lane or the scheduled residents. The simpler freight office and net loft remain legible between them.

## Verification

- `tests/waterfront_model_flow.gd` now checks both detailed storefronts, hidden replaced meshes, quay and hero props, retained collision, island separation, routes, and schedule anchors.
- The maintained aggregate includes `waterfront_model_flow.gd` as its twenty-ninth suite.

No Web export or publication was performed.
