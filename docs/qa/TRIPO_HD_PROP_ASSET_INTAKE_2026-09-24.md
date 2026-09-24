# Tripo HD Prop Asset Intake — 2026-09-24

Eighteen lower-poly Tripo HD exports were visually audited, imported under stable asset names, and validated in an isolated Godot project. The untouched export files were moved from the project root to `archive/`. The author reports that this HD/lower-poly generation path is faster, includes textures on its first pass, produces materially better results, and costs less than the earlier workflow; those workflow comparisons are author-reported rather than independently measured here.

## Active assets

| Category | Active asset | Archived source export |
| --- | --- | --- |
| Common | `assets/models/props/common/wall_clock_body.glb` | `analog+clock+3d+model.glb` |
| Common | `assets/models/props/common/oval_metal_tin_plain.glb` | `faceted+metal+box+3d+model.glb` |
| Common | `assets/models/props/common/metal_storage_box.glb` | `metal+storage+box+3d+model.glb` |
| Domestic | `assets/models/props/domestic/cloth_pile.glb` | `cloth+pile+3d+model.glb` |
| Domestic | `assets/models/props/domestic/menthol_tin.glb` | `menthol+metal+box+3d+model.glb` |
| Domestic | `assets/models/props/domestic/metal_bed.glb` | `metal+bed+3d+model.glb` |
| Domestic | `assets/models/props/domestic/wooden_dresser.glb` | `wooden+dresser+3d+model.glb` |
| Domestic | `assets/models/props/domestic/washstand_table.glb` | `wooden+table+3d+model.glb` |
| Civic | `assets/models/props/civic/binder_book_stack.glb` | `blue+binder+stack+3d+model.glb` |
| Civic | `assets/models/props/civic/morgue_table_clean.glb` | `clean+morgue+table+3d+model.glb` |
| Civic | `assets/models/props/civic/morgue_table_aged.glb` | `older+morgue+table+3d+model.glb` |
| Civic | `assets/models/props/civic/office_stamp.glb` | `metal+stamp+3d+model.glb` |
| Civic | `assets/models/props/civic/precinct_counter.glb` | `precinct+desk+3d+model.glb` |
| Civic | `assets/models/props/civic/clerk_nameplate.glb` | `stone+nameplate+3d+model.glb` |
| Civic | `assets/models/props/civic/filing_drawer_wide.glb` | `wide+drawer+3d+model.glb` |
| Civic | `assets/models/props/civic/filing_cabinet_wide.glb` | `wide+metal+filing+cabinet+3d+model.glb` |
| Estate | `assets/models/props/estate/pantry_door_boarded_hd.glb` | `pantry+boarded+up+3d+model.glb` |
| Estate | `assets/models/props/estate/pantry_door_cleared_hd.glb` | `pantry+door+un-boarded+3d+model.glb` |

`assets/models/props/estate/pantry_door_states_hd.tscn` wraps the two self-contained HD pantry states. The earlier modular pantry-door set remains available as a fallback until placement testing selects the final variant.

## Direct audit

All 18 assets contain one mesh and one material. Triangle counts range from 1,665 to 2,406. Twelve use 1024×1024 embedded textures and six use 2048×2048 textures. Direct Godot renders confirmed readable silhouettes and textures; the cabinet and drawer are separate resources, both morgue-table variants remain distinct, and the clock body is suitable for separate runtime-driven hands. The assets and HD pantry state scene load successfully in Godot. They are processed resources but have not yet been placed into gameplay scenes.

`archive/.gdignore` remains the archive boundary; archived exports are preserved for provenance and excluded from Godot resource scanning.
