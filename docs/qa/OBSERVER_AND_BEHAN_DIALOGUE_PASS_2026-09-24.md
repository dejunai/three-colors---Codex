# Observer and Behan dialogue pass — 24 September 2026

**Context:** Content adjustments in `dialogue/` per Design Bible v18 (Part Two, "The Observers"; Design Law 5) and TDD v46 Part Four, "Still open," items 1, 2, 3 and 6. Enforces Law 5: the Observers' discipline and color tell appear only as a glimpse; no character states origin or purpose, or connects the Ophion's loss to insurance money; refusals remain flat and unbothered.

---

## 1. `harbor_observer.dialogue` — `TOPIC: drowned_island`

### Before
```dialogue
  WALTER CORWIN: "Nobody takes dories out to the old whaling ruins anymore."
  VOICE: trombone_dismissive_short_v1
  MANUEL SILVA: "Nothing out there to catch."
  WALTER CORWIN: "The try-works buildings are still standing above the mud."
  VOICE: trombone_neutral_short_v2
  MANUEL SILVA: "Standing isn't the same as welcoming."
  [He resumes chipping, steady, flat strikes without anger or haste.]
  VOICE: trombone_haunting_long_v2
  MANUEL SILVA: "Our grandfathers learned in a single night what looking at that water costs.\nThose who came back couldn't tell the same story twice.\nThe insurance paid the big houses on the hill; the sea kept the men.\nWe leave the mud where it settled."
  NOTEBOOK: observer_island_1 | "Mason on the drowned island: 'Our grandfathers learned in a single night what looking at that water costs... We leave the mud where it settled.'"
```

### After
```dialogue
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

---

## 2. `harbor_observer.dialogue` — `TOPIC: the_ring`

### Before
```dialogue
TOPIC: the_ring
  GATE: coat = plain
  TAG: observer_ring
  LABEL: "Ask about the copper ring on his hand"
  WALTER CORWIN: "That copper band on your hand. The observers on the water have worn those colored links since long before I was born."
  [The mason turns his hand slightly, the reddish-brown metal familiar against the grey stone, worn smooth by decades of granite work.]
  VOICE: trombone_neutral_medium_v1
  MANUEL SILVA: "An anchor link beaten flat. Worn since my father's time, and his father before him."
  WALTER CORWIN: "The old people along the slipway say the observers wear them for a purpose."
  VOICE: trombone_bureaucratic_long_v2
  MANUEL SILVA: "To remind the eye what belongs to the daylight.\n\nYou ask a great many questions, Officer.\nYou should ask yourself sometime whether you're trying to solve this town or just trying to become the next thing it forgets."
  NOTEBOOK: observer_ring_1 | "The harbor observers have worn colored anchor links for generations to 'remind the eye what belongs to daylight.' Warned Walter against asking too far."
  EVIDENCE: observer_color_tell
```

### After
```dialogue
TOPIC: the_ring
  GATE: coat = plain
  TAG: observer_ring
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
  EVIDENCE: observer_color_tell
```

---

## 3. `harbor_observer.dialogue` — `TOPIC: estate_grounds_crew` Notebook Label

### Before
```dialogue
  NOTEBOOK: observer_pantry_refusal | "Harbor mason on grounds crew avoiding pantry: 'A sensible man doesn't put his hand where the stone is soft.'"
```

### After
```dialogue
  NOTEBOOK: observer_pantry_refusal | "Manuel Silva, asked about the harbor men on the estate crew who won't go near the pantry door: 'A sensible man doesn't put his hand where the stone is soft.'"
```

---

## 4. `groundskeeper.dialogue` — Abel's Tell is a Ring

### Before
```dialogue
  THE KITCHEN WING YARD: "A groundskeeper stacks crates beside a banked fire, working fast in the cold, the dull copper band on his wrist catching the ember-light. The service door stands a few feet off. He never sets a crate nearer to it than the last."
```

### After
```dialogue
  THE KITCHEN WING YARD: "A groundskeeper stacks crates beside a banked fire, working fast in the cold, the dull copper ring on his hand catching the ember-light. The service door stands a few feet off. He never sets a crate nearer to it than the last."
```

---

## 5. `father_behan.dialogue` — `behan_repeat_plain_graves`

### Before
```dialogue
  FATHER BEHAN: "The ground settled uneven on the east side of the wall. That whole row went down in three weeks back in eighteen.\nI wore through two spade helves before the frost broke. Since then, when a man comes to me with six names on a paper, I don't ask what kind of autumn he thinks he's having."
```

### After
```dialogue
  FATHER BEHAN: "The ground settled uneven on the east side of the wall. That whole row went down in three weeks back in eighteen.\nI wore through two spade helves before the frost broke. Since then I've learned what it looks like when a town decides how many graves it's going to count."
```

---

## Verification & Corpus Checks

1. **`harbor_observer.dialogue` Search Checks:**
   - `remind the eye`: 0 hits
   - `insurance`: 0 hits
   - `big houses`: 0 hits
   - `try-works`: 0 hits
   - `Mason`: 0 hits

2. **`groundskeeper.dialogue` Search Check:**
   - `wrist`: 0 hits

3. **Whole Corpus Check:**
   - Regex `\b(influenza|flu|grippe|Spanish)\b` across `dialogue/`, `objects/`, `portals/`: 0 player-facing hits.

4. **Automated Test Results:**
   - `tests/dialogue_catalog_flow.gd`: PASS (73 NPCs, 468 topics)
   - `tests/instrument_voice_flow.gd`: PASS (144-cue manifest, 745 NPC lines)
   - `tests/dialogue_content_flow.gd`: PASS (All cast reverse-engineered, clean gating)
   - `tests/audit_dialogue_ast.gd`: PASS (73 definitions, 0 errors, 0 warnings)
   - `python tests/run_all_qa.py`: ALL 39 QA SUITES PASSED CLEANLY.
