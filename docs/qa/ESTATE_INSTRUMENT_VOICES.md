# Estate instrumental-voice audition — 2026-09-11

Implemented by Codex at Dejunai's request. Scope is limited to the estate NPCs: gatehouse boy, Captain Odell, coroner's assistant, gardener, and groundskeeper. Walter, narration, objects, town NPCs, the steward, and later locations remain silent.

The dialogue DSL accepts an optional `VOICE: cue_id` directly before a spoken line. The runtime carries the cue on that card; Chapter One plays `assets/audio/instrument_voices/cue_id.wav` when the card appears and stops it on advance. Cue IDs must be simple identifiers, preventing path traversal. Missing assets warn and leave the card silent. Cues never affect gates, timing, evidence, notes, saves, or case state.

Accessibility settings now include **Instrument voices**, default 45%, range 0–100%. Zero fully mutes these cues without muting other audio.

The September 11 full placeholder library comes from commit `011395a` of Dejunai's `three-colors-voice-pack` repository. It contains 144 stable cue IDs: trombone and violin, twelve delivery styles, three lengths, and two takes. The WAVs were rendered from expressive MIDI through MuseScore General. The shipped `manifest.json` is now authoritative: runtime dialogue loading rejects a well-formed `VOICE:` identifier that is absent from the manifest instead of failing silently during playback.

The estate remains the only voiced location. Instruments stay consistent by character: Odell, the gardener, and the groundskeeper use trombone; the gatehouse boy and coroner's assistant use violin. Seventeen lines vary mood, length, and take, including the gatehouse boy's previously silent alarmed line. Other NPCs, Walter, narration, and objects remain silent.

Validation: `tests/instrument_voice_flow.gd` verifies all 144 manifest entries and assets, unknown-cue rejection, clean parsing, all 17 estate cue references, estate-only scope, renderer metadata, playback, stop-on-advance, and independent mute. No Web export or publication was performed.
