extends SceneTree

# Live-content adapter audit for the portal system, runnable directly:
#   godot --headless --path . --script res://tests/portal_content_flow.gd
# Unlike portal_lang_flow.gd/portal_template_flow.gd (pure grammar/runtime,
# inline fixtures, manual commit_through()/after_go() calls), this drives
# every real shipped .portal route through the actual chapter_one.gd
# _interact()/_travel() call path in a live main.tscn instance — including
# route_speakeasy from the real contiguous-town "town" world (not a direct
# g._travel("lower",...) shortcut), so a portal's GATE can never again be
# silently bypassed by the shared exterior street reaching it a different
# way than a segmented pocket world would.

const PortalRuntime = preload("res://scripts/shared/portal_runtime.gd")

# Single source of truth this test checks the real files against: every id
# chapter_one.gd's portals.sync_points()/portals.interact() calls expect a
# given location's .portal file to define.
const LIVE_FILES = {
	"estate": ["service_entrance", "exit"],
	"lounge": ["lounge_exit"],
	"lower": ["route_speakeasy"],
	"town": ["street_precinct", "street_almy", "street_room", "street_estate", "route_post"],
	"tunnel": ["tunnel_exit"],
}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_check_parse_and_wiring()
	var g = await _new_game()
	await _check_service_entrance_and_lounge(g)
	await _check_town_street_portals(g)
	await _check_speakeasy_via_contiguous_town(g)
	await _check_tunnel_exit_both_branches(g)
	await _check_authored_time_charges_once()
	print("PASS: live portal content audits clean; parse errors/wiring, service_entrance/lounge_exit round trip (including an immediate-GO completion), town street portals, route_speakeasy gated correctly from the real contiguous town world, both tunnel_exit branches, and authored TIME charging exactly once per portal identity all verified through the real chapter_one.gd adapter")
	quit(0)

func _check_parse_and_wiring() -> void:
	for location in LIVE_FILES:
		var path = "res://portals/%s.portal" % location
		var def = PortalRuntime.load_location(path)
		assert(def.errors.is_empty(), "%s must parse without errors: %s" % [path, str(def.errors)])
		assert(String(def.location) == location, "%s's LOCATION header must match its filename" % path)
		var known = PortalRuntime.known_ids(def)
		for id in LIVE_FILES[location]:
			assert(known.has(id), "%s is wired in chapter_one.gd but %s has no PORTAL block for it" % [id, path])

func _new_game():
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var g = scene.chapter
	g.test_mode = true
	g.playthrough_log.endpoint_url = ""
	g.state = g.CaseState.new()
	g.state.started = true
	return g

func _drain_cards(g) -> void:
	while g.page == "dialogue": g._next_card()

func _check_service_entrance_and_lounge(g) -> void:
	assert(g.state.world == "estate", "fresh CaseState should start in the estate")
	assert(not g.state.visited.has("almy"), "fresh CaseState should not have visited almy yet")

	g._interact("service_entrance")
	assert(g.page == "dialogue", "the locked service entrance must show a card, not silently do nothing")
	_drain_cards(g)
	assert(g.state.world == "estate", "the locked service entrance must not travel")

	g.state.visited.append("almy")
	g._interact("service_entrance")
	await process_frame
	assert(g.state.world == "lounge", "the unlocked service entrance must travel to the lounge")
	assert(g.state.portal_state.portal_done("estate", "service_entrance"), "an immediate GO with no post-arrival cards must still complete its portal session")

	g._interact("lounge_exit")
	await process_frame
	assert(g.state.world == "estate", "lounge_exit must travel back to the estate")
	assert(g.state.lounge_exited, "lounge_exit's adapter-side effect (_before_travel) must fire")
	assert(g.state.portal_state.portal_done("lounge", "lounge_exit"), "lounge_exit's immediate GO must also complete its portal session")

	# Check exit portal:
	assert(g.state.report.is_empty(), "test setup: report is not filed yet")
	g._interact("exit")
	assert(g.page == "dialogue" and g.dialogue.cards[0][1].contains("paperwork"), "uncompleted report must show paperwork card")
	_drain_cards(g)
	assert(g.state.world == "estate", "blocked exit must stay in estate")
	g.state.report = "Observations filed"
	g._interact("exit")
	assert(g.page == "dialogue" and g.dialogue.cards[0][0] == "PICKMAN STREET", "unlocked exit must show arrival cards")
	_drain_cards(g)
	await process_frame
	assert(g.state.world == "town", "unlocked exit must travel to town")
	assert(g.state.estate_complete, "exit portal must trigger estate_complete")
	assert(g.state.portal_state.portal_done("estate", "exit"), "exit portal session must complete")

