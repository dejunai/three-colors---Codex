# Tripo batch 5 review: 36 props (2026-09-25)

**For:** Codex. **From:** the TDD maintainer (Cowork), with the author's selection.

**Source:** 36 GLBs in the repo root. Each was rendered front, back and untextured, and its mesh and texture data read.

**Contact sheets:** `tripo_batch5_1.png` to `_7.png` in the HCL repository's `Claude outputs/`.

**Specs:** all 36 are within the established budget:

- one mesh, one material;
- about 1,580–2,450 triangles;
- no normal map; metallic 0, roughness 0.9;
- grounded at Y = 0 and normalized to one unit.

Import rules are unchanged from the earlier intakes (TDD v46, Part Three, "Interior props"):

- **Archive:** raw exports go to `archive/`.
- **Names:** use stable names under `assets/models/props/{civic,common,domestic,estate}/`.
- **Scale:** uniform, tuned against Walter.
- **Collision:** stays with the primitives.

**Name collisions:** `low+poly+chair` and `low-poly+chair` are different models, and so are the `lamp` and `sofa` pairs. The `+`/`-` is the only difference, so rename carefully. The table uses the exact export filenames.

**Verdicts:** **Approve** means import as is. **Notes** means import, with the note applied. **Reject** means archive only.

| # | Export file | Verdict | Suggested name | Notes |
|---|---|---|---|---|
| 1 | `low+poly+chair+3d+model.glb` | **Approve** | `domestic/club_armchair.glb` | Rolled-arm club chair that reads as leather. This is the smoking-lounge chair; it replaces the rustic slatted armchairs there. |
| 2 | `low+poly+sofa+3d+model.glb` | **Approve** | `domestic/club_sofa.glb` | Matches #1. Lounge or upper-quarter parlour. |
| 3 | `bar+counter+3d+model.glb` | **Approve** | `estate/lounge_bar_counter.glb` | Paneled bar front; replaces the lounge's primitive bar block. The steward stays behind it. A bar back (shelving) is still needed. |
| 4 | `wooden+round+table+3d+model.glb` | **Notes** | `domestic/round_table_low.glb` | Low octagonal table, to go between the club chairs. Scale by height, low (side/coffee height), not dining height. |
| 5 | `stone+fireplace+3d+model.glb` | **Approve** | `domestic/stone_fireplace.glb` | Lounge or upper quarter. Never in the lower quarter (heating rule: lower quarter uses stoves). |
| 6 | `stone+ashtray+3d+model.glb` | **Notes** | `common/ashtray.glb` | Keep this one of the two ashtrays. It's small, so scale it to a hand-sized object on the lounge tables. |
| 7 | `geometric+ashtray+3d+model.glb` | **Reject** | — | Near-duplicate of #6. |
| 8 | `low-poly+books+3d+model.glb` | **Approve** | `common/book_stack.glb` | Plain, period-neutral stack. Use it **instead of** `binder_book_stack` on the precinct desk (lever-arch binders are a 1923 anachronism). |
| 9 | `wooden+picture+frame+3d+model.glb` | **Notes** | `common/picture_frame.glb` | The glass face is blank, which is what we want. Put a texture on the face: the historical society's ink drawing of the three-masted bark, and other wall pictures. No baked text. |
| 10 | `wooden+sideboard+3d+model.glb` | **Approve** | `domestic/sideboard.glb` | Boardinghouse or upper-quarter dining; could also serve as the lounge bar back if nothing better arrives. |
| 11 | `wooden+cabinet+3d+model.glb` | **Notes** | `domestic/kitchen_dresser.glb` | Open-shelf kitchen dresser. Carved/rustic edges, so lower quarter or the boardinghouse kitchen, not civic rooms. Not to be confused with the existing `wooden_cabinet_small`. |
| 12 | `low+poly+lamp+3d+model.glb` | **Approve** | `common/table_lamp_a.glb` | Period-plausible table lamp. |
| 13 | `low-poly+lamp+3d+model (1).glb` | **Approve** | `common/table_lamp_b.glb` | Baluster base. A second lamp variant. |
| 14 | `low-poly+lamp+3d+model.glb` | **Reject** | — | Third lamp; the squat vase base is the weakest of the three. Archive unless you want a third variant. |
| 15 | `geometric+rug+3d+model.glb` | **Approve** | `common/rug_patterned.glb` | Patterned (Oriental-style) rug for the lounge or upper quarter. Check that it lies flat and doesn't z-fight with the floor; lift it by a millimetre if needed. |
| 16 | `geometric+rug+3d+model (1).glb` | **Reject** | — | Near-duplicate of #15. |
| 17 | `rug+3d+model.glb` | **Approve** | `common/rug_plain.glb` | Plain rug. Same z-fighting check as #15. Useful in Corwin's room, which reads empty. |
| 18 | `dark+textured+rug+3d+model.glb` | **Reject** | — | Near-duplicate of #17, with the largest texture in the batch (773 KB). |
| 19 | `wooden+table+3d+model.glb` | **Notes** | `domestic/side_table_drawer.glb` | Side table with a drawer. Rustic edges: lower quarter or boardinghouse. |
| 20 | `wooden+coffee+table+3d+model.glb` | **Notes** | `domestic/low_table.glb` | Low table; upper-quarter parlour. Keep out of civic rooms. |
| 21 | `wooden+table+3d+model (1).glb` | **Notes** | `domestic/low_table_plank.glb` | Low plank table or bench. Lower quarter or speakeasy. |
| 22 | `wooden+stool+3d+model.glb` | **Notes** | `common/bar_stool_square.glb` | Rustic square stool; speakeasy cellar. |
| 23 | `low-poly+chair+3d+model.glb` | **Reject** | — | Splayed tapered legs read as mid-century. |
| 24 | `low-poly+armchair+3d+model.glb` | **Reject** | — | Mid-century frame. #1 replaces it. |
| 25 | `low-poly+sofa+3d+model.glb` | **Reject** | — | Track arms and tapered feet read as mid-century or modern. #2 replaces it. |
| 26 | `low+poly+vase+3d+model.glb` | **Reject** | — | Faceted geometric form reads as contemporary décor. |
| 27 | `vase+3d+model.glb` | **Reject** | — | Same as #26. |
| 28 | `faceted+bowl+3d+model.glb` | **Reject** | — | Same. The enamel `wash_basin_enamel` already covers the washstand. |
| 29 | `low+poly+landscape+3d+model.glb` | **Reject** | — | The landscape is sculpted in 3D and bulges out of the frame. Use #9 with a texture. |
| 30 | `low-poly+landscape+frame+3d+model.glb` | **Reject** | — | Same problem, milder. Use #9. |
| 31 | `geometric+hanging+lamp+3d+model.glb` | **Reject** | — | Broken: stray floating fragments, and it reads as an upturned birdbath. |
| 32 | `low-poly+clock+3d+model.glb` | **Reject** | — | Lumpy mantel clock with the face sculpted in. For clocks, use a face texture with separate hands (they can follow the game clock). |
| 33 | `faceted+pillow+3d+model.glb` | **Reject** | — | Crumpled faceted blob; reads as a rock. |
| 34 | `faceted+pillow+3d+model (1).glb` | **Reject** | — | Same. |
| 35 | `geometric+pillow+3d+model.glb` | **Reject** | — | Same. |
| 36 | `polygonal+pillow+3d+model.glb` | **Reject** | — | Same. |

**Totals:** 10 approve, 8 approve with notes, 18 reject (archive only).

## What this unlocks

**Smoking lounge:** #1, #2, #3, #4, #5, #6, #15, plus a lamp (#12 or #13). Together these replace the rustic plank tables and slatted armchairs from the first dressing pass. Move those rustic pieces to the lower-quarter kitchen, per the set-dressing rules.

**Precinct desk:** #8 replaces the lever-arch binder stack.

**Corwin's room:** #17 under or beside the bed helps the empty-floor problem noted in the first in-game test.

**Historical society:** #9 is the frame for the bark drawing.

## Checks

- Re-run `tests/interior_prop_dressing_flow.gd` if lounge node names change, and update its `EXPECTED` list.
- Also re-run `tests/test_placement_audit.gd`, then the full `python tests/run_all_qa.py`.
- Add the rejected and duplicate exports to the intake note as archive-only, as the HD intake did.
