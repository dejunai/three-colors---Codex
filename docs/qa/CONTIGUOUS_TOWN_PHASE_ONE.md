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

## Remaining seams

1. Fold the existing business street geometry into the shared exterior and replace `route_business` with a logical district boundary that does not reload the exterior.
2. Build the second-stage climb, stairs, alleys, and retaining walls from business level to the upper quarter.
3. Fold the upper district into the shared exterior and provide a different physical return route to Pickman Street.
4. Remap scheduled exterior NPC positions into shared coordinates while retaining every current NPC ID and separate interior destination.
5. Profile the complete Phase 1 exterior on desktop and Web before introducing streamed cells, HLOD, or model upgrades.
