# Returning precinct and morgue NPCs

Prepared by Codex from Claude's npc_precinct_morgue_skeletons.json, supplied by Dejunai. Dialogue prose will be authored by Dejunai. The repaired JSON in docs is a reference, not a live runtime registry; no placeholder dialogue was installed.

## File headers to use

`dialogue/odell_precinct.dialogue`:

```text
NPC: odell_precinct
LOCATION: precinct
SCHEDULE: morning=precinct, midday=precinct, evening=closed, night=closed
```

`dialogue/assistant_morgue.dialogue`:

```text
NPC: assistant_morgue
LOCATION: morgue
SCHEDULE: morning=morgue, midday=morgue, evening=closed, night=closed
```

Use CAPTAIN ODELL and CORONER'S ASSISTANT as speaker names. The suffixes are internal IDs only.

For Odell's first greeting use `TOPIC: default` with `GATE: NOT topic_done(odell_precinct, default)`. For an automatic repeat greeting use another `TOPIC: default` with `GATE: topic_done(odell_precinct, default)`. Use separate TAG values. An estate follow-up can require `topic_done(odell, default)` plus `NOT topic_done(odell_precinct, your_topic_id)`; do not negate the estate prerequisite. Evidence and earlier choices are shared case state, while topic completion uses the explicit NPC ID.

Replace placeholder topic IDs and prerequisites with real IDs. Add EVIDENCE only when a conversation actually earns a defined observation, not as a greeting reward. New authored evidence should have an appropriate NOTEBOOK statement preceding it.

## Prepared integration

The catalog reserves a precinct position (3.8,0,1) for odell_precinct and a morgue aisle position (1.6,0,-1) for assistant_morgue, separate from the intake clerk and coroner. Both require day >= 2 and estate_complete. Existing time schedules still control working hours; night remains closed. With the current montage, day-three visits are the playable use of these placements.

The population cache now also checks day and estate completion, so story changes cannot leave stale actors solely because the room and time phase are unchanged. No new general scheduling syntax or save fields are introduced. The original estate actors retain their existing departure rules.

After adding the .dialogue files, restart the game so the catalog rescans. Run the dialogue checks and tools/regenerate_npc_tree.gd to update the viewer from the authored source. The existing viewer already discovers new location categories; do not hand-paste compiled NPCS entries.

Validation: tests/returning_staff_flow.gd passes for unavailable opening/day-one states, available day-two/day-three workplaces, and night absence using fixture definitions. Final dialogue playback and in-game reachability should be checked after the real files arrive. No export/publication performed. Existing ropewalk dialogue and NPC viewer edits were preserved.
