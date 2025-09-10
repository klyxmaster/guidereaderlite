import os
import re
import csv
import shutil

def load_npc_qid_gps(csv_path):
    qid_npc_coords = {}  # {qid: {npc_entry: [(x, y), ...]}}
    with open(csv_path, encoding="utf-8") as f:
        reader = csv.DictReader(f, delimiter=";")
        for row in reader:
            qid = row["quest_id"]
            npc_entry = row["npc_entry"]
            try:
                x, y = float(row["position_x"]), float(row["position_y"])
            except ValueError:
                continue
            qid_npc_coords.setdefault(qid, {}).setdefault(npc_entry, []).append((x, y))
    return qid_npc_coords

def compute_centroid(coords):
    if not coords:
        return None
    x_avg = sum(x for x, y in coords) / len(coords)
    y_avg = sum(y for x, y in coords) / len(coords)
    return round(x_avg, 1), round(y_avg, 1)

def update_guide_file(filepath, qid_npc_coords):
    # Make a .bak backup
    bak_path = filepath.rsplit('.', 1)[0] + '.bak'
    shutil.copy2(filepath, bak_path)

    with open(filepath, encoding="utf-8") as f:
        lines = f.readlines()
    new_lines = []
    # Match "C ..." or "G ..." with |QID|1234|
    qid_pattern = re.compile(r"^([CG]) [^\|]*\|QID\|(\d+)\|.*?(\|M\|[\d\.]+,[\d\.]+\|)?")
    for line in lines:
        m = qid_pattern.match(line)
        if m:
            step_type, qid, m_field = m.group(1), m.group(2), m.group(3)
            # Try all npc_entries for this qid and pick the one with most coords
            npc_entries = qid_npc_coords.get(qid, {})
            best_coords = []
            for npc_entry, coords in npc_entries.items():
                if len(coords) > len(best_coords):
                    best_coords = coords
            if best_coords:
                centroid = compute_centroid(best_coords)
                if centroid:
                    new_m = f"|M|{centroid[0]},{centroid[1]}|"
                    if m_field:
                        # Replace old M field
                        line = re.sub(r"\|M\|[\d\.]+,[\d\.]+\|", new_m, line)
                    else:
                        # Add M field (before first "|N|" or at end)
                        if "|N|" in line:
                            line = line.replace("|N|", f"{new_m} |N|")
                        else:
                            line = line.rstrip() + f" {new_m}\n"
        new_lines.append(line)
    with open(filepath, "w", encoding="utf-8") as f:
        f.writelines(new_lines)

def main():
    qid_npc_coords = load_npc_qid_gps("NPC-QID-GPS.csv")
    # Process all .lua files except LH_NPCData.lua
    for filename in os.listdir("."):
        if filename.endswith(".lua") and filename.lower() != "lh_npcdata.lua":
            update_guide_file(filename, qid_npc_coords)
            print(f"Updated {filename}, backup at {filename.rsplit('.', 1)[0] + '.bak'}")

if __name__ == "__main__":
    main()