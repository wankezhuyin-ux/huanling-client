#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 10-29「命名体系落地」改过的显示名全部改回原版。

用户要求：「所有的 宠物，物品，地图 名称全部改回原版」。

改名源表在 tools/build_name_table.py 里，每项都是 (原版名, 新名, 说明)，
方向是「原版 → 新版」。这里反向用，把新名换回原名。

改动的文件：
  客户端
    scripts/game_data.gd            ALL_ITEMS / 武学 / 宠物技能 / 技能书 / 套装
    scripts/maps_data_complete.gd   地图 key / name / description
    ui/main_ui.gd                   散落在 UI 文案里的名字
  服务端
    data/maps.json                  地图 key / name
    data/pet-catalog.json           宠物图鉴名
    data/items.json（若有）          道具名
    data/pet-rename.json / item-rename.json  改名迁移表（改成空表）
    data/map-rename.json            改名迁移表（改成空表）

用法：
    python3 tools/revert_names_to_original.py --dry-run
    python3 tools/revert_names_to_original.py --apply
"""

import argparse
import glob
import hashlib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_name_table as B

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(os.path.dirname(ROOT), "deploy", "server")


def collect_pairs():
    """收集全部 (新名, 原名) 对。"""
    pairs = {}

    # 地图
    for old, new in B.MAP_NEW.items():
        if old != new:
            pairs[new] = old

    # 道具
    for g in ("PILLS", "CULTIVATION", "HERBS", "MATERIALS", "GEAR",
              "EGGS", "SOULS", "CHESTS", "GIFTS", "GIFTS_HOLD"):
        for it in getattr(B, g, []):
            old, new = it[0], it[1]
            if old != new:
                pairs[new] = old

    # 武学
    for grp in B.ARTS:
        for old, new, _ in grp[1]:
            if old != new:
                pairs[new] = old

    # 宠物技能
    for old, new, _ in B.PET_SKILLS:
        if old != new:
            pairs[new] = old

    # 技能书
    for old, new, _ in B.BOOKS:
        if old != new:
            pairs[new] = old

    return pairs


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--only", default="", help="只处理名字里含该子串的")
    args = ap.parse_args()

    pairs = collect_pairs()
    # 长名优先，避免「小还墨」被「还墨」抢先替换
    order = sorted(pairs.keys(), key=len, reverse=True)
    print("改名对 %d 条（新名 → 原名）" % len(pairs))

    targets = []
    # 客户端 GDScript
    targets += glob.glob(os.path.join(ROOT, "scripts", "**", "*.gd"), recursive=True)
    targets += glob.glob(os.path.join(ROOT, "ui", "**", "*.gd"), recursive=True)
    # 服务端 JSON
    targets += glob.glob(os.path.join(SERVER, "data", "*.json"))

    total_files = 0
    total_hits = 0
    for path in targets:
        if os.sep + ".godot" + os.sep in path:
            continue
        try:
            s = open(path, encoding="utf-8").read()
        except Exception:
            continue
        orig = s
        hits = 0
        for new in order:
            if args.only and args.only not in new:
                continue
            old = pairs[new]
            n = s.count('"%s"' % new)
            if n:
                s = s.replace('"%s"' % new, '"%s"' % old)
                hits += n
            # 带坐标后缀的地图名："新名（x,y）"
            n2 = s.count("%s（" % new)
            if n2:
                s = s.replace("%s（" % new, "%s（" % old)
                hits += n2
            # 描述里的 "新名 - 坐标"
            n3 = s.count("%s - 坐标" % new)
            if n3:
                s = s.replace("%s - 坐标" % new, "%s - 坐标" % old)
                hits += n3
        if s != orig:
            total_files += 1
            total_hits += hits
            rel = os.path.relpath(path, os.path.dirname(ROOT))
            print("  %-60s %d 处" % (rel, hits))
            if args.apply:
                open(path, "w", encoding="utf-8").write(s)

    print("\n共 %d 个文件、%d 处%s" % (total_files, total_hits,
                                     "（已写入）" if args.apply else "（干跑，加 --apply 生效）"))

    if not args.apply:
        return 0

    # ---- 改名迁移表清空（不再需要迁移，直接就是原版名）----
    def write_empty_table(path, note):
        if not os.path.exists(path):
            return
        d = json.load(open(path, encoding="utf-8"))
        d["note"] = note
        d["count"] = 0
        d["map"] = {}
        json.dump(d, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
        print("  已清空迁移表:", os.path.basename(path))

    write_empty_table(
        os.path.join(SERVER, "data", "map-rename.json"),
        "地图名已全部改回原版，不再需要改名迁移（保留空表兼容老存档读取）。")
    write_empty_table(
        os.path.join(SERVER, "data", "pet-rename.json"),
        "宠物名已全部改回原版，不再需要改名迁移（保留空表兼容老存档读取）。")
    write_empty_table(
        os.path.join(SERVER, "data", "item-rename.json"),
        "道具名已全部改回原版，不再需要改名迁移（保留空表兼容老存档读取）。")

    # 客户端的迁移表常量（game_data.gd）同样清空
    gd = os.path.join(ROOT, "scripts", "game_data.gd")
    s = open(gd, encoding="utf-8").read()
    for const in ("MAP_NAME_MIGRATION", "ITEM_NAME_MIGRATION", "PET_NAME_MIGRATION"):
        m = re.search(r"const %s: = \{.*?\n\}" % const, s, re.S)
        if m:
            s = s[:m.start()] + ("const %s: = {}" % const) + s[m.end():]
            print("  已清空客户端常量:", const)
    open(gd, "w", encoding="utf-8").write(s)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
