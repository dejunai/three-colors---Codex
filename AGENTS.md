# AGENTS.md — who's who on Three Colors of Madness

This file exists because a prior Claude session working this project got overloaded, compacted its context too often, and corrupted state. A fresh session shouldn't have to reconstruct the team, the roles, or the verification discipline from 80KB of provenance log before it can be useful. Read this first.

The roster below is as the author (Dejunai) described it, not independently audited — same convention this project already uses elsewhere for a relayed claim ("reported," pending its own verification) versus one traced to source. Update it if the workflow changes; don't let it go stale the way the HCL did.

## The team

**Dejunai** — founder, sole developer, final decision-maker. Co-designer of the trilogy and co-author of the Design Bible. Wrote the initial short stories for each chapter as the canonical playthroughs. Edited every resistant and mixed-method playthrough draft. Co-generated the three original mixed-method premises with Perplexity. Author of much of the `.dialogue`/`.object`/`.portal` flat-file content.

**Claude** — two distinct environments, same model family, same capable DNA chain, different jobs:

- **Claude Sonnet 5 in Cowork** (this session, and its predecessors under the same setup) — co-designer and co-author of the Design Bible. Expanded Dejunai's canonical short stories to their current length. Solo-authored both resistant playthroughs (edited by Dejunai). Solo-authored the mixed-method narratives from Perplexity/Dejunai-generated briefs (edited by Dejunai). Its other recurring role — visible throughout `docs/qa/TDD_PENDING_NOTES.md` and the HCL, though never written down before this file — is independent verification: tracing a claim (from any source, including the author) to real source code or a real test execution before it's recorded as settled, and marking anything untraced as "reported, not confirmed" rather than accepting it at face value. See **Verification standard** below.
- **Claude Sonnet 5 in VS Code** — a separate session/environment, built the `.dialogue`/`.object`/`.portal` flat-file grammar systems (`*_lang.gd`/`*_runtime.gd`/`*_state.gd`) and their adapters, under the author's lead.

Sometimes credited as "Copilot" by GitHub's own tooling attribution regardless of which agent actually wrote the code — see the HCL's byline-correction entries. Neither environment retains the other's session memory; treat work attributed to "Claude" elsewhere in the docs/HCL as one of these two unless the entry says otherwise.

**Codex** — lead programmer for the project throughout.

**Antigravity** — co-author of `.dialogue`/`.object`/`.portal` content alongside Dejunai; does further authoring work whenever a global/systemic content change is implemented (e.g., the corpus-wide `TIME:` adjustment). Also has bug-hunting/bug-stomping as its designated specialty — not a restriction on anyone else: Codex and Claude fix bugs they encounter in the course of their own work same as always, this just names whose lane it is when a hunt needs assigning.

**Perplexity** — leads red-team analysis of the docs and code for logic gaps and inconsistencies (see `docs/qa/PERPLEXITY_REVIEW_TODO.md`). Co-generated the three original mixed-method story premises with Dejunai.

**Manus** — third-party auditor, a later arrival to the team; distinguished from the other reviewers by being able to actually play the game rather than only read source and docs.

**Grok-bot-minis** — red-team the conceptual commercial release (market/positioning concerns, not code or docs).

**Lumo and MetaAI** — consulted occasionally for outside assessments of the repository, usually after major updates; may or may not red-team the code depending on what's asked of them for that pass.

**Meshy.AI** — 3D asset contributor: character models, generic cast archetypes, corpses, quay/waterfront props, and exterior building models were all generated through Meshy under Dejunai's own artistic direction (poses, silhouettes, materials, and which real-world references to build from are his calls, not Meshy's). Much of this generation was driven through Meshy's own "Agent" product — a conversational, delegating workflow tool (their branding, trademarked as "Agent™") that takes a described asset and routes it to the appropriate underlying Meshy models/pipelines on its own. Meshy exports still need correction after generation — most notably per-asset scale, since exports normalize to a roughly uniform bounding box regardless of intended real-world size — which is why every model above got tuned against a known reference (Walter's height, an estate NPC, a doorway) before integration; see the HCL for the specific scale factors and commits.

## Verification standard

