# Pickman Street exterior model pass

Date: 2026-09-21
Branch: `feature/district-textures`
Scope: first selective use of the generated exterior set

## Selection

The generated exteriors were treated as optional source material rather than a set that had to be placed in full. A contact-sheet audit found three models whose silhouettes and entrances support the existing Pickman Street destinations:

- `police_precinct.glb` for Precinct 4;
- `pickman_house_1.glb` for Mrs. Almy's boardinghouse;
- `pickman_house_3.glb` for Walter's rooms above the cobbler.

`pickman_house_2.glb` was mislabeled during asset production; it was originally intended for the lower district and is integrated there as Dwelling No. 2. The storefronts, schoolhouse, estate house, and upper-district houses remain available but unplaced. In particular, the storefront family reads as lower-district or waterfront construction and was not forced into Pickman Street merely because the assets exist.

## Gameplay boundary

`town.gd` now builds the former north-side shells under `LegacyPickmanCollisionVisuals`, instantiates the selected models under `RenderedPickmanFrontage`, and hides only the legacy presentation. The solid primitive shells remain active as collision authority. The established `street_precinct`, `street_almy`, and `street_room` interaction points, portal identities, destinations, and separate interior scenes are unchanged.

The models use non-uniform placement scale to fit the authored frontage widths while preserving each original building's approximate height and depth. Their grounded bases meet the existing north sidewalk. Existing destination labels remain visible because they carry gameplay information more clearly than relying on model detail alone.

## Visual review

The models were first reviewed together in a neutral Blender contact sheet, then through the live Godot renderer and Chapter One film treatment using the new `town_pickman` capture mode. The live pass confirmed correct forward orientation, grounded placement, distinct silhouettes, readable destination labels, and a substantially closer match between rendered and collision widths after one scale adjustment.

## Verification

- `tests/pickman_exterior_model_flow.gd` checks the rendered hierarchy, all three selected meshes, hidden legacy visuals, retained collision, and stable entrance ids.
- `tests/contiguous_town_phase_one_flow.gd` completes the full Pickman/business/upper walking loop with shared scheduled actors.
- The maintained 27-suite aggregate passes cleanly, including town portals, interiors, schedule/progression coverage, the complete slice, model assets, textures, and this new frontage check.

No Web export or publication was performed.
