#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 item-rename.json 的「旧名哈希 → 新名」表生成进 game_data.gd 的 ITEM_NAME_MIGRATION。

客户端只拿得到哈希，看不到旧名明文，解包也读不出历史名字。
用法: python3 tools/sync_item_migration.py [--check]
"""
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GD = os.path.join(ROOT, "scripts", "game_data.gd")
SRC = os.path.join(os.path.dirname(ROOT), "deploy", "server", "data", "item-rename.json")

BEGIN = "const ITEM_NAME_MIGRATION: = {"
END = "}"
PER_LINE = 3


def build(mapping):
    items = sorted(mapping.items())
    lines = [BEGIN]
    for i in range(0, len(items), PER_LINE):
        chunk = items[i:i + PER_LINE]
        lines.append("\t" + " ".join('"%s": "%s",' % (k, v) for k, v in chunk))
    lines.append(END)
    return "\n".join(lines)


def main():
    with io.open(SRC, encoding="utf-8") as f:
        data = json.load(f)
    mapping = data.get("map", {})

    with io.open(GD, encoding="utf-8") as f:
        text = f.read()

    # 只保留目标名真实存在的条目：改名表里混进不存在的物品，老存档会被改成
    # 「未知物品」，比不改还糟。
    items_block_start = text.find("const ALL_ITEMS = {")
    if items_block_start < 0:
        raise SystemExit("找不到 ALL_ITEMS")
    existing = set(re.findall(r'^\t"([^"]+)": \{', text[items_block_start:], re.M))
    dropped = {k: v for k, v in mapping.items() if v not in existing}
    if dropped:
        print("丢弃 %d 条无效条目（目标物品不存在）: %s"
              % (len(dropped), "、".join(sorted(dropped.values())[:4])))
        mapping = {k: v for k, v in mapping.items() if v in existing}

    start = text.find(BEGIN)
    if start < 0:
        # 第一次生成：插在 ALL_ITEMS 之前
        anchor = "const ALL_ITEMS = {"
        pos = text.find(anchor)
        if pos < 0:
            raise SystemExit("找不到插入位置")
        block = build(mapping) + "\n\n\n"
        text = text[:pos] + block + text[pos:]
        if "--check" not in sys.argv:
            with io.open(GD, "w", encoding="utf-8") as f:
                f.write(text)
            print("已插入 ITEM_NAME_MIGRATION（%d 条）" % len(mapping))
        return

    depth = 0
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i + 1
                break
    new_block = build(mapping)
    if text[start:end].strip() == new_block.strip():
        print("已一致（%d 条）" % len(mapping))
        return
    if "--check" in sys.argv:
        print("不一致，需要重新生成")
        sys.exit(2)
    text = text[:start] + new_block + text[end:]
    with io.open(GD, "w", encoding="utf-8") as f:
        f.write(text)
    print("已更新 ITEM_NAME_MIGRATION（%d 条）" % len(mapping))


if __name__ == "__main__":
    main()
