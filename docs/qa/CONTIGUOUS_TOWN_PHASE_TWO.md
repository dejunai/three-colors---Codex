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

## Remaining seams

1. Walk and visually review the Pickman-to-lower transition.
2. Establish a downhill route and sightline from lower town to the waterfront.
3. Fold the waterfront into the shared exterior while preserving its island whaling-station view and all NPC schedules.
4. Profile the complete exterior before deciding whether streaming or LOD is justified.