func _check_town_street_portals(g) -> void:
	g._travel("town", Vector3(0, 0.1, 17), 0)
	await process_frame
	assert(g.state.world == "town")

	# street_precinct
	g._interact("street_precinct")
	await process_frame
	assert(g.state.world == "precinct", "street_precinct must travel to precinct")
	assert(g.state.portal_state.portal_done("town", "street_precinct"), "street_precinct must complete portal session")

	# Return to town
	g._travel("town", Vector3(0, 0.1, 17), 0)
	await process_frame

	# street_almy
	g._interact("street_almy")
	await process_frame
	assert(g.state.world == "boardinghouse", "street_almy must travel to boardinghouse")
	assert(g.state.portal_state.portal_done("town", "street_almy"), "street_almy must complete portal session")

	# Return to town
	g._travel("town", Vector3(0, 0.1, 17), 0)
	await process_frame

	# street_room
	g._interact("street_room")
	await process_frame
	assert(g.state.world == "room", "street_room must travel to room")
	assert(g.state.portal_state.portal_done("town", "street_room"), "street_room must complete portal session")

	# Return to town
	g._travel("town", Vector3(0, 0.1, 17), 0)
	await process_frame

	# route_post
	g._interact("route_post")
	await process_frame
	assert(g.state.world == "post_office", "route_post must travel to post_office")
	assert(g.state.portal_state.portal_done("town", "route_post"), "route_post must complete portal session")

	# Return to town
	g._travel("town", Vector3(0, 0.1, 17), 0)
	await process_frame

	# street_estate
	g._interact("street_estate")
	await process_frame
	assert(g.state.world == "estate", "street_estate must travel to estate")
	assert(g.state.portal_state.portal_done("town", "street_estate"), "street_estate must complete portal session")

func _check_speakeasy_via_contiguous_town(g) -> void:
	g._travel("town", Vector3(0, 0.1, 17), 0)
	await process_frame
	assert(g.state.world == "town", "traveling to town must land in the shared contiguous exterior")
	assert(g.estate.has_node("ContiguousTownPhaseTwo/LowerDistrictExterior"), "the lower district's facade must share the town exterior")
	assert(g.estate.routes.has("route_speakeasy"), "the cellar door hotspot must exist on the contiguous exterior")

	g.state.clock_minutes = 360.0 # morning
	g._interact("route_speakeasy")
	assert(g.page == "dialogue" and g.dialogue.cards[0][0] == "CELLAR BULKHEAD", "a morning attempt must show the locked bulkhead card")
	_drain_cards(g)
	assert(g.state.world == "town", "a blocked route_speakeasy must not travel — state.world must still read town, proving the GATE was actually consulted here, not bypassed by the raw estate.routes entry")

	g.state.clock_minutes = 1020.0 # evening
	g.state.coat = "Police coat"
	g._interact("route_speakeasy")
	assert(g.page == "dialogue" and g.dialogue.cards[0][0] == "THE VIEWING SLIT", "an evening attempt in a police coat must show the rejection card")
	_drain_cards(g)
	assert(g.state.world == "town", "a coat-rejected route_speakeasy must not travel either")

	g.state.coat = "Plain wool coat"
	g._interact("route_speakeasy")
	await process_frame
	assert(g.state.world == "speakeasy", "an evening attempt in a plain coat must finally travel to the speakeasy")
	assert(g.state.portal_state.portal_done("lower", "route_speakeasy"), "the unlocked route_speakeasy must complete its portal session")

