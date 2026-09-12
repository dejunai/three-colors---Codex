import os
import re
import sys
import json
from collections import defaultdict

DIALOGUE_DIR = r"c:\Users\Dejunai\projects\three colors — Codex\dialogue"
SCRIPTS_DIR = r"c:\Users\Dejunai\projects\three colors — Codex\scripts"
ROOT_DIR = r"c:\Users\Dejunai\projects\three colors — Codex"

def analyze():
    files = [f for f in os.listdir(DIALOGUE_DIR) if f.endswith(".dialogue")]
    
    npcs = {}
    all_topics = defaultdict(dict) # npc -> {topic_id: topic_data}
    all_tags = defaultdict(dict) # npc -> {tag: topic_id}
    all_shared_tags = defaultdict(set) # tag/topic -> set of npcs
    all_evidence_emitted = defaultdict(list) # evidence_id -> list of (npc, topic)
    all_notebooks_emitted = defaultdict(list)
    all_voice_cues = []
    
    # Store raw parsed info
    dialogue_files_data = {}
    
    # Also collect evidence emitted by GDScript files (story.gd, case_state.gd, town_story.gd, etc.)
    game_evidence = set()
    gd_files = []
    for root, dirs, fnames in os.walk(ROOT_DIR):
        if ".git" in root or ".godot" in root:
            continue
        for fname in fnames:
            if fname.endswith(".gd"):
                gd_files.append(os.path.join(root, fname))
                
    for gdf in gd_files:
        with open(gdf, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
            # find evidence additions or checks
            # e.g., evidence.append("..."), discover("..."), state.evidence.has("...")
            ev_matches = re.findall(r'(?:discover|evidence\.append|evidence\.has|has_evidence|record_evidence)\s*\(\s*["\']([a-zA-Z0-9_]+)["\']', content)
            for ev in ev_matches:
                game_evidence.add(ev)
            # also look for string keys in FACTS dicts
            fact_matches = re.findall(r'["\']([a-zA-Z0-9_]+)["\']\s*:\s*\{', content)
            for fm in fact_matches:
                game_evidence.add(fm)

    print(f"Discovered {len(files)} dialogue files.")
    
    for fname in sorted(files):
        fpath = os.path.join(DIALOGUE_DIR, fname)
        with open(fpath, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        header = {}
        topics = []
        current_topic = None
        
        for idx, line in enumerate(lines):
            line_num = idx + 1
            stripped = line.strip()
            
            if not stripped or stripped.startswith("#"):
                continue
                
            indent = len(line) - len(line.lstrip())
            
            # Header
            if indent == 0 and not stripped.startswith("TOPIC:"):
                if ":" in stripped:
                    k, v = stripped.split(":", 1)
                    header[k.strip().upper()] = v.strip()
                continue
                
            if indent == 0 and stripped.startswith("TOPIC:"):
                topic_id = stripped.split(":", 1)[1].strip()
                current_topic = {
                    "id": topic_id,
                    "line": line_num,
                    "gate": None,
                    "tag": None,
                    "label": None,
                    "time": None,
                    "steps": [],
                    "evidence_emitted": [],
                    "notebook_emitted": [],
                    "voice_cues": [],
                    "raw_lines": []
                }
                topics.append(current_topic)
                continue
                
            if current_topic:
                current_topic["raw_lines"].append((line_num, indent, stripped))
                if stripped.startswith("GATE:"):
                    current_topic["gate"] = (line_num, stripped.split(":", 1)[1].strip())
                elif stripped.startswith("TAG:"):
                    current_topic["tag"] = (line_num, stripped.split(":", 1)[1].strip())
                elif stripped.startswith("LABEL:"):
                    current_topic["label"] = (line_num, stripped.split(":", 1)[1].strip())
                elif stripped.startswith("TIME:"):
                    current_topic["time"] = (line_num, stripped.split(":", 1)[1].strip())
                elif stripped.startswith("VOICE:"):
                    v_cue = stripped.split(":", 1)[1].strip()
                    current_topic["voice_cues"].append((line_num, v_cue))
                    all_voice_cues.append((fname, line_num, v_cue))
                elif stripped.startswith("EVIDENCE:"):
                    ev_id = stripped.split(":", 1)[1].strip()
                    current_topic["evidence_emitted"].append((line_num, ev_id))
                    all_evidence_emitted[ev_id].append((fname, current_topic["id"], line_num))
                elif stripped.startswith("NOTEBOOK:"):
                    nb_content = stripped.split(":", 1)[1].strip()
                    current_topic["notebook_emitted"].append((line_num, nb_content))
                    all_notebooks_emitted[nb_content].append((fname, current_topic["id"], line_num))
                    
        npc_name = header.get("NPC", fname.replace(".dialogue", ""))
        npcs[npc_name] = {
            "file": fname,
            "header": header,
            "topics": topics
        }
        
        for t in topics:
            all_topics[npc_name][t["id"]] = t
            all_shared_tags[t["id"]].add(npc_name)
            if t["tag"]:
                tag_id = t["tag"][1]
                all_tags[npc_name][tag_id] = t["id"]
                all_shared_tags[tag_id].add(npc_name)

    print(f"Parsed {len(npcs)} NPCs.")
    
    # Now, parse and analyze all GATE expressions
    # Function calls in gates:
    # visit_count(npc_id)
    # spoken_to(npc_id)
    # topic_done(npc_id, topic_or_tag)
    # topic_count(shared_topic_or_tag)
    # evidence(id)
    # filed(id)
    # flag(id)
    # properties: coat, day, phase, estate_complete, steward_ready
    
    issues = []
    
    call_pattern = re.compile(r'([a-zA-Z0-9_]+)\s*\(([^)]*)\)')
    
    for npc_name, data in npcs.items():
        fname = data["file"]
        for t in data["topics"]:
            if not t["gate"]:
                continue
            line_num, gate_str = t["gate"]
            if gate_str.strip() in ("always", "never"):
                continue
                
            # Check for illegal operators like ==, &&, ||, !
            if "==" in gate_str:
                issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': GATE uses '==' instead of '=': '{gate_str}'")
            if "&&" in gate_str:
                issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': GATE uses '&&' instead of 'AND': '{gate_str}'")
            if "||" in gate_str:
                issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': GATE uses '||' instead of 'OR': '{gate_str}'")
            # check for standalone ! not followed by =
            if re.search(r'!(?!=)', gate_str):
                issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': GATE uses '!' instead of 'NOT': '{gate_str}'")
                
            # Find function calls
            calls = call_pattern.findall(gate_str)
            for fn_name, args_str in calls:
                args = [a.strip().strip('"\'') for a in args_str.split(",") if a.strip()]
                
                if fn_name == "visit_count":
                    target_npc = args[0] if args else ""
                    if target_npc not in npcs:
                        issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': visit_count references unknown NPC '{target_npc}' in GATE: '{gate_str}'")
                elif fn_name == "spoken_to":
                    target_npc = args[0] if args else ""
                    if target_npc not in npcs:
                        issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': spoken_to references unknown NPC '{target_npc}' in GATE: '{gate_str}'")
                elif fn_name == "topic_done":
                    if len(args) < 2:
                        issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': topic_done with fewer than 2 arguments in GATE: '{gate_str}'")
                    else:
                        target_npc, target_topic_or_tag = args[0], args[1]
                        if target_npc not in npcs:
                            issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': topic_done references unknown NPC '{target_npc}' in GATE: '{gate_str}'")
                        else:
                            # check if target_topic_or_tag exists as topic or tag on target_npc
                            has_topic = target_topic_or_tag in all_topics[target_npc]
                            has_tag = target_topic_or_tag in all_tags[target_npc]
                            if not (has_topic or has_tag):
                                issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': topic_done references unknown topic/tag '{target_topic_or_tag}' on NPC '{target_npc}' in GATE: '{gate_str}'")
                elif fn_name == "topic_count":
                    if len(args) < 1:
                        issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': topic_count with no arguments in GATE: '{gate_str}'")
                    else:
                        target_id = args[0]
                        count_sources = len(all_shared_tags.get(target_id, set()))
                        if count_sources == 0:
                            issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': topic_count references '{target_id}' which is never used as topic or tag anywhere! GATE: '{gate_str}'")
                elif fn_name == "evidence":
                    if not args:
                        issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': evidence() with no argument in GATE: '{gate_str}'")
                    else:
                        ev_id = args[0]
                        # check if evidence is emitted or known in game_evidence
                        if ev_id not in all_evidence_emitted and ev_id not in game_evidence:
                            issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': evidence('{ev_id}') checked, but '{ev_id}' is never emitted in dialogue or known in game code! GATE: '{gate_str}'")
                elif fn_name == "filed":
                    if not args:
                        issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': filed() with no argument in GATE: '{gate_str}'")
                    else:
                        ev_id = args[0]
                        if ev_id not in all_evidence_emitted and ev_id not in game_evidence:
                            issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': filed('{ev_id}') checked, but '{ev_id}' is never emitted or known in game code! GATE: '{gate_str}'")
                elif fn_name == "flag":
                    pass # flags can be engine flags
                else:
                    issues.append(f"[{fname}:{line_num}] in topic '{t['id']}': Unknown function '{fn_name}' in GATE: '{gate_str}'")

    print("\n--- GATE AND DEPENDENCY ISSUES ---")
    if not issues:
        print("No gate or dependency issues found!")
    else:
        for iss in issues:
            print(iss)

    # Check Voice Cues
    print("\n--- VOICE CUES CHECK ---")
    audio_dir = os.path.join(ROOT_DIR, "assets", "audio", "instrument_voices")
    existing_wavs = set()
    if os.path.exists(audio_dir):
        existing_wavs = set(os.listdir(audio_dir))
    for fname, line_num, cue in all_voice_cues:
        wav_name = cue + ".wav"
        if wav_name not in existing_wavs:
            print(f"Missing audio file for voice cue '{cue}': {wav_name} (in {fname}:{line_num})")

    # Check Schedule Keys
    print("\n--- SCHEDULE KEYS CHECK ---")
    for npc_name, data in npcs.items():
        fname = data["file"]
        sched = data["header"].get("SCHEDULE", "")
        if sched:
            pairs = [p.strip() for p in sched.split(",") if p.strip()]
            for p in pairs:
                if "=" in p:
                    phase, loc = p.split("=", 1)
                    phase = phase.strip().lower()
                    if phase not in ["morning", "midday", "evening", "night"]:
                        print(f"Non-standard schedule phase '{phase}' in {fname}: '{p}'")

    # Summarize all Evidence IDs Emitted vs Checked
    print("\n--- EVIDENCE SUMMARY ---")
    all_ev_keys = sorted(list(all_evidence_emitted.keys()))
    print(f"Total distinct evidence IDs emitted by dialogue: {len(all_ev_keys)}")
    for ev in all_ev_keys:
        sources = [f"{s[0]}:{s[1]}" for s in all_evidence_emitted[ev]]
        print(f"  {ev}: emitted by {sources}")

if __name__ == "__main__":
    analyze()
