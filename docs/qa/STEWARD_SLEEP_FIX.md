# Steward sleep blocker — 2026-09-11

Reported by Dejunai after completing the steward conversation: sleep still directed Walter to ask about staff records.

Root cause: chapter_one_dialogue.gd credited only the steward_first tag. With Almy's service_work evidence, the authored default branch is steward_first_lead, which completed and recorded testimony without incrementing steward_visits. The sleep and objective gates therefore continued to treat the steward as unvisited.

Codex fix: both first-conversation tags credit visit one on completion. CaseState.restore also repairs zero-count saves on days one/two when the completed barman visit and completed steward default topic are present. It does not credit merely opening an interrupted conversation, change evidence, advance time, or replace later visit counts. No save-version bump is required for this idempotent repair.

Validation: tests/steward_sleep_flow.gd exercises both live dialogue branches, unfinished conversation, restoration of the previously broken counter, sleep entry into the montage, and preservation of visit two on day three. Existing --qa-usability passes. Tests ran in an isolated copy with isolated application data.

Restart the updated game and load the existing save to apply the repair. The running web build requires a new export/deployment before it contains this fix. Existing build/web files were left untouched.
