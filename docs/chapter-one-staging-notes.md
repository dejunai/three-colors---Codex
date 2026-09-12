# Chapter One — agreed staging and progression notes

Discussion notes, September 8, 2026. These record the user's decisions for a future implementation pass. No game changes are authorized by these notes. The user will incorporate the decisions into the TDD. The Design Bible takes precedence over the TDD and build brief.

## Locations and encounters

- The barman is now the steward; the bar is now a smoking lounge.
- The steward belongs inside the smoking lounge, not in the rose garden.
- Access through the service entrance is unavailable until Walter has spoken to Mrs. Almy.
- The groundskeeper encounter becomes available only when Walter leaves the smoking lounge. It is not an opening encounter or a Perception-gated encounter.
- The gardener's second, plain-coat encounter is optional. It must take place outside the rose garden; the later location remains unspecified.
- Bodies must be removed after the opening scene. They must not remain on a later visit, even if Walter returns that same day.
- Captain Odell and the coroner's assistant depart when the bodies are removed; they do not linger at the scene once the bodies are cleared.
- The gardener moves out of the rose garden for later encounters, relocating nearby on the grounds ("not too far").
- The gatehouse boy receives new dialogue pointing Walter toward the gardener's new position ("over yonder...").

## Temporary three-visit progression

1. Day one: Walter speaks to the steward in the smoking lounge. This playable conversation counts as the first visit.
2. Until that first conversation has happened, trying to sleep is blocked with a brief message that there is more work to do. Suggested wording from the discussion: “There's still work to do.” This restriction is explicitly a temporary placeholder.
3. The day-two montage includes the smoking-lounge encounter, counting as the second visit. Use stills and subtitles/intertitles. The final intertitle is the steward saying: “Come back tomorrow, and don't bring your badge.”
4. On day three, Walter returns in the plain old coat for the third visit, when the steward opens up.

Repeated entries on day one do not substitute for this agreed day-one / montage / day-three sequence. Exact handling of a day-three return in uniform remains to be specified.

## Montage purpose

- The montage is a placeholder until there is enough worthwhile playable content to occupy the intervening day.
- The coroner's interview at the morgue may appear in the montage for now; in the final game it should be enacted.
- The steward's rebuffs will eventually arise primarily as consequences of other conversations, rather than simply serving as time gates.

## Dialogue direction

- For now, support the canonical and resistance player routes.
- The final game must support mixed responses and middle-ground players through multiple branching dialogues, with each response having a consequence later.
- Do not treat those two initial routes as a requirement to lock the player into a single permanent alignment. Record specific choices so their consequences can be expressed later, consistent with the Bible's prohibition on morality scoring.

## Retained scope from the discussion

- A portable notebook should mirror the corkboard's evidence, links, and causal-spine display read-only. Linking remains at the corkboard.
- Notebook unreliability, the ontological break, and the fatal ending remain outside this staging pass.
- Use the existing coat toggle; a new wardrobe system is not requested.
- The gardener's optional second interview must not be treated as mandatory when assessing the minimal opening route's pacing.
- Timings and claims about existing NPC coat variations still require verification before implementation; discussion has not established them as tested facts.

## Linkage mechanic feedback

- The corkboard linkage/connection mechanic requires substantive diegetic feedback for both positive and negative connection attempts:
  - **Positive feedback (`[this link makes sense]`)**: When a valid connection is drawn, provide evocative, investigative narrative reasoning explaining how and why the two observations corroborate each other.
  - **Negative feedback (`[that doesn't make any sense]`)**: When an invalid connection is attempted, provide Walter's internal deductive voice articulating why the two cards have no causal or factual relationship, rather than failing silently or with a generic refusal.
  - The current feedback is painfully brief; the expanded feedback must provide full, atmospheric reasoning that respects Walter's investigative discipline and the case facts.

## Status

Historical discussion notes (8 September 2026). The staging described here was implemented; see `docs/qa/STAGING_PASS.md` and `scripts/chapters/chapter_one_staging.gd` for the live contract. Retained out-of-scope items in this note (notebook unreliability, ontological break, fatal ending) remain future work. Design Bible still wins over TDD and build briefs.
