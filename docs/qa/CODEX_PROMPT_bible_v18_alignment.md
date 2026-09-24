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

## Round 2 (after commit `120a488`)

Items 2–10 above landed in `120a488` and were verified against source, with all 38 suites passing. Item 1 (publish path) is still open. What's left is listed in TDD v46 Part Four under "Still open" and in Part Six. In order:

1. **Harbor-mason Law 5 lines.** In `harbor_observer`, `drowned_island` states the Observers' origin outright, and `the_ring` explains the color tell. Propose refusal/glimpse rewrites for both. **(author call)**
2. **Out-of-date scenery line.** Walter's "The try-works buildings are still standing above the mud" in `drowned_island` needs to fit the buried-station scenery.
3. **Abel's tell.** The build has a copper wrist band; the Bible and novellas have a ring. **(author call)**
4. **Coat-aware retreat card.** `tunnel_story.gd` `RETREAT` says "tears loose from its pin" even when the badge was pocketed.
5. **Small text fixes:**
   - `story.gd` `testimony` calls the coroner's assistant "He."
   - The `harbor_observer` notebook lines still say "Mason."
   - `morgue_coroner.dialogue` voices a stage direction as speech, with a violin cue.
6. **Orphaned `coroner_model.gd`.** Remove it, or give it to the morgue coroner. Confirm whether the morgue coroner has a rendered figure.

## Round 3 (after the 2026-09-24 VS Code doc-sync pass)

Round 2 item 6 (orphaned `coroner_model.gd`) is resolved: it now renders the morgue coroner. Round 2 items 1–5 are still open. New:

1. **Remove the second morgue coroner.** `town_expansion.gd::_morgue()` still calls `person(Vector3(0,0,-5.5),"a1ae98",false)` and `target("morgue_coroner","Speak with the coroner",Vector3(0,0,-4.5))`. The rendered coroner now comes from `dialogue_catalog.gd` `FIXED_STAFF` at `(-1.6,0,-1.0)`. Remove the primitive and the stale target, as `town.gd` did for the intake clerk. Afterwards, re-run `tests/dialogue_catalog_flow.gd`, `tests/test_placement_audit.gd` and `tests/staff_model_integration_flow.gd`.
2. **Portal `examine_count`.** Add `examine_count` to `portal_runtime.gd::make_context()` so all three runtimes expose the same functions, and add one assertion to `tests/portal_lang_flow.gd`.
3. **Abel's tell (author call).** There are three versions: a ring (Bible and novellas), a copper wrist band (dialogue), and a chest-height red accent (model). Wait for Dejunai's choice, then align the dialogue line and the model accent to it.

## Definition of done

Run each change's focused test, then the full aggregate (39 suites as of 2026-09-24). Visually check any presentation change. Leave a short dated `docs/qa/` pass note for each item landed. The TDD maintainer will verify it and fold it into the TDD and HCL.
