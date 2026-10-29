#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""删除 9 只 IP 侵权宠物：西门吹雪 / 六道佐助 / 九喇嘛 / 不知火舞 / 八神 / 狠人大帝 / 柳神 / 巴巴塔 / 尤尔哈

同时清理：
  - 服务端 data/*.json 的目录条目与榜单条目
  - runtime-config.json 的 sponsorCustomPetIds
  - 客户端 game_data.gd / pet_data_complete.gd 的字典条目
  - assets/pets 与 assets/sprites 的图

用法：
  python3 purge_ip_pets.py            # 预览
  python3 purge_ip_pets.py --apply    # 执行
"""
import argparse
import json
import os
import re
import shutil
import time

ROOT = os.path.expanduser("~/Documents/Codex/2026-10-21/n/outputs")
GAME = os.path.join(ROOT, "recovered-godot-project")
SRV = os.path.join(ROOT, "deploy/server")

TARGETS = {
    "ximenchuixue": "西门吹雪",
    "zuozhu": "六道佐助",
    "jiulama": "九喇嘛",
    "buzhihuowu": "不知火舞",
    "bashen": "八神",
    "henrendadi": "狠人大帝",
    "liushen": "柳神",
    "babata": "巴巴塔",
    "youerha": "尤尔哈",
}
IDS = set(TARGETS)
NAMES = set(TARGETS.values())


def backup(paths):
    stamp = time.strftime("%Y%m%d-%H%M%S")
    dst = os.path.join(ROOT, "backup", f"purge-ip-{stamp}")
    for p in paths:
        rel = os.path.relpath(p, ROOT)
        out = os.path.join(dst, rel)
        os.makedirs(os.path.dirname(out), exist_ok=True)
        if os.path.isdir(p):
            shutil.copytree(p, out, dirs_exist_ok=True)
        else:
            shutil.copy2(p, out)
    return dst


# ---------- GDScript 字典条目切除 ----------
def cut_gd_entry(src, key):
    """删除形如 \t"key": { ... },\n 的顶层字典条目（括号平衡）。"""
    pat = re.compile(r'\n\t"%s":\s*\{' % re.escape(key))
    m = pat.search(src)
    if not m:
        return src, False
    start = m.start() + 1  # 保留前一个换行
    i = src.index("{", m.end() - 1)
    depth = 0
    while i < len(src):
        c = src[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                break
        elif c == '"':  # 跳过字符串
            i += 1
            while i < len(src) and src[i] != '"':
                if src[i] == "\\":
                    i += 1
                i += 1
        i += 1
    end = i + 1
    # 吃掉尾随逗号与空白
    while end < len(src) and src[end] in " \t":
        end += 1
    if end < len(src) and src[end] == ",":
        end += 1
    while end < len(src) and src[end] in " \t":
        end += 1
    if end < len(src) and src[end] == "\n":
        end += 1
    return src[:start] + src[end:], True


def purge_gd(path, apply, log):
    src = open(path, encoding="utf-8").read()
    n = 0
    for key in TARGETS:
        src2, ok = cut_gd_entry(src, key)
        while ok:
            src = src2
            n += 1
            src2, ok = cut_gd_entry(src, key)
            if not ok:
                break
    # 残留的纯字符串引用（如名字列表）
    for name in NAMES:
        c = src.count('"%s"' % name)
        if c:
            log.append(f"  ! {os.path.basename(path)} 仍有 {c} 处名字字面量 {name}")
    if n and apply:
        open(path, "w", encoding="utf-8").write(src)
    log.append(f"{'改' if apply else '将改'} {path}  删除条目 {n}")


def purge_json_dict(path, apply, log):
    data = json.load(open(path, encoding="utf-8"))
    removed = []

    def walk(o):
        if isinstance(o, dict):
            for k in list(o):
                if k in IDS:
                    removed.append(k)
                    del o[k]
                else:
                    walk(o[k])
        elif isinstance(o, list):
            keep = []
            for v in o:
                if isinstance(v, str) and (v in IDS or v in NAMES):
                    removed.append(v)
                    continue
                if isinstance(v, dict) and (
                    v.get("id") in IDS
                    or v.get("name") in NAMES
                    or v.get("pet_name") in NAMES
                    or str(v.get("pet_id", "")).split("_")[0] in IDS
                    or v.get("pet_id") in IDS
                ):
                    removed.append(v.get("id") or v.get("name"))
                    continue
                keep.append(v)
                walk(v)
            o[:] = keep

    walk(data)
    if removed and apply:
        json.dump(data, open(path, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
    log.append(f"{'改' if apply else '将改'} {os.path.basename(path)}  删除 {len(removed)} 处")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    gd_files = [
        os.path.join(GAME, "scripts/game_data.gd"),
        os.path.join(GAME, "scripts/pet_data_complete.gd"),
        os.path.join(GAME, "scripts/evolution_data.gd"),
    ]
    json_files = [
        os.path.join(SRV, "data/pet-catalog.json"),
        os.path.join(SRV, "data/pets.json"),
        os.path.join(SRV, "data/ranking-pets-non-evolution.json"),
        os.path.join(SRV, "data/runtime-config.json"),
        os.path.join(SRV, "data/evolution-chains.json"),
        os.path.join(SRV, "data/drop-config.json"),
        os.path.join(SRV, "data/gift-rewards.json"),
    ]
    existing_gd = [p for p in gd_files if os.path.exists(p)]
    existing_json = [p for p in json_files if os.path.exists(p)]

    if a.apply:
        dst = backup(existing_gd + existing_json)
        print("备份 ->", dst)

    log = []
    for p in existing_gd:
        purge_gd(p, a.apply, log)
    for p in existing_json:
        purge_json_dict(p, a.apply, log)

    print("\n".join(log))

    # 素材
    art = []
    for pid in IDS:
        for sub in ("assets/pets", "assets/sprites"):
            d = os.path.join(GAME, sub)
            for f in os.listdir(d):
                if f == pid + ".png" or f.startswith(pid + "_") or f.startswith(pid + "."):
                    art.append(os.path.join(d, f))
    print(f"\n素材待删 {len(art)} 个")
    for p in art[:6]:
        print("  ", os.path.relpath(p, GAME))
    if a.apply:
        bk = backup([os.path.dirname(p) if False else p for p in art])
        for p in art:
            os.remove(p)
        print("已删除素材 ->", bk)


if __name__ == "__main__":
    main()
