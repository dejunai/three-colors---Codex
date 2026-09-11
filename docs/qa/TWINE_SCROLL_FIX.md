# Corkboard twine scrolling fix — 2026-09-11

Dejunai reported twine disappearing when the first row scrolled offscreen. Codex reproduced the issue in native Godot with an 18-card board and a connection from the first to last row.

Root cause: the custom thread Control had a zero-sized rectangle at the board origin. ScrollContainer culled the Control after that origin left the viewport, despite its custom drawing extending over the board. Brass pins disappeared with the same layer.

Fix: anchor the thread layer to the full board rectangle after parenting. Existing shared coordinates, clipping, link data, and mouse passthrough remain intact.

Validation: native before/after screenshots at scroll offset 500 show the missing/restored thread and pins. tests/twine_scroll_flow.gd checks rendered red thread pixels in the visible gutter while the first pin is offscreen (requires a graphical renderer). No web export or deployment performed.
