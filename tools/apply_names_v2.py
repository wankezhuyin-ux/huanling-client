#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按《命名对照全表 v2》落地改名（道具 / 武学 / 宠物技能 / 技能书 / 套装）。

要点：
- 只改玩家看得见的显示名和存档键，**同时重建改名迁移表**，老存档读档自动换名。
- 迁移表同时覆盖「原版名」和「上一版文雅名」，两代存档都不会变成未知物品。
- 地图不在此脚本内（mapId 带坐标、可能被位置字段引用，单独一批处理）。

用法：
  python3 tools/apply_names_v2.py            # 干跑，只打印将改多少处
  python3 tools/apply_names_v2.py --apply    # 真正写入
"""

import io
import json
import glob
import hashlib
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import build_name_table as B

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(os.path.dirname(ROOT), "deploy", "server")

# ---------------------------------------------------------------- 当前代码里的名字 → 最终名
# 武学：上一版（画法术语）→ 通俗版
ARTS_PREV = {
    "匀息描": "吐纳功", "积染桩": "强身术", "罩染功": "铁布衫", "飞白步": "疾风步",
    "顿笔捶": "蛮牛劲", "含毫诀": "蓄墨诀", "养砚功": "养生诀",
    "游丝描": "仙鹤功", "重彩罩": "金刚身", "掠水痕": "踏水步", "破锋掌": "破山掌",
    "行云笔": "行墨诀", "宿墨养真": "长春功",
    "紫毫功": "紫云功", "铁线描": "不动身", "留白步": "踏雪步", "泼墨式": "移山劲",
    "藏锋诀": "归真诀", "朱砂护": "烈阳功",
    "永字诀": "无字经", "金碧罩": "不坏身", "一笔千里": "缩地功", "万毫齐力": "万剑归一",
    "凝毫诀": "凝墨诀", "长青皴": "不死身",
    "一气呵成": "混元劲", "不坏丹青": "万劫身", "瞬息落纸": "瞬息千里", "斧劈皴": "开天劲",
    "玄渊诀": "玄罡诀", "绢寿千年": "长生身",
    "墨寿无疆": "同寿功", "金刚罩染": "铁壁功", "破纸行": "破空行", "焦墨燎原": "破灭劲",
    "造化凝锋": "造化功", "生宣长存": "生生不息", "点苔封穴": "点穴手", "露锋": "破军劲",
    "焦笔重按": "重击诀",
}

# 宠物技能：上一版（笔势）→ 通俗版。溅墨不变，不入表
PETS_PREV = {
    "连笔": "连击", "护墨": "护主", "逆锋": "反打", "固色": "硬皮", "吮墨": "饮血",
    "疾笔": "轻身", "寿墨": "长命", "壮笔": "力壮", "烈墨": "凶性", "断锋": "致命",
    "回润": "自复", "续笔": "追杀", "守纸": "守主", "引锋": "挑衅", "破纸": "破防",
    "收锋": "挡伤",
}

BOOKS_PREV = {"三锋齐下": "一击三伤", "以墨养墨": "以血养血"}


def item_pairs():
    """道具：原版名 → 新名（这些还没动过，代码里就是原版名）。"""
    out = []
    for grp in (B.PILLS, B.CULTIVATION, B.HERBS, B.MATERIALS, B.GEAR,
                B.EGGS, B.SOULS, B.CHESTS, B.GIFTS, B.GIFTS_HOLD):
        for old, new, _ in grp:
            if old != new:
                out.append((old, new))
    out += [(old, new) for old, new, _ in B.BOOKS if old != new]
    return out


def art_pairs():
    return [(old, new) for _, its in B.ARTS for old, new, _ in its if old != new]


def pet_pairs():
    return [(old, new) for old, new, _ in B.PET_SKILLS if old != new]


def all_pairs():
    pairs = []
    pairs += ARTS_PREV.items()
    pairs += PETS_PREV.items()
    pairs += BOOKS_PREV.items()
    pairs += item_pairs()
    pairs += [(a, b) for a, b, _ in B.SUITS if a != b]
    # 长名优先，避免「小还丹」被「还丹」类短串切开
    return sorted(set(pairs), key=lambda p: -len(p[0]))


def apply_text(text, pairs):
    for old, new in pairs:
        if old in text:
            text = text.replace(old, new)
    return text


def gd_files():
    pats = ["scripts/**/*.gd", "ui/**/*.gd", "dev/*.gd"]
    out = []
    for p in pats:
        out += glob.glob(os.path.join(ROOT, p), recursive=True)
    return [f for f in out if "restyle-backup" not in f]


def server_files():
    out = glob.glob(os.path.join(SERVER, "*.py"))
    out += glob.glob(os.path.join(SERVER, "handlers", "*.py"))
    out += glob.glob(os.path.join(SERVER, "data", "*.json"))
    return [f for f in out if "item-rename" not in f and "map-rename" not in f
            and "maps.json" not in f]


# ---------------------------------------------------------------- 迁移表
def build_migration():
    """旧名（两代都要）→ 最终名。键用 md5 前 8 位，磁盘不留明文。"""
    old_to_new = {}

    # 道具：原版名 → 最终名
    for old, new in item_pairs():
        old_to_new[old] = new

    # 武学不进迁移表：线上 147 个账号里没有任何人持有武学（已核实），
    # 而且武学是显示名不作物 id，不需要按道具那套走。

    # 宠物技能 + 82 本技能书：两代前缀都要覆盖
    for old, new, _ in B.PET_SKILLS:
        if old == new:
            continue
        for lv in range(1, 6):
            old_to_new["%slv%d技能书" % (old, lv)] = "%slv%d技能书" % (new, lv)
    for old, new in PETS_PREV.items():
        for lv in range(1, 6):
            old_to_new["%slv%d技能书" % (old, lv)] = "%slv%d技能书" % (new, lv)

    # 武学技能书
    for old, new, _ in B.BOOKS:
        old_to_new[old] = new
    for old, new in BOOKS_PREV.items():
        old_to_new[old] = new

    import re as _re
    gd_text = io.open(os.path.join(ROOT, "scripts", "game_data.gd"), encoding="utf-8").read()
    m = _re.search(r"^const ALL_ITEMS = \{", gd_text, _re.M)
    depth, end = 0, len(gd_text)
    for i in range(m.end() - 1, len(gd_text)):
        if gd_text[i] == "{":
            depth += 1
        elif gd_text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    exists = {x.group(1) for x in _re.finditer(r'^\t"([^"]+)": \{', gd_text[m.end():end], _re.M)}

    table = {}
    for old, new in old_to_new.items():
        if old == new or new not in exists:
            continue
        table[hashlib.md5(old.encode("utf-8")).hexdigest()[:8]] = new
    return table


def gd_dict_literal(table, per_line=6):
    keys = sorted(table)
    lines = []
    for i in range(0, len(keys), per_line):
        chunk = keys[i:i + per_line]
        lines.append("\t" + " ".join('"%s": "%s",' % (k, table[k]) for k in chunk))
    return "\n".join(lines)


def rewrite_gd_migration(text, table):
    start = text.find("const ITEM_NAME_MIGRATION: = {")
    if start < 0:
        raise SystemExit("找不到 ITEM_NAME_MIGRATION")
    end = text.find("\n}", start) + 2
    block = "const ITEM_NAME_MIGRATION: = {\n%s\n}" % gd_dict_literal(table)
    return text[:start] + block + text[end:]


def rebuild_client_names():
    """白名单 = game_data.gd ALL_ITEMS 的全部键（必须按大括号配平截块，否则会算到后面的数据表）。"""
    import re as _re
    text = io.open(os.path.join(ROOT, "scripts", "game_data.gd"), encoding="utf-8").read()
    m = _re.search(r"^const ALL_ITEMS = \{", text, _re.M)
    depth, end = 0, len(text)
    for i in range(m.end() - 1, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                end = i
                break
    keys = [x.group(1) for x in _re.finditer(r'^\t"([^"]+)": \{', text[m.end():end], _re.M)]
    path = os.path.join(SERVER, "data", "client-item-names.json")
    old = json.load(io.open(path, encoding="utf-8"))
    old["items"] = keys
    old["count"] = len(keys)
    json.dump(old, io.open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    return len(keys)


def main():
    apply_it = "--apply" in sys.argv
    pairs = all_pairs()
    print("替换规则 %d 条（%d 道具 / %d 武学 / %d 宠物技能 / %d 书 / 套装）"
          % (len(pairs), len(item_pairs()), len(art_pairs()), len(pet_pairs()), len(B.BOOKS)))

    changed = []
    for f in gd_files() + server_files():
        s = io.open(f, encoding="utf-8").read()
        n = apply_text(s, pairs)
        if n != s:
            hit = sum(s.count(a) for a, _ in pairs)
            changed.append((f, hit))
            if apply_it:
                io.open(f, "w", encoding="utf-8").write(n)

    print("%s：%d 个文件有改动" % ("已写入" if apply_it else "干跑", len(changed)))
    for f, c in sorted(changed, key=lambda x: -x[1])[:12]:
        print("  %3d 处  %s" % (c, os.path.relpath(f, ROOT if f.startswith(ROOT) else SERVER)))

    if not apply_it:
        print("\n加 --apply 才真正写入")
        return

    # 迁移表
    table = build_migration()
    gd = os.path.join(ROOT, "scripts", "game_data.gd")
    text = io.open(gd, encoding="utf-8").read()
    io.open(gd, "w", encoding="utf-8").write(rewrite_gd_migration(text, table))

    rename_path = os.path.join(SERVER, "data", "item-rename.json")
    doc = {
        "note": "道具改名表：旧名 md5 前 8 位 → 现用名。覆盖两代旧名（原版名与上一版名），"
                "磁盘与客户端包里都不留旧名明文。服务端 core.migrate_item_name 与客户端 "
                "GameData.migrate_item_name 共用同一份数据。",
        "version": 2,
        "count": len(table),
        "map": table,
    }
    json.dump(doc, io.open(rename_path, "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    n = rebuild_client_names()
    print("迁移表 %d 条；白名单 %d 个道具" % (len(table), n))


if __name__ == "__main__":
    main()
