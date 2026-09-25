# Upper-ridge residence model pass

Date: 2026-09-21
Branch: `feature/district-textures`
Scope: one upper-class landmark and a restrained generated-prop composition

## Selection

`assets/models/exteriors/estate_house.glb` now presents Residence No. 4 on the north frontage of the upper residential ridge. This placement lets its principal face look south across the street and downhill toward the town. It is a private upper-class home; it does not replace the investigation estate, whose terrace window, service entrance, lounge relationship, and evidence geometry remain purpose-built.

The property uses one generated fence/gate, two hedge sections, and two tree/bush clusters. The generated gate is visibly closed, so it sits on the side garden boundary; the main walk remains visibly open between the hedges. Concentrating the props on one residence makes maintained private grounds a class marker without turning the three assets into visible town-wide repetition.

## Gameplay boundary

The former procedural Residence No. 4 lives under `LegacyUpperResidenceCollisionVisuals` and is hidden as presentation while retaining the solid house footprint. Two simple hidden hedge proxies make the flanking greenery solid while leaving the central entrance approach open. The rendered house and landscape assets live under `RenderedUpperLandmarks`.

The existing `RESIDENCE No. 4` label, `route_upper_house_4`, separate interior, schedules, and street layout remain unchanged. No investigation or dialogue content is attached to the decorative landscape.

## Verification

- `tests/upper_exterior_model_flow.gd` checks both the contiguous and old-save upper layouts, all six rendered landmarks, hidden collision authority, and the stable interior route.
- `town_upper_residence` provides a focused live-render view for scale, open main approach, side-gate placement, hedge collision alignment, and downhill-facing composition.
- The maintained aggregate includes the focused model test.

No Web export or publication was performed.
