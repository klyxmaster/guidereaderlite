#!/usr/bin/env python3
# Fix |M|x y| -> |M|x,y| (and trim spaces around comma) in *.lua files, recursively.
# Default: dry-run. Pass --write to actually modify files.

import re, sys, os
from pathlib import Path

SPACE_TO_COMMA = re.compile(r"(\d{1,3}(?:\.\d+)?)[ \t]+(\d{1,3}(?:\.\d+)?)")
TIDY_COMMA     = re.compile(r"(\d{1,3}(?:\.\d+)?)\s*,\s*(\d{1,3}(?:\.\d+)?)")
M_BLOCK        = re.compile(r"\|M\|([^|]*)\|")

def fix_m_block(m):
    body = m.group(1)
    # 1) x<space>y  -> x,y
    body2 = SPACE_TO_COMMA.sub(r"\1,\2", body)
    # 2) x , y      -> x,y
    body2 = TIDY_COMMA.sub(r"\1,\2", body2)
    return f"|M|{body2}|"

def process_file(p, write=False, backup_ext=".bak"):
    try:
        txt = p.read_text(encoding="utf-8", errors="ignore")
    except Exception as e:
        print(f"skip {p}: {e}")
        return 0,0
    before = txt
    after  = M_BLOCK.sub(fix_m_block, txt)
    if after != before:
        changes = 1
        diffs = len(SPACE_TO_COMMA.findall(before)) + len(TIDY_COMMA.findall(before))
        if write:
            if backup_ext:
                try:
                    Path(str(p)+backup_ext).write_text(before, encoding="utf-8", errors="ignore")
                except Exception as e:
                    print(f"backup failed {p}: {e}")
            p.write_text(after, encoding="utf-8", errors="ignore")
        return changes, diffs
    return 0,0

def main():
    # roots to scan (defaults to alliance + horde + current folder *.lua)
    roots = sys.argv[1:]
    write = False
    if "--write" in roots:
        write = True
        roots.remove("--write")
    if not roots:
        roots = ["alliance", "horde", "."]

    files = []
    for r in roots:
        rp = Path(r)
        if rp.is_file() and rp.suffix.lower()==".lua":
            files.append(rp)
        elif rp.exists():
            files.extend(rp.rglob("*.lua"))

    changed_files = 0
    total_diffs = 0
    for f in files:
        ch, df = process_file(f, write=write)
        changed_files += ch
        total_diffs  += df

    mode = "WROTE" if write else "DRY-RUN"
    print(f"{mode}: {changed_files} file(s) touched, ~{total_diffs} coord pair(s) normalized")

if __name__ == "__main__":
    main()
