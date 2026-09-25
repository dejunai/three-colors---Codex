# Interior dressing pass 2 - implementation record

**Date:** 2026-09-25  
**Basis:** `CODEX_PROMPT_interior_dressing_pass2.md` used as an audit checklist; live source, traversal tests, and renderer captures remain authoritative.

## Applied

- Replaced non-uniform prop transforms with uniform scale. Long precinct and post-office runs now use repeated modules; the post office uses two enlarged counter modules and two pigeonhole banks.
- Reduced Corwin's bed and dresser, separated the bed from the radiator, kept the existing exemption hotspot, and retained grounded Y=0 placement.
- Centralized chair placement and kept imported ladderback angles literal so seats face their desks and service points.
- Moved the rendered post-office clerk behind the counter and moved the talk point just forward of the enlarged counter collision.
- Replaced precinct lever-arch binder clutter with a small period book stack.
- Populated several post-office pigeonholes with paper bundles.
- Removed rustic plank tables and armchairs from the smoking lounge pending purpose-built club furniture.
- Wired `pantry_door_states_hd.tscn` into the lounge. Boarded/cleared visibility follows completed portal history and survives a precinct round trip.
- Disabled shadow casting on the two interior lamp-shade meshes.
- Kept imported meshes presentation-only; sibling primitive collision bodies retain traversal footprints.

## Deferred

- The lounge's procedural bar remains because no suitable period club bar/back asset is present.
- The small imported lounge cabinet remains as restrained wall furniture; it is not treated as a finished club wardrobe replacement.
- Moving the dresser against a wall would move the fixed exemption interaction coordinate, so this pass prioritizes the existing gameplay contract.

## Verification

- `dialogue_catalog_flow.gd`: PASS - 73 NPCs, 468 topics, reachable scheduled actors, notebook, links, and save/load.
- `test_placement_audit.gd`: PASS - 64 living NPCs, zero coordinate collisions across all phases.
- `staff_model_integration_flow.gd`: PASS - intake and postal clerk placement remains accessible.
- `break_flow.gd`: PASS - pantry gate, checkpoint, ending flow, and cleared-state round trip persist.
- `interior_prop_dressing_flow.gd`: PASS - domestic, precinct, post-office, and lounge props render with gameplay targets intact.
- `--qa-town` and `--qa-loop`: PASS.
- `python tests/run_all_qa.py`: PASS - all 40 maintained QA suites passed cleanly.
- Renderer inspection completed for Corwin's room, precinct, post office, smoking lounge, pantry boarded, and pantry cleared. Final captures are in `archive/screenshots/`.
