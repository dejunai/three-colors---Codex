# Coroner's assistant model pass — 2026-09-23

The estate and returning morgue coroner's assistant now use the female Meshy model supplied as `Meshy_Female-Coroner-Assist-Animations.glb`, integrated as `assets/models/coroners_assistant.glb`. The source asset contains one skinned mesh (16,983 triangles), a 2048×2048 embedded texture, and seven animation clips.

The new `scripts/shared/coroners_assistant_model.gd` adapter maps the asset's authored clip names onto the existing semantic contract:

- `Idle_11` → `Idle`
- `Idle_3` → `Idle_Alt`
- `Stand_and_Chat` → `Confer`

The adapter retains the established 1.18 scale, placement, focus distance, dialogue identity, schedules, and save behavior. The previous male `assets/models/coroner.glb` remains available for the actual coroner; this pass does not alter the concurrently authored `morgue_coroner` placement work.

Verification lives in `tests/coroners_assistant_model_flow.gd`, the updated live-scene `tests/coroner_model_integration_flow.gd`, `tests/check_model_textures.gd`, and the `--capture=coroners_assistant` presentation capture.