This is the load-bearing convention across the whole project history, made explicit here for the first time:

- A claim from any tool — including a summary from the author, relayed secondhand — is "reported" until it's been traced to real source or a real test run. Don't write it into a doc, and don't act on it, as settled fact before that.
- Prefer a captured log over a killed/inferred process observation. The HCL's `route_lower`/`town_expansion_flow.gd` saga (three different diagnoses across three revisions, v39–v42) is the standing cautionary tale for why: an unreliable process-kill observation got carried forward as "confirmed" for two full revisions before a cleanly captured log corrected it.
- Prefer running the actual test suite over trusting a dated `docs/qa/*.md` snapshot's stated pass/fail — those snapshots are provenance for the date they were written, not live status. `docs/DOC_SYNC_INCONSISTENCIES.md` is the current authority for Bible/TDD drift; the individual dated `docs/qa/` files are historical record.
- When two sources disagree (a tool's audit vs. live source, or an older doc vs. a newer one), say so explicitly rather than silently picking one — record both readings and which one the direct check confirmed.

## Working rules

Operational, not roster — how any agent should actually behave on this project, day to day:

- **Relayed agent output is advisory.** Pasting Grok's, Perplexity's, Manus's, or another agent's response into a session does not by itself authorize or endorse whatever it recommends. Nothing from it gets acted on or written into a doc as settled unless Dejunai explicitly says so — same standard as any other unverified claim, see **Verification standard** above.
- **Authority order**, highest first: Dejunai's current instruction → the Design Bible for canon → the TDD for intended implementation → live source/tests for actual behavior → the living docs (`README.md`, `docs/ARCHITECTURE.md`) → dated `docs/qa/*.md` reports. Earlier items override later ones when they conflict; a dated QA report never outranks a live test run.
- **Concurrent-work discipline.** Check the active branch and working tree — `git status`, `git branch` — before editing, and again immediately before committing. Other agents may switch branches, commit, export, or create files mid-session without warning. Never discard or silently absorb changes you didn't make; if something unexpected is sitting in the working tree, say so rather than overwriting it.
- **Publishing boundary.** Committing locally is fine. Pushing, merging, exporting a Web build, or publishing (GitHub Pages, itch.io, or anywhere else) requires an explicit request from Dejunai — don't infer it from "this seems done."
- **Documentation discipline.** Update the living implementation docs (`README.md`, `docs/ARCHITECTURE.md`) alongside the code changes that make them stale. Do not revise the Design Bible or the TDD unless specifically asked to; if source and the Bible/TDD disagree, record the discrepancy in `docs/DOC_SYNC_INCONSISTENCIES.md` rather than silently editing either document to match.
- **Definition of done.** Before calling something finished: run the relevant focused test, run the maintained aggregate (`python tests/run_all_qa.py`) when the change touches shared behavior, and visually inspect any UI/rendering change rather than trusting the test suite alone to catch it.
- **Incomplete-work handoff.** If a session limit, interruption, or context constraint cuts work short, leave a small, task-specific handoff note (what's done, what's not, what the next session needs to check first) rather than letting the next session reconstruct state from scratch.

## Where things live

- `docs/design/` — the Design Bible and TDD, the narrative/design and implementation authorities respectively.
- `docs/ARCHITECTURE.md`, `README.md` — current living implementation state.
- `docs/DOC_SYNC_INCONSISTENCIES.md` — current Bible/TDD-vs-source drift register.
- `docs/qa/*.md` — dated pass reports; historical record, not live status.
- The Historical Change Log (full provenance of every doc/tool pass across the project) lives **outside this repository**, in a sibling folder, for the moment. It is evidence-based by the same standard above and currently runs behind live `main` — new work (recent Codex/Antigravity/Perplexity/Manus passes) needs a verified catch-up pass before it's folded in, not a transcription of a summary.

## For a new session picking this up

Read, in order: this file, `README.md`, `docs/ARCHITECTURE.md`, `docs/DOC_SYNC_INCONSISTENCIES.md`. Then the Bible/TDD if design questions are in scope. Run `python tests/run_all_qa.py` yourself before trusting any stated pass/fail. Don't fold a relayed claim into a doc without tracing it first.
