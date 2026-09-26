# Codex handoff: prop placement tables and grounding guard

**Written:** 2026-09-26, by the Cowork session that maintains the TDD.

**Why:** interior dressing now runs in two stages. Codex lays out props per room, then a Grok-bot-mini touches up the numbers: position, yaw and uniform scale (see `AGENTS.md`, Grok-bot-minis). For that to work, Grok's corrections must survive Codex's next pass, and floating, tilted or clipping props should be caught by a test before anyone has to spot them in a screenshot.

**Rules** (see `AGENTS.md`):

- Check `git status` and `git branch` before editing and again before committing.
- Don't push, merge, export or publish.
- Primitives stay the collision and interaction authority.
- Hotspot, talk-point and `FIXED_STAFF`/`RETURNING_STAFF` coordinates are fixed contracts.

## 1. Move placements into one table per room

`town.gd::_place_prop()` already enforces a single uniform scale, which is good; keep that. What's missing is that placements are scattered `_place_prop(...)` calls inside the builders (about 63 of them across `town.gd` and `town_expansion.gd`), so a hand fix and a later Codex edit touch the same lines.

- Give each dressed room one constant table, for example `const POST_OFFICE_PROPS := [ {id, path, pos, yaw, scale, collision, surface}, ... ]`.
  - The table can sit in the builder, or in a small `scripts/chapters/interior_props/<room>.gd` data file, whichever is cleaner.
  - The builder loops over the table and calls `_place_prop()` for each row.
- `id` is the node name and stays stable, so a row can be adjusted without renaming.
- `surface` records what the prop rests on:
  - `"floor"`;
  - `"wall:<name>"`;
  - `"on:<other id>"` (counter top, table top, shelf);
  - `"ceiling"` for pendants.

  The test in section 2 uses it.
- **Ownership:**
  - Codex adds, removes and reorders rows.
  - Grok changes only the `pos` / `yaw` / `scale` values in existing rows.
  - Neither rewrites the other's rows wholesale.
- The data-driven pigeonhole fill (`8a9fe0f`) can stay procedural. Record its seed or its row list so it's reproducible.

Convert these rooms first: the post office, precinct intake, Corwin's room, the smoking lounge, and the parlor dressing already in `town_expansion.gd`.

## 2. Grounding and facing guard

Extend `tests/interior_prop_dressing_flow.gd`. For every row in every table, instance the room and check the rendered prop's world AABB:

| `surface` | Assertion (tolerance about 0.02 m) |
|---|---|
| `floor` | AABB bottom at Y = 0 |
| `on:<id>` | AABB bottom equals the top of the named prop's AABB, and its footprint lies inside that top |
| `wall:<name>` | back face flush with that wall's plane; no pitch or roll (the tilted picture frame in the latest screenshots) |
| `ceiling` | top at the ceiling height; shadow casting off on the mesh |
| all rows | uniform scale; `rotation.x` and `rotation.z` equal 0 unless the row sets an explicit `tilt` flag (pigeonhole letters) |

Also assert:

- no rendered prop's AABB intersects a `FIXED_STAFF`/`RETURNING_STAFF` standing position or a talk point;
- no prop AABB sits inside another's, except `on:` pairs.

Print one line per violation, then fail, so the output doubles as Grok's fix list.

## 3. Cleanup visible in the latest post office screenshots

- **Old lamp shades:** remove the white primitive lamp shades. They now duplicate the enamel pendants.
- **Pendant shadows:** turn off shadow casting on the pendant shade meshes. They're what's casting the dark floor ovals.
- **Parcels:** sit them on counter or shelf tops, not inside the grille and not floating at the clerk's chest.
- **Letters:** push the pigeonhole letters into the cells, rather than flush with the front where they read as labels.
- **Clerk:** place the post office clerk behind a grille, with the talk point on the public side.
- **Other rooms:** once section 2 exists, run it on every dressed room and fix what it reports.

## Definition of done

- Run `tests/interior_prop_dressing_flow.gd`, `tests/test_placement_audit.gd` and `tests/staff_model_integration_flow.gd`, then the full `python tests/run_all_qa.py`.
- Capture one wide screenshot per converted room into `archive/screenshots/`.
- Leave a short dated `docs/qa/` pass note that lists the tables and the guard.
- The TDD maintainer will verify it and fold it into the TDD and the HCL.
