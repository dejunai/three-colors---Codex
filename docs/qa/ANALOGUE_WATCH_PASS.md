# Analogue pocket-watch pass — 20 September 2026

Implemented on `feature/analogue-pocket-watch` as the first focused UI refinement.

## Player-facing behavior

- Tab / I opens Personal Effects; the small closed-watch icon at its upper right opens a code-drawn brass analogue watch with Roman numerals and hour/minute hands driven by `clock_minutes`.
- A small aperture in the face shows a sun from 06:00 through 17:59 and clicks to a moon at 18:00. It remains moonlit through midnight.
- The exact twelve-hour readout and day/phase label remain beneath the face for accessibility and development diagnostics. At the ceiling the text reads `MIDNIGHT`.
- Night lighting and schedules still begin at 20:00. Time continues during valid wandering, conversations and travel until 24:00, then every advancement path clamps there until Walter sleeps. Sleep resets an enacted next day to 06:00 through the existing staging code.
- No second hand is shown because the game clock does not model seconds.

## Implementation

`scripts/ui/pocket_watch_face.gd` draws the case, dial, ticks, numerals, aperture and hands without adding a final-art dependency. `scripts/shared/day_clock.gd` owns both the midnight ceiling and the aperture boundary. `case_state.gd` accepts restored clock values through midnight.

The watch remains a paused menu. Opening it cannot advance time, and reopening it rebuilds the hands from the current state rather than maintaining separate UI time.

## Verification

- `tests/pocket_watch_flow.gd`: analogue node and live minutes, exact text, sun through 17:59, moon at 18:00, paused-menu behavior, wandering update and midnight clamp.
- `tests/day_clock_flow.gd`: all advancement sources hold at midnight; save/load retains midnight; sleep still resets Day 2 and Day 3 to 06:00.
- `archive/docs/qa/analogue_watch.png`: native Godot renderer capture at Day 2, 18:30; inspected for hand position, Roman-numeral alignment, moon aperture, exact readout and button placement.
