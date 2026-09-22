# Three Colors of Madness — No Exit Wound

Native third-person 3D Chapter One vertical slice aligned with the Design Bible and current TDD. This is a blockout build with provisional writing: most geometry is still procedural primitives, but a growing set of characters (Walter, Captain Odell, the coroner's assistant, the club steward, Father Behan, the gatehouse boy, six background-resident archetypes, the estate's murder victims and covered bodies) and several exterior landmarks (the waterfront, three Pickman Street frontages, a lower-district dwelling, the business-district schoolhouse) now use rendered 3D models rather than primitive placeholders. See "Character and landmark models" below. It now spans three enacted investigation days and a service-passage ending beat; human playtime is measured through cold playtests and anonymous telemetry rather than promised as a fixed duration.

## Current staging pass

The steward is inside the smoking lounge, reached through the estate's service entrance after speaking to Mrs. Almy. Speak to him once, return home and sleep to open day two, which now plays live (no montage — the old intertitle sequence is archived code, retained only for legacy-save resume and reference captures), then return on day three in the plain wool coat. Sleep is temporarily blocked until the first conversation (and the existing intake/identification beats) are complete. Repeated entries do not advance a visit. The groundskeeper appears when leaving the lounge. On estate returns, the bodies, Odell and the coroner's assistant are gone and the gardener is beside the approach drive, below the garden hedge; his plain-coat testimony remains optional.

“Read the notebook” in personal effects or the case file opens the read-only reference. Linking remains at the physical board. Setting the notebook down at Walter's desk is reflective only; the bed advances the day. After the third steward encounter, the bed refuses to end the slice until Walter follows the pantry lead through the service passage and reaches the glass-shattering break. A save made after the break resumes directly at the ending. See `docs/qa/GLASS_BREAK_PASS.md`.

See `docs/qa/STAGING_PASS.md` for the historical restaging pass and `docs/qa/MONTAGE_ARCHIVE_PASS.md` for enacted Day 2. `Test staging.cmd` verifies current progression. Its old 3.1–3.6/6.6–7.8 minute figures describe only the original estate opener, not the present three-day slice.

## Town expansion pass

Pickman Street's opposite frontage leads into the business district, upper residential quarter and lower residential quarter, plus the post office, with eighteen registered buildings and twelve accessible interiors in the original expansion registry. Precinct intake also leads to a morgue with a coroner. Those early placeholder rooms now sit inside the larger 71-NPC scheduled dialogue catalog; some interiors remain deliberately empty or exterior-only. Departing the estate for town clears the rose garden's six bodies; returning from town on Day 3 after two completed estate visits silently clears the birches too, with no accompanying scene. See `docs/qa/TOWN_EXPANSION_PASS.md` for the historical geography pass and the contiguous-town documents for the current exterior.

## Contiguous town exterior

The neighborhoods above, the lower district, and the waterfront are no longer separate loading-boundary hubs: `scripts/chapters/contiguous_town_phase_one.gd` and `contiguous_town_phase_two.gd` grow one continuous, physically walkable exterior outward from Pickman Street (a stone incline up to the business district and upper quarter, then a descending lane east to the lower district and on to the waterfront), so the whole loop can be walked without a single travel transition. Interiors remain separate scenes, and every authored location, route, and NPC id stays stable; old saves still load directly into the legacy hub layout. A cached 128-pixel procedural surface library gives each district a small material vocabulary—orderly masonry uphill, patched and sooted work below, salt-worn timber and algae stone at the water—without changing geometry or adding large image assets. The approved modeling pass now supplies rendered Walter, the bounded waterfront slice, three selectively fitted Pickman Street landmarks (Precinct 4, Mrs. Almy's boardinghouse, and Walter's rooms), a rendered Dwelling No. 2 landmark in the lower district, and the business district schoolhouse. Hidden primitive shells retain collision authority for the rendered environments. See `docs/qa/CONTIGUOUS_TOWN_PHASE_ONE.md`, `docs/qa/CONTIGUOUS_TOWN_PHASE_TWO.md`, `docs/qa/DISTRICT_TEXTURE_PASS.md`, `docs/qa/MODELING_PASS_PHASE_ONE.md`, `docs/qa/PICKMAN_EXTERIOR_MODEL_PASS.md`, `docs/qa/LOWER_EXTERIOR_MODEL_PASS.md`, and `docs/qa/BUSINESS_SCHOOLHOUSE_MODEL_PASS.md`; `docs/qa/PHASE_ONE_WEB_PROFILE_HANDOFF.md` retains the profiling methodology and decision rule (no streaming/HLOD without a measured, player-visible stall). `tests/contiguous_town_profile.gd` reports the current desktop construction-time/memory baseline.

