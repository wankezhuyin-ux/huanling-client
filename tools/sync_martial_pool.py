#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把服务端 data/martial-arts.json 的武学池同步进 game_data.gd 的 MARTIAL_ARTS_POOL。

真源只有一个（服务端 json），客户端常量由本脚本生成，避免两处漂移。
用法:
    python3 tools/sync_martial_pool.py           # 写入
    python3 tools/sync_martial_pool.py --check   # 只比对，不一致时退出码 2
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(os.path.dirname(ROOT), "deploy", "server", "data", "martial-arts.json")
GD = os.path.join(ROOT, "scripts", "game_data.gd")

BEGIN = "const MARTIAL_ARTS_POOL = {"


def build_block(pool):
    lines = [BEGIN]
    realms = pool.get("realms", {})
    for realm, rows in realms.items():
        lines.append('\t"%s": [' % realm)
        for row in rows:
            lines.append(
                '\t\t{"name": "%s", "effect_type": "%s", "base_value": %s, "desc": "%s"}, '
                % (row["name"], row["effect_type"], row["base_value"], row["desc"])
            )
        lines.append("\t], ")
    lines.append("}")
    return "\n".join(lines)


def find_block(text):
    start = text.find(BEGIN)
    if start < 0:
        raise SystemExit("找不到 MARTIAL_ARTS_POOL")
    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return start, i + 1
    raise SystemExit("MARTIAL_ARTS_POOL 括号不配对")


def main():
    with open(SRC, encoding="utf-8") as f:
        pool = json.load(f)
    with open(GD, encoding="utf-8") as f:
        text = f.read()

    new_block = build_block(pool)
    start, end = find_block(text)
    old_block = text[start:end]

    if old_block.strip() == new_block.strip():
        print("已一致，无需改动（%d 条）" % sum(len(v) for v in pool["realms"].values()))
        return

    if "--check" in sys.argv:
        print("不一致：game_data.gd 需要重新生成")
        sys.exit(2)

    with open(GD, "w", encoding="utf-8") as f:
        f.write(text[:start] + new_block + text[end:])
    print("已写入 %d 条武学（%d 境界）" % (sum(len(v) for v in pool["realms"].values()), len(pool["realms"])))


if __name__ == "__main__":
    main()
