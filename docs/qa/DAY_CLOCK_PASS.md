# Shared clock and daylight — 9 September 2026

Implemented the agreed clock/daylight pass. NPC availability, door access, the speakeasy, and schedules remain unchanged. The Day 2 montage remains until there is sufficient enacted investigation content.

## Rules

- Morning begins at 06:00, noon at 12:00, evening at 17:00, and night at 20:00. Night holds at 20:00; it does not advance the day automatically.
- Wandering advances the investigation clock five game minutes per real minute. Dialogue, notebook, and other menus pause wandering time. Existing real movement minutes are retained separately for pacing probes.
- Completing a substantive conversation costs 30 minutes, once per content ID. Reopening recorded content cannot charge again. Introductory pleasantries, brief refusals, placeholder residents, and reading objects are free. Intake's combined conversation is charged once. An explicit override table supports longer future conversations.
- Travel between districts costs 30 minutes. Estate/lounge/tunnel form one district; Pickman Street and its interiors form another; each residential or business hub and its interiors form its own district. Entering a shop, lodging, morgue, or room is free. Save/load does not charge travel. Scripted tunnel returns to town do charge the district crossing.
- Existing sleep prerequisites are preserved. The existing montage bridge resets the clock to morning, ending at Day 3 morning. No extra investigative days are introduced by this pass.

## Presentation

A simple pale sphere marks the sun: east (+X) in the morning, directly overhead at noon, west (-X) in the evening. It disappears at night. Sky/ambient light and existing directional lights switch between fixed phase settings; there is no continuously simulated sun trajectory. Street lamps turn on during evening and remain on at night. Existing interior illumination is preserved.

The location caption includes day and phase. Mouse look can now tilt upward to see the overhead sun. The avatar hides when the camera looks steeply upward from beneath it or a wall/gate pushes the camera too close, then returns when there is room for the normal view.

## Persistence and validation

CaseState schema 7 stores clock_minutes and timed_conversations. Versions 1–6 remain supported. Old saves begin at morning because they contain no reliable investigation clock; earned conversation content is migrated to avoid charging established testimony again.

The new tests/day_clock_flow.gd passed: 5x rate; paused dialogue/notebook; completion-only conversation cost; free repeats and refusals; district vs. interior travel; save/load; four sun/lamp states; night hold; legacy migration; invalid clock rejection; montage morning reset.

Opening, town, staging, usability, and phase-two regression suites passed. Existing staging tests retain their two-ObjectDB-instances shutdown warning. Native morning/noon/evening/night captures were inspected, including the final east/west light direction and corrected captions. Web export completed. A Chrome smoke check reached the opening gameplay with no captured browser console or page errors on the final release; this is not a complete Web playthrough. git diff --check passed.

The revised Web release is in the project's build/web directory. Nothing was committed, pushed, or published by this task. Human playtesting should now establish when evening/night arrives along typical investigation routes; no closure rules are being imposed yet.
