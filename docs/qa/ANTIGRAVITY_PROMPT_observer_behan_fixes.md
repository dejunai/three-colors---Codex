# Antigravity: Observer and Behan dialogue fixes

**Context:** Dejunai has made the author calls below. This is content work only, in `dialogue/`. The authorities are Design Bible v18 (Part Two, "The Observers"; Design Law 5) and TDD v46 Part Four, "Still open," items 1, 2, 3 and 6.

**Rules** (see `AGENTS.md`):

- Check `git status` and `git branch` before editing and again before committing.
- Don't edit `docs/design/`.
- Don't push, merge, export or publish.
- Don't change any `TAG:`, `GATE:`, `LABEL:` id or `EVIDENCE:` id unless this prompt says to. Downstream gates depend on them:
  - `observer_stone_discipline` gates `harbor_observer` `drowned_island`;
  - `observer_color_tell` gates `net_seller.dialogue` line 112.
- Keep the existing `VOICE:` cue on each NPC line. For a new NPC line, reuse a cue already used in the same topic.

**The rule behind items 1–3 (Law 5):** the Observers' discipline and their color tell may appear only as a glimpse. No character, Walter included, may state where the discipline came from, what the tell is for, or connect the Ophion's loss to the insurance money. Refusals should be flat and unbothered, never spooked.

## 1. `harbor_observer.dialogue` — `TOPIC: drowned_island`

This fixes two problems. The origin speech states the Observers' history outright (Law 5). Walter's line about the try-works buildings "standing" contradicts the scenery, where the station is buried whole. Replace the topic body between `TIME: 7` and `EVIDENCE: island_memory` with the following. Keep the same `GATE`, `TAG`, `LABEL`, `TIME` and `EVIDENCE`:

```
  WALTER CORWIN: "Nobody takes dories out to the old whaling ruins anymore."
  VOICE: trombone_dismissive_short_v1
  MANUEL SILVA: "Nothing out there to catch."
  WALTER CORWIN: "There's a chimney standing up out of the mud. Somebody built a station out there once."
  VOICE: trombone_neutral_short_v2
  MANUEL SILVA: "Somebody did."
  [He resumes chipping, steady, flat strikes without anger or haste.]
  VOICE: trombone_haunting_long_v2
  MANUEL SILVA: "My grandfather never went out past the point. Neither did his.\nWe leave the mud where it settled."
  NOTEBOOK: observer_island_1 | "Manuel Silva on the drowned island: three generations of his family have not gone out past the point. 'We leave the mud where it settled.' He offered nothing further."
```

## 2. `harbor_observer.dialogue` — `TOPIC: the_ring`

The existing topic explains the tell ("to remind the eye what belongs to the daylight"). Walter's lines also assert the tell's history and purpose ("the observers… since long before I was born," "for a purpose"). Replace the `LABEL:` and the body between `TAG: observer_ring` and `EVIDENCE: observer_color_tell` with the following. Keep `GATE: coat = plain`, the `TAG` and the `EVIDENCE`:

```
  LABEL: "Ask about the ring on his hand"
  [The mason turns his hand slightly: a flattened copper ring, worn smooth by decades of granite work.]
  WALTER CORWIN: "That ring. I've seen the same on others down here."
  VOICE: trombone_neutral_medium_v1
  MANUEL SILVA: "An anchor link, beaten flat. My father wore it. His father before him."
  WALTER CORWIN: "What's it for?"
  [He looks at the ring, then at Walter, and goes back to the stone.]
  VOICE: trombone_bureaucratic_long_v2
  MANUEL SILVA: "It's for wearing, Officer.\n\nYou ask a great many questions.\nYou should ask yourself sometime whether you're trying to solve this town or just trying to become the next thing it forgets."
  NOTEBOOK: observer_ring_1 | "Manuel Silva wears a flattened copper anchor link as a ring, passed father to son for three generations. He would not say what it was for, and warned Walter against asking too far."
```

## 3. `harbor_observer.dialogue` — `TOPIC: estate_grounds_crew` notebook label

The notebook still calls him "Harbor mason." Replace only the `NOTEBOOK:` line:

```
  NOTEBOOK: observer_pantry_refusal | "Manuel Silva, asked about the harbor men on the estate crew who won't go near the pantry door: 'A sensible man doesn't put his hand where the stone is soft.'"
```

## 4. `groundskeeper.dialogue` — Abel's tell is a ring

Canon: Abel Tavares's tell is a colored **ring**, as in the Bible and the novellas. The rendered placeholder model's wrist bands, brooch and necklace are deliberately over-visible placeholders. Leave the model alone, and don't make the dialogue describe it. In the first `TOPIC: default` (`TAG: crew`), change the stage line:

- from: `…working fast in the cold, the dull copper band on his wrist catching the ember-light.…`
- to: `…working fast in the cold, the dull copper ring on his hand catching the ember-light.…`

Change nothing else in that line.

## 5. `father_behan.dialogue` — `behan_repeat_plain_graves`

Keep the first two sentences exactly. Replace the final sentence:

- from: `Since then, when a man comes to me with six names on a paper, I don't ask what kind of autumn he thinks he's having.`
- to: `Since then I've learned what it looks like when a town decides how many graves it's going to count.`

## Checks before calling it done

- Run `tests/dialogue_catalog_flow.gd`, `tests/instrument_voice_flow.gd`, `tests/dialogue_content_flow.gd` and `tests/audit_dialogue_ast.gd`, then the full `python tests/run_all_qa.py` (39 suites as of 2026-09-24).
- Search `harbor_observer.dialogue` for "remind the eye," "insurance," "big houses," "try-works" and "Mason". Expect zero hits.
- Search `groundskeeper.dialogue` for "wrist". Expect zero hits.
- Search the whole corpus for "influenza|flu|grippe|Spanish". Expect zero player-facing hits.
- Leave a short dated `docs/qa/` pass note that quotes the **actual** before and after lines, copied from the files rather than paraphrased, plus the test results. The TDD maintainer will verify it against source and fold it into the TDD and the Change Log.