func _check_tunnel_exit_both_branches(g) -> void:
	# Branch 1: no lower_foundation evidence yet — falls through to the
	# unconditional GATE: always block, an immediate GO straight to "room".
	g._travel("tunnel", Vector3(0, 0.1, 5), 0)
	await process_frame
	assert(not g.state.evidence.has("lower_foundation"), "test setup: lower_foundation must not be recorded yet")
	g._interact("tunnel_exit")
	await process_frame
	assert(g.state.world == "room", "without lower_foundation evidence, tunnel_exit must fall through to its always-true room branch")
	assert(not g.state.tunnel_complete, "the plain room branch must not trigger the precinct-only adapter side effect")

	# Branch 2: with lower_foundation evidence — the gated block wins, with
	# its dynamic BACK AT THE PRECINCT card (adapter escape hatch) shown
	# before the authored A LATER PAGE card, then travels to precinct.
	g._travel("tunnel", Vector3(0, 0.1, 5), 0)
	await process_frame
	g.state.discover("lower_foundation")
	g._interact("tunnel_exit")
	assert(g.page == "dialogue" and g.dialogue.cards[0][0] == "BACK AT THE PRECINCT", "with lower_foundation evidence, the dynamic custody-result card must show first")
	_drain_cards(g)
	await process_frame
	assert(g.state.world == "precinct", "the gated tunnel_exit branch must travel to the precinct")
	assert(g.state.tunnel_complete, "_before_travel's tunnel_complete side effect must fire for this branch")
	assert(g.state.portal_state.portal_done("tunnel", "tunnel_exit"), "the gated tunnel_exit branch must complete its portal session")

# None of the four shipped portals author TIME yet, so this drives a
# synthetic definition straight through the real _play()/_advance()/
# _perform_go() chain (same trick object_content_flow.gd uses for its
# synthetic FORK) rather than writing a throwaway file under portals/ that a
# concurrent agent session could collide with. interact()'s own res:// file-
# existence guard is deliberately skipped here — that guard is exercised
# elsewhere; this test is only about the TIME-charging logic, run in its own
# fresh game so no earlier scenario's accumulated clock_minutes can approach
# the day's cap. Clock reads happen immediately after _play() (which runs
# fully synchronously through commit_through()/_perform_go() for a
# cards-then-GO segment with nothing to click through) rather than after an
# awaited process_frame, since a settled "play" page's own tick_world() adds
# a small real-time WANDER_RATE nudge that would make an exact comparison flaky.
func _check_authored_time_charges_once() -> void:
	var g = await _new_game()
	var Lang = load("res://scripts/shared/portal_lang.gd")
	var toll_src = "LOCATION: test_toll\nPORTAL: toll_gate\n  GATE: always\n  TIME: 15\n  GO: estate | 0,0.1,35 | 0\n"
	var parsed = Lang.parse(toll_src)
	assert(parsed.errors.is_empty(), "toll fixture must parse: %s" % str(parsed.errors))

	var starting_minutes = g.state.clock_minutes
	var first = PortalRuntime.enter(parsed, "toll_gate", PortalRuntime.make_context(g.state), g.state)
	assert(first.go != null, "toll_gate must GO immediately")
	g.portals._play(g, first)
	assert(g.state.clock_minutes == starting_minutes + 15.0, "the first crossing must charge the authored TIME")
	assert(g.state.portal_state.portal_done("test_toll", "toll_gate"), "the first crossing must complete the portal")

	var minutes_before_replay = g.state.clock_minutes
	var second = PortalRuntime.enter(parsed, "toll_gate", PortalRuntime.make_context(g.state), g.state)
	g.portals._play(g, second)
	assert(g.state.clock_minutes == minutes_before_replay, "a repeat crossing of an already-completed timed portal must not charge again")

	# Omitted TIME defaults to 3 minutes, charged once on first completion:
	var default_time_src = "LOCATION: test_default_time\nPORTAL: default_door\n  GATE: always\n  GO: estate | 0,0.1,35 | 0\n"
	var default_parsed = Lang.parse(default_time_src)
	assert(default_parsed.errors.is_empty(), str(default_parsed.errors))
	var before_default = g.state.clock_minutes
	var def_first = PortalRuntime.enter(default_parsed, "default_door", PortalRuntime.make_context(g.state), g.state)
	g.portals._play(g, def_first)
	assert(g.state.clock_minutes == before_default + 3.0, "omitted TIME must default to 3 minutes on first crossing")
	assert(g.state.portal_state.portal_done("test_default_time", "default_door"), "first crossing must complete the portal")
	var before_def_replay = g.state.clock_minutes
	var def_second = PortalRuntime.enter(default_parsed, "default_door", PortalRuntime.make_context(g.state), g.state)
	g.portals._play(g, def_second)
	assert(g.state.clock_minutes == before_def_replay, "repeat crossing of default-timed portal must not charge again")

