# Prop reference list: for Codex review

**Status:** proposal. Nothing here is approved for integration yet. Dejunai wants Codex's thoughts and approval on *how* these props would enter the build before any assets are produced.

**What this is:** a list of individual props (not whole scenes) drawn from Grok-generated concept renders, with notes on canon and gameplay constraints. The renders are concept art only. They will not be used wholesale, and nothing in them is final geometry. Any text painted into a render (signs, plaques, "EST. 1923," captions) is **not** reference and must be ignored.

**Renders:** `docs/art_reference/renders/`, reduced to JPEG for repo size.

- `v2-*`: the second pass, done to the "New England Gothic, 1923: ordinary, not haunted" brief. Prefer these.
- `v1-*`: first-pass images kept for one or two specific props.

This folder has a `.gdignore`, so Godot won't import the images into the project or the web `.pck`.

---

## 1. Props

"Scene builder" names the function that draws the room today, as far as the TDD maintainer could confirm. Codex should confirm the rest.

| # | Prop | Reference | Scene builder | Gameplay coupling | Canon / constraints |
|---|---|---|---|---|---|
| 1 | **Morgue table** | `v2-05`, `v1-05` | `town_expansion.gd::_morgue()` (six primitive tables at x = ±4, z = -4/0/4, each with a `body()`) | The `morgue_tables` object hotspot is at (-2.4, 0, 3.0). The coroner (`FIXED_STAFF`) is at (-1.6, 0, -1.0) and the assistant (`RETURNING_STAFF`) at (1.6, 0, -1). | **Two variants:** older, chipped enamel (×2) and newer, bright enamel (×4), to match the `morgue_tables` examine text ("Four newer than the others"). Waist height, with a drain. Must still carry the existing `body()` sheeted figures. |
| 2 | **Iron bed, single** | `v2-10`, `v2-12` | `town.gd::_corwin_room()`; lower-quarter bedrooms (builder TBC) | Walter's room holds the `sleep` interaction. | A plain iron frame, no brass. One model for Walter's room and the lower-quarter bedrooms. |
| 3 | **Washstand, pitcher, basin** | `v2-10` | `town.gd::_corwin_room()` | None today. | Pitcher and basin as separate meshes on the stand. The washstand appears in the canon novella `08`. |
| 4 | **Walter's dresser** | `v2-10` | `town.gd::_corwin_room()` | The `exemption` object hotspot (the dresser drawer). | Plain chest of drawers. |
| 5 | **Menthol tin; folded gauze masks** | `v2-10`, `v1-07` | `town.gd::_corwin_room()` | Described by the `exemption` object text (Bible v18, "1918"). | **Separate small props** that sit on or in the dresser. Never labelled "influenza" or anything similar (1918 guardrail). |
| 6 | **School desk** | `v2-12` (lower rooms), `v1-12` | Schoolhouse interior (builder TBC) | None. | Desk and seat as one piece, placed many times. Mrs. Teague: "eight desks filled," so leave most of the room empty. |
| 7 | **Precinct intake counter; clerk's desk; filing cabinet; bench; wall clock** | `v2-04` | `town.gd::_precinct()` (`_desk()` at (0,0,-2.5), `_chair()` at (0,0,-4.2)) | The `intake_clerk` figure stands behind the counter at (0.4, 0, -4.0), with its talk point on the public side at (0.4, 0, -2.5). `intake` is at (0, 0, -1.3) and `supplement` at (-5, 0, 2.1). | The counter must keep the clerk visibly *behind* it and the public side reachable. |
| 8 | **Post office counter with brass grille; pigeonhole wall; letter scale; notice board** | `v2-06` | `town_expansion.gd::_post_office()` | `post_office_clerk` placement. | The pigeonhole wall could double as the precinct records wall. |
| 9 | **Glass display case; framed ship drawing** | `v2-07` | Historical society interior (builder TBC) | `local_historian` (Abernathy) placement. | The dialogue has Abernathy tap "a framed pen-and-ink rendering of the three-masted bark." The drawing prop matches it. |
| 10 | **Boarded pantry door** (two states) | `v2-08` | `town.gd::_smoking_lounge()` (existing boards at x ≈ -8.62) | `pantry_door` portal hotspot at (-7.4, 0, -3.0): "Examine the boarded pantry door" before `pantry_lead`, then "Open the boarded pantry door" (`town.gd::sync_pantry()`). | **Two visual states**, boarded and open/forced, following the hotspot's label change. Gaps between the planks so light shows through. |
| 11 | **Lounge armchairs; bar back; side lamps** | `v2-08` | `town.gd::_smoking_lounge()` | Steward model at the bar. | 1920s club leather. Not the mid-century sofa and lamps in `v2-14`. |
| 12 | **Meal ledger** | `v2-09` | `town.gd::_boardinghouse()` | The `lodging` object hotspot ("Examine the meal ledger"). | A small closed or open ledger. No readable title (render text isn't reference). |
| 13 | **Boardinghouse dining table (cloth), chairs, sideboard** | `v2-09` | `town.gd::_boardinghouse()` | Mrs. Almy placement. | Lace curtains are set dressing, optional. |
| 14 | **Lower-quarter stove, sink, table, bench** | `v2-11`, `v2-13` | Lower-quarter interiors (builder TBC) | Scheduled residents. | Heat comes from the stove, not radiators. |
| 15 | **Upper-quarter dining set, sideboard, bedroom set** | `v2-15`, `v2-16` | Upper-quarter interiors (builder TBC) | Scheduled residents. | Period-correct. Avoid `v2-14`'s modern sofa and lamps. |
| 16 | **Speakeasy barrels, crates, stools, trestle bar** | `v2-17`, `v1-04` | Lower-quarter speakeasy cellar (builder TBC) | `speakeasy_bartender`, night owls, and the `speakeasy_bar` overheard exchange. | Crates **unlabelled or disguised** (Prohibition), never "WHISKEY." |

## 2. Integration constraints

These come from how model integration is already done in this build (TDD v46, "Character and Environment Models"). Codex should confirm or amend them.

- **Collision stays with the primitives.** Existing pattern: keep the primitive shell hidden as the collision authority (`Legacy*CollisionVisuals`), and add the rendered model as presentation only (`Rendered*`). Routes, labels, schedules, interiors and hotspot positions do not change.
- **Hotspot and staff positions are fixed contracts.** The props must fit around the coordinates in table 1: the `FIXED_STAFF`/`RETURNING_STAFF` spots, and the object and portal hotspots. The morgue already had one focus collision this week; `tests/dialogue_catalog_flow.gd` and `tests/test_placement_audit.gd` should gate any change there.
- **Scale and orientation:** tune against Walter, as with every existing model. Ground at Y = 0 and correct +Z to -Z facing, as the existing adapters do. `upper_street.gd::place_model()` may be the right shared helper.
- **Web budget:** the district-texture work was built to avoid growing `index.pck`. New props mean new GLBs and textures (2K or 1K), so the web-profile comparison in TDD Part Eight becomes more important.
- **Palette:** near-grayscale. The film shader desaturates Chapter One, and the only intended color is the Observers' tell. Don't bake color into prop textures.
- **Tests:** likely a prop-assets suite in the style of `tests/waterfront_prop_assets_flow.gd` (loads, grounded, single mesh), plus the existing texture audit.

## 3. Questions for Codex

1. **Priority:** which props are worth doing first? Suggested: the morgue tables, Walter's room set, the pantry door and the intake counter. They sit on the critical path and carry gameplay or canon meaning.
2. **The pantry door's two states:** swap two models, or toggle visibility inside one scene? Where should the switch live, given that `sync_pantry()` currently only relabels the hotspot?
3. **Morgue tables:** can the two enamel variants share one mesh with different materials, or do they need two models?
4. **Instancing:** for repeated props (school desks, chairs, barrels), is `MultiMeshInstance3D` worth it here, or are a handful of instanced GLBs fine?
5. **Placement:** one shared prop-placement helper, or one adapter script per prop in the style of the character `*_model.gd` files?
6. **Where the files go:** `assets/models/props/` (which already exists for the estate tree/bush clusters) or a new folder per location?
7. **Primitives:** which existing primitives each prop replaces visually. Confirm the builders marked TBC above.

---

*Prepared by the TDD maintainer (Cowork session), 2026-09-24, from Grok renders supplied by Dejunai. Not a Bible or TDD change. Once Codex's approach is agreed, the TDD will record the integration plan.*
