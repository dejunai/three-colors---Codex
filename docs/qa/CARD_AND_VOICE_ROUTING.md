# Card and voice routing — 2026-09-12

Scripted dialogue now resets the shared card presentation to `dialogue` whenever a segment begins. Previously, the adapter started `dialogue_sequence.gd` directly and could retain `card_kind == "examine"` from the preceding interaction, causing a conversation to use the physical-examination frame. `dialogue_live_flow.gd` reproduces and guards that sequence.

The precinct intake clerk remains legacy `town_story.gd` content rather than a `.dialogue` NPC. Her five spoken cards now carry explicit instrumental cues. For authored `.dialogue` content, the runtime supplies a neutral medium cue when a real NPC line omits `VOICE:` and emits a warning naming the file, speaker, and fallback. It preserves the speaker's established instrument when possible and otherwise uses trombone. Braced cookbook/shared identities remain exempt because their examples are deliberately incomplete and never enter live play.

Validation: `dialogue_live_flow.gd`, `instrument_voice_flow.gd`, and `dialogue_content_flow.gd` pass. The voice test covers the 144-entry manifest, every explicitly authored NPC cue (455 at the September 12 documentation sync), fallback behavior, and every legacy intake-clerk card. The assertion derives coverage from the parsed corpus rather than freezing that changing line count. No Web export or publication was performed.
