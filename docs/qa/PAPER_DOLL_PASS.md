# Personal Effects paper-doll pass — 20 September 2026

Implemented on `feature/analogue-pocket-watch` as the second focused UI refinement.

## Player-facing behavior

- The former six-rectangle placeholder is now a code-drawn Walter whose visible equipment comes directly from live case state.
- Six labelled, keyboard-focusable callouts select coat, badge, notebook, revolver, flask and boots.
- Coat selection uses the existing police/plain change behavior, refreshes the world model, saves, and redraws the figure. It does not create a second clothing state.
- Flask selection uses the existing flask panel and drinking mechanic. After the tunnel, the bottle becomes a severed strap and its inspection reports the loss.
- The badge appears only on the police coat while it remains in Walter's possession. Plain-coat and `badge_lost` inspections explain the actual state.
- Revolver inspection reports live ammunition. Boots are a short character detail. Notebook selection opens the existing notebook.
- The equipment paragraph and full-width watch button were removed. A compact closed-watch control occupies the previously empty upper-right area and opens the existing analogue face.
- `Return to the grounds` sits directly beneath the notebook and case-file actions, so the player does not scroll past the paper doll merely to close the parent screen.
- Screens entered from Personal Effects retain that parent context: closing the watch, flask, notebook, case file, fact pages, badge, revolver or boots returns to the paper doll. The same screens opened directly from gameplay still close to gameplay.

## Verification

- `tests/paper_doll_flow.gd`: all six controls exist; coat selection mutates the canonical state and redraws; badge visibility follows coat/loss; flask loss and ammunition mirror state; the grounds action stays in the right-hand action group; child equipment/notebook UI returns to the doll while directly opened UI still returns to gameplay.
- `tests/pocket_watch_flow.gd`: the icon exists with its textual tooltip and still reaches the full watch behavior.
- `docs/qa/paper_doll.png`: native Godot capture inspected for hierarchy, callout alignment, equipment readability, watch placement, scrolling and return-button placement.

The paper doll is presentation over existing state. It adds no equipment bonuses, inventory duplication, or new combat rules.
