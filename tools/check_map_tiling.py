#!/usr/bin/env python3
"""巡检所有战斗背景的拼接效果。

背景卷动有两条路（scripts/ui/battle_scroll_world.gd）：
  · 可平铺（AI 生成时左右边缘做成一样）→ 三张都用原图，一屏周期，接缝天然无缝；
  · 不可平铺的老图 → 原图 + **水平镜像**，接缝像素级连续。

镜像的代价：屏幕上会出现左右对称。老图越不对称，这道对称越扎眼。
本脚本对每张图给出：
  edge_diff    左右边缘平均色差（<=14 判为可平铺），口径与游戏一致
  mode         实际走的拼接方式
  saliency     「不对称度」= 左半与(右半镜像)之间的平均像素差。
               越大 = 镜像后越容易看出人工对称（地标会对称出现两次）
并输出：
  · 按 saliency 排序的清单（最扎眼的排前面，方便决定哪张图值得重生成）
  · 每张图按实际拼接方式拼好的缩略图大图（contact sheet），肉眼直接过一遍

用法：
  python3 tools/check_map_tiling.py                    # 报告 + 大图
  python3 tools/check_map_tiling.py --sheet=/tmp/x.png # 只出大图
  python3 tools/check_map_tiling.py --top=20           # 只看最扎眼的 20 张
"""

import argparse
import glob
import os

import numpy as np
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BG_DIR = os.path.join(ROOT, "assets", "backgrounds")

# 与 battle_scroll_world.gd 的 TILEABLE_EDGE_STRIP / TILEABLE_MAX_DIFF 保持一致
TILEABLE_EDGE_STRIP = 2
TILEABLE_MAX_DIFF = 14.0


def edge_diff(img: np.ndarray) -> float:
    """左右边缘各 2 列、每 4 行采样，求每通道平均差（0~255 口径）。"""
    h, w = img.shape[:2]
    s = min(TILEABLE_EDGE_STRIP, w // 4)
    if s <= 0 or h < 32:
        return 255.0
    left = img[:, :s, :].astype(np.float32)
    right = img[:, w - s:, :].astype(np.float32)[:, ::-1, :]
    ys = slice(0, h, 4)
    diff = np.abs(left[ys] - right[ys]).sum(axis=2)
    return float(diff.mean() / 3.0)


def saliency(img: np.ndarray) -> float:
    """不对称度：左半 与 (右半镜像) 的平均像素差（0~255）。

    图本来就越接近左右对称，这个值越小 —— 镜像拼接后越看不出人工痕迹。
    """
    h, w = img.shape[:2]
    half = w // 2
    a = img[:, :half, :].astype(np.float32)
    b = img[:, w - half:, :].astype(np.float32)[:, ::-1, :]
    return float(np.abs(a - b).mean())


def build_preview(img: Image.Image, tileable: bool) -> Image.Image:
    """按游戏里的真实拼接方式拼一张预览：可平铺就重复原图，否则原图+镜像。"""
    w, h = img.size
    if tileable:
        strip = Image.new("RGB", (w * 2, h))
        strip.paste(img, (0, 0))
        strip.paste(img, (w, 0))
    else:
        strip = Image.new("RGB", (w * 2, h))
        strip.paste(img, (0, 0))
        strip.paste(img.transpose(Image.FLIP_LEFT_RIGHT), (w, 0))
    # 取中间一段（相当于屏幕上看到的范围），再压扁成横幅便于排版
    crop = strip.crop((w // 4, 0, w // 4 + w, h)).resize((300, 190), Image.LANCZOS)
    return crop


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--sheet", default="", help="contact sheet 输出路径")
    ap.add_argument("--top", type=int, default=0, help="只列最扎眼的前 N 张")
    ap.add_argument("--cell", type=int, default=300, help="大图单格宽度")
    args = ap.parse_args()

    files = sorted(glob.glob(os.path.join(BG_DIR, "*.jpg")))
    files += sorted(glob.glob(os.path.join(BG_DIR, "*.png")))
    if not files:
        print("没找到背景图")
        return 1

    rows = []
    for p in files:
        try:
            im = Image.open(p).convert("RGB")
        except Exception as e:  # noqa: BLE001
            print("跳过", os.path.basename(p), e)
            continue
        arr = np.asarray(im)
        ed = edge_diff(arr)
        sa = saliency(arr)
        tileable = ed <= TILEABLE_MAX_DIFF
        rows.append({
            "name": os.path.splitext(os.path.basename(p))[0],
            "edge_diff": ed,
            "tileable": tileable,
            "mode": "重复(无缝)" if tileable else "镜像(无缝)",
            "saliency": sa,
            "path": p,
            "im": im,
        })

    n_mirror = sum(1 for r in rows if not r["tileable"])
    print("背景共 %d 张：可平铺 %d 张（走重复铺），其余 %d 张走镜像拼接 —— 两种都是像素级无缝。"
          % (len(rows), len(rows) - n_mirror, n_mirror))

    rows.sort(key=lambda r: -r["saliency"])
    show = rows[: args.top] if args.top > 0 else rows
    print("\n按「镜像后对称有多扎眼」排序（差值越大越扎眼）：")
    print("%-28s %8s %8s %-12s %s" % ("地图", "边缘差", "不对称度", "拼接方式", "评价"))
    for r in show:
        s = r["saliency"]
        note = "很扎眼" if s > 42 else ("略扎眼" if s > 26 else "基本看不出来")
        print("%-28s %8.1f %8.1f %-12s %s" % (r["name"], r["edge_diff"], s, r["mode"], note))

    if args.sheet:
        cell = args.cell
        cols = 6
        rowsn = (len(rows) + cols - 1) // cols
        ch = int(cell * 0.63)
        sheet = Image.new("RGB", (cols * (cell + 8) + 8, rowsn * (ch + 26) + 8), (36, 34, 32))
        d = ImageDraw.Draw(sheet)
        for i, r in enumerate(rows):
            x = 8 + (i % cols) * (cell + 8)
            y = 8 + (i // cols) * (ch + 26)
            prev = build_preview(r["im"], r["tileable"])
            sheet.paste(prev.resize((cell, ch), Image.LANCZOS), (x, y + 18))
            flag = "镜" if not r["tileable"] else "重"
            d.text((x + 2, y + 3), "%s [%s] %.0f" % (r["name"][:16], flag, r["saliency"]),
                   fill=(235, 230, 220))
        sheet.save(args.sheet)
        print("\ncontact sheet 已存：", args.sheet, sheet.size)

    # 清单存档，方便以后决定重生成哪几张
    out_csv = os.path.join(ROOT, "tools", "map_tiling_report.csv")
    with open(out_csv, "w", encoding="utf-8") as f:
        f.write("name,edge_diff,tileable,mode,saliency\n")
        for r in rows:
            f.write("%s,%.2f,%s,%s,%.2f\n" % (r["name"], r["edge_diff"], r["tileable"], r["mode"], r["saliency"]))
    print("清单：", out_csv)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
