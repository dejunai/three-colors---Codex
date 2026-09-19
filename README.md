# Three Colors of Madness — No Exit Wound

Native third-person 3D opening prototype aligned with the Design Bible and current TDD. This is a playable blockout, with primitive art and provisional writing. Roughly ten minutes is an exploratory pacing target, not a measured playtime or a forced timer.

## Current staging pass

The steward is inside the smoking lounge, reached through the estate's service entrance after speaking to Mrs. Almy. Speak to him once, return home and sleep for the provisional second-day montage, then return on day three in the plain wool coat. Sleep is temporarily blocked until the first conversation (and the existing intake/identification beats) are complete. Repeated entries do not advance a visit. The groundskeeper appears when leaving the lounge. On estate returns, the bodies, Odell and the coroner's assistant are gone and the gardener is beside the approach drive, below the garden hedge; his plain-coat testimony remains optional.

“Read the notebook” in personal effects or the case file opens the new read-only reference. Linking remains at the physical board. The desk's end-of-day action now follows the same staging milestones as the bed. The existing service-passage continuation follows the third encounter and return home.

See `docs/qa/STAGING_PASS.md` for the precise flow, historical save migration, test results, and pacing estimates. `Test staging.cmd` verifies the new progression. The minimal opener estimates 3.1–3.6 minutes; all opening observations estimate 6.6–7.8 minutes.

## Town expansion pass

Pickman Street's opposite frontage leads to three neighborhoods — a business district, an upper residential quarter, and a lower residential quarter — plus the post office, for eighteen buildings and twelve accessible interiors in total. Precinct intake also leads to a morgue with a coroner. Only the stationer, Residence No. 1, and Dwelling No. 1 hold a placeholder resident with a single dismissive line; the rest are empty interiors or exterior-only fronts. Departing the estate for town clears the rose garden's six bodies; returning from town on Day 3 after two completed estate visits silently clears the birches too, with no accompanying scene. See `docs/qa/TOWN_EXPANSION_PASS.md` for the geography table and verification. There is no dedicated launcher script yet; run the check directly with the engine's `--headless --path . --fixed-fps 60 --script res://tests/town_expansion_flow.gd` arguments.

## Contiguous town exterior

The neighborhoods above, the lower district, and the waterfront are no longer separate loading-boundary hubs: `scripts/chapters/contiguous_town_phase_one.gd` and `contiguous_town_phase_two.gd` grow one continuous, physically walkable exterior outward from Pickman Street (a stone incline up to the business district and upper quarter, then a descending lane east to the lower district and on to the waterfront), so the whole loop can be walked without a single travel transition. Interiors remain separate scenes, and every authored location, route, and NPC id stays stable; old saves still load directly into the legacy hub layout. See `docs/qa/CONTIGUOUS_TOWN_PHASE_ONE.md` and `docs/qa/CONTIGUOUS_TOWN_PHASE_TWO.md` for the step-by-step builds and `docs/qa/PHASE_ONE_WEB_PROFILE_HANDOFF.md` for the profiling methodology and decision rule (no streaming/HLOD without a measured, player-visible stall). `tests/contiguous_town_profile.gd` reports the current desktop construction-time/memory baseline.

## Waterfront district

A quay with a seawall, mooring apron, small fishing boats, and four exterior-only fronts (chandlery, freight office, net loft, fish stores); the abandoned whaling station is visible offshore scenery with no route or clue attached. Reached via the continuous descending lane from the lower district (see Contiguous town exterior above); old saves can still load directly into its legacy hub entry. Scheduled residents include the harbor mason, salt mender, quay bookkeeper, and net seller. Crossing into it costs the same 30 minutes as any district travel. See `docs/qa/WATERFRONT_PASS.md`.

## Live dialogue and town residents

