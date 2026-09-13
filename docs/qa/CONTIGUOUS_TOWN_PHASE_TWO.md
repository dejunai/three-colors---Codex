# Contiguous town — Phase 2

Branch: `dev/contiguous-town-phase-2`, stacked on Phase 1.

Phase 2 grows east and downhill from Pickman Street through the lower district, then continues to the waterfront. Interiors remain separate scenes and all authored IDs remain stable.

## Step 1 — Shared lower district

- Extract the existing lower geometry into one reusable builder for legacy saves and continuous play.
- Place the lower street east of Pickman at a visibly lower elevation.
- Replace the lower loading portal with a physical descending lane.
- Preserve all six dwelling IDs, the permanent speakeasy cellar door, interior returns, and scheduled NPC IDs.
- Validate physical traversal and shared-coordinate scheduled actors before beginning the waterfront seam.

No Web export is produced from this branch.

## Step 2 — Waterfront approach and sightline

- Add a continuous lane descending south through a gap in the lower frontage.
- Move the stable waterfront handoff to the bottom of that physical lane.
- Extend town fall recovery below the future quay elevation.
- Keep a low, unreachable whaling-station silhouette visible down the lane without exposing an island route.
- Leave the detailed waterfront in its existing hub until the approach passes independently.

## Step 3 — Shared waterfront exterior

- Place the existing quay, working buildings, boats, seawall, water, and offshore station at the bottom of the tested descent.
- Remove the final exterior loading boundary while retaining direct legacy-hub loading for old saves.
- Transform waterfront NPC schedules into shared coordinates without changing authored schedule names or actor IDs.
- Keep the island visible and physically unreachable.

## Remaining seams

1. Walk and visually review the Pickman-to-lower and lower-to-waterfront transitions.
2. Profile the complete exterior before deciding whether streaming or LOD is justified.
