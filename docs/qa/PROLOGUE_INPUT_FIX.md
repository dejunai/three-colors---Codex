# Prologue input lock — 2026-09-11

Reported by Dejunai after importing the photographic Grok-inspired intro. Loading an existing game worked; the new-game prologue appeared to deny input.

Codex diagnosis and fix:
- _new_game calls _travel, whose _close captures the mouse for gameplay. Prologue show_slide did not restore visible mouse mode. Both show_title and show_slide now explicitly restore visible pointer input.
- _clear previously queued old controls for deletion but left them parented until the end of the frame. _focus_first could find an old title/slide button and focus it instead of the new Continue. Old children are now detached immediately before queue_free.
- hide_all now hides the full-screen prologue root; show methods restore it. This prevents the otherwise empty Control remaining over gameplay after the intro.

Validation: tests/prologue_input_flow.gd passed with native graphical Godot using injected mouse press/release and Enter events, not direct button signals. It clicks Begin at the estate, checks visible pointer and Continue focus on all three slides, verifies completed gameplay state and captured mouse afterward, then repeats via keyboard advancement. Existing saves and story content are unchanged. No web export or publication performed.
