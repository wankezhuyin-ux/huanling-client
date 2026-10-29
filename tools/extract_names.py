#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 game_data.gd 里的道具/技能/武学名抽成 JSON，供改名对照与批量替换使用。

用法:
    python3 tools/extract_names.py            # 打印统计
    python3 tools/extract_names.py --dump     # 写出 build/names-raw.json
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GD = os.path.join(ROOT, "scripts", "game_data.gd")
OUT = os.path.join(ROOT, "build", "names-raw.json")

RE_ITEM = re.compile(r'^\t"([^"]+)": \{"name": "([^"]+)", "type": "([^"]+)"(?:, "rarity": "([^"]+)")?')


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def slice_block(text, const_name):
    """截取 `const NAME = {` 到与之配对的收尾 `}` 之间的文本。"""
    m = re.search(r"^const %s = \{" % re.escape(const_name), text, re.M)
    if not m:
        return ""
    start = m.end() - 1
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    return ""


def main():
    text = read(GD)

    items = []
    block = slice_block(text, "ALL_ITEMS")
    for line in block.splitlines():
        m = RE_ITEM.match(line)
        if m:
            items.append({
                "id": m.group(1),
                "name": m.group(2),
                "type": m.group(3),
                "rarity": m.group(4) or "",
            })

    # 武学池：按境界分组
    arts = {}
    block = slice_block(text, "MARTIAL_ARTS_POOL")
    realm = None
    for line in block.splitlines():
        r = re.match(r'^\t"([^"]+)": \[', line)
        if r:
            realm = r.group(1)
            arts[realm] = []
            continue
        a = re.search(r'\{"name": "([^"]+)", "effect_type": "([^"]+)"', line)
        if a and realm:
            arts[realm].append({"name": a.group(1), "effect": a.group(2)})

    # 宠物技能：skill_id -> 中文名（同名多级去重）
    pet_skills = {}
    block = slice_block(text, "PET_SKILLS")
    for line in block.splitlines():
        m = re.search(r'"skill_id": "([^"]+)", "name": "([^"]+)"', line)
        if m:
            pet_skills.setdefault(m.group(2), set()).add(m.group(1))
    pet_skills = {k: sorted(v) for k, v in pet_skills.items()}

    data = {"items": items, "martial_arts": arts, "pet_skills": pet_skills}

    if "--dump" in sys.argv:
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        with open(OUT, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
        print("写出", OUT)

    print("道具 %d 条" % len(items))
    by_type = {}
    for it in items:
        by_type.setdefault(it["type"], []).append(it)
    for t, v in sorted(by_type.items(), key=lambda kv: -len(kv[1])):
        print("  %-22s %3d" % (t, len(v)))
    print("武学 %d 条 / %d 个境界" % (sum(len(v) for v in arts.values()), len(arts)))
    for r, v in arts.items():
        print("  %-8s %d" % (r, len(v)))
    print("宠物技能 %d 种" % len(pet_skills))
    print("  " + " / ".join(pet_skills.keys()))


if __name__ == "__main__":
    main()
