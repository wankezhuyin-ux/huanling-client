#!/usr/bin/env python3
"""对比 ink_sprite_preview 输出的左右两半：亮度守恒 + 对比度（立体感的客观代理）。

左半 = 原图，右半 = 着色器。左右两半在同一张 940x640 里，各占 440 宽。
只看角色像素（与宣纸底色的差 > 阈值），避免背景拉平统计。

用法：python3 tools/sprite_shade_stats.py /tmp/n1_banbanhu.png
"""
import sys
from PIL import Image
import numpy as np

W_PANEL = 440
BG = np.array([0.76, 0.74, 0.70]) * 255.0


def stats(a: np.ndarray, bg: np.ndarray):
    d = np.abs(a - bg).sum(axis=2)
    m = d > 24
    px = a[m]
    if px.size == 0:
        return None
    lum = px @ np.array([0.299, 0.587, 0.114])
    return dict(n=int(m.sum()), mean=float(lum.mean()), std=float(lum.std()),
                p05=float(np.percentile(lum, 5)), p95=float(np.percentile(lum, 95)),
                sat=float((px.max(axis=1) - px.min(axis=1)).mean()))


def main(path, probe=False):
    im = Image.open(path).convert("RGB")
    a = np.asarray(im).astype(np.float32)
    left = a[:, 40:40 + W_PANEL]
    right = a[:, 480:480 + W_PANEL]
    if probe:
        # 探针模式下右半是灰度图，不能靠「跟纸色差多少」找角色，
        # 直接借左半（同一张图、同一位置）的遮罩来量。
        m = np.abs(left - BG).sum(axis=2) > 24
        lum = right[m] @ np.array([0.299, 0.587, 0.114])
        print(f"file: {path}  probe: n={int(m.sum())} mean={lum.mean():.4f} "
              f"median={float(np.median(lum)):.4f} p10={float(np.percentile(lum, 10)):.4f} "
              f"p90={float(np.percentile(lum, 90)):.4f}")
        return
    sl, sr = stats(left, BG), stats(right, BG)
    print(f"file: {path}")
    for tag, s in (("原图", sl), ("shader", sr)):
        if s is None:
            print(f"{tag}: 无像素")
            continue
        print(f"{tag:7s} px={s['n']:6d} mean={s['mean']:6.2f} std={s['std']:6.2f} "
              f"p05={s['p05']:6.2f} p95={s['p95']:6.2f} sat={s['sat']:6.2f}")
    if sl and sr:
        print(f"亮度偏差 {(sr['mean'] - sl['mean']) / sl['mean'] * 100:+.2f}%   "
              f"对比度增幅 {(sr['std'] / sl['std'] - 1) * 100:+.1f}%   "
              f"饱和度差 {(sr['sat'] - sl['sat']):+.2f}")


if __name__ == "__main__":
    args = [x for x in sys.argv[1:] if not x.startswith("--")]
    main(args[0] if args else "/tmp/n1_banbanhu.png", probe="--probe" in sys.argv)
