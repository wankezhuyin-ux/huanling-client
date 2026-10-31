#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""以 git baseline（换皮前原版）为基准，验证当前工作区的资源有没有被换过。

为什么用 baseline 而不是反解原包：
  baseline commit 330b6d7 就是「换皮改造前的完整基线」，里面的 PNG 与原包逐字节同源。
  反解出来的 ctex 再存 PNG 会有编码差异（JPEG 尤其明显），像素比对全是噪声。

判定（PNG/JPG 逐张）：
  · baseline 里没有、当前有        → 多出来（自加素材）
  · baseline 里有、当前没有        → 缺失
  · 两者都有 → 解码后比像素：
      尺寸不同                     → 不一致
      最大通道差 <= 2               → 一致（存盘量化噪声）
      否则                          → 不一致（换过图）

用法：
  python3 tools/verify_against_baseline.py [--base=330b6d7] [--thresh=2]
"""
import argparse
import io
import os
import subprocess
import sys

from PIL import Image, ImageChops
import numpy as np

PROJ = "/Users/a1111/Documents/Codex/2026-10-21/n/outputs/recovered-godot-project"
SUBS = ["pets", "sprites", "backgrounds", "portraits", "items", "icons", "background"]


def base_bytes(rel: str, base: str):
    r = subprocess.run(
        ["git", "-C", PROJ, "show", f"{base}:{rel}"],
        capture_output=True,
    )
    return r.stdout if r.returncode == 0 else None


def base_list(sub: str, base: str):
    r = subprocess.run(
        ["git", "-C", PROJ, "ls-tree", "--name-only", base, f"assets/{sub}/"],
        capture_output=True,
    )
    if r.returncode != 0:
        return []
    out = []
    for line in r.stdout.decode("utf-8", "replace").splitlines():
        if "/" in line and (line.endswith(".png") or line.endswith(".jpg")):
            out.append(line)
    return sorted(out)


def cur_list(sub: str):
    d = os.path.join(PROJ, "assets", sub)
    if not os.path.isdir(d):
        return []
    return sorted(
        os.path.join("assets", sub, f)
        for f in os.listdir(d)
        if f.endswith((".png", ".jpg"))
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="330b6d7")
    ap.add_argument("--thresh", type=int, default=2)
    args = ap.parse_args()

    total_bad = 0
    for sub in SUBS:
        bset = base_list(sub, args.base)
        cset = cur_list(sub)
        bnames = {os.path.basename(x) for x in bset}
        cnames = {os.path.basename(x) for x in cset}
        extra = sorted(cnames - bnames)
        miss = sorted(bnames - cnames)
        same = diff = 0
        difflist = []
        for rel in bset:
            name = os.path.basename(rel)
            cur = os.path.join(PROJ, rel)
            if name not in cnames:
                continue
            bb = base_bytes(rel, args.base)
            if bb is None:
                continue
            try:
                a = Image.open(io.BytesIO(bb)).convert("RGBA")
                b = Image.open(cur).convert("RGBA")
            except Exception as e:
                difflist.append(f"{rel}  [读取失败 {e}]")
                diff += 1
                continue
            if a.size != b.size:
                difflist.append(f"{rel}  [尺寸 {a.size} vs {b.size}]")
                diff += 1
                continue
            d = np.asarray(ImageChops.difference(a, b), dtype=np.int16)
            mx = int(d.max())
            if mx <= args.thresh:
                same += 1
            else:
                mean = float(d.mean())
                pct = 100.0 * float((d > args.thresh).any(axis=2).mean())
                difflist.append(f"{rel}  [最大差{mx} 平均{mean:.2f} 显著差异{pct:.2f}%]")
                diff += 1

        print(f"[{sub:<13}] baseline {len(bset)} | 一致 {same} | 不一致 {diff} | "
              f"多出 {len(extra)} | 缺失 {len(miss)}")
        for x in difflist:
            print("     差异:", x)
        if extra:
            print("     多出:", extra)
        if miss:
            print("     缺失:", miss)
        total_bad += diff + len(extra)

    print(f"\n对不上的总数: {total_bad}")
    return 0 if total_bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
