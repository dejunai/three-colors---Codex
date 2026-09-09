# Town expansion and body timeline — 8 September 2026

Implemented in the game project, based on 98ab692. Changes remain uncommitted. The local Web release has been refreshed; nothing was pushed or published by this task.

## Body timeline

CaseState schema 6 stores independent `rose_bodies_removed` and `birch_bodies_removed` flags, plus `estate_visits_completed`.

The first departure to Pickman Street clears the six rose garden bodies. Odell and the assistant remain absent on revisits. The woman and boy remain physically present, unattended, and examinable through the second estate visit, including a second visit on Day 3 in the plain coat. Their evidence interactions remain available until removal.

The birches clear only when entering the estate from town after both Day 3 has begun and two estate visits have been completed. No scene, dialogue, notification, or camera event accompanies their removal. Entering the lounge and returning does not complete an estate visit; loading a save does not advance the count. Existing evidence is retained.

Versions 1–5 remain supported. Old departed-estate saves migrate to one completed visit with the rose garden cleared and the birches still present, protecting the neglected second-visit beat where older saves contain no reliable visit count.

## New geography

Pickman Street retains its existing destinations. The opposite frontage now contains three signed neighborhood passages and the post office. Each destination is instantiated as a separate space.

| Neighborhood | Occupied placeholder interior | Light interiors | Exterior only | Total |
|---|---|---|---|---:|
| Business district | Stationer, with private rooms-above door | Schoolhouse, one-room museum, haberdasher | Printer, clock repairer | 6 |
| Upper residential | Residence No. 1 | Residences 2–4 | Residences 5–6 | 6 |
| Lower residential | Dwelling No. 1 | Dwellings 2–4 | Dwellings 5–6 | 6 |

There are 18 neighborhood buildings, 12 accessible interiors, and three placeholder residents. Each resident has only the agreed dismissive line; no evidence, dialogue tree, or schedule was added. Names and door numbers are provisional signs, not new character lore. Closed filler doors have visible boards and no entry prompt.

The upper neighborhood uses taller houses, porticos, hedges, and trees. The business district uses shop windows, awnings, and upper windows. The lower neighborhood uses shorter clapboard fronts, doorstep benches, and a shared washing line. The schoolhouse has desks and a clear center aisle, with frontage space reserved for later pickup gatherings. The museum has display plinths and a desk; the historian and teacher remain for a later content pass.

The Pickman Street post office has a counter, mail compartments, and waiting chairs. Mail errands and school pickup remain the next NPC/schedule pass.

The morgue is a distinct room accessed through precinct intake, with six sheeted tables and a coroner. Source inspection found the full interview in the prose treatment, not an existing playable dialogue scene. This pass therefore supplies only a short, source-aligned placeholder interaction. The Day 2 montage remains; a full enacted coroner interview has not been claimed or introduced.

## Verification

- Opening, town, staging, usability, and phase-two mechanics regression suites passed.
- New `tests/town_expansion_flow.gd` passed: real walking to all three street passages, all 12 neighborhood interior entrances and exits, neighborhood return passages, morgue, and post office; saved location and position restore; filler doors remain inaccessible.
- Body tests cover a Day 3 second visit, retained birches evidence, silent removal on a later visit, save/load, lounge detours, and v5 migration. Existing staging tests cover the same-day revisit.
- Screenshots of all three neighborhoods, schoolhouse, museum, post office, morgue, and Pickman Street were inspected.
- Godot import and Web release export completed successfully. Browser startup check is recorded separately below; native traversal is not a claim of a full Web playthrough.
- `git diff --check` passed. Existing staging and phase-two suites still report two ObjectDB instances at shutdown; assertions pass, and the new expansion suite exits without that warning.

To run the expansion test, use Godot Mono 4.7.2 with an isolated APPDATA directory: `--headless --path <project> --fixed-fps 60 --script res://tests/town_expansion_flow.gd`.

Density, first-time navigation, and the emotional effect of the birches still need human playtesting. TDD and Bible files were not modified.

Browser smoke check: fresh release opened to the title screen in headless Chrome at 1440 × 900 with no captured page or console errors. Web index.pck SHA-256: 2D16A8C5B43D13FAD38FFC0E6EB3CA35FA40A784E534EBED41059BB8BE63566C.
