# Modeling Pass — Phase 1

Date agreed: 2026-09-20  
Working branch: `feature/district-textures`  
Status: Implementation complete — Walter and waterfront accepted in desktop play; Web profiling awaits the next authorized export

## Provenance

This phase follows the completed procedural district-texture pass at commit `1a2b651`. Dejunai chose to retain that feature branch for the next visual-development work rather than create or rename another branch.

The scope below records the conversation between Dejunai and Codex, including two suggestions relayed from Claude and then explicitly accepted by Dejunai:

1. After rendered Walter is integrated, pause and replay the ending through the glass shattering before beginning the environment model pass.
2. Treat intentionally distant scenery and unfinished development geometry as different visual categories. Fog is atmosphere, not a substitute for authored scenery.

The relayed suggestions are included as settled direction because Dejunai expressly adopted them. This document does not treat other agent commentary as authority by itself.

## Goal

Give players a credible first view of the intended post-*Gothic* visual standard without altering Chapter One's locked investigation logic, narrative structure, routes, or interaction state. Phase 1 consists of one finished protagonist and one deliberately bounded environment slice.

## Walter Corwin

Walter is the first full character model because he remains visible throughout play and therefore improves every district immediately.

Working target:

- An angular, stylized early-2000s silhouette rather than realism.
- Approximately 10,000–18,000 triangles for the primary model, subject to live Web measurement.
- One full-color material atlas beneath Chapter One's monochrome presentation.
- A modest humanoid rig, approximately 25–40 deforming bones.
- Modular uniform coat, plain coat, hat, badge, boots, holster, and later equipment so the model can serve the existing coat state and the paper-doll interface.
- The current `CharacterBody3D`, collision body, camera target, movement code, interaction range, and save state remain authoritative.
- Locomotion remains code-driven without root motion. The rendered model follows the existing controller.

Initial animation set:

- idle;
- ordinary walk;
- brisk walk;
- turning and settling;
- short examine/interact gesture;
- restrained conversational gesture;
- sitting pose for later eavesdropping use;
- ground pickup.

### Ground pickup

The ground-pickup animation is required for the estate knife and pocket watch. Walter stops, faces the interaction, bends, and reaches toward the ground. The object disappears when his hand reaches the pickup point, then Walter stands and control returns.

The existing evidence/inventory operation remains authoritative. Animation must never be able to block progression: the visual removal can synchronize to an animation event, with a timeout or completion fallback that still commits the existing interaction. The knife and pocket watch share one animation in this phase.

## Mandatory glass-break checkpoint

Rendered Walter changes silhouette, pose, animation timing, and possible camera occlusion even if no narrative code changes. For that reason, environment modeling pauses after Walter integration until a complete in-game run confirms that the ending remains seamless.

The checkpoint covers:

- Walter's final position and silhouette;
- camera framing and obstruction;
- loss and restoration of player control;
- animation state at the break;
- glass geometry and presentation effects;
- sound timing;
- the final transition or end-state behavior.

The glass break is the visual benchmark for accepting Walter. If the new model weakens that beat, Walter's integration is not complete.

## Waterfront environment slice

After Walter passes the glass-break checkpoint, the waterfront becomes the first modeled district slice.

Reasons for choosing it:

- It has one principal street frontage, allowing a convincing composition without modeling an enclosed neighborhood.
- Quay, water, boats, props, and the offshore silhouette create depth beyond the playable footprint.
- Salt-worn timber, tar, rope, nets, rust, algae stone, and wet masonry form the town's clearest material identity.
- Several of Chapter One's deeper conversations occur there, so players have reason to remain in and study the finished space.
- Its asset family can later support the offshore whaling station and other working areas.

First bounded composition:

1. Quay and seawall.
2. One fishing boat.
3. Chandlery and net loft.
4. Freight office or fish store.
5. Lamps, bollards, crates, ropes, nets, and mooring equipment.
6. The offshore island and mud-covered whaling-station silhouette.

Buildings should use a reusable kit of walls, corners, windows, doors, roofs, foundations, and waterfront props. Existing gameplay geometry supplies placement and collision truth until each replacement is verified; simple purpose-built collision proxies should preserve that behavior.

The Chapter One island is provisional atmospheric staging, not the authoritative island design and not architectural or narrative foreshadowing. Chapter Two will establish the final island; once that environment exists, Chapter One's inaccessible distant version will be rebuilt from it at the appropriate reduced detail, silhouette, and viewing distance.

## Distance is authored

Anything visible to the player must show deliberate composition even when it is unreachable or uses a low-detail model.

**Atmospherically distant scenery** uses designed silhouettes, simplified roofs and chimneys, broad material groups, selective windows or lamps, and recognizable landmarks. The whaling station belongs to this category.

**Unfinished geometry** is development material. It must remain outside the composed view, sit behind a deliberate temporary occluder, or be replaced by a purpose-built skyline module. It cannot be presented as distant scenery merely by adding fog.

Distance reduces geometric and texture detail; it does not reduce intention.

## Phase boundary and acceptance

Phase 1 is complete when:

- Walter's rendered model and initial animations operate through the existing controller;
- uniform/plain-coat state remains correct;
- the knife and pocket watch use the ground-pickup beat without changing their game-state behavior;
- a full ending run confirms the glass break remains seamless;
- one coherent waterfront composition is rendered with intentional near, middle, and distant layers;
- current routes, collisions, interactions, dialogue, schedules, saves, and ending logic still pass their relevant checks;
- desktop and Web profiling show no player-visible stall or unacceptable memory increase.

The rest of the town remains outside this phase. Its procedural materials continue to provide the established visual baseline until this slice proves the modeling and animation pipeline.
