# Antigravity: 1918 content follow-ups

**Context:** Dejunai and Antigravity have added 1918 influenza texture to Chapter One. The changes are uncommitted in `dialogue/apothecary.dialogue`, `county_clerk.dialogue`, `father_behan.dialogue`, `mrs_almy.dialogue`, `school_parent.dialogue`, `objects/estate.object`, `objects/town.object`, `story.gd` and `town_story.gd`. A review against Design Bible v18 (Part Two, "1918") found the work sound: no character names the illness, and nothing ties it to the cough or the entity. All 38 QA suites pass. The items below are the follow-ups.

**Rules** (see `AGENTS.md`):

- Check `git status` and `git branch` before editing and again before committing.
- Don't edit the Design Bible, the TDD or the novellas in `docs/design/`.
- Don't push, merge, export or publish.
- Items marked **(author call)** need Dejunai's choice. Present options, then wait.

**1918 guardrails, which every change must keep:**

- Never name the illness ("influenza," "flu," "grippe," "Spanish") in any player-facing text.
- Never connect it to the cough, the entity, the tunnel or the Ophion.
- Texture only: no flashbacks, no memorial scenes, no one explaining what 1918 meant.

## Fixes

1. **Fenn's certificate wording.** In `objects/estate.object` (`wounds`, `EXAMINE · DR. FENN`) and the matching line in `story.gd` (`SCENES.wounds`), change "Fenn signed Constance Corwin's **release** eleven months back" to "Fenn signed Constance Corwin's **death certificate** eleven months back." Keep the two files word-for-word identical.

2. **"Fifth form" → American usage.** In `dialogue/school_parent.dialogue` (`parent_repeat_schoolhouse_desks`), change "The fifth form has only eight desks occupied this term" to "The fifth grade has only eight desks filled this term." A town schoolhouse in 1923 Massachusetts wouldn't say "form."

3. **Two characters named Vane (author call).** The clockmaker (`clockmaker.dialogue`, speaker `MR. VANE`, also mentioned in `business_resident_04.dialogue`) and the sail mender Observer (`waterfront_sail_mender.dialogue`, speaker `ENOCH VANE`) share a surname.
   - Ask Dejunai whether they're related.
   - If they're not, propose three period-appropriate replacement surnames for the sail mender. He's a harbor-side laborer; Portuguese/Cape Verdean or old New England names both fit, and Lovecraft proper nouns are not allowed. Apply the chosen one to every speaker label and notebook line in that file.
   - If they are related, leave both, and note it for the TDD maintainer.

4. **Father Behan's east-wall line (author call).** `father_behan.dialogue` `behan_repeat_plain_graves` ends: "Since then, when a man comes to me with six names on a paper, I don't ask what kind of autumn he thinks he's having." That reads as Behan accepting the official six, but elsewhere he pointedly refuses to call the deaths an accident. Offer Dejunai two alternatives, keeping the first two sentences exactly:
   - (a) Cut the final sentence entirely.
   - (b) Replace it with something that keeps his refusal intact, for example: "Since then I've learned what it looks like when a town decides how many graves it's going to count."

   Apply only the chosen version.

5. **Season of the murders (author call; build side only).** The build places the murders in autumn: `groundskeeper.dialogue` says "November," and the new Behan line says "autumn." Novella `10` says "the spring of 1923," and the Bible doesn't say. Don't change any novella or Bible text; the TDD maintainer handles those once Dejunai decides. Your part: list every player-facing line in `dialogue/`, `objects/`, `portals/` and the `*_story.gd` files that states or implies a season or month for the 1923 events, so the decision can be applied consistently. Report the list; don't edit.

## Optional placements (author call; only if Dejunai approves)

These are proposed in TDD v46 Part Four under "1918: optional content":

6. **"Six in one night."** Add to one Pickman Street resident (a `pickman_resident_0N.dialogue` file) as a weighted `TOPIC: default`, visible only in the first day or two after the deaths (for example `day <= 2`, following the corpus's existing day-gate idiom):
   *"Six in one night. Haven't seen the undertaker's wagon that busy since October of '18."*
   The word "six" is deliberate: the townsperson repeats the town's count, not the true eight. Keep it.
7. **The morgue's six tables.**
   - (a) Examine text on the tables, as a new morgue object hotspot: *"Six tables. Four newer than the others, the enamel still bright. The county put them in during the autumn of '18 and never took them out."*
   - (b) One flat, work-detail line for the coroner's assistant in a morgue topic: *"We ran two tables until '18. The county added the rest that October."*
   - (c) Optional, and only on Dejunai's explicit yes: a brass donor plate on the newer tables naming the Ophion Club. Findable only, never remarked on.

## Definition of done

- Run `tests/dialogue_catalog_flow.gd` and `tests/instrument_voice_flow.gd` for any dialogue change, `tests/object_content_flow.gd` for any object change, then the full `python tests/run_all_qa.py` (38 suites as of 2026-09-23).
- Search the whole corpus once more for "influenza|flu|grippe|Spanish" and confirm there are zero player-facing hits.
- Leave a short dated `docs/qa/` pass note listing what changed, which author calls were made, and the item 5 season list. The TDD maintainer will verify it and fold it into the TDD and the Change Log.