Chapter One's dialogue runs on an authored, data-driven system instead of hand-coded per-NPC menus. `scripts/chapters/chapter_one_dialogue.gd` reads all 72 `.dialogue` files under `dialogue/` (71 concrete NPC files plus a background template; parser-authoritative totals can change as content is authored) — 465 `TOPIC:` headers in the current source tree — resolving each NPC's current line or menu from location, time of day, and prior conversations, with real FORK choice buttons and mid-conversation save/resume. Multiple `default` greetings can form a `WEIGHT`-based pool for exhausted/ambient variety (immediate-repeat memory is cosmetic only), and a `FORK` branch can commit an immutable `OUTCOME: decision_id = value_id`, readable later via `outcome()`/`outcome_is()`. Interacting with an NPC who has no eligible default topic and no available menu choices fails loudly: rather than silently closing and leaving the character standing unresponsive ("turning into an unresponsive totem pole"), the runtime emits an engine error and presents an on-screen developer warning card naming the NPC. `scripts/chapters/dialogue_catalog.gd` places four dozen-plus scheduled residents (shopkeepers, clerks, the historian, the clockmaker, Widow Kessler, waterfront tradespeople, a drayman, a fish smoker, a lamplighter, and other named townsfolk) into their morning/midday/evening/night positions across the estate, precinct, the expanded town neighborhoods, and the waterfront district. A night-only speakeasy adds two night-owl patrons and a bartender, evening/night hours only. Every authored NPC line carries or is auto-assigned an instrumental `VOICE:` delivery cue (never a truth signal) from `assets/audio/instrument_voices/`, adjustable under **Instrument voices** in Accessibility & controls. See `docs/qa/DIALOGUE_LIVE_PASS.md` for the full integration record, `docs/qa/DIALOGUE_LANG_PASS.md` for the underlying grammar, `docs/DIALOGUE_AUTHORING.md` for the current authoring reference, `docs/qa/ESTATE_INSTRUMENT_VOICES.md` and `docs/qa/CARD_AND_VOICE_ROUTING.md` for the instrument-voice system, `docs/qa/WATERFRONT_PASS.md` for the waterfront district, and `docs/qa/DAY_ONE_PACING_REVIEW.md` for a strategic, code-free review of opening-flow rough edges.

## World objects: examine points and carryable items

