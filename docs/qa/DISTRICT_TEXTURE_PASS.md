# District texture pass

Date: 2026-09-20  
Branch: `feature/district-textures`

## Purpose

Give the contiguous exterior recognizable district surfaces while preserving its primitive geometry, stable routes, collisions, NPC placement, and Chapter One monochrome presentation.

## Implementation

`scripts/shared/district_surfaces.gd` generates and caches 128×128 grayscale textures and tinted triplanar materials at runtime. The small shared vocabulary includes brick, soot-darkened brick, stone, cut stone, cobble, patched cobble, plaster, cracked plaster, wood, salt-worn wood, tarred wood, slate, rusted metal, and algae-stained stone. No large bitmap assets were added.

- Pickman Street retains civic masonry, with soot-darkened older fronts and stone door surrounds.
- The business district keeps its orderly mixed masonry and gains restrained facade variation.
- The upper quarter uses regular cobble, pale plaster, cut-stone trim, and slate.
- The lower district uses patched cobble, soot-darkened brick, cracked plaster, exposed timber repairs, and rust.
- The waterfront uses timber planking, salt-worn and tarred wood, algae stone, and rusted fittings.
- Inclines and retaining works use the neighboring district's surfaces so the treatment remains continuous between blocks.

Geometry, collision shapes, route ids, and interaction positions were not changed.

## Verification

- `tests/contiguous_town_phase_one_flow.gd`: PASS — full Pickman/business/upper walking loop and shared scheduled actors.
- `tests/contiguous_town_phase_two_flow.gd`: PASS — Pickman/lower descent, stable interiors, and scheduled actors.
- `tests/contiguous_town_profile.gd`: `build_ms=425.95`, `nodes=2859`, `meshes=2339`, `bodies=107`, `collisions=107`, `targets=68`, `scheduled_actors=47`, `static_mb=78.97` on the development machine.
- Live OpenGL captures completed for Pickman, business, upper, lower, and waterfront views. The new capture modes are `town_business`, `town_upper`, `town_lower`, and `town_waterfront`.
- `git diff --check`: clean.

The broader `--qa-town` suite currently stops at `tests/town_flow.gd:159` (`Departure survives loading`) after the old-woman interaction. That state/save assertion is outside the surface and geometry paths changed in this pass; it remains a separate investigation rather than being hidden by this visual branch.
