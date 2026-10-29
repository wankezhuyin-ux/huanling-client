#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""宠物技能改名（第二批 B1-2）：17 种技能 + 82 本技能书。

名字体系「以画喻武」——笔势类：溅墨、连笔、护墨、逆锋、固色、吮墨……
一个技能改名会同时刷新 5 个等级、以及 5 个等级对应的技能书道具名。

用法:
    python3 tools/rename_pet_skills.py            # 干跑，只报将要改的数量
    python3 tools/rename_pet_skills.py --apply    # 实际写入
"""
import hashlib
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GD = os.path.join(ROOT, "scripts", "game_data.gd")
CFG = os.path.join(ROOT, "scripts", "pet_skill_config.gd")
BAG_SORT = os.path.join(ROOT, "scripts", "ui", "inventory_bag_sort.gd")
SERVER_DATA = os.path.join(os.path.dirname(ROOT), "deploy", "server", "data")

# 旧名 -> 新名（两字为主，前字表功能、后字归水墨）
SKILLS = {
    "溅射": "溅墨",
    "连射": "连笔",
    "神佑": "护墨",
    "反击": "逆锋",
    "坚固": "固色",
    "吸血": "吮墨",
    "迅捷": "疾笔",
    "长寿": "寿墨",
    "强壮": "壮笔",
    "凶猛": "烈墨",
    "必杀": "断锋",
    "自愈": "回润",
    "追击": "续笔",
    "忠心": "守纸",
    "嘲讽": "引锋",
    "破甲": "破纸",
    "格挡": "收锋",
}


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path, text):
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def rename_in(path, apply_it):
    """在指定文件里做三类替换：道具键前缀、name 字段、skill_name 字段。"""
    text = read(path)
    before = text
    hits = 0
    for old, new in SKILLS.items():
        # 技能书道具键与显示名：`"溅射lv1技能书"` 这种带等级前缀的
        pat = '"%slv' % old
        hits += text.count(pat)
        text = text.replace(pat, '"%slv' % new)
        # 纯技能名：`"name": "溅射"` / `"skill_name": "溅射"`
        for field in ("name", "skill_name"):
            pat = '"%s": "%s"' % (field, old)
            hits += text.count(pat)
            text = text.replace(pat, '"%s": "%s"' % (field, new))
    if apply_it and text != before:
        write(path, text)
    return hits


def update_bag_sort(apply_it):
    """背包排序里的稀有技能名前缀表要跟着换，否则稀有书不再置顶。"""
    text = read(BAG_SORT)
    m = re.search(r"const RARE_PET_SKILL_NAMES: = \[(.*?)\]", text, re.S)
    if not m:
        return 0
    old_list = re.findall(r'"([^"]+)"', m.group(1))
    new_list = [SKILLS.get(x, x) for x in old_list]
    if old_list == new_list:
        return 0
    body = "\n\t" + ", ".join('"%s"' % x for x in new_list) + ", \n"
    text = text[:m.start()] + "const RARE_PET_SKILL_NAMES: = [" + body + "]" + text[m.end():]
    if apply_it:
        write(BAG_SORT, text)
    return len(new_list)


def build_book_pairs():
    """生成 82 条「旧书 → 新书」对照，用于存档迁移与白名单。"""
    pairs = {}
    for old, new in SKILLS.items():
        for lv in range(1, 6):
            pairs["%slv%d技能书" % (old, lv)] = "%slv%d技能书" % (new, lv)
    return pairs


def hash8(text):
    return hashlib.md5(text.encode("utf-8")).hexdigest()[:8]


def rename_server_data(apply_it):
    """服务端 data/*.json 里的奖励池/说明文案也写着旧书名，不改会发出客户端不认识的名字。"""
    hits = 0
    for fn in sorted(os.listdir(SERVER_DATA)):
        if not fn.endswith(".json") or fn == "item-rename.json":
            continue
        path = os.path.join(SERVER_DATA, fn)
        text = read(path)
        before = text
        for old, new in SKILLS.items():
            pat = "%slv" % old
            hits += text.count(pat)
            text = text.replace(pat, "%slv" % new)
        if apply_it and text != before:
            write(path, text)
    return hits


def sync_client_names(apply_it):
    """重建 client-item-names.json：白名单必须与客户端 ALL_ITEMS 的键完全一致。"""
    text = read(GD)
    m = re.search(r"^const ALL_ITEMS = \{", text, re.M)
    if not m:
        return 0
    depth, end = 0, len(text)
    for i in range(m.end() - 1, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    keys = re.findall(r'^\t"([^"]+)": \{', text[m.end():end], re.M)
    out = os.path.join(SERVER_DATA, "client-item-names.json")
    payload = {
        "note": "客户端 game_data.gd ALL_ITEMS 的键名快照，服务端发道具前用它校验，"
                "避免发出客户端不认识的名字（邮件领取会报「未知物品」）",
        "count": len(keys),
        "items": keys,
    }
    if apply_it:
        with io.open(out, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=1)
    return len(keys)


def main():
    apply_it = "--apply" in sys.argv
    total = 0
    total += rename_in(GD, apply_it)
    total += rename_in(CFG, apply_it)
    total += update_bag_sort(apply_it)
    total += rename_server_data(apply_it)
    n_names = sync_client_names(apply_it)

    pairs = build_book_pairs()
    print("%s：技能表/配置替换 %d 处，技能书对照 %d 条，白名单 %d 条"
          % ("已写入" if apply_it else "干跑", total, len(pairs), n_names))

    if not apply_it:
        return

    # 旧名列表给服务端做存档迁移：只存「md5 前 8 位 → 新名」，不在包里留明文旧名
    migration = {hash8(k): v for k, v in pairs.items()}
    out = os.path.join(SERVER_DATA, "item-rename.json")
    payload = {
        "note": "道具改名迁移表。键是旧物品名的 md5 前 8 位，值是现用名。"
                "服务端读存档时按此表把老物品整形成新名；客户端 game_data.gd 的 "
                "ITEM_NAME_MIGRATION 由此生成，同样只存哈希。",
        "version": 1,
        "count": len(migration),
        "map": migration,
        "names": sorted(pairs.values()),
    }
    with io.open(out, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print("写出迁移表", out)
    print("旧名（内部核对用，不进包）:", " ".join(sorted(pairs)[:3]) + " ...")


if __name__ == "__main__":
    main()
