# Lower district exterior model pass

Date: 2026-09-21
Branch: `feature/district-textures`

## Decision

`assets/models/exteriors/pickman_house_2.glb` is a historically mislabeled lower-district dwelling, not an unused Pickman Street house. It is now the rendered exterior for Dwelling No. 2.

Dwelling No. 2 was selected because the model's narrow, repeatedly repaired silhouette gives the otherwise regular lower frontage a useful landmark. It also corresponds to an authored residential destination used by the salt mender's schedule. Dwelling No. 5 was deliberately left unchanged so its permanent speakeasy cellar door remains visually and mechanically clear.

## Gameplay boundary

`scripts/chapters/lower_street.gd` builds the old Dwelling No. 2 presentation under `LegacyLowerDwellingCollisionVisuals`, instantiates the imported house under `RenderedLowerLandmarks`, and hides only the old rendering. The primitive shell and doorstep retain collision authority. `route_lower_house_2`, every other lower-district route, NPC placement, and the separate dwelling interior remain unchanged.

The model is grounded at the existing building center and scaled to the authored twelve-unit frontage, 5.2-unit height, and seven-unit depth. The existing `DWELLING No. 2` label remains because it communicates the destination more reliably than environmental detail alone.

## Visual review

The existing `town_lower` live capture was inspected through the actual Chapter One camera and film treatment. It confirms forward orientation, grounded placement, a clear entrance and sign, unobstructed resident positions, and a distinct lower-town silhouette without disturbing the cellar approach.

## Verification

- `tests/lower_exterior_model_flow.gd` checks the rendered model in both the continuous town and old-save direct lower hub, hidden compatibility shells, retained collision, stable Dwelling No. 2 route, and untouched speakeasy route.
- `tests/contiguous_town_phase_two_flow.gd` checks the continuous descent into the lower district, stable interiors, and shared scheduled actors.
- The maintained aggregate contains the new regression as its twenty-eighth suite.

No Web export or publication was performed.
