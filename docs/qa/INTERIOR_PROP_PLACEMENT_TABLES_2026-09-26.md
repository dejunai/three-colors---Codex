# Interior prop placement tables — 2026-09-26

The first five dressed interiors now keep imported-prop placement in isolated data files under `scripts/chapters/interior_props/`:

- `corwin_room.gd`
- `precinct.gd`
- `smoking_lounge.gd`
- `upper_parlor.gd`
- `post_office.gd`

Each stable row records the asset, node id, primitive collision footprint, support relationship, authored tilt, shadow behavior, and clearance policy. Codex owns those fields and the row inventory. The numeric `pos`, `yaw`, and positive uniform `scale` values are isolated for Grok touch-up. Builders still route every row through `town.gd::_place_prop()`, keeping rendered meshes presentation-only and primitive siblings authoritative for traversal.

Named support definitions cover desk, counter, washstand, sideboard, table and sofa-seat planes plus the post-office pigeonhole cell volume. The five sorting-wall bundles are expanded into individually named rows so each can be adjusted without changing the procedural builder. Post-office primitive lamp shades are suppressed because the imported pendants replace them; pendant and table-lamp shadow metadata is applied recursively to imported mesh descendants.

`tests/interior_prop_dressing_flow.gd` now validates row ids, paths, positive scales and support references before instantiation. It then checks recursive world bounds, grounding, named support height and footprint, interior regions, wall/ceiling contact, uniform scale, authored pitch/roll, shadow behavior, oriented collision-footprint overlap, and explicit clearance radii around staff and interaction contracts. Every violation prints `room | id | rule | measurement` before exiting nonzero, providing the numeric fix list for Grok.

The structural conversion is complete. The first guard run reports four remaining numeric touch-ups:

- `precinct | PrecinctSideChair | clearance` — conflicts with the fixed `supplement` interaction radius.
- `post_office | PostOfficeBalanceScale | support.footprint` — overhangs the counter-top footprint.
- `post_office | PostOfficePendantLeft | ceiling` — top is 0.44 m below the ceiling.
- `post_office | PostOfficePendantRight | ceiling` — top is 0.44 m below the ceiling.

`tests/test_placement_audit.gd` passes with 64 living NPCs and zero schedule-coordinate collisions. `tests/staff_model_integration_flow.gd` passes with the intake and postal clerk positions and public talk points unchanged. The five renderer captures were inspected and archived for the numeric touch-up pass. The aggregate intentionally remains pending until the four table values are adjusted and `tests/interior_prop_dressing_flow.gd` passes.
