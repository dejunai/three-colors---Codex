# Estate instrumental-voice audition — 2026-09-11

Implemented by Codex at Dejunai's request. Scope is limited to the estate NPCs: gatehouse boy, Captain Odell, coroner's assistant, gardener, and groundskeeper. Walter, narration, objects, town NPCs, the steward, and later locations remain silent.

The dialogue DSL accepts an optional `VOICE: cue_id` directly before a spoken line. The runtime carries the cue on that card; Chapter One plays `assets/audio/instrument_voices/cue_id.wav` when the card appears and stops it on advance. Cue IDs must be simple identifiers, preventing path traversal. Missing assets warn and leave the card silent. Cues never affect gates, timing, evidence, notes, saves, or case state.

Six trombone files were copied from Dejunai's `three-colors-ch1-squiggles` repository: alarmed v1, bureaucratic v1, cautious v1/v2, dismissive v1, and weary v1. Seventeen estate NPC lines use this small set. The newer files described as `trombone_{style}_medium_v1/v2.wav` were not present in the repository after `git pull`; this audition therefore uses the available earlier filenames. They can be replaced or recued later without changing the DSL.

Accessibility settings now include **Instrument voices**, default 45%, range 0–100%. Zero fully mutes these cues without muting other audio.

Validation: `tests/instrument_voice_flow.gd` verifies clean parsing, all 17 cue references, asset availability, safe cue IDs, renderer metadata, playback, stop-on-advance, and independent mute. Existing dialogue language, content, and template flows pass. No Web export or publication was performed.
