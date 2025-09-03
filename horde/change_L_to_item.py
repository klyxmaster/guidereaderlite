import os
import glob

def replace_L_with_item_in_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    new_content = content.replace('|L|', '|ITEM|')
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated: {filepath}")
    else:
        print(f"No change: {filepath}")

def main():
    lua_files = glob.glob('*.lua')
    for lua_file in lua_files:
        replace_L_with_item_in_file(lua_file)

if __name__ == "__main__":
    main()