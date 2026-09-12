#!/usr/bin/env python3
"""Seed uncued NPC lines with deterministic placeholder instrument voices."""

from __future__ import annotations

import argparse
import hashlib
import re
from pathlib import Path

DIRECTIVES = {
    "NPC", "LOCATION", "TOPIC", "GATE", "TAG", "TIME", "LABEL",
    "SCHEDULE", "INCLUDE", "CHOICE", "NOTEBOOK", "EVIDENCE", "VOICE",
}
SILENT_SPEAKERS = {
    "WALTER CORWIN", "WALTER'S NOTEBOOK", "THE KITCHEN WING YARD",
    "THE COVERING LETTER", "THE DAY BOOK", "THE GAZETTE — CORRECTION",
    "OUTSIDE THE SHUTTERED SHOP", "A CLEAN READ", "THE SMOKING LOUNGE",
}
VIOLIN_NPCS = {
    "chandlers_boy", "coroners_assistant", "coroners_assistant_morgue",
    "gatehouse_boy", "miss_wexley", "mrs_almy", "mrs_ashcroft",
    "mrs_pell", "mrs_whitlock", "old_woman", "school_parent",
    "schoolteacher", "widow_kessler",
}
ESTATE_REFERENCE = {
    "coroners_assistant", "gardener", "gatehouse_boy", "groundskeeper", "odell",
}

LINE_RE = re.compile(r'^(\s*)([^:#]+):\s*"(.*)$')

STYLE_RULES = (
    ("alarmed", ("!", "hurry", "look out", "what's left", "dead", "police")),
    ("angry", ("damn", "liar", "get out", "leave me", "how dare", "won't tolerate")),
    ("pleading", ("please", "i beg", "help me", "must understand", "forgive")),
    ("conspiratorial", ("quiet", "whisper", "between us", "don't repeat", "secret", "overheard")),
    ("haunting", ("drowned", "mother", "never came home", "beneath", "dream", "the tide", "the sea")),
    ("weary", ("tired", "again", "enough", "all day", "can't tell", "nothing more")),
    ("dismissive", ("no.", "nothing", "not my", "won't", "can't help", "that's all", "go away")),
    ("bureaucratic", ("report", "record", "file", "official", "county", "office", "form", "list", "book")),
    ("cautious", ("perhaps", "might", "maybe", "careful", "i don't know", "i couldn't", "not sure")),
    ("questioning", ("?",)),
    ("happy", ("glad", "good morning", "thank you", "welcome", "smile", "laugh")),
)


def choose_style(text: str) -> str:
    lowered = text.lower().replace("\\n", " ")
    for style, needles in STYLE_RULES:
        if any(needle in lowered for needle in needles):
            return style
    return "neutral"


def choose_length(text: str) -> str:
    words = re.findall(r"[A-Za-z0-9']+", text.replace("\\n", " "))
    if len(words) <= 8:
        return "short"
    if len(words) <= 26:
        return "medium"
    return "long"


def choose_take(npc: str, speaker: str, text: str) -> int:
    digest = hashlib.sha256(f"{npc}|{speaker}|{text}".encode("utf-8")).digest()
    return 1 + digest[0] % 2


def seed_file(path: Path) -> int:
    if path.name == "background_npc_template.dialogue":
        return 0
    source = path.read_text(encoding="utf-8")
    lines = source.splitlines(keepends=True)
    npc = ""
    for raw in lines:
        stripped = raw.strip()
        if stripped.startswith("NPC:"):
            npc = stripped[4:].strip()
            break
    if not npc:
        raise ValueError(f"{path}: missing NPC header")
    instrument = "violin" if npc in VIOLIN_NPCS else "trombone"
    output: list[str] = []
    pending_voice = False
    inserted = 0
    for raw in lines:
        stripped = raw.strip()
        if stripped.startswith("VOICE:"):
            pending_voice = True
            output.append(raw)
            continue
        match = LINE_RE.match(raw.rstrip("\r\n"))
        if not match:
            output.append(raw)
            continue
        speaker = match.group(2).strip()
        upper = speaker.upper()
        if upper in DIRECTIVES:
            output.append(raw)
            continue
        if pending_voice:
            pending_voice = False
            output.append(raw)
            continue
        if upper in SILENT_SPEAKERS:
            output.append(raw)
            continue
        text = match.group(3)
        style = choose_style(text)
        length = choose_length(text)
        take = choose_take(npc, upper, text)
        newline = "\r\n" if raw.endswith("\r\n") else "\n"
        output.append(f"{match.group(1)}VOICE: {instrument}_{style}_{length}_v{take}{newline}")
        output.append(raw)
        inserted += 1
    path.write_text("".join(output), encoding="utf-8", newline="")
    return inserted


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("dialogue_dir", nargs="?", default="dialogue")
    args = parser.parse_args()
    root = Path(args.dialogue_dir)
    total = 0
    for path in sorted(root.glob("*.dialogue")):
        total += seed_file(path)
    print(f"Seeded {total} previously silent NPC lines across {len(list(root.glob('*.dialogue')))} files.")


if __name__ == "__main__":
    main()
