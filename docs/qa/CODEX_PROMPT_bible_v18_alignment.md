# Codex handoff: Bible v18 alignment and pre-playtest cleanup

**Written:** 2026-09-23, by the Cowork Claude session that maintains the TDD. **Authority:** `docs/design/0) Three Colors of Madness — Design Bible v18.md` and `docs/design/07) Three Colors of Madness — TDD v46.md`. Read TDD v46 Parts Four and Six first. This note only sequences that work; it doesn't restate it.

**Rules for this work** (see `AGENTS.md`):

- Check `git status` and `git branch` before editing and again before committing.
- Don't push, merge, export or publish without an explicit request from Dejunai.
- Don't edit the Bible or the TDD. Record any disagreement in `docs/DOC_SYNC_INCONSISTENCIES.md`.
- Items marked **(author call)** need Dejunai's wording or decision before content changes. Prepare options; don't pick.

## Do in this order

1. **Publish path (TDD v46 Part Two / Part Eight item 1).** Propose, but don't execute, a way to deploy `build/web/` again. Options: a `workflow_dispatch` or `actions/upload-pages-artifact` step in `.github/workflows/deploy-pages.yml`. Write the proposal as a diff for Dejunai to approve.
2. **Backup-route reachability test (Part Six).** Add a test that asserts each of the twelve backup `EVIDENCE:` topics listed in TDD v45/v46 (for example `tailor` `pruitt_family_naming`) is reachable on at least one route in the live corpus. Wire it into `tests/run_all_qa.py`.
3. **Ophion meaning out of Chapter One (Part Four item 1).**
   - Remove or rewrite the "Ask about the annotations" branch of `local_historian.dialogue` `dr_fenn_library`: Fenn underlining gods "not slain, only 'displaced'," and `EVIDENCE: displaced_god_doctrine`. Nothing gates on `displaced_god_doctrine` (checked 2026-09-23).
   - Replacement wording is an **(author call)**. The limit: Fenn may be shown researching and annotating obsessively, but the content of the myth must not reach Walter.
4. **Flask timing (Part Four item 2).**
   - Move the flask loss from the spur (descent) to the stair fall (retreat), so the flask, badge and whistle are lost together.
   - Update `tunnel_story.gd`'s stair text, the case-file record line in `chapter_one.gd`, and `tests/break_flow.gd`'s assertion.
   - Check that the paper doll behaves correctly on a plain-coat descent. Per the Bible, the badge is carried pocketed under the plain coat.
5. **Named Observers (Part Four item 3).**
   - Add canonical names in data for `crew` (groundskeeper), `gardener` and `harbor_observer`.
   - Chapter One's ring-wearing estate-crew member is **Abel Tavares**. Which existing NPC he is, and whether speaker labels show names, is an **(author call)**.
   - Also list any ambient NPC assigned a `cast_observer_*` archetype.
6. **Old woman gating (Part Four item 4).** Currently she appears as soon as `evidence(naomi)` is held. Propose two or three later gate options, each with its downstream effect on `EVIDENCE: old_woman`. **(author call)**
7. **Sixth-man audit (Part Four item 5).** Report every topic touching the sixth man, starting with `tailor` `the_sixth_jacket` ("already provided… since his grandfather's winter"). Flag anything that reads as a clue toward an answer rather than an unanswered question. **(author call)**
8. **Offshore scenery (Part Four item 7).** Capture a screenshot of the unreachable offshore station from the waterfront. The Bible has the station buried whole, so check that it reads as ruins on the drowned island.
9. **Housekeeping (Part Six).**
   - Regenerate `narrative_threads.txt` from live source as part of the QA run, or propose deleting it.
   - Find out what an omitted portal `TIME:` actually charges via `_travel()`'s automatic path, then correct `portal_lang.gd`'s header comment and `docs/PORTAL_AUTHORING.md` to match.

10. **Stale height comments.** Character scale is settled (TDD v46, Character and Environment Models). The header comments in `walter_model.gd`, `captain_odell_model.gd`, `cast_model.gd`, `coroner_model.gd`, `steward_model.gd`, `father_behan_model.gd` and `gatekeeper_boy_model.gd` still quote absolute heights from earlier scale passes ("~2.21m", "~2.34m" and so on). Rewrite them to describe relative stature and the reference each model was tuned against. Comments only: don't change any `SCALE_FACTOR` or `scale` values.

## Definition of done

Run each change's focused test, then the full aggregate (36 suites as of 2026-09-23). Visually check any presentation change. Leave a short dated `docs/qa/` pass note for each item landed. The TDD maintainer will verify it and fold it into the TDD and HCL.
