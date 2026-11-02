#!/usr/bin/env python3
"""按游戏里真实的贴图几何，把「A | 镜像A | A | 镜像A」拼成一条长卷，
再切出卷动过程中的几帧，用来肉眼验接缝。

为什么要单独做这个：游戏里背景是 STRETCH_KEEP_ASPECT_COVERED，512x700 的图
铺进 700x1005 的面板时会被放大到 735x1005 并左右各裁掉 17.5px。裁切是左右对称的，
所以 A 的右边缘和镜像A 的左边缘正好是同一列像素——接缝天然连续。
这里就用同一套缩放/裁切把它复现出来，避免「游戏里看着有一条缝」才发现。

用法：
  python3 tools/preview_scroll_tiling.py --bg assets/backgrounds/浮影水城外郊.jpg
  python3 tools/preview_scroll_tiling.py --bg x.jpg --panel 700x1005 --frames 6
"""
import argparse
import os

import numpy as np
from PIL import Image

OUT_DIR = "/Users/a1111/WorkBuddy/2026-10-22-23-24-31/outputs/horizontal-maps/preview"


def covered_tile(tex: Image.Image, pw: int, ph: int) -> Image.Image:
    """复刻 TextureRect 的 STRETCH_KEEP_ASPECT_COVERED：等比放大到盖住面板，居中裁切。"""
    tw, th = tex.size
    s = max(pw / float(tw), ph / float(th))
    w, h = int(round(tw * s)), int(round(th * s))
    big = tex.resize((w, h), Image.LANCZOS)
    x0 = (w - pw) // 2
    y0 = (h - ph) // 2
    return big.crop((x0, y0, x0 + pw, y0 + ph))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--bg", required=True)
    ap.add_argument("--panel", default="700x1005")
    ap.add_argument("--frames", type=int, default=4)
    ap.add_argument("--out-dir", default=OUT_DIR)
    args = ap.parse_args()

    pw, ph = [int(v) for v in args.panel.lower().split("x")]
    tex = Image.open(args.bg).convert("RGB")
    tile_a = covered_tile(tex, pw, ph)
    tile_b = tile_a.transpose(Image.FLIP_LEFT_RIGHT)

    # 4 块：A | 镜像A | A | 镜像A（内容周期两屏）
    strip = Image.new("RGB", (pw * 4, ph))
    for i in range(4):
        strip.paste(tile_a if i % 2 == 0 else tile_b, (i * pw, 0))

    name = os.path.splitext(os.path.basename(args.bg))[0]
    os.makedirs(args.out_dir, exist_ok=True)
    strip_path = os.path.join(args.out_dir, f"卷轴拼贴检验_{name}.png")
    strip.save(strip_path)

    # 几张截图：展示卷动过程中接缝经过屏幕的位置
    n = max(2, args.frames)
    cycle = pw * 2
    sheet = Image.new("RGB", (pw * 2, ph * ((n + 1) // 2)), (18, 18, 20))
    for k in range(n):
        off = int(round(cycle * k / float(n)))
        frame = strip.crop((off, 0, off + pw, ph))
        sheet.paste(frame, ((k % 2) * pw, (k // 2) * ph))
    sheet_path = os.path.join(args.out_dir, f"卷轴拼接分帧_{name}.png")
    sheet.save(sheet_path)

    # 接缝像素连续性：A 最后一列 vs 镜像A 第一列
    a = np.asarray(tile_a).astype(int)
    b = np.asarray(tile_b).astype(int)
    d1 = float(np.abs(a[:, -1] - b[:, 0]).mean())
    d2 = float(np.abs(b[:, -1] - a[:, 0]).mean())
    # 与「普通两张并排」的接缝落差对比，作为参照量级
    dref = float(np.abs(a[:, -1] - a[:, 0]).mean())
    print(f"{name}: 接缝平均通道差 A|镜像={d1:.1f}  镜像|A={d2:.1f}（参照 原图右|原图左={dref:.1f}）")
    print(f"  接缝{'无缝' if d1 < 1.0 and d2 < 1.0 else '有落差，需要阴影带或重做图'}")
    print(f"  {strip_path}")
    print(f"  {sheet_path}")


if __name__ == "__main__":
    main()
