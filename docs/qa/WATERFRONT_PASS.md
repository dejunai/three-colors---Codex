# Waterfront district — 11 September 2026

Dejunai requested the waterfront as a playable district. Codex added a separate outdoor hub using the existing travel, clock, save, and dialogue systems, then wired in four additional authored waterfront residents alongside the three earlier scheduled ones. No Web export or publication was performed; the phone experiment remains separate.

Enter at the western end of Pickman Street, through the WATERFRONT marker near the estate-road end. Return through the signed lane between the harbor buildings. Crossing districts costs the existing 30 minutes. The waterfront saves and restores under the stable world ID `waterfront`; schema 9 is unchanged.

The quay has a seawall, mooring apron, small fishing boats, stone repairs, drying nets, lamps, and four exterior fronts: chandlery, freight office, net loft, fish stores. These fronts do not yet open into interiors. The abandoned whaling station sits on a low offshore island partly buried by mud. It is visible scenery, with no route, new clue, explanation, or objective attached.

Scheduled residents and their dialogue IDs:

- Harbor mason: `quay_repair` in morning and midday; returns to `lower_house_3` in evening.
- Salt mender: home in morning/evening; `quay` on the waterfront at midday.
- Quay bookkeeper: `quay_office` in morning/midday; unavailable in evening.
- Chandler's boy: `waterfront_chandlery` in morning/midday; unavailable in evening.
- Net seller: `waterfront_net_loft` in morning/midday; unavailable in evening.
- Quay docker: `waterfront_moorings` in morning/midday; unavailable in evening.
- Ropewalk foreman: `waterfront_fish_stores` in morning/midday; unavailable in evening.

The catalog's existing blanket night closure still applies. These are phase placements, not simulated walks between districts. No new unnamed people or mysteries were added.

## Locations for the next writers

Use `LOCATION: waterfront` with an explicit schedule. The current named frontage slots in use are `waterfront_chandlery`, `waterfront_net_loft`, `waterfront_fish_stores`, and `waterfront_moorings`; `quay`, `quay_repair`, and `quay_office` are also occupied in the active schedule set. For example:

```text
NPC: your_unique_npc_id
LOCATION: waterfront
SCHEDULE: morning=waterfront_chandlery, midday=waterfront_chandlery, evening=closed, night=closed
```

Do not give multiple residents the same slot in the same phase without intentionally restaging the district. Consult `docs/DIALOGUE_AUTHORING.md` for gates and dialogue syntax. The NPC HTML reference was regenerated from the changed location/schedule metadata.

## Validation

`tests/waterfront_flow.gd`: entry/return, travel cost, outdoor daylight setup, island scenery without route, all seven waterfront residents' live interaction focus, evening/night schedules, and save restoration. `tests/dialogue_catalog_flow.gd`: 33 NPCs / 157 nonempty topics, effects, timing, links, and reachable placements. `tests/town_expansion_flow.gd`: existing neighborhoods, rooms, morgue, post office, and body timeline. All passed. The older expansion test was corrected to check a placeholder resident only when its interaction actually exists; the stationer's named dialogue already replaces that placeholder.

A rendered Godot view was inspected. Primitive geometry remains deliberate. Water and island are scenery beyond the playable seawall; no swimming, boats, island exploration, new interior, or night venue is implied by this pass.
