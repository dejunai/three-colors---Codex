# Contiguous town — Phase 1

Branch: `dev/contiguous-town-phase-1`

The exterior grows outward from Pickman Street in independently playable seams. Interiors remain separate scenes, and existing location, route, NPC, and save identifiers remain stable until their physical replacements pass traversal tests.

## Step 1 — Pickman edge and business ascent

Implemented September 13, 2026:

- Removed the blocking warehouse mass behind the existing business passage.
- Added a continuous stone incline from Pickman Street toward the business district.
- Added irregular retaining walls and surface divisions to establish the hand-built Gothic/eurojank geometry target.
- Added upper-quarter silhouettes and ridge lamps above the business roofline, establishing the permanent vertical order before detailed construction.
- Moved the stable `route_business` transition to the top of the incline. The existing business scene remains active beyond it during this seam.
- Expanded Pickman Street's movement bounds to include the climb.
- Added a traversal regression that walks around the established Gazette bench, ascends the full grade, and reaches the existing business route.

No Web export was produced.

## Step 4 — Shared upper-quarter exterior

Implemented September 13, 2026:

- Extracted the existing upper-quarter geometry into a reusable builder so old hub saves and the contiguous exterior use the same layout.
- Placed the upper street on its established plateau at the top of the physical climb.
- Removed the `route_upper` and upper `route_pickman` loading boundaries from new continuous play.
- Preserved every residence interior and stable route ID, with returns transformed to the corresponding upper-street doorway.
- Retained direct loading of the former upper hub for save compatibility and updated its regression accordingly.
- Expanded the shared movement bounds through the complete upper block.

Validated by walking from Pickman through business and onto the upper street without changing exterior state. The dialogue catalog also passes. No Web export was produced.

### Retaining-works repair

After visual playtesting, the raised business ground read as an unsupported bridge from the Pickman incline. Added a masonry retaining face, side walls, irregular buttresses, and a supported gateway around the incline. The walking surface and route remain unchanged.

## Step 2 — Shared Pickman and business exterior

Implemented September 13, 2026:

- Placed the existing business-street geometry at the top of the Pickman incline in the same exterior scene.
- Removed the `route_business` and `route_pickman` loading boundaries from the shared exterior.
- Preserved every business interior as a separate scene with its existing stable route ID.
- Added transformed return positions so leaving a business interior places Walter outside its corresponding storefront in the shared exterior.
- Moved the upper-quarter silhouettes beyond the business roofs and expanded the shared movement boundary through the complete business block.
- Extended the traversal regression through the incline and onto the raised business street without changing `state.world` from `town`.

Validated with the Step 2 traversal test and the full dialogue-catalog regression. No Web export was produced.

## Step 3 — Business-to-upper climb

Implemented September 13, 2026:

- Removed the obsolete upper- and business-district portal facades from Pickman Street, leaving the future lower-quarter portal intact.
- Added a steep but continuously walkable stone approach at the northwest end of the business block, with visible courses, retaining walls, and repaired posts.
- Moved the upper-quarter silhouettes farther uphill so the next detailed exterior can occupy its proper plateau.
- Relocated the stable `route_upper` transition to the top of the physical climb. The upper district remains its existing separate exterior for this seam.
- Extended the traversal regression from Pickman through business and to the upper-quarter handoff.

No Web export was produced.

## Remaining seams

1. Add a different physical return route from the upper quarter to Pickman Street.
2. Remap scheduled exterior NPC positions into shared coordinates while retaining every current NPC ID and separate interior destination.
3. Profile the complete Phase 1 exterior on desktop and Web before introducing streamed cells, HLOD, or model upgrades.
