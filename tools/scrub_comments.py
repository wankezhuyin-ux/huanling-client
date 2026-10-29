#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""清理脚本里的原游戏痕迹：注释中的「原版/原服/群号/原版源码路径」等。

规则（按行）：
  1. 含原版源码路径（wechat-game-stage 等）的注释行 → 整行删除
  2. 含 QQ 群号的注释行 → 整行删除
  3. 术语替换：原版→参考稿、原游戏→旧工程、原服→线上、照抄→对齐
  4. 原服 IP / 抓包文件名 → 中性说法

用法：python3 tools/scrub_comments.py [--apply]
"""
import argparse
import os
import re

GAME = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DELETE_PATTERNS = [
    r"wechat-game-stage",
    r"630273***",
    r"original-live-capture",
    r"101\.42\.200\.117",
]

REPLACE = [
    ("原版源码", "参考实现"),
    ("原版", "参考稿"),
    ("原游戏", "旧工程"),
    ("原服", "线上"),
    ("照抄", "对齐"),
    ("抓包", "日志采样"),
]

TARGET_DIRS = ["scripts", "ui", "dev", "tools", "main.gd"]


def iter_files():
    for t in TARGET_DIRS:
        p = os.path.join(GAME, t)
        if os.path.isfile(p):
            yield p
            continue
        for d, _, fs in os.walk(p):
            if ".godot" in d:
                continue
            for f in fs:
                if f.endswith(".gd"):
                    yield os.path.join(d, f)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    total_del = total_rep = 0
    touched = []
    for path in iter_files():
        src = open(path, encoding="utf-8").read()
        lines = src.split("\n")
        out = []
        nd = nr = 0
        for ln in lines:
            if any(re.search(p, ln) for p in DELETE_PATTERNS):
                nd += 1
                continue
            new = ln
            for old, rep in REPLACE:
                if old in new:
                    nr += new.count(old)
                    new = new.replace(old, rep)
            out.append(new)
        if nd or nr:
            total_del += nd
            total_rep += nr
            touched.append((os.path.relpath(path, GAME), nd, nr))
            if a.apply:
                open(path, "w", encoding="utf-8").write("\n".join(out))

    touched.sort(key=lambda x: -(x[1] * 3 + x[2]))
    for rel, nd, nr in touched[:25]:
        print(f"  删行 {nd:3d}  替换 {nr:3d}  {rel}")
    print(f"\n共 {len(touched)} 个文件：删行 {total_del}，术语替换 {total_rep}")
    print("已写入" if a.apply else "（预览，加 --apply 执行）")


if __name__ == "__main__":
    main()
