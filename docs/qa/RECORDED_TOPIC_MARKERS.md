# Recorded dialogue-topic markers — 2026-09-11

The original handwritten witness menus appended `  · recorded` to completed questions. That feedback was unintentionally lost when menu construction moved into the generalized dialogue runtime: `menu()` returned only the authored label and never consulted dialogue completion state.

The generalized menu now appends the same marker when either the topic ID or its optional TAG has been completed for that NPC. Completion state is authoritative rather than evidence possession, because a valid conversation may record notebook prose without granting separate evidence. Topics whose GATE deliberately hides them after completion remain hidden.

`tests/dialogue_lang_flow.gd` covers a repeatable completed topic and tag-only completion. Live dialogue, the 35-NPC catalog, timing, saves, and old-save compatibility also pass.
