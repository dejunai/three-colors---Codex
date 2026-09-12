# Title accessibility button fix — 2026-09-11

Reported by Dejunai while attempting to audition instrument-voice volume. The button callback opened the ordinary settings panel underneath the photographic title layer, which remained visible and continued intercepting input.

The title now uses a dedicated callback that hides the prologue presentation before opening Accessibility & controls. Apply & return reconstructs the title normally. No setting values or title visuals changed.

`tests/title_settings_flow.gd` uses mouse input from a fresh title screen, confirms the visible Instrument voices slider, and confirms return to the photographic title. No Web export or publication was performed.
