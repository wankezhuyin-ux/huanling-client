#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""落地地图改名（148 张命名，只换玩家看得见的名字，坐标不动）。

mapId 形如「浮影水城外郊（0,0）」，改名只替换括号前的名字，
所有以 mapId 为键的表（客户端地图表 / 怪物表 / 任务表 / 服务端 maps.json）同步替换。
同时重建 map-rename.json，供存档里 current_map / previous_map 迁移用。

用法：
  python3 tools/apply_map_names.py            # 干跑
  python3 tools/apply_map_names.py --apply    # 写入
"""

import io
import json
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_name_table as B

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(os.path.dirname(ROOT), "deploy", "server")


def pairs():
    """长名优先，避免「天关」吃掉「天关城」。"""
    return sorted(((a, b) for a, b in B.MAP_NEW.items() if a != b), key=lambda p: -len(p[0]))


def apply_text(text, ps):
    """两阶段替换：先全部换成占位符，再还原成新名。

    直接逐个 replace 会链式误伤（例如「过道」→「长过道」之后，
    已经变成「窄过道」的那条又被命中，长出「窄长过道」）。
    """
    holders = []
    for i, (old, new) in enumerate(ps):
        tag = "\x00M%d\x00" % i
        holders.append(tag)
        text = text.replace(old + "（", tag + "（")
        text = text.replace(old + " - 坐标", tag + " - 坐标")
        if len(old) >= 3:
            text = text.replace(old, tag)
    for (old, new), tag in zip(ps, holders):
        text = text.replace(tag, new)
    return text


def files():
    out = []
    for p in ("scripts/**/*.gd", "ui/**/*.gd", "dev/*.gd"):
        out += glob.glob(os.path.join(ROOT, p), recursive=True)
    out += glob.glob(os.path.join(ROOT, "dev", "*.json"))
    out += glob.glob(os.path.join(SERVER, "*.py"))
    out += glob.glob(os.path.join(SERVER, "handlers", "*.py"))
    out += [f for f in glob.glob(os.path.join(SERVER, "data", "*.json"))
            if not f.endswith("map-rename.json")]
    return [f for f in out if "restyle-backup" not in f]


def rebuild_rename_table():
    """map-rename.json：旧名 → 新名 + 域/地形/设定（美术和迁移共用）。"""
    path = os.path.join(SERVER, "data", "map-rename.json")
    old = json.load(io.open(path, encoding="utf-8")) if os.path.exists(path) else {}
    rows, _ = B.load_maps()
    table = {}
    for src, new, terr, zone in rows:
        setting = (old.get(src) or {}).get("setting", "")
        table[src] = {"name": new, "domain": zone, "terrain": terr, "setting": setting}
    doc = {
        "note": "地图改名表：原版名 → 新名。mapId 形如「名字（x,y）」，改名只换括号前的名字，"
                "坐标不动。服务端读档时按这张表迁移 current_map / previous_map。",
        "version": 2,
        "count": len(table),
        "map": table,
    }
    json.dump(doc, io.open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return table


def main():
    apply_it = "--apply" in sys.argv
    ps = pairs()
    changed = []
    for f in files():
        s = io.open(f, encoding="utf-8").read()
        n = apply_text(s, ps)
        if n != s:
            cnt = sum(s.count(a + "（") for a, _ in ps)
            changed.append((f, cnt))
            if apply_it:
                io.open(f, "w", encoding="utf-8").write(n)

    print("%s：%d 条规则，%d 个文件有改动"
          % ("已写入" if apply_it else "干跑", len(ps), len(changed)))
    for f, c in sorted(changed, key=lambda x: -x[1])[:10]:
        print("  %3d 个 mapId  %s" % (c, os.path.relpath(f)))

    if not apply_it:
        print("\n加 --apply 才真正写入")
        return

    table = rebuild_rename_table()
    print("map-rename.json 重建 %d 条" % len(table))


if __name__ == "__main__":
    main()
