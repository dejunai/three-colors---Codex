# Chapter One slice playtest

Current as of 2026-09-19. The playable slice now spans three enacted investigation days and ends at the glass-shattering break after the service passage. Human reading and exploration time is intentionally measured rather than prescribed; automated traversal proves reachability, not whether clues, navigation, pacing or horror land.

## Cold-play route

Start a new investigation without coaching. Let the player follow the gatehouse boy, investigate the estate, prepare and submit Walter's report, question townspeople, sleep when ready, revisit the steward across the three days, and decide whether to follow the pantry lead. The notebook on Walter's desk is reflective only; the bed advances the day. The slice ends after the tunnel retreat, Walter's return home, the board-completion beat and the breaking glass.

Do not require the corkboard, every witness, every district, or every optional observation. Missing an NPC or choosing a different coat should produce another path through the inquiry rather than invalidate the session.

Record:

1. Time to the garden, first observation, Odell, estate departure, first sleep, each later day, service passage and ending.
2. Where the player hesitated, became lost, or expected an interaction that was absent.
3. Whether the estate geography naturally led them to both body groups, Odell and the exit.
4. Whether report preparation and later supplements read as Walter's actions rather than menu bookkeeping.
5. Whether the difference between a dialogue card and an examined-object card remained legible.
6. Whether the pocket watch made the clock understandable and whether travel/conversation costs felt plausible.
7. Whether NPC schedules made the town feel alive, confusing, too large, or easy to navigate.
8. Whether the plain coat changed social access clearly without behaving like an abstract key.
9. Whether evidence linking was discovered at the board without instruction, and whether positive/negative feedback explained Walter's reasoning.
10. Whether the groundskeeper/harbor Observer accents were noticed without explanatory text.
11. Whether the steward's repeated visits felt like progression rather than repetition.
12. Whether the pantry lead and boarded door were understandable, and whether entering the service passage felt chosen.
13. Whether the cough/head-turn cycle communicated danger, cover and retreat before punishment.
14. Whether the frame widening, returning red/amber and breaking glass read as one coherent ontological rupture.
15. Whether the player wanted more content at the cutoff.

Afterward, inspect anonymous telemetry only as supporting evidence. A session can reach Day 3 without completing the slice; `session_end`, `day3_bed_reached` and the debrief distinguish an actual ending from a late save or abandoned run. Conversation events represent fully completed authored topic segments, not menus merely opened.

## Focused regression checks

- Run a minimal second investigation that avoids the case board and most optional witnesses.
- Save during dialogue, after a district transition, before the service passage, and after retreat; quit and continue each.
- Use both police and plain coats at social gates.
- Test click-to-move as well as WASD, and deliberately close menus while moving the mouse to check camera recapture.
- Open the Tab menu and check the pocket watch at multiple phases. F3 is a development-only brisk-speed toggle and must be off for pacing judgments.
- Test enlarged text, zero distortion, reduced flicker and muted instrument voices. Captions and factual access must survive every presentation setting.

Use `python tests/run_all_qa.py` for the maintained 13-suite regression set, including the complete steward-to-glass ending route. Run focused suites such as `dialogue_catalog_flow.gd`, `pocket_watch_flow.gd`, `playthrough_log_flow.gd`, population checks and presentation checks when those areas change. Automated success never substitutes for the cold-play questions above.
