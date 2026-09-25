# Tripo Batch 7 asset intake — 2026-09-25

This batch contained 12 post-office prop GLBs, including three balance-scale attempts. Every model was independently loaded, rendered, measured, and compared before intake.

## Result

- 10 assets were admitted under `assets/models/props/civic/`.
- The 3,143-triangle antique balance scale was selected over both 9K alternatives because its beam, pans, and chains form the cleanest neutral pose.
- The selected scale received a dark aged-iron and bronze material to replace its pale generated finish.
- The two high-poly scale attempts remain preserved with all other originals under `archive/tripo_batch7/`.
- All 12 root GLBs were removed after processing.

## Active library

| Original | Active asset |
|---|---|
| `antique+balance+scale+3d+model.glb` | `post_office_balance_scale.glb` |
| `framed+corkboard+3d+model.glb` | `post_office_corkboard.glb` |
| `gift+box+3d+model.glb` | `parcel_tied_square.glb` |
| `industrial+pendant+lamp+3d+model (1).glb` | `post_office_pendant_a.glb` |
| `industrial+pendant+lamp+3d+model.glb` | `post_office_pendant_b.glb` |
| `vintage+envelopes+3d+model.glb` | `envelope_stack.glb` |
| `wooden+hanging+frame+3d+model.glb` | `post_office_hanging_sign.glb` |
| `wooden+window+3d+model.glb` | `post_office_frosted_window.glb` |
| `wrapped+parcel+3d+model (1).glb` | `parcel_wrapped_large.glb` |
| `wrapped+parcel+3d+model.glb` | `parcel_wrapped_long.glb` |

## Archived scale alternatives

- `balance+scale+3d+model.glb` — 9,650 triangles; right pan nearly touches the base and reads as carrying an invisible load.
- `balance+scale+3d+model (1).glb` — 9,420 triangles; mechanically improved and usable, but offers less benefit than the cleaner 3,143-triangle scale.

## Scene use

The post-office counter now uses the selected scale, envelope stack, and all three parcel forms. Repeated parcel meshes use modest uniform scale and rotation changes to create additional variation at normal gameplay distance. Two pendant lamps frame the service counter; the corkboard, frosted window, and hanging sign dress the side walls. The frosted panes read as milky opaque glass in the current renderer, which is suitable for the room and avoids fragile transparency.

## Verification

- `tests/batch7_post_office_assets_flow.gd` checks all 10 active assets for runtime loading, a single grounded placement mesh, and material retention.
- `tests/interior_prop_dressing_flow.gd` verifies the added post-office nodes alongside the existing counters, pigeonholes, and gameplay route.
- The updated post-office renderer capture and the 12-model intake sheet are stored in `archive/screenshots/`.
- `archive/.gdignore` remains present.
