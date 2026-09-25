import os, re
from collections import defaultdict

DIALOGUE_DIR = r"c:\Users\Dejunai\projects\three colors — Codex\dialogue"

def map_threads():
    files = [f for f in os.listdir(DIALOGUE_DIR) if f.endswith(".dialogue") and not f.startswith("background_npc")]
    
    threads = defaultdict(list)
    all_evidence = {}
    npc_topics = {}
    
    for fname in files:
        fpath = os.path.join(DIALOGUE_DIR, fname)
        with open(fpath, "r", encoding="utf-8") as f:
            lines = f.readlines()
            
        npc = fname.replace(".dialogue", "")
        current_topic = None
        
        for line in lines:
            line_str = line.strip()
            if not line_str or line_str.startswith("#"):
                continue
            if line_str.startswith("NPC:"):
                npc = line_str.split(":", 1)[1].strip()
                npc_topics[npc] = []
            elif line_str.startswith("TOPIC:"):
                t_id = line_str.split(":", 1)[1].strip()
                current_topic = {"id": t_id, "gate": "always", "label": "", "evidence": [], "notebook": [], "lines": []}
                npc_topics[npc].append(current_topic)
            elif current_topic:
                if line_str.startswith("GATE:"):
                    current_topic["gate"] = line_str.split(":", 1)[1].strip()
                elif line_str.startswith("LABEL:"):
                    current_topic["label"] = line_str.split(":", 1)[1].strip()
                elif line_str.startswith("EVIDENCE:"):
                    ev = line_str.split(":", 1)[1].strip()
                    current_topic["evidence"].append(ev)
                    all_evidence[ev] = (npc, current_topic["id"])
                elif line_str.startswith("NOTEBOOK:"):
                    current_topic["notebook"].append(line_str.split(":", 1)[1].strip())
                elif ":" in line_str and not line_str.startswith("VOICE:") and not line_str.startswith("TIME:") and not line_str.startswith("TAG:"):
                    spk, txt = line_str.split(":", 1)
                    if spk.strip() != "CHOICE" and spk.strip() != "FORK":
                        current_topic["lines"].append((spk.strip(), txt.strip()))

    print(f"Loaded {len(npc_topics)} NPCs.")
    
    # Let's inspect the mysteries:
    # 1. The Ophion wreck & 1823 founding fraud / lay debt
    # 2. Naomi Freeman & her son (the murdered mother & boy)
    # 3. The 6 dead cultists (Fenn, Kessler, Wexford, Corliss, Pruitt, and the unknown 6th)
    # 4. The Observers & the harbor / sunken island / mud flood
    # 5. The Undersea Tunnel / cellar / salt / mooring cables / strange phenomena
    
    with open("narrative_threads.txt", "w", encoding="utf-8") as out:
        for npc, topics in sorted(npc_topics.items()):
            out.write(f"\n========================================\nNPC: {npc}\n")
            for t in topics:
                out.write(f"  TOPIC: {t['id']} (LABEL: {t['label']})\n")
                out.write(f"    GATE: {t['gate']}\n")
                if t['evidence']:
                    out.write(f"    EVIDENCE: {', '.join(t['evidence'])}\n")
                if t['notebook']:
                    for nb in t['notebook']:
                        out.write(f"    NOTEBOOK: {nb[:100]}...\n")

    print("Wrote narrative_threads.txt")

if __name__ == "__main__":
    map_threads()
