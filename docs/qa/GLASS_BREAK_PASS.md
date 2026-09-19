# Glass break pass — the slice now ends at the glass

Date: 2026-09-19. Branch: dev/contiguous-town-phase-2. Not committed.

## What changed

The alpha slice used to end at the Day 3 bed with "A name brought home." It now ends at the
first significant break with reality (Bible Part Three, the ontological crack), reached through
the steward's pantry lead. The entity, the mother's voice and the fatal ending are not in the slice.

Path: steward `pantry_lead` -> boarded pantry door in the smoking lounge -> service stair ->
tunnel (existing stealth encounter, unchanged) -> the spur takes the flask (unchanged) ->
"Go on into the dark" (new, optional; "Step back" remains) -> pressure, retreat, badge and
whistle lost -> home, night -> quiet -> the board goes whole -> frame widens, red twine, amber in
the glass, the cough -> silence -> the glass breaks -> two cards -> tester questions -> ending.

## Decisions made without asking (flag any you disagree with)

- **Quiet glass.** 08's glass, placed at the end of 01/04's board-completion. Cut before the
  mother-shape or any voice. 01/04 put her voice before the glass, which contradicts the Bible's
  "the cough is the frame's only sound until the crack"; this build follows the Bible.
- **Sleeping no longer ends the slice.** Until the break has played, the bed shows the existing
  "There's still work to do" panel with the current objective. The legacy close_day + debrief path
  is still reachable for a save that already carries `glass_broken`.
- **The tester questions now follow the glass**, not the bed. Their heading changed from
  "Before Walter sleeps" to "Before this closes". The telemetry event names and Worker allowlist are
  unchanged. `day3_bed_reached` now fires when the break begins.
- **Color is not a global grade.** Only red and amber (and, faintly, warm-leaning materials) return;
  the room stays gray. A global saturation lift was tried first and rendered the room lime green.
- **The tunnel's survey framing was reworded** (objective text, `tunnel_record` second card, the
  "Get behind stone" caption). `lower_foundation` evidence and its downstream paperwork are intact.
- **State lives in `dialogue_state` flags** (`tunnel_retreated`, `badge_lost`, `glass_broken`), so no
  save-schema bump. `state.finished` is set at the glass: a save from then on resumes at the ending.

## The sound rule

Instrument voices are the silent-film pit band. The world itself has no footsteps, doors or
interface tones; the cough is the only world sound until the glass. Any ordinary sound added
before this beat weakens it. The glass is synthesized (like the cough), so no audio asset was added.

## Accessibility

The widening and color channels are not attenuated by the distortion or flicker settings
(`tests/break_flow.gd` runs with distortion 0 and reduced flicker on). Both sounds have protected
captions ("[A dry cough.]", "[Glass breaking.]"). Not yet done: the TDD's open "accessible-mode
degradation vocabulary" question is untouched, and the widening is a slow tween, not a flash.

## Verification

- `tests/break_flow.gd` (new): the full path through the real adapters, including the held page
  (Escape, use and the case file cannot interrupt), no evidence change across the break, the
  point-of-no-return save, one debrief event, no replay.
- Updated for the new sleep gate: `town_flow`, `staging_flow`, `debrief_flow`; `portal_content_flow`
  now lists `pantry_door`.
- Full suite: 51 pass, 2 fail. Both failures pre-date this pass: `test_placement_audit` (known parse
  error) and `dialogue_catalog_flow` (`sarah_munn` shares a physical slot with `chandlers_boy`;
  reproduced on a clean checkout of HEAD).
- Rendered the room at each stage in a real window and inspected it. Sound has **not** been heard by
  anyone: the glass and cough were verified to build, not to sound right.

## Known gaps

- The ring-wearing crew member watching Walter find the pantry door (01/04) is not staged; the
  existing groundskeeper observation is the only Observer beat before the tunnel.
- The room is bare and Walter is a block figure; the beat leans on the prose, the width change and
  two colors. Judge it on a cold playtest before dressing it.
- A tester who loses mid-passage reloads the service-stair checkpoint, as before.
- The Worker's `debrief` fields still describe the town, not the ending. A horror-specific question
  needs a Worker change and redeploy, which was not attempted.
