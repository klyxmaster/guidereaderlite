import os
import re
import csv
import shutil

def load_qid_notes(csv_file):
    qid_notes = {}
    with open(csv_file, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter='\t', quotechar='"')
        for row in reader:
            qid = row['QID'].strip().strip('"')
            short = row['ObjectivesShort'].strip().strip('"')
            # Get the first sentence only
            first_sentence = short.split('.')[0].strip()
            if first_sentence and not first_sentence.endswith('.'):
                first_sentence += '.'
            qid_notes[qid] = first_sentence
    return qid_notes

def process_lua_file(filename, qid_notes):
    backup_filename = os.path.splitext(filename)[0] + '.bak'
    shutil.copyfile(filename, backup_filename)
    with open(backup_filename, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    qid_regex = re.compile(r'\|QID\|(\d+)\|')
    n_note_regex = re.compile(r'\|N\|.*?\|')
    # Pattern: step type (T/A/F), space, quest name, then tags
    step_type_regex = re.compile(r'^([TAFhC])\s+([^\|]+)')
    skip_steps = {'C', 'h'}

    new_lines = []
    for line in lines:
        qid_match = qid_regex.search(line)
        if not qid_match:
            new_lines.append(line)
            continue

        qid = qid_match.group(1)
        step_match = step_type_regex.match(line)
        if not step_match:
            new_lines.append(line)
            continue

        step_type, quest_name = step_match.groups()
        if step_type in skip_steps:
            new_lines.append(line)
            continue

        note = qid_notes.get(qid, '')
        if not note:
            new_lines.append(line)
            continue

        # Remove existing |N|..| (if present)
        line_wo_note = n_note_regex.sub('', line)

        # Find start of tags (first "|")
        first_tag_pos = line_wo_note.find('|')
        if first_tag_pos == -1:
            # No tags found, just append note after quest name
            insertion_pos = len(line_wo_note)
        else:
            insertion_pos = first_tag_pos

        # Compose new line: step type, quest name, |N|note|, then rest
        new_line = (
            line_wo_note[:insertion_pos] +
            f'|N|{note}|' +
            line_wo_note[insertion_pos:]
        )
        new_lines.append(new_line)

    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

def main():
    csv_file = 'questFullList.csv'
    qid_notes = load_qid_notes(csv_file)
    for fname in os.listdir('.'):
        if fname.endswith('.lua') and not fname.endswith('.lua.bak'):
            print(f'Processing {fname}')
            process_lua_file(fname, qid_notes)

if __name__ == '__main__':
    main()