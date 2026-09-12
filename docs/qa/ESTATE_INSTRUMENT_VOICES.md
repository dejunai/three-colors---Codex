# Instrumental NPC voices — 2026-09-11

Implemented by Codex at Dejunai's request. The first audition was limited to the estate. After its mechanics and placeholder quality were accepted, coverage expanded to every authored Chapter One NPC. Walter, narration, notebooks, objects, location cards, and system text remain silent.

The dialogue DSL accepts an optional `VOICE: cue_id` directly before a spoken line. The runtime carries the cue on that card; Chapter One plays `assets/audio/instrument_voices/cue_id.wav` when the card appears and stops it on advance. Cue IDs must be simple identifiers, preventing path traversal. Missing assets warn and leave the card silent. Cues never affect gates, timing, evidence, notes, saves, or case state.

Accessibility settings now include **Instrument voices**, default 45%, range 0–100%. Zero fully mutes these cues without muting other audio.

The September 11 full placeholder library comes from commit `011395a` of Dejunai's `three-colors-voice-pack` repository. It contains 144 stable cue IDs: trombone and violin, twelve delivery styles, three lengths, and two takes. The WAVs were rendered from expressive MIDI through MuseScore General. The shipped `manifest.json` is now authoritative: runtime dialogue loading rejects a well-formed `VOICE:` identifier that is absent from the manifest instead of failing silently during playback.

The estate assignments remain the hand-tuned reference set. Across the rest of Chapter One, each character keeps one instrument while mood, length, and take vary by line. `tools/seed_instrument_voices.py` deterministically fills uncued NPC lines and preserves every existing cue, so hand-tuned choices always win. The initial full-project seed covers 403 spoken NPC lines across 35 live dialogue files.

Validation: `tests/instrument_voice_flow.gd` verifies all 144 manifest entries and assets, unknown-cue rejection, clean parsing, complete NPC coverage, silent-player/object boundaries, character-level instrument consistency, renderer metadata, playback, stop-on-advance, and independent mute. No Web export or publication was performed.
