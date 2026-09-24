# NPC model roster audit — 2026-09-23

The scheduled cast was audited against live dialogue identities rather than inferred from job titles or delivery instruments. Four confirmed women were misclassified because their runtime ids do not contain an honorific: Miriam Ashcroft, Eleanor Whitlock, Miss Hallowell (`schoolteacher`), and Mrs. Peake (`salt_mender`). They now select the appropriate female cast archetype. Ambiguous occupational characters were left unchanged.

Three story actors that already existed in scripts now receive rendered figures without creating new NPC identities or changing dialogue state:

- `morgue_coroner` uses the existing dedicated `coroner.glb` through `coroner_model.gd`.
- `intake_clerk` uses the upper-civilian male archetype behind the precinct desk; its interaction point remains on the accessible public side of the counter.
- Abel Tavares (`crew`) uses the Observer-man archetype and retains the unlit, fog-free red color tell required by the film shader.

Scheduled figures now receive an initial wrapper yaw based on their street side or interior entrance. When one becomes Walter's active interaction target, the wrapper turns toward Walter. This works above the common Meshy child-level PI import correction and does not change collision, schedules, target ids, or save state.

Verification is owned by `tests/cast_model_flow.gd`, `tests/observer_accent_flow.gd`, `tests/staff_model_integration_flow.gd`, and the aggregate QA runner. Visual judgment still requires an in-game walk through each district because automated tests can verify the selected mesh and orientation state but cannot judge whether every work pose reads naturally in its surroundings.