## Waterfront district

A rendered 10,048-triangle waterfront slice now supplies the quay, seawall, timber apron, water, one fishing boat, working props, and four exterior fronts (a detailed harbor-supply chandlery and fish stores anchoring the authored freight office and net loft). Five additional hero quay props (a boat frame, a combined cargo cluster, a dock crane, a dock shed, and the primary moored fishing boat, each optimized to a 2K texture budget) dress the working apron between them. Hidden primitive geometry retains the verified collision and route footprint. The abandoned whaling station remains separate provisional offshore scenery with no route or clue attached. The district is reached via the continuous descending lane from the lower district; old saves can still load directly into its legacy hub entry. Its scheduled cast includes the harbor observer, salt mender, quay docker, net seller and additional waterfront laborers. Crossing the authored district bridge charges 30 game minutes. See `docs/qa/WATERFRONT_PASS.md` for the original district pass, `docs/qa/WATERFRONT_MODEL_PHASE_ONE.md` for the rendered slice, `docs/qa/WATERFRONT_STOREFRONT_PASS.md` for the selective detailed-frontage pass, and `docs/qa/QUAY_PROP_AUDIT_2026-09-21.md` for the five hero quay props.

## Character and landmark models

A modeling pass now replaces several primitive placeholders with rendered Meshy-generated GLB models, each with its own runtime adapter under `scripts/shared/`: Walter (`walter_model.gd`, 16,509 triangles, police/plain coat and badge visibility groups, an Idle/Walk/Brisk/Interact/Pickup_Ground/Surprise/Examine animation set), Captain Odell (`captain_odell_model.gd`, 15,172 triangles, one rendered model reused for both his one-shot estate appearance and his returning precinct schedule, with Idle/Idle_Alt/Confer animations), the coroner's assistant (`coroner_model.gd`, Idle/Idle_Alt/Confer), the club steward (`steward_model.gd`, Idle/Idle_Alt/Confer/Listen plus a default Clean_Glass idle), Father Behan and the gatehouse boy (`father_behan_model.gd`/`gatekeeper_boy_model.gd`, Idle/Idle_Alt/Listen), and six background-resident archetypes (`cast_model.gd`: `UPPER_MAN`/`UPPER_WOMAN`/`LOWER_MAN`/`LOWER_WOMAN`/`OBSERVER_MAN`/`OBSERVER_WOMAN`, classified onto scheduled NPC ids by district and role). The estate's six lawn corpses and the covered bodies of Naomi Freeman and her young son also use rendered models (`victim_model.gd`/`covered_body_model.gd`) rather than primitive stand-ins. Every rendered actor keeps its original interaction id, schedule, dialogue gate, and save behavior unchanged; only presentation is affected. Not every character has a rendered model yet — most background townsfolk outside the six archetypes above, and the tunnel's drowned sailors/cultists, remain procedural primitives. See `docs/qa/WALTER_MODEL_PHASE_ONE.md` and `docs/qa/ODELL_MODEL_PHASE_ONE.md` for the two written passes; the remaining models are verified only by their `tests/*_model_flow.gd`/`*_model_integration_flow.gd` suites, listed below.

## Live dialogue and town residents

