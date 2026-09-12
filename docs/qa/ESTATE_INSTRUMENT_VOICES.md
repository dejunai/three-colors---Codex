# Estate instrumental-voice audition — 2026-09-11

Implemented by Codex at Dejunai's request. Scope is limited to the estate NPCs: gatehouse boy, Captain Odell, coroner's assistant, gardener, and groundskeeper. Walter, narration, objects, town NPCs, the steward, and later locations remain silent.

The dialogue DSL accepts an optional `VOICE: cue_id` directly before a spoken line. The runtime carries the cue on that card; Chapter One plays `assets/audio/instrument_voices/cue_id.wav` when the card appears and stops it on advance. Cue IDs must be simple identifiers, preventing path traversal. Missing assets warn and leave the card silent. Cues never affect gates, timing, evidence, notes, saves, or case state.

Accessibility settings now include **Instrument voices**, default 45%, range 0–100%. Zero fully mutes these cues without muting other audio.

The September 11 playtest revision uses four cues from Dejunai's `three-colors-voice-pack` repository, rendered from expressive MIDI through the MuseScore General trombone and violin instruments. It replaces the rejected Iowa MIS grain-concatenation audition without changing cue IDs or dialogue behavior. Odell uses bureaucratic and dismissive trombone; cautious and weary deliveries use violin. Sixteen estate lines are cued for the audition. The gatehouse boy's alarmed line remains silent until an accepted alarmed sample exists.

Validation: `tests/instrument_voice_flow.gd` verifies clean parsing, all 16 cue references, asset availability, safe cue IDs, renderer metadata, playback, stop-on-advance, and independent mute. Existing dialogue language, content, and template flows pass. No Web export or publication was performed.
