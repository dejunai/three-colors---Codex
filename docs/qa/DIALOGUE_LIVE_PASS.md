# Live Chapter 1 dialogue — integration and provenance

9 September 2026. Codex completed the live integration requested by Dejunai,
rebasing the tested adapter onto commit `1f1055f` after the usage-limit interruption.
The original scripting system was developed with Claude Sonnet 5. The current
dialogue expansion and numeric TIME convention are Dejunai's subsequent work.
All 30 current `.dialogue` files are preserved byte-for-byte in this pass.

**Current-state addendum — September 12, 2026:** This document preserves the original integration pass below. The live catalog has since grown to 35 concrete NPC definitions and 217 nonempty topics. The same interpreter is now the planned foundation for all three chapters. It supports validated `VOICE:` cues, weighted repeat defaults, free unpriced greetings, and persistent branch-local `OUTCOME` values whose completed decisions automatically retire their source forks. The current behavior and authoring contract are maintained in `docs/DIALOGUE_AUTHORING.md`; the historical counts and three-minute omitted-default rule below describe the September 9 baseline only.

## Connected behavior

- Automatic catalog discovery registers 29 concrete NPCs; the background template
  is excluded. All 119 nonempty authored topics parse and render. GATE: never
  exclusions remain unavailable; the test count includes those authored blocks.
- ChapterOneDialogue now owns NPC intros, refreshed topic menus, real FORK buttons,
  per-card acknowledgment, effects, and mid-conversation saves. The selected Walter
  line is consumed by selecting its button; it is not shown again as a redundant card.
- EVIDENCE writes the existing case record; new evidence descriptions use the
  author's preceding NOTEBOOK text and witness/source, without replacing existing
  FACTS descriptions. NOTEBOOK also preserves authored free-text statements.
- Existing notebook, Perception, reports, county copies and supplements consume
  the same records. Seven explicit corroboration links connect new testimony to
  related observations (knife, watch, letters, press count, maternal wording,
  wage inquiry, and the foul-air story). These add no automatic discoveries.
- Two draft gate aliases connect established vocabulary: ophion_name reads
  behan_name or ophion_myth_classical; kessler_standing reads kessler_carriages.
  Aliases grant neither extra facts nor Perception.
- The first steward conversation, second-visit montage, third-day plain coat,
  groundskeeper-after-lounge, body timeline and opening paperwork gates remain.
  The montage has not been removed or replaced by invented Day 2 progression.

## TIME and saves

`TIME: 7` means seven in-game minutes on first completion of that topic/variant.
No time is charged while preparing cards, reading a pending conversation, or
choosing a branch. Completion uses the user's runtime implementation; the adapter
does not also apply the legacy 30-minute charge. Omitted/non-numeric values retain
the user's three-minute default. Explicit zero is supported. Repeat completions
do not farm elapsed time. TAG distinguishes default variants. Legacy timing keys
are honored so previously completed conversations are not charged twice.

CaseState schema 9 accepts versions 1–8. In particular, the interim version-8
build could save a blank DialogueState while still using legacy NPC dispatch;
earned visits, introductions, Odell's locked answer and inquiry milestones are now
imported idempotently. Reports remain immutable. The active actor, topic index,
choice history, consumed-card count and a content signature are saved. Restore
reconstructs the cursor from authored content, replaying prior branches only in
scratch state without time/effects/extra visits. Changed or malformed conversation
descriptors are discarded with feedback, leaving earned evidence intact. A changed
dialogue file can require starting that conversation again. Tunnel checkpoint
normalization includes the playback descriptor to preserve exact retry snapshots.

## Resident placement and schedules

Additional residents use their morning/noon/evening schedule entries, with dawn
and midday aliases supported. They are unavailable at night. Phase changes and
travel refresh their models and interaction points. Core existing NPC staging
continues to own the original investigation's availability rules.

The mapping lives in `scripts/chapters/dialogue_catalog.gd`. Museum, schoolhouse,
stationer, haberdasher, post office and available residential interiors use those
rooms. The printer and clockmaker stand at their existing exterior-only fronts.
The apothecary and quay bookkeeper use provisional business-street positions; the
registrar uses the precinct records area until a town hall exists. Widow Kessler
uses the shuttered shop frontage; her parlor, the editor's tavern and unbuilt upper
rooms likewise map to provisional fronts rather than invented full interiors.
These are discrete schedule positions, not continuous simulated commutes. New
LOCATION/SCHEDULE names may require another entry in this mapping.

## Reading notes for the author — no prose edits made

The Gazette, post office and schoolhouse give institutional indifference distinct
voices. Mrs. Peake's recollection gives Naomi moral clarity without making her a
present-day expositor. Mr. Vale and Mr. Wick provide complementary explanations
of how ordinary filing decisions bury a record.

Items to review in a later writing pass:

- Both the clockmaker and an upper-quarter resident are named Mr. Vane; their
  scripting identities are distinct. Confirm whether that shared surname is intended.
- The clerk's wage-claim topic and the postmaster's letters discussion let Walter
  know the surviving child's name/age with only lay_lead/naomi gates. Consider where
  Walter learns those details, then gate the statements on that knowledge.
- The county insurance NOTEBOOK line currently reads `,000` where the spoken line
  says eighty-four thousand. Some new files also contain literal replacement
  characters. These remain in the author's files for an explicit wording correction.
- The clockmaker's fused-spring explanation and the historian's displaced-gods
  material are more explicit than the older slice. Check their placement against
  the intended pace of revelation. No hidden sixth-member topic was enabled.
- Some new FORKs remain under repeatable GATE: always topics. Both branches can
  therefore be heard on separate conversations. Add topic_done gates where a
  response is meant to be permanently exclusive, as with Odell.

## Verification

Godot 4.7.2 headless checks passed for the grammar fixtures, actual content,
playback, live UI/save integration, catalog (29 NPCs / 119 topics), opening flow,
town flow, staging, numeric day clock, usability, combat and tunnel retry. The
catalog check tests every added actor's interaction focus at its scheduled
position, all generated evidence IDs, repeat timing, and every defined link.
Physical traversal through the original investigation remains covered by the
existing opening/town/staging suites. A few existing scene tests occasionally
report small ObjectDB cleanup warnings at shutdown; no script/assertion failures
remain in the passing runs.

The Web export succeeds and includes all live `.dialogue` files. Browser startup
was smoke-tested with no JavaScript/console errors; this is not a full browser
playthrough. Exported demos remain excluded. GitHub Pages was not published.
