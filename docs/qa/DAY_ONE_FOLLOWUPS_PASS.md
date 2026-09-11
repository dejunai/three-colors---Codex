# Day One follow-ups — a correction with a source

10 September 2026. Codex development pass authorized by Dejunai while three cold testers use the published build. Work is isolated on `dev/day-one-followups`, based on `fc7336a`. **Do not export Web, merge to main, or push this pass during that playtest without a new release instruction.**

## Lead audit and selected work

| Existing discovery | Current follow-up | Assessment |
| --- | --- | --- |
| Naomi's identification | Almy's meal ledger, estate-work inquiry, wage inquiry | Strong foundation; use the ledger for a visible consequence. |
| Gazette omits two deaths | Editor admits choosing six; Walter records the refusal | Selected gap: no way for a careful record to change the public account. |
| Historian's official account | Four distinct refusals, return to historian, covering letter, teacher | Already connected and covered by regression tests. |
| Staff work at the estate | First steward appointment, third plain-coat visit, day-book comparison | Already connected; keep three visits and montage. |
| Knife ownership | Kessler identifies the tool and describes the club | Useful corroboration; keep ownership distinct from proving its use. |
| Uncollected letters | Postmaster refuses custody; later county filing now waits on the earned postal trail | Bounded follow-up applied: later county wage-claim material no longer surfaces the mission/minor details before Walter earns them from the post office. |
| Foul-air account | Editor identifies Fenn's associate as its source | Leaves an attributable question. A later medical interview can pursue it; no new medical testimony invented here. |

The selected pass adds a modest, visible victory: a printed correction slip attached to unsold copies. It does not make the editor repent, force him to name a murderer, establish a cause, or erase copies already distributed.

## Playable sequence

1. Record the eight deaths and identify Naomi through Almy.
2. Challenge the editor's omission. Ask what he needs to correct the count and print Naomi's name.
3. He asks for the identification, the meal-ledger entry and the count in received paperwork. If not already done, return to Almy's ledger and file a dated supplement at the precinct.
4. Return to Halleck with those received pages. He prints a short correction: eight reported deaths, Naomi identified by Almy and corroborated by her ledger, the boy unnamed, cause unestablished.
5. Reading the newspaper again shows the original morning edition and a separate correction slip. Show the slip to Almy for her response. The two editions can also be compared through an optional link.

Both precinct-only filing and filing with a county copy qualify. Neither a county dispatch nor manual linking is a prerequisite. Earlier well-prepared paperwork is accepted immediately; there is no busywork requirement to submit it again. Someone who collected a clue *after* filing needs another dated supplement. The optional thread does not change sleep, montage, or main-story gates.

The editor's old refusal topics stop replaying after the correction. His unanswered inquiry about the original gas-story source remains available. Objective guidance acknowledges the pending correction while retaining the first steward appointment; the notebook gives the full source trail.

## Implementation and provenance

Built on Dejunai's Almy/editor dialogue, the existing report/supplement system, and the earlier Codex dialogue adapter. New dialogue in this pass is Codex-authored under Dejunai's permission to revise and interlink NPCs.

`dialogue_runtime.gd` adds a read-only gate function, `filed(evidence_id)`. It reads the received original report or received supplement snapshots/history. It does not treat currently held evidence as submitted, change any snapshot, or grant evidence/Perception. Existing save fields suffice; no schema migration is required.

The correction records `gazette_correction_terms` and `gazette_correction_printed`. Their descriptions come from authored NOTEBOOK text through the existing catalog. The later link is `public_count_corrected`. The original Gazette FACTS/SCENES and all received report copies remain unchanged. Later correction material is appended only when inspecting the newspaper after acquiring it.

The earlier wage-publicity fork retains its evidence ID for saved records, now requires Almy's wage lead, and describes her account rather than claiming Walter possesses a documented wage claim. No letters, claims, historical causes, or new family identities are inferred by this pass.

## Verification

- `press_correction_flow.gd`: held/draft evidence is insufficient; received original and historical supplements qualify; later discoveries do not appear retroactively; both filing choices work; partial dialogue does not print the slip; a live mid-print save resumes; time is charged once; original report/county/supplement snapshots remain unchanged; the newspaper keeps its original cards and adds a separate slip; the optional link and Almy response work.
- Catalog check: 29 concrete NPCs, 135 nonempty topics, parsing, numeric timing, repeat handling, evidence descriptions, all actor interaction targets and links.
- Social inquiry, live dialogue/save, town traversal/minimal progression, and staging/body/montage checks passed in an isolated current-project Godot copy.
- The sandboxed Godot checks emit a Windows root-certificate-store warning at shutdown; the test assertions pass. No network functionality is involved.

These are functional checks, not a cold playthrough. The open playtest question is whether the player's desire to correct the record carries them naturally from editor to ledger/counter and back.

## Playtest-build protection

No Web export command was run. All 12 files in `build/web` were SHA256-recorded before development and must match after application. Main and origin/main remain at `fc7336a`; no GitHub push is part of this pass. Testing uses isolated user-data folders, not the player's normal save.

Next decision: use today's tester feedback before choosing the next follow-up. The letters/family-source issue deserves a bounded continuity pass, but is not silently solved by this newspaper correction.
