# Perplexity Chapter One Review: Actionable Follow-Up

Perplexity ran a document-based analysis of the Chapter One route (Design Bible, TDD, README, ARCHITECTURE, object/portal grammar references, the Dialogue Authoring Reference, and the current glass-break material) on 2026-09-20. Its findings were cross-checked against the actual source in this repo, not just the docs, before anything below was accepted as a real task. Several of its High priority player-facing risks turned out to already be handled in the shipped code; those are recorded at the bottom as verified and closed rather than left open. What follows are the findings that survived verification.

## Confirmed, actionable

- [x] Object-grammar unknown-name silent failure (real bug-shaped gap). dialogue_lang.gd's _evaluate_cmp calls push_error(Unknown dialogue gate field/function ...) when a GATE references a name that doesn't resolve. object_lang.gd's equivalent _evaluate_cmp has no such check; an unknown field or function in an .object GATE just falls through to false with zero warning, silently making a branch permanently unreachable. Fix: add the same push_error path to object_lang.gd, matching dialogue's behavior, or document why the asymmetry is intentional if it turns out to be. Resolved: added push_error to object_lang.gd and portal_lang.gd.

- [x] day = N and other numeric GATEs use substring matching, not numeric equality. Confirmed in both dialogue_lang.gd:485 and the mirrored block in object_lang.gd: left.contains(right) or right.contains(left) for = and !=. day = 3 would match a resolved value of 13 (string 13 contains 3). No practical impact yet since the slice tops out at day 3, but it's a footgun for future content. Fix: add a linter/validation pass that warns on = or != against known-numeric fields (day, steward_visits, etc.), or give numeric fields a dedicated numeric-equality comparison path instead of falling through to string substring logic. Resolved: added exact numeric comparison path for '=' and '!=' across dialogue_lang.gd, object_lang.gd, and portal_lang.gd.

- [x] No include-cycle guard in dialogue_runtime.gd load_npc. Traced the function: _cache[path] is only written after includes are fully resolved, not before recursion starts. A genuine A INCLUDE B, B INCLUDE A cycle would recurse forever before the cache could break it: unbounded recursion / stack overflow, not a clean parse error. No such cycle exists in current content as far as traced, but nothing prevents one being authored later. Fix: track an in-progress path set per top-level load_npc call and raise a normal parse error on re-entry, the same way object_lang.gd should for unknown names above. Resolved: added in-progress loading_stack cyclic inclusion detection and parse error reporting in dialogue_runtime.gd.

## Optional / lower priority

- [x] midday vs noon vocabulary split: document more visibly. Schedules are authored with midday; GATE: clauses must use noon (the actual runtime phase value). dialogue_catalog.gd already translates between them correctly for scheduling (midday if phase == noon else phase), so this isn't a live bug, but a GATE: phase = midday typo would silently never match (known field, mismatched value, no error). Worth a parser-level warning if a GATE clause uses the raw string midday, since that's never valid on that side. Resolved: added push_warning in dialogue_lang.gd when evaluating 'phase = midday'.

- [ ] Conversation-vs-travel time tuning. Confirmed the numbers Perplexity cited: district travel costs a flat DayClock.advance(state, 30.0) minutes (chapter_one.gd:744) while individual dialogue defaults to a much smaller TIME cost. Whether this needs rebalancing is a playtest-feel question, not a bug; flagging for the next cold-playtest pass rather than queuing a code change now.


## Verified and already handled (no action needed)

These were Perplexity's High priority player-facing risks. Traced against the actual running code; all three already do what the report recommended.

