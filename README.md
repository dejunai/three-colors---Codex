# Three Colors of Madness — No Exit Wound

Native third-person 3D opening prototype using Design Bible v10. This is a playable blockout, with primitive art and provisional writing. Roughly ten minutes is an exploratory pacing target, not a measured playtime or a forced timer.

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

Optional observations: wounds, grove, knife, watch, intact windows, seating list, belongings, and the assistant's testimony. The gardener supplies an additional statement when Walter wears his plain wool coat (change it in personal effects).

A minimal run can go directly to Odell and the report. His statement supplies the count without claiming examinations Walter skipped. Opening the case file is optional; it never gates progression. The report snapshots the evidence present when prepared. Later observations remain in Walter's notebook until he revises the report at the desk.

The town includes optional witness questions, a meal ledger, a newspaper, a personal notice, and an automatic case board. The board never gates progression. Reports become immutable when received at the precinct; later findings can be filed as dated supplements, with optional county dispatch. Witness claims remain distinguished from corroborated findings.

## Saves and accessibility

The launcher stores Godot's user data in `.runtime-data` inside the project. Saves occur after interactions, every 20 seconds of exploration, on pause and on exit. Continue restores position, camera, evidence, statements, clothing, report copies, flask supply, and presentation relief. QA uses a separate save. Earlier opening saves migrate automatically; completed opening saves continue into town. Continue also looks for the newest save from a previous editor launch.

Accessibility is available before play: static grain by default, distortion intensity, grain, contrast, text size up to 130%, mouse sensitivity/inversion, and optional interaction markers. Text stays above all film effects; long menus scroll. This opening is intentionally silent. The cough motif and full audio design are not implemented.

## Scope

This build includes perspective movement/camera collision, eight optional observations, conversations, a sparse paperdoll and inventory, displayed Strength/Perception, clothing, a finite flask affecting presentation only, report choices, and a persistent opening record.

It does not include the tunnel, combat, forced spill, glass-shattering break, fatal comprehension, later chapters, gamepad support, full key rebinding, or a full encumbrance/level-up system. Later consumption of the record by Ekon is future work. The v10 difficulty screen is deferred. The respectful all-eight wording is provisional and needs review against Walter's intended initial bias. Neither report choice is scored as morality.

## Existing prototype

The earlier 2.5D scenes, scripts, shaders, and tests remain available through `Launch legacy.cmd`; see `README_legacy.md`. The project now starts `main.tscn`. `GameState` and `LegacyInputs` autoloads retain compatibility with the old scene.

## Verification and source

`Test town.cmd` checks travel through all three interiors, minimal progression without the board, optional inquiry, immutable report and supplement history, migration, and cross-location saves. `Test opening.cmd` checks the minimal route, optional observations, clothing testimony, report snapshots, save/load, completion, actual WASD traversal, departure focus, and hedge collision. The existing `tests/smoke_test.gd` also remains runnable.

Live renderer captures use `-- --capture=world`, `title`, `case`, `dialogue`, `settings`, `effects`, `large_text`, or `gate`. These developer arguments are not shown in-game. Reviewed captures are in `docs/qa/`.

- `main.gd`: movement, camera, UI, dialogue, saves, integration test harness.
- `estate.gd`: deterministic environment, figures, collision, interaction points.
- `case_state.gd`: canonical record and serialization.
- `story.gd`: provisional dialogue and factual evidence.
- `film.gdshader`: monochrome, iris, grain and subtle drift.
- `docs/PLAYTEST.md`: first-playtest questions.
