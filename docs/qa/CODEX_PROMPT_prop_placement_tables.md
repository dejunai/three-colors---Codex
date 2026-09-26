# Codex handoff: prop placement tables and grounding guard

**Written:** 2026-09-26, by the Cowork session that maintains the TDD. **Revision 2:** same day, folding in Codex's review. Codex has approved the workflow and ownership split with these refinements.

**Why:** interior dressing now runs in two stages. Codex lays out props per room, then a Grok-bot-mini touches up the numbers: position, yaw and uniform scale (see `AGENTS.md`, Grok-bot-minis). For that to work, Grok's corrections must survive Codex's next pass, and floating, tilted or clipping props should be caught by a test before anyone has to spot them in a screenshot.

**Rules** (see `AGENTS.md`):

- Check `git status` and `git branch` before editing and again before committing.
- Don't push, merge, export or publish.
- Primitives stay the collision and interaction authority.
- Hotspot, talk-point and `FIXED_STAFF`/`RETURNING_STAFF` coordinates are fixed contracts.

## 1. One placement file per room

`town.gd::_place_prop()` already enforces a single uniform scale; keep it as the single placement entry point.

- **One file per room.** Each dressed room gets its own data file, `scripts/chapters/interior_props/<room>.gd`, holding one constant array of rows. The builder loops over it and calls `_place_prop()`. One file per room gives Grok an isolated set of numeric rows to edit.
- **Row fields:**

  | Field | Owner | Meaning |
  |---|---|---|
  | `id` | Codex | Stable, unique node name |
  | `path` | Codex | Asset path |
  | `pos`, `yaw`, `scale` | **Grok** (values only) | Placement; `scale` is one positive uniform factor |
  | `support` | Codex | See the support grammar below |
  | `collision` | Codex | Primitive footprint, or none |
  | `tilt` | Codex | Allows non-zero pitch/roll (pigeonhole letters); default false |
  | `cast_shadow` | Codex | Default on; off for pendant shades and lamp glass |
  | `clearance_check` | Codex | Default on; off for deliberate overlaps (see section 2) |

- **Ownership:**
  - Codex adds, removes and reorders rows, and owns every field except `pos`, `yaw` and `scale`.
  - Grok edits only those three values in existing rows.
  - Neither rewrites the other's rows wholesale.
- **The data-driven pigeonhole fill** (`8a9fe0f`) can stay procedural. Record its seed or its expanded row list so it's reproducible.

### Support grammar

The support is a named plane or region, not the supporting prop's bounding-box top. A sofa's top is its backrest, but a pillow rests on its seat, and shelves and pigeonholes have the same problem.

| `support` value | Meaning |
|---|---|
| `"floor"` | Rests on the room floor, Y = 0 |
| `"on:<id>:<plane>"` | Rests on a named support plane of another prop, e.g. `on:post_counter:top`, `on:parlor_sofa:seat` |
| `"inside:<id>:<region>"` | Sits within a named volume of another prop, e.g. `inside:pigeonholes_a:cells` |
| `"wall:<name>"` | Mounted flush on a named wall plane |
| `"ceiling"` | Hangs from the ceiling |

Codex defines the named planes and regions per asset once: a local-space height plus footprint, or a box, scaled with the prop. A small `support_planes` dictionary keyed by asset path, next to the tables, is enough.

## 2. The guard: extend `tests/interior_prop_dressing_flow.gd`

### Stage A: validate the tables before placement

- Every `id` is unique within its room.
- Every `path` loads.
- Every `support` reference points at an existing row, and at a plane or region defined for that row's asset.
- Every `scale` is a single positive number.

### Stage B: check placement

**World bounds.** For each prop, compute its world bounds from every `MeshInstance3D` descendant, transformed into world space. Don't assume the imported scene root owns a single mesh.

**Per `support`** (tolerance about 0.02 m):

| `support` | Assertion |
|---|---|
| `floor` | Bounds bottom at Y = 0 |
| `on:<id>:<plane>` | Bottom on that plane's world height; footprint within that plane's world footprint |
| `inside:<id>:<region>` | Bounds fully inside that region's world box |
| `wall:<name>` | Back face flush with the wall plane; no pitch or roll |
| `ceiling` | Top at ceiling height; `cast_shadow` off |

**For every row:**

- uniform scale;
- `rotation.x` and `rotation.z` equal 0 unless `tilt` is set.

**Clearance:**

- Give each talk point and each `FIXED_STAFF`/`RETURNING_STAFF` standing position an explicit clearance radius (a point alone can't be tested for intersection).
- No prop with `clearance_check` on may intrude into those cylinders.
- No two `clearance_check` props may overlap each other.
- Rugs, pillows, tabletop objects, wall fixtures, `on:` and `inside:` children, and other deliberate overlaps set `clearance_check` to false.

**Output:** print one line per violation, naming the room, `id`, rule and measured error, then fail. That output is Grok's fix list.

## 3. Scope and cleanup

- **Scope:** convert the post office, precinct intake, Corwin's room, the smoking lounge, and the parlor dressing already in `town_expansion.gd`.
- **Post office cleanup** (from the latest screenshots):
  - Remove the white primitive lamp shades, which now duplicate the enamel pendants.
  - Set `cast_shadow` off on the pendant shades. They cast the dark floor ovals.
  - Parcels: support them `on:` the counter top or a shelf plane, not inside the grille and not floating at the clerk's chest.
  - Pigeonhole letters: support them `inside:` the cell region, set back from the front face, with `tilt` allowed.
  - **Clerk:** the clerk and the public talk point are already separated across the counter, and that contract stays fixed. Adjust the grille and the surrounding props around it, so the clerk reads as serving through the grille; don't move the clerk.
- **All five rooms:** once the guard exists, run it on each and fix what it reports. Codex fixes structural violations; Grok fixes numeric ones.

## Definition of done

- Run `tests/interior_prop_dressing_flow.gd`, `tests/test_placement_audit.gd` and `tests/staff_model_integration_flow.gd`, then the full `python tests/run_all_qa.py`.
- Capture one wide screenshot per converted room into `archive/screenshots/`.
- Leave a short dated `docs/qa/` pass note listing the tables, the support planes defined, and the guard's rules.
- The TDD maintainer will verify it and fold it into the TDD and the HCL.
