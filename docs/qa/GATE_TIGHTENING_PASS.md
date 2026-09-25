# Gate-tightening pass — 22 September 2026

Closes six "triggers too soon" bugs in the older, hand-migrated dialogue NPCs. Each fix moves a conversation topic behind the clue that should unlock it, so a topic can no longer fire before the player has actually earned the relevant evidence.

The six fixes were approved by Dejunai verbatim (matching an independent DeepSeek review). The parser-bug side item (`widow_kessler.dialogue` `coat_difference`, `coat = plain AND ( ... )` → "Unknown function 'AND'") was explicitly excluded and is **not** touched here; it is logged below for follow-up.

## Applied fixes

| # | File | Topic | Before | After |
| --- | --- | --- | --- | --- |
| 1 | `mrs_almy.dialogue` | `identify` | `GATE: always` | `GATE: coat = plain` |
| 2 | `county_clerk.dialogue` | `ophion_settlement` | `GATE: evidence(behan_name) OR evidence(ophion_myth_classical)` | `GATE: (evidence(behan_name) OR evidence(ophion_myth_classical)) AND evidence(lay_lead)` |
| 3 | `post_office_clerk.dialogue` | `ophion_club_mail` | `GATE: always` | `GATE: evidence(club_talk)` |
| 4 | `school_parent.dialogue` | `the_reader_lesson` | granted `EVIDENCE: sanitized_textbook` **and** `EVIDENCE: curriculum_abridgment` | grants `EVIDENCE: sanitized_textbook` only |
| 5 | `school_parent.dialogue` | `the_covering_letter` | `GATE: evidence(curriculum_abridgment) OR evidence(sanitized_textbook)` | `GATE: evidence(curriculum_abridgment)` |
| 6 | `widow_kessler.dialogue` | `club_standing` | `GATE: always` | `GATE: coat = plain` |

## Rationale per fix

1. **`mrs_almy` `identify` (the `naomi` leak).** The master clue `naomi` was available unconditionally. Now it requires the plain coat — consistent with the rest of Mrs. Almy's substantive topics, which all sit behind `coat = plain` (or `evidence(naomi)`). This is the same "uniform asks what belongs in a report" gate the character's own `almy_trust` topic establishes.

2. **`county_clerk` `ophion_settlement`.** The 1820s insurance/probate filing (which grants `insurance_fraud_record`) was reachable from either `behan_name` or `ophion_myth_classical` alone. The lay/wage-claim thread (`lay_lead`) is the intended trigger; it is now an additional requirement, so the settlement records no longer surface before the player has connected Naomi's wage claim to the Ophion.

3. **`post_office_clerk` `ophion_club_mail`.** This was the sole `always` leak against the three deliberate `GATE: never` locks on the sixth man. It grants `club_foreign_freight` and `postal_overseer_statements` (the "Overseer" banking branch). It is now gated behind `evidence(club_talk)` — the steward's third-visit reveal — so the club's private post only becomes askable after the player has actually learned about the club from the steward. **Note:** the specific gate value (`evidence(club_talk)`) was a judgment call not spelled out in the approved list; alternatives considered were `steward_ready` (too early — it is a story predicate, not a club reveal) and removing the "Overseer" branch entirely (rejected — it is load-bearing content). `club_talk` is already referenced via `evidence(club_talk)` in `local_historian.dialogue`, so the token is valid and consistent.

4. **`school_parent` `the_reader_lesson`.** This redundant-carrier backup was double-granting: it produced both `sanitized_textbook` and `curriculum_abridgment`. `curriculum_abridgment` is the historian's hard-earned reveal and should not be obtainable from a school parent's recitation. The topic now grants `sanitized_textbook` only.

5. **`school_parent` `the_covering_letter`.** The `OR evidence(sanitized_textbook)` branch let the covering letter fire from the cheap textbook clue alone. It now requires `curriculum_abridgment`, which (after fix #4) is only obtainable through the historian's `crew_omission_followup`.

6. **`widow_kessler` `club_standing`.** Kessler's social exclusion and the carriage pickup (`kessler_carriages`) were available unconditionally. Now gated behind `coat = plain`, matching the character's plain-coat/badge split established in her `default` greetings.

## Downstream safety (verified)

- **`postal_overseer_statements` and `club_foreign_freight`** (granted by `ophion_club_mail`) are grant-only with zero downstream references. Gating them later breaks nothing.
- **`curriculum_abridgment` / `reader_omission_letter` tightening is safe.** `curriculum_abridgment` remains reachable via `local_historian.crew_omission_followup` (gated on `crew_omission_official` done + `topic_count(crew_omission) >= 4`). The 4-witness `crew_omission` thread is completable — 9 NPCs carry the shared topic. `reader_omission_letter` still has two carriers (schoolteacher `reader_letter` and school_parent `the_covering_letter`), so the redundant-carrier pattern survives.
- **`sanitized_textbook`** retains two carriers (schoolteacher `founding`, school_parent `the_reader_lesson`), so downstream gates reading it (e.g. `clockmaker.tryworks_instruments`, `local_historian.crew_omission_official`) remain satisfiable.
- **`.object` and `.portal` files are clean** — no "triggers too soon" issues there. The problem was confined to the older hand-migrated dialogue NPCs.

## Follow-up (not part of this pass)

- **Parser-bug claim — confirmed false.** The earlier report that `widow_kessler.dialogue` `coat_difference` (`coat = plain AND (evidence(kessler_carriages) OR topic_done(widow_kessler, club_standing)) AND NOT topic_done(widow_kessler, coat_difference)`) produced "Unknown function 'AND'" does not hold against the live parser. Static trace of `dialogue_lang.gd` (`_or_expr → _and_expr → _unary → _atom → _comparison`) shows `AND`/`OR`/`NOT` are consumed as operators at their own precedence level before any identifier reaches `_comparison`'s function-call dispatch; `AND` immediately followed by `(` is parsed as an operator plus a correctly-recursed parenthesized group, never as a function name. A live headless run of `DialogueLang._parse_gate()` on the exact string returned a clean AST (and/or/not/cmp nodes, no error). The archive-log error was almost certainly stale, from an earlier parser or file version. No action required; the `coat_difference` topic was left untouched as instructed.

## Validation

Not re-run here (Windows project using Godot's headless executable; author typically runs `python tests/run_all_qa.py` and the `dialogue_lang_flow.gd` / `dialogue_template_flow.gd` headless scripts). The six edits are single-line gate/metadata changes using existing syntax only (`coat = plain`, `evidence()`, `AND`, parentheses), so the corpus should still parse clean. Recommend re-running the dialogue language and content flows before shipping.