Chapter One's dialogue runs on an authored, data-driven system instead of hand-coded per-NPC menus. `scripts/chapters/chapter_one_dialogue.gd` reads all 72 `.dialogue` files under `dialogue/` (71 concrete NPC files plus a background template). The live catalog audit reports 449 nonempty, parser-reachable topics; the source contains 465 raw `TOPIC:` headers because documentation-only blocks are intentionally excluded at runtime. It resolves each NPC's current line or menu from location, time of day, and prior conversations, with real FORK choice buttons and mid-conversation save/resume. Multiple `default` greetings can form a `WEIGHT`-based pool for exhausted/ambient variety (immediate-repeat memory is cosmetic only), and a `FORK` branch can commit an immutable `OUTCOME: decision_id = value_id`, readable later via `outcome()`/`outcome_is()`. Interacting with an NPC who has no eligible default topic and no available menu choices fails loudly: rather than silently closing and leaving the character standing unresponsive ("turning into an unresponsive totem pole"), the runtime emits an engine error and presents an on-screen developer warning card naming the NPC. `scripts/chapters/dialogue_catalog.gd` places four dozen-plus scheduled residents (shopkeepers, clerks, the historian, the clockmaker, Widow Kessler, waterfront tradespeople, a drayman, a fish smoker, a lamplighter, and other named townsfolk) into their morning/midday/evening/night positions across the estate, precinct, the expanded town neighborhoods, and the waterfront district. A night-only speakeasy adds two night-owl patrons and a bartender, evening/night hours only. Every authored NPC line carries or is auto-assigned an instrumental `VOICE:` delivery cue (never a truth signal) from `assets/audio/instrument_voices/`, adjustable under **Instrument voices** in Accessibility & controls. See `docs/qa/DIALOGUE_LIVE_PASS.md` for the full integration record, `docs/qa/DIALOGUE_LANG_PASS.md` for the underlying grammar, `docs/DIALOGUE_AUTHORING.md` for the current authoring reference, `docs/qa/ESTATE_INSTRUMENT_VOICES.md` and `docs/qa/CARD_AND_VOICE_ROUTING.md` for the instrument-voice system, `docs/qa/WATERFRONT_PASS.md` for the waterfront district, and `docs/qa/DAY_ONE_PACING_REVIEW.md` for a strategic, code-free review of opening-flow rough edges.

## World objects: examine points and carryable items

