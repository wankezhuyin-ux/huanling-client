#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""换皮改名一致性自检。每次批量改名后跑一遍，避免「客户端认识、服务端不认识」。

检查项:
  1. ALL_ITEMS 键 == client-item-names.json 白名单（服务端按它校验，缺一条就报未知物品）
  2. ITEM_NAME_MIGRATION 的每个目标名都真实存在于 ALL_ITEMS（否则老存档会被改成不存在的名字）
  3. MARTIAL_ARTS_POOL == martial-arts.json
  4. 客户端 json 里是否还留着旧名（迁移表目标名之外的重复项）

退出码 0 = 全过；1 = 有问题。
"""
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER_DATA = os.path.join(os.path.dirname(ROOT), "deploy", "server", "data")
GD = os.path.join(ROOT, "scripts", "game_data.gd")


def block(text, const):
    m = re.search(r"^const %s(: =| =) \{" % re.escape(const), text, re.M)
    if not m:
        return ""
    depth, start = 0, m.end() - 1
    for i in range(start, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return text[start:i + 1]
    return ""


def main():
    text = io.open(GD, encoding="utf-8").read()
    items_block = block(text, "ALL_ITEMS")
    keys = re.findall(r'^\t"([^"]+)": \{', items_block, re.M)
    key_set = set(keys)

    problems = []

    allow_path = os.path.join(SERVER_DATA, "client-item-names.json")
    allow = json.load(io.open(allow_path, encoding="utf-8"))
    allow_set = set(allow.get("items", []))
    missing = key_set - allow_set
    extra = allow_set - key_set
    if missing:
        problems.append("白名单缺少 %d 项（服务端会拒绝发放）: %s" % (len(missing), "、".join(sorted(missing)[:5])))
    if extra:
        problems.append("白名单多出 %d 项（客户端已无此物品）: %s" % (len(extra), "、".join(sorted(extra)[:5])))

    mig = block(text, "ITEM_NAME_MIGRATION")
    targets = set(re.findall(r'"[0-9a-f]{8}": "([^"]+)"', mig))
    orphan = targets - key_set
    if orphan:
        problems.append("迁移表指向不存在的物品 %d 项: %s" % (len(orphan), "、".join(sorted(orphan)[:5])))

    pool_block = block(text, "MARTIAL_ARTS_POOL")
    pool_names = set(re.findall(r'"name": "([^"]+)", "effect_type"', pool_block))
    server_pool = json.load(io.open(os.path.join(SERVER_DATA, "martial-arts.json"), encoding="utf-8"))
    server_names = set()
    for rows in server_pool.get("realms", {}).values():
        for row in rows:
            server_names.add(row["name"])
    if pool_names != server_names:
        problems.append("武学池与 martial-arts.json 不一致：客户端多 %s / 少 %s"
                        % (sorted(pool_names - server_names)[:3], sorted(server_names - pool_names)[:3]))

    print("道具 %d 项 / 白名单 %d 项 / 迁移表 %d 条 / 武学 %d 条"
          % (len(key_set), len(allow_set), len(targets), len(pool_names)))
    if problems:
        for p in problems:
            print("  ✗", p)
        sys.exit(1)
    print("  ✓ 全部一致")


if __name__ == "__main__":
    main()
