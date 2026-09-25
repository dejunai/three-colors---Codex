# Tripo HD Prop Asset Intake — 2026-09-24

Forty-one lower-poly Tripo HD exports were visually audited. Thirty-nine active props were imported under stable asset names and validated in isolated and in-project Godot checks. `faceted+metal+box+3d+model.glb` duplicated the menthol tin and remains archive-only; `metal+radiator+3d+model.glb` was rejected in favor of the cleaner long radiator and also remains archive-only. The untouched export files were moved from the project root to `archive/`. The author reports that this HD/lower-poly generation path is faster, includes textures on its first pass, produces materially better results, and costs less than the earlier workflow; those workflow comparisons are author-reported rather than independently measured here.

## Active assets

| Category | Active asset | Archived source export |
| --- | --- | --- |
| Common | `assets/models/props/common/wall_clock_body.glb` | `analog+clock+3d+model.glb` |
| Duplicate (archive only) | — | `faceted+metal+box+3d+model.glb` |
| Common | `assets/models/props/common/metal_storage_box.glb` | `metal+storage+box+3d+model.glb` |
| Rejected (archive only) | ? | `metal+radiator+3d+model.glb` |
| Common | `assets/models/props/common/desk_lamp.glb` | `low-poly+desk+lamp+3d+model.glb` |
| Common | `assets/models/props/common/radiator_long.glb` | `radiator+3d+model.glb` |
| Common | `assets/models/props/common/wooden_barrel.glb` | `wooden+barrel+3d+model.glb` |
| Common | `assets/models/props/common/wooden_crate_large.glb` | `wooden+crate+3d+model (1).glb` |
| Common | `assets/models/props/common/wooden_crate_lidded.glb` | `wooden+crate+3d+model (2).glb` |
| Common | `assets/models/props/common/wooden_crate_open.glb` | `wooden+crate+3d+model.glb` |
| Domestic | `assets/models/props/domestic/cloth_pile.glb` | `cloth+pile+3d+model.glb` |
| Domestic | `assets/models/props/domestic/menthol_tin.glb` | `menthol+metal+box+3d+model.glb` |
| Domestic | `assets/models/props/domestic/metal_bed.glb` | `metal+bed+3d+model.glb` |
| Domestic | `assets/models/props/domestic/wooden_dresser.glb` | `wooden+dresser+3d+model.glb` |
| Domestic | `assets/models/props/domestic/washstand_table.glb` | `wooden+table+3d+model.glb` |
| Domestic | `assets/models/props/domestic/bookshelf_narrow.glb` | `wooden+bookshelf+3d+model.glb` |
| Domestic | `assets/models/props/domestic/iron_teapot.glb` | `low+poly+teapot+3d+model.glb` |
| Domestic | `assets/models/props/domestic/stool_round.glb` | `wooden+stool+3d+model.glb` |
| Domestic | `assets/models/props/domestic/stool_upholstered.glb` | `low-poly+stool+3d+model.glb` |
| Domestic | `assets/models/props/domestic/wood_stove.glb` | `wood+stove+3d+model.glb` |
| Domestic | `assets/models/props/domestic/wooden_armchair.glb` | `wooden+chair+3d+model (1).glb` |
| Domestic | `assets/models/props/domestic/wooden_cabinet_small.glb` | `wooden+cabinet+3d+model.glb` |
| Domestic | `assets/models/props/domestic/wooden_chair_ladderback.glb` | `wooden+chair+3d+model.glb` |
| Domestic | `assets/models/props/domestic/wooden_table_long.glb` | `wooden+table+3d+model (3).glb` |
| Domestic | `assets/models/props/domestic/wooden_table_square.glb` | `blocky+wooden+table+3d+model.glb` |
| Civic | `assets/models/props/civic/binder_book_stack.glb` | `blue+binder+stack+3d+model.glb` |
| Civic | `assets/models/props/civic/morgue_table_clean.glb` | `clean+morgue+table+3d+model.glb` |
| Civic | `assets/models/props/civic/morgue_table_aged.glb` | `older+morgue+table+3d+model.glb` |
| Civic | `assets/models/props/civic/office_stamp.glb` | `metal+stamp+3d+model.glb` |
| Civic | `assets/models/props/civic/precinct_counter.glb` | `precinct+desk+3d+model.glb` |
| Civic | `assets/models/props/civic/clerk_nameplate.glb` | `stone+nameplate+3d+model.glb` |
| Civic | `assets/models/props/civic/filing_drawer_wide.glb` | `wide+drawer+3d+model.glb` |
| Civic | `assets/models/props/civic/filing_cabinet_wide.glb` | `wide+metal+filing+cabinet+3d+model.glb` |
| Civic | `assets/models/props/civic/school_desk_antique.glb` | `antique+school+desk+HD+3d+model.glb` |
| Civic | `assets/models/props/civic/filing_drawer_single.glb` | `metal+file+cabinet+drawer+3d+model.glb` |
| Civic | `assets/models/props/civic/filing_cabinet_single.glb` | `metal+filing+cabinet+3d+model.glb` |
| Civic | `assets/models/props/civic/display_case_rectangular.glb` | `wooden+display+case+3d+model.glb` |
| Civic | `assets/models/props/civic/display_case_sloped.glb` | `wooden+display+cabinet+3d+model.glb` |
| Civic | `assets/models/props/civic/wooden_desk_long.glb` | `wooden+desk+3d+model.glb` |
| Estate | `assets/models/props/estate/pantry_door_boarded_hd.glb` | `pantry+boarded+up+3d+model.glb` |
| Estate | `assets/models/props/estate/pantry_door_cleared_hd.glb` | `pantry+door+un-boarded+3d+model.glb` |

`assets/models/props/estate/pantry_door_states_hd.tscn` wraps the two self-contained HD pantry states. The earlier modular pantry-door set remains available as a fallback until placement testing selects the final variant.

## Direct audit

All 39 active assets contain one mesh and one material. Triangle counts range from 1,586 to 2,446. Fifteen use 1024?1024 embedded textures and twenty-four use 2048?2048 textures. Direct Godot renders confirmed readable silhouettes and textures. The new long radiator has cleaner fins and fittings than the rejected 3,551-triangle radiator despite using only 2,388 triangles. Both chair types, both stool types, all three crate types, both display-case types, and both new table forms remain distinct resources. The single cabinet and drawer are separate resources and were normalized independently by Tripo, so their matching scale should be tuned during scene placement. Both morgue-table variants remain distinct, and the clock body is suitable for separate runtime-driven hands. The assets and HD pantry state scene load successfully in Godot. They are processed resources but have not yet been placed into gameplay scenes.

`archive/.gdignore` remains the archive boundary; archived exports are preserved for provenance and excluded from Godot resource scanning.