- Sleep-gate ambiguity: using the bed before glass_broken already shows an explicit panel (There's still work to do) followed by the exact current objective text (chapter_one_staging.gd). Not silent.
- Plain-coat discovery: the steward says, in-fiction, every single time the player approaches in the wrong coat on Day 3: I asked you to leave your badge behind (steward.dialogue line 15). This is a stronger signal than a document-only review would assume.
- Pantry-lead clarity: _objective() already returns The steward pointed to the old pantry door, off the smoking lounge the moment the lead is recorded (chapter_one.gd); essentially what the report asked for, already shipped.

## Not actioned

- The report's proposed cold-path playtest matrix (five runs: minimal, curious, resistant, schedule-adversarial, save/load) is a good idea for a future pass but wasn't run this session; flagging here so it isn't lost, not because it was rejected.
- Developer error exposed in release (fail-loud EOF/error cards reaching a published build) and web/native parity were not verified against the actual web export this session; worth a look before the next public push but not chased down here.

## Manus Godot 4 script audit (2026-09-20): verified against source

Manus ran a static source review of all 113 .gd files against main at commit 8f2c809 (confirmed exact match: git rev-parse main returned 8f2c809 at review time). It could not run Godot's own parser (no Windows Godot install mounted in its sandbox). Every one of its 10 findings was independently traced against that exact commit using git show main:<path> in this session; all 10 checked out accurately, with correct line numbers and correct mechanism. Nothing fabricated or overstated found.

### Confirmed, actionable (from the Manus audit)

- [x] Input map duplicate events. main.gd _setup_inputs(): InputMap.has_action() only guards add_action(); InputMap.action_add_event() runs unconditionally every call, so repeated scene instantiation (hot reload, multiple QA instances) appends duplicate equivalent key events to the same action forever. Fix: guard each event with InputMap.action_has_event(action, event) before adding, per Manus's suggested snippet. Resolved: added event guard in main.gd _setup_inputs().
- [ ] Per-physics-frame focus raycasting. tick_world() (chapter_one.gd) calls _find_focus() unconditionally every physics tick; _find_focus() scans all of estate.points and does a real physics raycast per closer candidate. Confirmed both call sites. Fix: throttle to a short timer (8-15 Hz) or invalidate-on-move/turn instead of every frame, per Manus's recommendation; keep an immediate refresh on interaction input.
- [ ] Uncached procedural meshes. estate.gd box()/cylinder()/sphere() each allocate a fresh mesh resource (and StaticBody3D+CollisionShape3D when solid) on every call, with no mesh cache. Confirmed the material cache (mats dict) IS real, so this is specifically a mesh-caching gap, not a general caching gap. town.gd and town_expansion.gd multiply this across the contiguous town. Fix order Manus suggests: MultiMeshInstance3D for repeated non-colliding decoration first, then mesh caching by primitive+dimensions, then shared/merged collision, then profile before considering streaming.

- [x] Unguarded node lookups (get_node, model child names). main.gd: chapter=get_node(chapter_path) has no get_node_or_null/assert. main.gd _physics_process calls model.get_node(LeftLeg/RightLeg/LeftArm/RightArm) every frame, uncached, unguarded. chapter_one.gd line 929: model.get_node(Coat) is also unguarded. One nuance Manus didn't note: the very next line guards Badge with model.has_node(Badge) first, so the codebase is inconsistent about this rather than uniformly brittle. Fix: cache player model node references once in build_player(), validate with get_node_or_null() plus a dev assertion, per Manus's recommendation for findings 5 and 7. Resolved: cached limb nodes in main.gd build_player(), guarded physics rotations, asserted chapter node lookup, guarded Coat lookup in chapter_one.gd.
- [x] Dead prototype player path. scripts/player_controller.gd and scripts/chapter_one_demo.gd (plus scenes/chapter_one_demo.tscn) exist in the repo but main.tscn's ext_resource entries only reference main.gd and chapter_one.gd. Confirmed genuinely unreferenced from the active scene. Risk is false fixes: edits to player_controller.gd do nothing in the shipped build. Fix: archive under a clearly named legacy directory or add a header comment to both paths stating which is shipped; only delete after confirming no QA/capture workflow calls it. Resolved: added clear prototype/legacy header comments to scripts/player_controller.gd and scripts/chapter_one_demo.gd.
- [ ] Travel teardown ordering needs a runtime check, not a blind fix. chapter_one.gd's travel function does remove_child(estate); estate.queue_free() then immediately constructs and add_child()s the replacement world in the same call, before the deferred free resolves. Confirmed exactly. Manus is explicit this may already be safe and tests may rely on the current ordering; the ask is a targeted runtime test for stale collision/interaction points during the transition frame (especially contiguous-exterior to interior), not an unprompted code change.

### Lower priority, verified but not queued (from the Manus audit)

- Inline preload() repeats: confirmed inline preload(res://town_expansion.gd) and preload(res://scripts/chapters/town_places.gd) inside chapter_one.gd's travel function body rather than hoisted to top-level constants. Cosmetic/maintainability only, no correctness impact (Godot caches loaded resources).
- Async ending sequence has no explicit cancellation token: confirmed chapter_one_break.gd's glass-break sequence is a chain of bare sequential await _wait(...) calls with no running/validity guard between them. Defensive-only; normal gameplay already blocks interruption during this page.
- Unbounded telemetry buffer: confirmed playthrough_log.gd's buffer.append(event) has no cap; entries are only popped on success, and the code comment literally says never retry in a gameplay loop. Only matters during a sustained telemetry outage.

### Not independently verified

- The reference-check table's no missing res:// references / no broken scene ext_resource claim was spot-checked (main.tscn's ext_resource entries) but not exhaustively re-run across all 113 .gd files; Manus itself notes Godot's own parser was unavailable in its sandbox, so a real editor-side reimport check is still worth doing before relying on this fully.

### Manus's recommended order of work (for reference)

1. Make _setup_inputs() idempotent. 2. Cache required player model nodes and add startup assertions. 3. Profile _find_focus() and throttle or invalidate-driven refresh if it is a measurable cost. 4. Profile world construction; convert repeated decorative geometry to MultiMesh or shared meshes. 5. Add a transition-frame test around travel and a cancellation guard to the ending sequence. 6. Clearly label or archive the unused prototype player path.
