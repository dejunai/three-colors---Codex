# Business district schoolhouse model pass

Date: 2026-09-21  
Branch: `feature/district-textures`  
Scope: first bounded placement from the remaining civic exterior set

## Selection

`assets/models/exteriors/schoolhouse.glb` now replaces the procedural schoolhouse presentation in both the contiguous town and the old-save business hub. Its weathered clapboard, dark roof, windows, and subdued civic palette already fit the business district under the Chapter One treatment, so the source texture was retained instead of applying a broad material override that would erase its authored trim and window detail.

The model occupies the established Schoolhouse lot at the west end of the southern frontage. The existing `SCHOOLHOUSE` label, bench, notice case, entrance target, interior route, and separate interior scene remain unchanged.

## Gameplay boundary

The former procedural schoolhouse is grouped under `LegacySchoolhouseCollisionVisuals` and hidden as presentation. Its solid foundation and building body remain active as the collision authority. The generated model is render-only and lives under `RenderedBusinessLandmarks/SchoolhouseExterior`.

No dialogue, schedule, navigation, time, route, portal, or interior behavior changed.

## Verification

- `tests/business_exterior_model_flow.gd` checks the contiguous and old-save business layouts, rendered mesh, hidden compatibility shell, retained collision, and stable `route_schoolhouse` id.
- `tests/contiguous_town_phase_one_flow.gd` continues to cover the full Pickman/business/upper walking loop.
- `town_business` remains the live renderer review view for scale, orientation, frontage fit, and entrance readability.

No Web export or publication was performed.