A sibling, flat-file authoring system covers static world hotspots — things Walter examines rather than someone he talks to — instead of hardcoded per-scene dispatch. `objects/*.object` files (currently `estate.object`, `town.object`, and `tunnel.object`: all seven estate examine points, the three town-side ones, and the tunnel's foundation measurement) are parsed by `scripts/shared/object_lang.gd`/`object_runtime.gd` and rendered live through `scripts/chapters/chapter_one_objects.gd`, sharing the dialogue system's GATE grammar, evidence/outcome state, and adding inventory support (`TAKE:`). A hotspot whose visibility and interaction state disagree fails loudly with an on-screen error naming the location and id, rather than doing nothing. See `docs/OBJECT_AUTHORING.md` for the authoring reference and `docs/OBJECT_MIGRATION_HOWTO.md` for the migrated inventory, what's deliberately left alone, and the recipe used to convert a hardcoded hotspot. `tests/object_lang_flow.gd`/`object_template_flow.gd` are standalone grammar/cookbook proofs; `tests/object_content_flow.gd` audits the real shipped files and a live FORK through the adapter.

## Travel points and portals

A third sibling flat-file system covers travel points — hotspots that send Walter somewhere else, like the estate's service entrance — rather than an examine point's static content. `portals/*.portal` files (currently `estate.portal`, `lounge.portal`, `lower.portal`, `town.portal`, and `tunnel.portal`, covering the migrated estate, lounge, lower-district, town-street, and tunnel travel points) are parsed by `scripts/shared/portal_lang.gd`/`portal_runtime.gd` and rendered live through `scripts/chapters/chapter_one_portals.gd`, sharing the same GATE grammar and evidence/outcome state as dialogue and objects. Its one new step, `GO: destination | x,y,z | yaw | flags`, is a circuit breaker like `FORK`: reaching it hands control to the adapter, which is the only thing that actually moves the player, and any content authored after it plays as arrival narration once the adapter resumes. An omitted `TIME:` defaults to 3 minutes, charged once per portal identity the first time it completes; an authored `TIME:` overrides that default. A hotspot whose visibility and interaction state disagree fails loudly, the same as objects. See `docs/PORTAL_AUTHORING.md` for the authoring reference. `tests/portal_lang_flow.gd`/`portal_template_flow.gd` are standalone grammar/cookbook proofs; `tests/portal_content_flow.gd` audits the real shipped files by driving every migrated route through the actual `chapter_one.gd` adapter, including `route_speakeasy` from the real contiguous-town world.

## Title screen and prologue

Launching the game opens a photographic title screen (bundled serif fonts, a gradient scrim over a desaturated period photo, and a looping civic-reel music cue) instead of the plain menu; starting a new game plays a three-slide photographic prologue before Walter reaches the estate gates. `scripts/shared/prologue_presentation.gd` owns this presentation layer independently of the ordinary dark modal UI in `chapter_interface.gd`. See `docs/qa/PROLOGUE_INPUT_FIX.md` and `docs/qa/TITLE_SETTINGS_FIX.md` for fixes applied after the initial pass.

## Anonymous playthrough telemetry

The game logs a small, fixed set of pacing/progression events (session start, first objective, district transitions, phase changes, completed dialogue topics with coat/location/day context, Day-3 ending arrival, optional debrief, and session end) tagged only with a random per-playthrough UUID — no name, account, device fingerprint, or IP address is stored. Events buffer in memory and upload to the single endpoint named in the `three_colors/telemetry_endpoint` project setting; a blank endpoint disables logging entirely and gameplay never stalls waiting on a request. The current Cloudflare Worker dual-writes accepted events to queryable D1 and raw JSON batches to R2, with no public read route. The pocket watch is live UI but does not currently emit the formerly proposed `watch_checked` event. See `docs/LOG_PLAYER_ASK.md` for the full event schema and privacy constraints, and `docs/qa/PLAYER_LOG_ENDPOINT_HANDOFF.md` for the deployed endpoint and verification record.

## Play

Double-click `Launch.cmd`, or open `project.godot` in Godot and press F5. The launcher uses the installed engine at `C:\Portables\Godot4\Godot_v4.7.2-stable_mono_win64.exe`. No downloads, additional libraries, or network connection are needed.

## Controls

- WASD / arrows: move; mouse: look; Q/R: orbit camera.
- Mouse wheel: camera distance; Shift: brisk walking.
- E / F: examine or speak.
- Tab / I: Personal Effects paper doll; select Walter's coat, badge, notebook, revolver, flask or boots directly. The closed watch icon in the upper-right opens the analogue watch; it changes from sun to moon at 6 PM and holds at midnight until Walter sleeps. J opens the case file; F1 or Escape pauses. F1 remains available in browser fullscreen, where Escape may leave fullscreen before the game receives it.
- F11: fullscreen. Menus support mouse or Tab, Shift+Tab, Enter/Space.

Development only: F3 toggles Shift between the player brisk pace (4.0) and the temporary developer pace (10.5) for the current process.

## Opening route

Read the civic-history intertitles. Speak to the gatehouse boy, follow the drive, and explore the rose garden, terrace, and birch grove. Consult Captain Odell beyond the fountain. Prepare a report at the field desk beside him. Return to the estate gates to continue to Pickman Street. Submit the report at the precinct and ask Mrs. Almy about the unidentified woman at the boardinghouse. Sleep advances the investigation through enacted Days 2 and 3; the desk notebook does not. The current slice continues through the steward's pantry lead, the service passage, Walter's retreat home, and the glass-shattering break.

Optional observations: wounds, grove, knife, watch, intact windows, seating list, belongings, the assistant's testimony, and the grounds crew's fixed distance from the kitchen wing's service door. After the opening, the gardener supplies an optional additional statement beside the drive below the garden hedge when Walter wears his plain wool coat (change it in personal effects). The club's steward, inside the smoking lounge, opens his three-topic revisitable menu on the third visit under the conditions above.

A minimal run can go directly to Odell and the report. His statement supplies the count without claiming examinations Walter skipped. Odell's dismissal ("Six members, Corwin... The other two are a filing matter") opens a genuine choice — answer him to his face, or say nothing and let the notebook carry it — recorded as a distinct statement either way; neither option is scored or gates anything downstream. Opening the case file is optional; it never gates progression. The report snapshots the evidence present when prepared. Later observations remain in Walter's notebook until he revises the report at the desk.

The town includes optional witness questions, a meal ledger, a newspaper, a personal notice, an automatic case board, Father Behan on the street behind the rectory marker, whose own revisitable menu turns up why the Ophion Club is named for a lost ship and the money it left behind, and an unnamed woman outside Kessler's shuttered shop, who warns Walter once and does not stay to explain herself. The board never gates progression. Reports become immutable when received at the precinct; later findings can be filed as dated supplements, with optional county dispatch. Witness claims remain distinguished from corroborated findings.

## Saves and accessibility

The launcher stores Godot's user data in `.runtime-data` inside the project. Saves occur after interactions, every 20 seconds of exploration, on pause and on exit. Continue restores position, camera, evidence, statements, links, clothing, report copies, flask supply, ammunition, the day clock, dialogue progress, and presentation relief. QA uses a separate save. Earlier opening saves migrate automatically; completed opening saves continue into town. Continue also looks for the newest save from a previous editor launch.

Accessibility is available before play: static grain by default, distortion intensity, grain, contrast, text size up to 130%, mouse sensitivity/inversion, optional interaction markers, and an independent Instrument voices volume for NPC delivery cues (zero fully mutes them without muting other audio). Text stays above all film effects; long menus scroll. The service passage includes a provisional synthetic cough with a matching readable caption. Full audio design remains unfinished.

## Scope

This build includes perspective movement/camera collision, twelve optional observations (three of them behind a revisitable witness menu), a branching response to Odell, a sparse paperdoll and inventory, displayed Strength/Perception, clothing, a finite flask affecting presentation only, report choices, a persistent opening record, a scoped Observer color tell in the active shader, a player-drawn corkboard link mechanic (now a colored warm-paper/cork/brass-pin presentation, see `docs/qa/COLORED_CASE_PRESENTATION.md`) that accelerates Perception, and a real day/night clock driving lighting.

The service passage adds a forced flask spill, a six-round revolver, and knife melee: drowned sailors can be finished off permanently once staggered, while fully transformed cultists can only be staggered and evaded, never killed. The opening slice now runs all the way to the first significant break with reality: the board goes whole, the frame widens, and the near-total silence built around a single recurring cough breaks open for good at the sound of glass shattering — the ontological crack described in the Design Bible. It does not include the fatal-comprehension ending, the entity, the mother's voice beyond that crack, later chapters, gamepad support, full key rebinding, or a full encumbrance/level-up system. Later consumption of the record by Ekon is future work. The v10 difficulty screen is deferred. The respectful all-eight wording is provisional and needs review against Walter's intended initial bias. Neither report choice is scored as morality. See `docs/qa/GLASS_BREAK_PASS.md` for the build record.

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

`python tests/run_all_qa.py` is the maintained aggregate runner. Its current 33-suite set covers the dialogue, object and portal grammars/templates/live content; opening, town, service-passage loop, usability integration, and the complete steward-to-glass ending path; and the accepted character, victim, exterior, texture, pickup, Pickman-frontage, lower-district, business-schoolhouse, and waterfront-integration model checks. `tests/dialogue_catalog_flow.gd`, the population/placement checks, pocket-watch, telemetry, camera and presentation checks remain focused suites outside that aggregate and should be run when their areas change. The `.cmd` launchers remain convenient partial checks, not the authoritative complete set.

Live renderer captures use `-- --capture=` followed by a mode name: `world`, `walter`, `walter_pickup`, `odell`, `odell_precinct`, `glass_break`, `title`, `case`, `dialogue`, `settings`, `effects`, `watch`, `large_text`, `gate`, `town`, `town_pickman`, `town_business`, `town_schoolhouse`, `town_upper`, `town_lower`, `town_waterfront`, `town_waterfront_frontage`, `town_waterfront_seaward`, `town_waterfront_workyard`, `precinct`, `boardinghouse`, `room`, `board`, `witness`, `tunnel_access`, `tunnel_death`, `tunnel_record`, `return_gardener`, `lounge`, `montage`, `notebook`, `cleared_estate`, `observer`, `link_picker`, `link_positive`, or `link_negative` (see `tests/capture_views.gd` for the authoritative list). These developer arguments are not shown in-game. Reviewed captures are in `docs/qa/`.

- `main.gd`: shared player movement and camera rig.
- `scripts/chapters/chapter_one.gd`: Chapter One progression and interaction orchestration.
- `scripts/chapters/chapter_one_archive.gd`: chapter-specific record and inventory panels.
- `scripts/chapters/chapter_one_staging.gd`: day/visit progression and sleep gate; also retains the legacy montage intertitle code for old-save resume and reference captures.
- `scripts/chapters/montage_still.gd`: the legacy procedural storyboard intertitles (archived, not called by live progression).
- `scripts/chapters/chapter_one_notebook.gd`: read-only detached notebook.
- `scripts/chapters/chapter_one_dialogue.gd`: connects the dialogue grammar to live NPC menus, branches, and saves.
- `scripts/chapters/dialogue_catalog.gd`: scheduled resident registry and placement.
- `scripts/chapters/waterfront_district.gd`: waterfront geometry and placement within the contiguous exterior (plus legacy hub compatibility).
- `scripts/shared/dialogue_lang.gd` / `dialogue_runtime.gd` / `dialogue_state.gd`: the flat-file dialogue grammar, its game-facing loader/renderer, and persistent visit/topic/outcome state.
- `scripts/shared/object_lang.gd` / `object_runtime.gd` / `object_state.gd`: a sibling flat-file grammar for world hotspots (examine points, carryable items), its loader/renderer, and persistent examine/completion state.
- `scripts/chapters/chapter_one_objects.gd`: connects the object grammar to live hotspots, FORK choices, and saves.
- `objects/`: the authored `.object` files (`estate.object`, `town.object`, `tunnel.object`) plus the annotated cookbook template.
- `scripts/shared/portal_lang.gd` / `portal_runtime.gd` / `portal_state.gd`: a third sibling flat-file grammar for travel points, its loader/renderer, and persistent attempt/completion state.
- `scripts/chapters/chapter_one_portals.gd`: connects the portal grammar to real `_travel()` calls, arrival narration, and saves.
- `portals/`: the authored `.portal` files (`estate.portal`, `lounge.portal`, `lower.portal`, `town.portal`, `tunnel.portal`) plus the annotated cookbook template.
- `scripts/shared/prologue_presentation.gd`: the photographic title screen and prologue slides.
- `scripts/shared/case_board.gd` / `case_paper.gd` / `case_threads.gd`: the colored corkboard presentation (cards, notebook paper, and twine/pin threads).
- `scripts/shared/walter_model.gd` / `captain_odell_model.gd` / `coroner_model.gd` / `steward_model.gd` / `father_behan_model.gd` / `gatekeeper_boy_model.gd` / `cast_model.gd` / `victim_model.gd` / `covered_body_model.gd`: rendered-model adapters for Walter, Odell, the coroner's assistant, the steward, Father Behan, the gatehouse boy, background-resident archetypes, and the estate's murder victims/covered bodies (see "Character and landmark models" above).
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
