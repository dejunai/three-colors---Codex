# THREE COLORS OF MADNESS — Chapter One ("No Exit Wound") Restaging + day-cycle pass — build brief for Codex

## CONTEXT
This is a Godot 4.7 project (GL Compatibility renderer). The Design Bible and TDD are authoritative — where this brief conflicts with either, stop and flag it rather than guessing. Design Law 4 governs everything below: "the presentation can become unreliable; the underlying game state cannot become unfair." Players may doubt the narrator; they may never doubt the controls.

## GOAL
The current opening slice plays ~8 minutes but only has ~3-5 minutes of real content in it — it's bloated because two characters are staged too early and in the wrong location. Fix the staging, add a day-cycle montage, and add a read-only notebook. Do NOT touch anything about the entity, the ontological break, or presentation-unreliability effects — none of that is in scope yet.

## TASK 1 — Restage the club steward (currently "barman")
Currently placed in the open rose-garden crime-scene environment alongside the six bodies. This is wrong on two counts:
- (a) Narratively, per the source story, he only opens up "out of uniform, three nights running, at the far end of the bar" — a private, off-the-record beat, not something that happens in the open next to a crime scene;
- (b) It undercuts the coat mechanic's whole purpose if he's reachable before the player has any reason to be wearing the plain coat.

**Requirements:**
- Move him to an interior space, reached via a service entrance (not the member-facing entrance).
- Gate his scene behind:
  1. Player has completed the Mrs. Almy scene, AND
  2. Player is wearing the plain coat (no badge), AND
  3. This is visit #3 to that location (see Task 3 — day cycle).
- Visits 1 and 2 (in-scene, if the player tries early) should rebuff the player in-character — he's polite, gives nothing, doesn't acknowledge anything is different about the coat yet.
- On visit 3, he delivers the line that gates the day-cycle payoff (see Task 3) and opens up for real.

## TASK 2 — Restage the groundskeeper
Currently registered unconditionally (per existing `target("crew", ...)` call in `estate.gd`, no perception gate) and appears in the first scene. Per the Design Bible, the grounds crew are this chapter's Observers — meant to be noticed in passing, "precise, unbothered, back to work in the same breath," not an opening info-dump. Move his observation point out of the opening beat entirely; he should be encountered later, incidentally, during normal movement around the estate — not gated behind Perception (that's still correct per the bible), just not front-loaded into minute one.

## TASK 3 — Sleep / day-cycle montage
There is currently no mechanic for time passing. Build a lightweight montage system:
- Triggers when the player sleeps (existing bed prop already in-scene; wire it to this).
- Nights 1 and 2: a short still-image montage (not playable scenes) showing Walter interviewing witnesses, ending on a still of him arriving at the steward's location. Final beat of each night's montage: the steward rebuffing him, ending night 2's montage with the explicit line: "Come back tomorrow. And don't bring your badge."
- This is diegetic teaching of the coat mechanic — no tooltip, no UI popup explaining it. The line does the teaching.
- After night 2's montage, day 3 begins with the steward scene from Task 1 now available (assuming coat + Mrs. Almy conditions are met).
- Do NOT build a full paper-doll or wardrobe system. The existing coat toggle (badge / no badge) is sufficient — confirm it already gates NPC dialogue variation for the town clerk and Kessler's widow per the source material, and extend that same pattern to the steward, not a new system.

## TASK 4 — Notebook (read-only mirror) & Rich Linkage Feedback
Add a new notebook UI object that mirrors the corkboard's current state (evidence, links, Perception display state — UNRESOLVED/FORMING/COMPLETE) read-only. Do NOT move the linking interaction off the corkboard — `_link_picker()` and `_board()` stay exactly as they are; the notebook has no interactive logic of its own, it just renders the same `case_state` data the board already exposes.

**Rich Diegetic Linkage Feedback (Positive & Negative):**
The linkage mechanic currently has painfully brief feedback. Expand this with rich, atmospheric deductive text in Walter's investigative voice:
- **Positive feedback (`[this link makes sense]`)**: When a valid connection is drawn, provide a substantive narrative explanation of why these two observations corroborate each other and what deduction Walter draws from the connection.
- **Negative feedback (`[that doesn't make any sense]`)**: When an invalid connection is attempted, provide Walter's internal reasoning dismissing the link (why these facts do not connect or lack causal relevance) rather than a brief generic error.

**IMPORTANT — explicitly out of scope for this pass:**
Any mechanic where the notebook's text diverges from or "lies" relative to the board. The board must stay 100% factual (Design Law 4 — it's still the controls). The notebook, once built, is the planned future home for presentation unreliability, but that feature is deferred and should not be started.

## TASK 5 — Tighten the opener, scene clean-up & NPC repositioning
- **Pacing / timing check**: With the steward and groundskeeper removed from the opening beat (Tasks 1-2), confirm the remaining opener (gatekeeper boy, gardener — interviewed twice, with badge and without — coroner, Odell, the exit paperwork, the four clues, the bodies in the birches) plays in roughly 3-5 minutes. If it's still running long, flag what's adding time rather than cutting content unilaterally.
- **Post-opener scene clean-up**: When the bodies are removed after the opening scene, Captain Odell and the coroner's assistant must also depart. They should not linger around an empty crime scene on subsequent visits.
- **Gardener repositioning**: For subsequent visits/encounters, the gardener must move out of the rose garden to a nearby spot on the grounds ("not too far").
- **Gatehouse boy dialogue**: Give the gatehouse boy new dialogue pointing Walter toward the gardener's relocated position ("over yonder...").

## ACCEPTANCE / VERIFICATION
Per this project's existing standard (see TDD Verification section), don't just self-report — check source and, where possible, play it:
- Confirm via source that the steward's scene is unreachable until all three gating conditions are met, and unreachable via any path that bypasses them (save/load, replaying earlier scenes, etc. — same rigor as the existing `tests/town_flow.gd` assertions for the old woman).
- Confirm Captain Odell, the coroner's assistant, and the bodies are absent on repeat visits to the opening area.
- Confirm the gardener relocates to a nearby position outside the rose garden and the gatehouse boy directs Walter there.
- Confirm the corkboard displays rich, diegetic positive feedback for valid links and substantive negative feedback for invalid attempts.
- Confirm the notebook has no code path that can write to `case_state` — it should be provably read-only.
- Confirm the montage doesn't block the player from re-entering already-explored areas afterward (no soft-lock).
- Report total playtime for opener + Pickman Street + tunnel entry, per Task 5.

## OUT OF SCOPE (do not touch)
- The ontological break / glass-shatter / aspect-ratio / color-bleed sequence.
- The fatal-comprehension ending.
- Notebook "lying" / presentation-unreliability effects.
- Paper-doll wardrobe system.
- Renaming "barman"/"bar" — a naming pass is coming separately, don't touch these terms yet.
