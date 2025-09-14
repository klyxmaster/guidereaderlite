# -*- coding: utf-8 -*-
"""
add_m_coords_from_questie.py

Parse wotlkNpcDB.lua to map quest IDs -> NPC spawn coords (for quest starts/ends).
Then walk a guides folder and, for any step line containing |QID|xxx| that
doesn't already include an |M|…| tag, append "  |M|x y|" using coords from the DB.

Rules:
- If the action starts with 'A ' (Accept), prefer quest-start coords.
- If 'T ' (Turn in), prefer quest-end coords.
- Otherwise prefer quest-end coords; fall back to quest-start if needed.
- Always ensure at least two spaces before the injected |M| tag.
- Detect existing |M| in either "|M|x,y|" or "|M|x y|" forms and skip those lines.
- Edits in-place and writes a ".bak" backup per file.

Usage: local per folder
python add_m_coords_from_questie.py --npcdb wotlkNpcDB.lua --guides .
"""

import argparse
import os
import re
from typing import Dict, List, Optional, Tuple

FLOAT_PAIR_RE = re.compile(r"\{\s*([0-9]+(?:\.[0-9]+)?)\s*,\s*([0-9]+(?:\.[0-9]+)?)\s*\}")
HAS_M_RE = re.compile(r"\|M\|\s*\d+(?:\.\d+)?\s*(?:,|\s)\s*\d+(?:\.\d+)?\s*\|")
QID_RE = re.compile(r"\|QID\|\s*(\d+)\s*\|")
ACTION_RE = re.compile(r"^\s*([ATC]\b)", re.IGNORECASE)

def split_top_level_commas(s: str) -> List[str]:
    """Split on commas that are at top-level (not inside braces)."""
    parts: List[str] = []
    depth = 0
    start = 0
    for i, ch in enumerate(s):
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth = max(depth - 1, 0)
        elif ch == "," and depth == 0:
            parts.append(s[start:i].strip())
            start = i + 1
    tail = s[start:].strip()
    if tail:
        parts.append(tail)
    return parts

def extract_return_block(text: str) -> str:
    idx = text.find("return")
    if idx == -1:
        raise ValueError("Could not find 'return' in wotlkNpcDB.lua")
    brace_idx = text.find("{", idx)
    if brace_idx == -1:
        raise ValueError("Could not find '{' after 'return'")
    depth = 0
    start = brace_idx
    for i in range(brace_idx, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start:i+1]
    raise ValueError("Unbalanced braces")

def iter_npc_entries(ret_block: str):
    i = 0
    n = len(ret_block)
    while i < n:
        m = re.search(r"\[(\d+)\]\s*=\s*\{", ret_block[i:])
        if not m:
            break
        npc_id = int(m.group(1))
        entry_start = i + m.end() - 1
        depth = 0
        end = entry_start
        while end < n:
            if ret_block[end] == "{":
                depth += 1
            elif ret_block[end] == "}":
                depth -= 1
                if depth == 0:
                    yield npc_id, ret_block[entry_start+1:end]
                    i = end + 1
                    break
            end += 1
        else:
            break

def parse_npcdb(npcdb_path: str):
    with open(npcdb_path, "r", encoding="utf-8", errors="ignore") as f:
        text = f.read()
    ret_block = extract_return_block(text)
    qid_to_start, qid_to_end = {}, {}
    for _, entry in iter_npc_entries(ret_block):
        fields = split_top_level_commas(entry)
        if len(fields) < 11:
            continue
        spawns_field = fields[6].strip()
        coords = None
        if spawns_field.lower() != "nil":
            mcoords = FLOAT_PAIR_RE.search(spawns_field)
            if mcoords:
                coords = (float(mcoords.group(1)), float(mcoords.group(2)))
        if not coords:
            continue
        starts_field, ends_field = fields[9], fields[10]
        starts = [int(q) for q in re.findall(r"\d+", starts_field)] if starts_field.lower() != "nil" else []
        ends = [int(q) for q in re.findall(r"\d+", ends_field)] if ends_field.lower() != "nil" else []
        for qid in starts:
            qid_to_start.setdefault(qid, []).append(coords)
        for qid in ends:
            qid_to_end.setdefault(qid, []).append(coords)
    return qid_to_start, qid_to_end

def pick_coords(qid: int, action: str, start_map, end_map):
    action = action.upper()
    if action == "A":
        return (start_map.get(qid) or end_map.get(qid) or [None])[0]
    if action == "T":
        return (end_map.get(qid) or start_map.get(qid) or [None])[0]
    return (end_map.get(qid) or start_map.get(qid) or [None])[0]

def process_file(path, start_map, end_map):
    changed = False
    with open(path, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
    new_lines = []
    for line in lines:
        if "|QID|" not in line or HAS_M_RE.search(line):
            new_lines.append(line)
            continue
        mqid = QID_RE.search(line)
        if not mqid:
            new_lines.append(line)
            continue
        qid = int(mqid.group(1))
        maction = ACTION_RE.match(line)
        action = maction.group(1)[0].upper() if maction else "C"
        coords = pick_coords(qid, action, start_map, end_map)
        if not coords:
            new_lines.append(line)
            continue
        x, y = coords
        updated = f"{line.rstrip()}  |M|{x:.2f} {y:.2f}|\n"
        new_lines.append(updated)
        if updated != line:
            changed = True
    if changed:
        with open(path + ".bak", "w", encoding="utf-8") as fb:
            fb.writelines(lines)
        with open(path, "w", encoding="utf-8") as fw:
            fw.writelines(new_lines)
    return changed

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--npcdb", required=True)
    ap.add_argument("--guides", required=True)
    args = ap.parse_args()
    print(f"Loading NPC DB: {args.npcdb}")
    start_map, end_map = parse_npcdb(args.npcdb)
    total = changed = 0
    for root, _, files in os.walk(args.guides):
        for fn in files:
            if fn.lower().endswith((".lua", ".txt")):
                total += 1
                if process_file(os.path.join(root, fn), start_map, end_map):
                    changed += 1
    print(f"Processed {total} files, modified {changed}. Backups created.")
if __name__ == "__main__":
    main()
