# Three Colors of Madness — No Exit Wound

Native third-person 3D opening prototype aligned with Design Bible v13 and TDD v2. This is a playable blockout, with primitive art and provisional writing. Roughly ten minutes is an exploratory pacing target, not a measured playtime or a forced timer.

## Play

Double-click `Launch.cmd`, or open `project.godot` in Godot and press F5. The launcher uses the installed engine at `C:\Portables\Godot4\Godot_v4.7.2-stable_mono_win64.exe`. No downloads, additional libraries, or network connection are needed.

## Controls

- WASD / arrows: move; mouse: look; Q/R: orbit camera.
- Mouse wheel: camera distance; Shift: brisk walking.
- E / F: examine or speak.
- Tab / I: personal effects; J: case file; Escape: pause.
- F11: fullscreen. Menus support mouse or Tab, Shift+Tab, Enter/Space.

## Opening route

Read the civic-history intertitles. Speak to the gatehouse boy, follow the drive, and explore the rose garden, terrace, and birch grove. Consult Captain Odell beyond the fountain. Prepare a report at the field desk beside him. Return to the estate gates to continue to Pickman Street. Submit the report at the precinct, ask Mrs. Almy about the unidentified woman at the boardinghouse, and return to your room. Set the notebook on the desk to finish the current playable inquiry.

Optional observations: wounds, grove, knife, watch, intact windows, seating list, belongings, the assistant's testimony, and the grounds crew's fixed distance from the kitchen wing's service door. The gardener supplies an additional statement when Walter wears his plain wool coat (change it in personal effects). The club's barman, near the portico, opens into a revisitable menu of three further observations asked one at a time, each unlocking the next.

A minimal run can go directly to Odell and the report. His statement supplies the count without claiming examinations Walter skipped. Odell's dismissal ("Six members, Corwin... The other two are a filing matter") opens a genuine choice — answer him to his face, or say nothing and let the notebook carry it — recorded as a distinct statement either way; neither option is scored or gates anything downstream. Opening the case file is optional; it never gates progression. The report snapshots the evidence present when prepared. Later observations remain in Walter's notebook until he revises the report at the desk.

The town includes optional witness questions, a meal ledger, a newspaper, a personal notice, an automatic case board, and Father Behan on the street behind the rectory marker, whose own revisitable menu turns up why the Ophion Club is named for a lost ship and the money it left behind. The board never gates progression. Reports become immutable when received at the precinct; later findings can be filed as dated supplements, with optional county dispatch. Witness claims remain distinguished from corroborated findings.

## Saves and accessibility

The launcher stores Godot's user data in `.runtime-data` inside the project. Saves occur after interactions, every 20 seconds of exploration, on pause and on exit. Continue restores position, camera, evidence, statements, clothing, report copies, flask supply, and presentation relief. QA uses a separate save. Earlier opening saves migrate automatically; completed opening saves continue into town. Continue also looks for the newest save from a previous editor launch.

Accessibility is available before play: static grain by default, distortion intensity, grain, contrast, text size up to 130%, mouse sensitivity/inversion, and optional interaction markers. Text stays above all film effects; long menus scroll. The service passage includes a provisional synthetic cough with a matching readable caption. Full audio design remains unfinished.

## Scope

This build includes perspective movement/camera collision, twelve optional observations (three of them behind a revisitable witness menu), a branching response to Odell, a sparse paperdoll and inventory, displayed Strength/Perception, clothing, a finite flask affecting presentation only, report choices, a persistent opening record, and a scoped Observer color tell in the active shader.

It does not include combat, forced spill, glass-shattering break, fatal comprehension, later chapters, gamepad support, full key rebinding, or a full encumbrance/level-up system. Later consumption of the record by Ekon is future work. The v10 difficulty screen is deferred. The respectful all-eight wording is provisional and needs review against Walter's intended initial bias. Neither report choice is scored as morality.

## Existing prototype

The earlier 2.5D scenes, scripts, shaders, and tests remain available through `Launch legacy.cmd`; see `README_legacy.md`. The project now starts `main.tscn`. `GameState` and `LegacyInputs` autoloads retain compatibility with the old scene.

## Verification and source

`Test town.cmd` checks travel through all three interiors, minimal progression without the board, optional inquiry, immutable report and supplement history, migration, and cross-location saves. `Test opening.cmd` checks the minimal route, Odell's response branch, optional observations including the barman's revisitable menu, clothing testimony, report snapshots, save/load, completion, actual WASD traversal, departure focus, and hedge collision. The existing `tests/smoke_test.gd` also remains runnable.

Live renderer captures use `-- --capture=world`, `title`, `case`, `dialogue`, `settings`, `effects`, `large_text`, or `gate`. These developer arguments are not shown in-game. Reviewed captures are in `docs/qa/`.

- `main.gd`: shared player movement and camera rig.
- `scripts/chapters/chapter_one.gd`: Chapter One progression and interaction orchestration.
- `scripts/chapters/chapter_one_archive.gd`: chapter-specific record and inventory panels.
- `scripts/shared/`: reusable interface, dialogue sequence, save store, accessibility settings, and film presentation.
- `tests/`: extracted traversal and integration checks.
- `tunnel.gd` / `tunnel_story.gd`: service passage encounter and provisional text.
- `estate.gd`: deterministic environment, figures, collision, interaction points.
- `case_state.gd`: canonical record and serialization.
- `story.gd`: provisional dialogue and factual evidence.
- `film.gdshader`: monochrome, iris, grain, subtle drift, and a narrow-hue exception that lets Observer-flagged materials keep color.
- `docs/PLAYTEST.md`: first-playtest questions.

## Service passage interaction loop

After finishing the town inquiry, choose **Continue to the service passage**. Existing completed town saves can enter it too. Read the plan, observe the cough/head-turn cycle, reach the lower measurement, and return to the entrance. The long outer route works with an empty flask and without consulting the board. Higher Perception reveals wear marks on a shorter recess route; its physical space exists for every player.

The flask reduces presentation strain; it does not change the encounter's rules. Death offers an entrance checkpoint retry restoring the full record, resources, relief, camera, and encounter state. Continuing a dead save preserves the death screen. Menus pause the encounter.

Returning to the precinct exposes a consequence of the records actually sent to the county. A copy containing both wound and intact-window observations opens a further foundation-record request. The precinct survey drawer lets Walter follow that reference directly, or independently search the property index after measuring the passage. Transcribing the comparison adds a sourced notebook entry; filing it remains optional. Report and supplement snapshots retain statements and evidence-source labels at filing time.

`Test interaction loop.cmd` verifies both routes, empty-flask completion, county consequences, historical snapshots, death/continue/retry, exact saves, paused reading, settings migration, and presentation relief with distortion disabled. `Test opening.cmd` and `Test town.cmd` remain regression checks. Renderer capture names also include `tunnel_access`, `tunnel_death`, and `tunnel_record`.

See `docs/ARCHITECTURE.md` for reuse boundaries and provisional encounter rules. This is a bounded interaction test, not the chapter's fatal ending.
