# Tripo Prop Asset Intake — 2026-09-24

Seven Tripo GLB exports were audited and admitted to the active asset library. The untouched export files were moved from the project root to `archive/`; `archive/.gdignore` is present, so Godot does not scan the archived copies.

## Active assets

| Purpose | Active asset | Original export in `archive/` |
| --- | --- | --- |
| Enamel wash basin | `assets/models/props/domestic/wash_basin_enamel.glb` | `faceted+ceramic+bowl+3d+model.glb` |
| Enamel wash pitcher | `assets/models/props/domestic/wash_pitcher_enamel.glb` | `faceted+pitcher+3d+model.glb` |
| Post-office counter and grille | `assets/models/props/civic/post_office_counter.glb` | `post+office+counter+3d+model.glb` |
| Post-office pigeonholes | `assets/models/props/civic/post_office_pigeonholes.glb` | `post+office+pigeon+holes+3d+model.glb` |
| Cleared pantry doorway | `assets/models/props/estate/pantry_door_cleared.glb` | `cracked+door+3d+model.glb` |
| Damaged pantry door leaf | `assets/models/props/estate/pantry_door_damaged_leaf.glb` | `damaged+door+3d+model.glb` |
| Boarded pantry frame | `assets/models/props/estate/pantry_door_boarded_frame.glb` | `wooden+door+3d+model.glb` |

`assets/models/props/estate/pantry_door_states.tscn` combines the door pieces. Its `Boarded` child is initially visible and places the damaged leaf behind the barricaded frame; its `Cleared` child is initially hidden. Placement code should switch those children while retaining the existing authored hotspot and simple collision.

## Direct audit

Each GLB contains one mesh, one material, and one embedded 1024×1024 texture. Individual triangle counts range from 1,852 to 2,451. The basin and pitcher have modeled hollow interiors, the counter grille retained open geometry, and the pigeonholes retained modeled recesses. These assets have been imported and validated as resources but have not yet been placed into gameplay scenes.
