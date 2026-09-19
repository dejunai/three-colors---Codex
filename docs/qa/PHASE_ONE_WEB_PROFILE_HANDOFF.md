# Phase 1 Web profile handoff

Branch base: `dev/contiguous-town-phase-1` at or after `ccfbf93`

This task measures the completed Pickman–business–upper exterior in a local Web build. It does not publish or replace the frozen public build.

## Existing desktop baseline

- Construction: 107.16 ms
- Nodes: 1,678
- Mesh instances: 1,436
- Bodies / collision shapes: 72 / 72
- Interaction targets: 26
- Scheduled morning actors: 8
- Static memory: 67.32 MiB

The repeatable desktop diagnostic is `res://tests/contiguous_town_profile.gd`.

## Work

1. Export the development branch to a temporary local Web output outside `build/web/`.
2. Serve it locally with browser caching disabled.
3. Record initial load time, time from New Game to controllable Pickman Street, peak memory if the browser exposes it, visible frame stalls while walking the complete loop, and failures on a representative phone-sized viewport.
4. Walk both routes: Pickman → business → upper, then the alternate upper → business → Pickman return.
5. Confirm business and upper scheduled NPCs appear and remain interactive.
6. Delete or retain the temporary output outside the tracked project; do not publish it.

## Decision rule

Do not add streaming, HLOD, or distance culling merely because the exterior contains many primitive meshes. Recommend an architectural change only if the Web profile shows a repeatable player-visible stall, memory failure, or unacceptable sustained frame rate, and include the measured trigger in the recommendation.

## Report

Add the Web figures and test device/browser details to `docs/qa/CONTIGUOUS_TOWN_PHASE_ONE.md`. Keep generated export files out of Git.