A sibling, flat-file authoring system covers static world hotspots — things Walter examines rather than someone he talks to — instead of hardcoded per-scene dispatch. `objects/*.object` files (currently `estate.object`, `town.object`, and `tunnel.object`: all seven estate examine points, the three town-side ones, and the tunnel's foundation measurement) are parsed by `scripts/shared/object_lang.gd`/`object_runtime.gd` and rendered live through `scripts/chapters/chapter_one_objects.gd`, sharing the dialogue system's GATE grammar, evidence/outcome state, and adding inventory support (`TAKE:`). A hotspot whose visibility and interaction state disagree fails loudly with an on-screen error naming the location and id, rather than doing nothing. See `docs/OBJECT_AUTHORING.md` for the authoring reference and `docs/OBJECT_MIGRATION_HOWTO.md` for the migrated inventory, what's deliberately left alone, and the recipe used to convert a hardcoded hotspot. `tests/object_lang_flow.gd`/`object_template_flow.gd` are standalone grammar/cookbook proofs; `tests/object_content_flow.gd` audits the real shipped files and a live FORK through the adapter.

## Travel points and portals

A third sibling flat-file system covers travel points — hotspots that send Walter somewhere else, like the estate's service entrance — rather than an examine point's static content. `portals/*.portal` files (currently `estate.portal`, `lounge.portal`, `lower.portal`, `town.portal`, and `tunnel.portal`, covering the migrated estate, lounge, lower-district, town-street, and tunnel travel points) are parsed by `scripts/shared/portal_lang.gd`/`portal_runtime.gd` and rendered live through `scripts/chapters/chapter_one_portals.gd`, sharing the same GATE grammar and evidence/outcome state as dialogue and objects. Its one new step, `GO: destination | x,y,z | yaw | flags`, is a circuit breaker like `FORK`: reaching it hands control to the adapter, which is the only thing that actually moves the player, and any content authored after it plays as arrival narration once the adapter resumes. An omitted `TIME:` preserves the travel system's automatic charge; an authored `TIME:` overrides it and is charged once per portal identity the first time it completes. A hotspot whose visibility and interaction state disagree fails loudly, the same as objects. See `docs/PORTAL_AUTHORING.md` for the authoring reference. `tests/portal_lang_flow.gd`/`portal_template_flow.gd` are standalone grammar/cookbook proofs; `tests/portal_content_flow.gd` audits the real shipped files by driving every migrated route through the actual `chapter_one.gd` adapter, including `route_speakeasy` from the real contiguous-town world.

## Title screen and prologue

Launching the game opens a photographic title screen (bundled serif fonts, a gradient scrim over a desaturated period photo, and a looping civic-reel music cue) instead of the plain menu; starting a new game plays a three-slide photographic prologue before Walter reaches the estate gates. `scripts/shared/prologue_presentation.gd` owns this presentation layer independently of the ordinary dark modal UI in `chapter_interface.gd`. See `docs/qa/PROLOGUE_INPUT_FIX.md` and `docs/qa/TITLE_SETTINGS_FIX.md` for fixes applied after the initial pass.

## Anonymous playthrough telemetry

The game can log a small, fixed set of pacing/progression events (session start, district transitions, phase changes, objectives, ending reached, and an optional post-game debrief tap) tagged only with a random per-playthrough UUID — no name, account, device fingerprint, or IP address is recorded. Events buffer in memory and upload to the single endpoint named in the `three_colors/telemetry_endpoint` project setting; a blank endpoint disables logging entirely and gameplay never stalls waiting on a request. The current build points at a Cloudflare Worker/R2 receiver with no public read route. See `docs/LOG_PLAYER_ASK.md` for the full event schema and privacy constraints, and `docs/qa/PLAYER_LOG_ENDPOINT_HANDOFF.md` for the deployed endpoint and verification record.

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

Optional observations: wounds, grove, knife, watch, intact windows, seating list, belongings, the assistant's testimony, and the grounds crew's fixed distance from the kitchen wing's service door. After the opening, the gardener supplies an optional additional statement beside the drive below the garden hedge when Walter wears his plain wool coat (change it in personal effects). The club's steward, inside the smoking lounge, opens his three-topic revisitable menu on the third visit under the conditions above.

A minimal run can go directly to Odell and the report. His statement supplies the count without claiming examinations Walter skipped. Odell's dismissal ("Six members, Corwin... The other two are a filing matter") opens a genuine choice — answer him to his face, or say nothing and let the notebook carry it — recorded as a distinct statement either way; neither option is scored or gates anything downstream. Opening the case file is optional; it never gates progression. The report snapshots the evidence present when prepared. Later observations remain in Walter's notebook until he revises the report at the desk.

The town includes optional witness questions, a meal ledger, a newspaper, a personal notice, an automatic case board, Father Behan on the street behind the rectory marker, whose own revisitable menu turns up why the Ophion Club is named for a lost ship and the money it left behind, and an unnamed woman outside Kessler's shuttered shop, who warns Walter once and does not stay to explain herself. The board never gates progression. Reports become immutable when received at the precinct; later findings can be filed as dated supplements, with optional county dispatch. Witness claims remain distinguished from corroborated findings.

## Saves and accessibility

The launcher stores Godot's user data in `.runtime-data` inside the project. Saves occur after interactions, every 20 seconds of exploration, on pause and on exit. Continue restores position, camera, evidence, statements, links, clothing, report copies, flask supply, ammunition, the day clock, dialogue progress, and presentation relief. QA uses a separate save. Earlier opening saves migrate automatically; completed opening saves continue into town. Continue also looks for the newest save from a previous editor launch.

Accessibility is available before play: static grain by default, distortion intensity, grain, contrast, text size up to 130%, mouse sensitivity/inversion, optional interaction markers, and an independent Instrument voices volume for NPC delivery cues (zero fully mutes them without muting other audio). Text stays above all film effects; long menus scroll. The service passage includes a provisional synthetic cough with a matching readable caption. Full audio design remains unfinished.

## Scope

This build includes perspective movement/camera collision, twelve optional observations (three of them behind a revisitable witness menu), a branching response to Odell, a sparse paperdoll and inventory, displayed Strength/Perception, clothing, a finite flask affecting presentation only, report choices, a persistent opening record, a scoped Observer color tell in the active shader, a player-drawn corkboard link mechanic (now a colored warm-paper/cork/brass-pin presentation, see `docs/qa/COLORED_CASE_PRESENTATION.md`) that accelerates Perception, and a real day/night clock driving lighting.

The service passage adds a forced flask spill, a six-round revolver, and knife melee: drowned sailors can be finished off permanently once staggered, while fully transformed cultists can only be staggered and evaded, never killed. It does not include glass-shattering break, fatal comprehension, later chapters, gamepad support, full key rebinding, or a full encumbrance/level-up system. Later consumption of the record by Ekon is future work. The v10 difficulty screen is deferred. The respectful all-eight wording is provisional and needs review against Walter's intended initial bias. Neither report choice is scored as morality.

## Existing prototype

The earlier 2.5D scenes, scripts, shaders, and tests remain available through `Launch legacy.cmd`; see `README_legacy.md`. The project now starts `main.tscn`. `GameState` and `LegacyInputs` autoloads retain compatibility with the old scene.

## Web build on GitHub Pages

The exported Web build already lives in `build/web/`. GitHub Pages can publish that static folder over HTTPS once **Settings → Pages** is set to **Source: GitHub Actions**. The workflow in `.github/workflows/deploy-pages.yml` uploads `build/web/` and deploys it whenever the Web export changes on `main`.

Suggested publish URL: `https://dejunai.github.io/three-colors---Codex/`

Update flow:

1. Re-export the Godot Web build so `build/web/` contains the latest `index.html`, `.js`, `.wasm`, and `.pck` files.
2. Commit and push the updated `build/web/` files.
3. Wait for the **Deploy GitHub Pages** workflow to finish.
4. Open the GitHub Pages URL instead of `http://localhost:8060`.

The existing `Build and serve web.cmd` script still runs the local HTTP server on port 8060 for local checks; GitHub Pages is the HTTPS publishing path.

## Verification and source

`Test town.cmd` checks travel through all three interiors, minimal progression without the board, optional inquiry, immutable report and supplement history, migration, and cross-location saves. `Test opening.cmd` checks the minimal route, Odell's response branch, optional observations including the barman's revisitable menu, clothing testimony, report snapshots, save/load, completion, actual WASD traversal, departure focus, and hedge collision. `tests/phase_two_mechanics.gd` (`--qa-phase2`) covers the forced spill, revolver/knife combat, and corkboard causal spine; `tests/usability_flow.gd` (`--qa-usability`) covers waypoint traversal and interaction focus. Neither has a dedicated `.cmd` launcher yet — run them via the engine's `--headless --fixed-fps 60` arguments. The existing `tests/smoke_test.gd` also remains runnable.

Live renderer captures use `-- --capture=` followed by a mode name: `world`, `title`, `case`, `dialogue`, `settings`, `effects`, `large_text`, `gate`, `town`, `precinct`, `boardinghouse`, `room`, `board`, `witness`, `tunnel_access`, `tunnel_death`, `tunnel_record`, `return_gardener`, `lounge`, `montage`, `notebook`, `cleared_estate`, `observer`, `link_picker`, `link_positive`, or `link_negative` (see `tests/capture_views.gd` for the authoritative list). These developer arguments are not shown in-game. Reviewed captures are in `docs/qa/`.

- `main.gd`: shared player movement and camera rig.
- `scripts/chapters/chapter_one.gd`: Chapter One progression and interaction orchestration.
- `scripts/chapters/chapter_one_archive.gd`: chapter-specific record and inventory panels.
- `scripts/chapters/chapter_one_staging.gd`: day/visit progression, sleep gate, and montage intertitles.
- `scripts/chapters/chapter_one_notebook.gd`: read-only detached notebook.
- `scripts/chapters/montage_still.gd`: procedural storyboard intertitles.
- `scripts/chapters/chapter_one_dialogue.gd`: connects the dialogue grammar to live NPC menus, branches, and saves.
- `scripts/chapters/dialogue_catalog.gd`: scheduled resident registry and placement.
- `scripts/chapters/waterfront_district.gd`: waterfront hub geometry and placement.
- `scripts/shared/dialogue_lang.gd` / `dialogue_runtime.gd` / `dialogue_state.gd`: the flat-file dialogue grammar, its game-facing loader/renderer, and persistent visit/topic/outcome state.
- `scripts/shared/object_lang.gd` / `object_runtime.gd` / `object_state.gd`: a sibling flat-file grammar for world hotspots (examine points, carryable items), its loader/renderer, and persistent examine/completion state.
- `scripts/chapters/chapter_one_objects.gd`: connects the object grammar to live hotspots, FORK choices, and saves.
- `objects/`: the authored `.object` files (`estate.object`, `town.object`, `tunnel.object`) plus the annotated cookbook template.
- `scripts/shared/portal_lang.gd` / `portal_runtime.gd` / `portal_state.gd`: a third sibling flat-file grammar for travel points, its loader/renderer, and persistent attempt/completion state.
- `scripts/chapters/chapter_one_portals.gd`: connects the portal grammar to real `_travel()` calls, arrival narration, and saves.
- `portals/`: the authored `.portal` files (`estate.portal`, `lounge.portal`, `lower.portal`, `town.portal`, `tunnel.portal`) plus the annotated cookbook template.
- `scripts/shared/prologue_presentation.gd`: the photographic title screen and prologue slides.
- `scripts/shared/case_board.gd` / `case_paper.gd` / `case_threads.gd`: the colored corkboard presentation (cards, notebook paper, and twine/pin threads).
- `scripts/shared/`: also reusable interface, dialogue sequence, save store, accessibility settings, film presentation, the day/night clock, its lighting presentation, and the Chapter Two trinket generator.
- `tests/`: extracted traversal and integration checks.
- `tunnel.gd` / `tunnel_story.gd`: service passage encounter and provisional text.
- `estate.gd`: deterministic environment, figures, collision, interaction points.
- `town.gd` / `town_story.gd` / `town_expansion.gd`: town scenes, dialogue, and the neighborhood/morgue/post-office expansion.
- `scripts/chapters/town_places.gd` / `business_street.gd`: neighborhood building registry and street geometry.
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
