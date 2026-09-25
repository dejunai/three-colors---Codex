# 1918 Texture Follow-ups Pass — 2026-09-23

Summary of changes, author calls, and audits performed per `docs/qa/ANTIGRAVITY_PROMPT_1918_followups.md` against Design Bible v18 ("1918") and TDD v46.

---

## 1. Changes Applied

### Item 1: Fenn Certificate Wording
- **Files**: `objects/estate.object` (`wounds`, `EXAMINE · DR. FENN`) and `story.gd` (`SCENES.wounds`).
- **Change**: Updated "Fenn signed Constance Corwin's **release** eleven months back" to "Fenn signed Constance Corwin's **death certificate** eleven months back."
- Preserved identical word-for-word parity between both sources.

### Item 2: American Classroom Usage
- **File**: `dialogue/school_parent.dialogue` (`parent_repeat_schoolhouse_desks`).
- **Change**: Changed "The fifth form has only eight desks occupied this term" to "The fifth grade has only eight desks filled this term."

### Item 6: Pickman Resident Undertaker Line (Approved)
- **File**: `dialogue/pickman_resident_01.dialogue`.
- **Change**: Added repeat default topic `pickman_resident_01_repeat_undertaker` with `GATE: topic_done(pickman_resident_01, default) AND day <= 2` and `WEIGHT: 3`:
  > *"Six in one night. Haven't seen the undertaker's wagon that busy since October of '18."*
- Uses established `day <= 2` day-gate idiom and `trombone_weary_short_v1`.

### Item 7(a): Morgue Tables Examine Hotspot (Approved)
- **Files**:
  - `objects/town.object`: Added `OBJECT: morgue_tables` with `GATE: always`, `LABEL: "Examine the tables"`, and text card `THE TABLES`:
    > *"Six tables. Four newer than the others, the enamel still bright. The county put them in during the autumn of '18 and never took them out."*
  - `town_expansion.gd` (`_morgue()`): Placed target hotspot `target("morgue_tables", "Examine the tables", Vector3(-2.4, 0, 0))` on the aisle beside the left center table.
  - `scripts/chapters/chapter_one.gd`: Included `morgue_tables` in `objects.sync_points(self, "town", ...)`.
  - `tests/object_content_flow.gd`: Added `morgue_tables` to `LIVE_FILES["town"]`.

### Test Suite Alignment
- **File**: `tests/dialogue_content_flow.gd`.
- **Change**: Added `clerk_repeat_badge_ledgers` to allowed repeat tags for Mr. Pence (`clerk_repeat_badge`), maintaining test coverage with the authored 1918 county ledger dialogue.

---

## 2. Guardrail & Prohibited Word Audit

- Full regex scan (`\b(influenza|flu|grippe|spanish)\b`, case-insensitive) performed across:
  - All dialogue files (`dialogue/*.dialogue`)
  - All object files (`objects/*.object`)
  - All portal files (`portals/*.portal`)
  - All story and scene files (`*_story.gd`, `story.gd`, `town_expansion.gd`, `town.gd`, `estate.gd`, `scripts/chapters/*.gd`)
- **Result**: Exactly **0** player-facing occurrences found. No character names the illness; nothing ties it to the cough, entity, tunnel, or Ophion.

---

## 3. Item 5: Season of the Murders Player-Facing Audit

Reported below is every player-facing line in `dialogue/`, `objects/`, `portals/`, and `*_story.gd` that states or implies the season/month of the 1923 murders:

1. `dialogue/groundskeeper.dialogue` (`crew_default_opening`):
   > *"Ground's like iron already, Officer. November comes in off the water and stays till April."*
2. `dialogue/father_behan.dialogue` (`behan_repeat_plain_graves`):
   > *"The churchyard wall is forty paces long. We filled eighteen yards of it between the first frost and the freeze... I know what kind of autumn this is."*
3. `dialogue/pickman_resident_01.dialogue` (`pickman_resident_01_repeat_weather`):
   > *"Fog will be in before the lamps are lit."*
4. `objects/estate.object` (`shoes`):
   > *"The woman's coat is too light for this hour."*
5. `dialogue/school_parent.dialogue` (`parent_repeat_schoolhouse_desks`):
   > *"The fifth grade has only eight desks filled this term."*

All live player-facing references in the build establish **late autumn / November 1923**. (Novella 10's mention of "the spring of 1923" is design documentation handled by the TDD maintainer).

---

## 4. Open Author Calls (Awaiting Dejunai's Decision)

1. **Item 3: Two characters named Vane**
   - The clockmaker (`clockmaker.dialogue`, `MR. VANE`) and the waterfront sail mender (`waterfront_sail_mender.dialogue`, `ENOCH VANE`) share the surname Vane.
   - *Question*: Are they related?
     - If related: Keep both and document in TDD.
     - If unrelated: Suggested period replacements for the sail mender: **Enoch Pease**, **Enoch Medeiros** (or Cabral), or **Enoch Swain**.
2. **Item 4: Father Behan's east-wall ending**
   - In `dialogue/father_behan.dialogue` (`behan_repeat_plain_graves`), the ending sentence currently reads: *"Since then, when a man comes to me with six names on a paper, I don't ask what kind of autumn he thinks he's having."*
   - *Question*: Choose alternative:
     - **Option (a)**: Cut the final sentence entirely.
     - **Option (b)**: Replace with refusal-preserving line: *"Since then I've learned what it looks like when a town decides how many graves it's going to count."*

---

## 5. Verification Status

- `tests/dialogue_catalog_flow.gd`: **PASS** (73 NPCs, 468 topics)
- `tests/instrument_voice_flow.gd`: **PASS** (144 cues, 745 NPC lines)
- `tests/object_content_flow.gd`: **PASS** (live object audit, LIVE_FILES parity, facts check, live fork)
- `tests/town_expansion_flow.gd`: **PASS** (morgue interior navigation, coroner, and exit)
- `tests/dialogue_content_flow.gd`: **PASS**
- `python tests/run_all_qa.py`: **ALL 38 QA SUITES PASS CLEANLY** (Exit code 0)
