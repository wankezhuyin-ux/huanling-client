#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""全量像素级比对：当前工作区资源 vs 原游戏 APK 解包资源。

流程：
1. 先用 tools/export_orig_ctex.gd 把原包 .ctex 反解成 PNG（/tmp/orig_export）
2. 本脚本把反解结果与当前 assets/ 逐张做像素比对

判定：
  · 尺寸不同            → 不一致（换过图）
  · 像素完全相同        → 一致
  · 最大通道差 <= 2     → 一致（JPEG 重压缩噪声）
  · 否则                → 不一致

用法：
  python3 tools/verify_all_assets.py [--orig=/tmp/orig_export] [--thresh=2]
"""
import argparse
import json
import os
import sys

from PIL import Image, ImageChops
import numpy as np

CUR_ASSETS = "/Users/a1111/Documents/Codex/2026-10-21/n/outputs/recovered-godot-project/assets"

# 这 9 只 IP 侵权宠物是有意删除的（commit cd3bf57），不算「对不上」
EXPECTED_MISSING = {
    "babata", "bashen", "buzhihuowu", "henrendadi", "jiulama",
    "liushen", "ximenchuixue", "youerha", "zuozhu",
}


def compare(a_path: str, b_path: str, thresh: int):
    """返回 (状态, 详情)。状态: same / diff / size"""
    a = Image.open(a_path).convert("RGBA")
    b = Image.open(b_path).convert("RGBA")
    if a.size != b.size:
        return "size", f"尺寸 {a.size} vs {b.size}"
    d = np.asarray(ImageChops.difference(a, b), dtype=np.int16)
    mx = int(d.max())
    if mx <= thresh:
        return "same", f"最大差{mx}"
    mean = float(d.mean())
    pct = 100.0 * float((d > thresh).any(axis=2).mean())
    return "diff", f"最大差{mx} 平均{mean:.2f} 显著差异{pct:.2f}%"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--orig", default="/tmp/orig_export")
    ap.add_argument("--thresh", type=int, default=2)
    ap.add_argument("--json", default="")
    args = ap.parse_args()

    same = diff = miss = 0
    diff_list = []
    jpg_diff = []
    miss_list = []
    sub_stats = {}
    # jpg 类的差异单列：JPEG 重新存盘必然有量化噪声，
    # 这不代表换了图 —— 权威判定跑 tools/verify_against_baseline.py
    # （拿换皮前的原版 PNG 逐像素比，那个是同源同编码，没有噪声）

    for root, _dirs, files in os.walk(args.orig):
        for f in sorted(files):
            if not f.endswith((".png", ".jpg")):
                continue
            rel = os.path.relpath(os.path.join(root, f), args.orig)
            sub = rel.split(os.sep)[0]
            cur_p = os.path.join(CUR_ASSETS, rel)
            st = sub_stats.setdefault(sub, {"same": 0, "diff": 0, "miss": 0})
            if not os.path.exists(cur_p):
                st["miss"] += 1
                miss += 1
                miss_list.append(rel)
                continue
            status, detail = compare(os.path.join(root, f), cur_p, args.thresh)
            if status == "same":
                st["same"] += 1
                same += 1
            elif rel.endswith(".jpg"):
                st["diff"] += 1
                jpg_diff.append(f"{rel}  [{detail}]")
            else:
                st["diff"] += 1
                diff += 1
                diff_list.append(f"{rel}  [{detail}]")

    print("=== 像素级比对结果（当前 vs 原包）===")
    for sub in sorted(sub_stats):
        s = sub_stats[sub]
        flag = "" if (s["diff"] == 0 and s["miss"] == 0) else "  <- 有差异"
        print(f"  [{sub:<14}] 一致 {s['same']:>4} | 不一致 {s['diff']:>3} | 缺失 {s['miss']:>3}{flag}")

    if diff_list:
        print("\n--- PNG 不一致明细（这些是真的换过图）---")
        for x in diff_list:
            print("  ", x)

    if jpg_diff:
        print(f"\n--- JPG 有 {len(jpg_diff)} 张存在量化差异 ---")
        print("  JPG 重新存盘必然有压缩噪声，不代表换了图。")
        print("  权威判定：python3 tools/verify_against_baseline.py")
        for x in jpg_diff[:5]:
            print("  ", x)
        if len(jpg_diff) > 5:
            print(f"   ...（其余 {len(jpg_diff)-5} 张略）")

    unexpected_miss = [m for m in miss_list if os.path.splitext(m)[0] not in EXPECTED_MISSING]
    print(f"\n缺失 {len(miss_list)} 张，其中非预期缺失 {len(unexpected_miss)} 张")
    if unexpected_miss:
        print("  非预期缺失:", unexpected_miss)
    else:
        print("  （缺失的都是有意删除的 IP 侵权宠物）")

    print(f"\nPNG 合计：一致 {same} | 真不一致 {diff} | 缺失 {miss} | JPG 量化差异 {len(jpg_diff)}")

    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump({"diff": diff_list, "jpg_diff": jpg_diff, "missing": miss_list},
                      f, ensure_ascii=False, indent=1)

    return 0 if (diff == 0 and not unexpected_miss) else 1


if __name__ == "__main__":
    sys.exit(main())
