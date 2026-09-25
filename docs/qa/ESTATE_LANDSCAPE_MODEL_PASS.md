# Estate entrance landscape model pass

Date: 2026-09-21
Branch: `feature/district-textures`
Scope: generated-prop review and restrained estate use

## Decision

The estate's authored iron gate remains unchanged. It opens with progression, supplies the scene exit, and already has tested moving collision. The generated fence/gate is visibly closed and would give the wrong signal at this location. It therefore remains confined to the upper residence's side garden.

The rose-garden and boundary hedges also remain authored geometry because their openings, collision, evidence placement, and walkable investigation route are functional. Covering them with repeated generated hedge sections would add visible repetition while making the collision less legible.

Two generated tree/bush clusters now sit against the outer entrance walls at `x = -18` and `x = 14`; the asymmetry keeps the west cluster clear of the gate lodge. They enrich the estate's arrival silhouette without entering the central gate, lodge, garden, birch-grove, service-door, or evidence spaces.

## Gameplay boundary

The clusters are render models under `RenderedEstateLandscaping`. Two broad hidden box proxies under `LegacyEstateLandscapeCollisionVisuals` keep their dense foliage solid. The authored gate leaves, `exit` target, exit exclusions, gate-opening state, and every investigation target are unchanged.

## Verification

- `tests/estate_landscape_model_flow.gd` checks both rendered clusters, the two hidden proxies, the unchanged centered exit, and the original pair of gate leaves.
- The maintained opening-flow suite continues to walk the actual estate route and verify the working gate and hedge collision.
- `estate_approach` provides a fixed wide renderer view confirming that the entrance remains visually dominant and unobstructed; the older `gate` view remains available for interaction-focused captures.

No Web export or publication was performed.
