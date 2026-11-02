#!/usr/bin/env python3
"""把 AI 出的水墨横版底图做成游戏可直接用的战斗背景（512x700 JPG）。

只做三件事，都是机械的、可批量复现的：
  1. 去水印：AI 出图右下角带「AI生成 WORKBUDDY」，用上方同宽的一条地面纹理镜像盖掉。
  2. 地平线归位：AI 老把地平线画在 62%~66%，而战场只露出 y=16%~83% 这一带，
     角色脚底在 56%~72%，所以地平线必须落在 53%，否则后排怪会站在水里。
     做法是分段纵向重采样：地平线以上压到 53%，以下拉伸到 47%，不改变横向构图。
  3. 落盘：缩到 512x700（与原背景同尺寸），按目标体积调 JPEG 质量。

用法：
  python3 tools/build_horizontal_map.py --src raw/a.png --horizon 0.625 --out assets/backgrounds/x.jpg
  python3 tools/build_horizontal_map.py --src raw/a.png --horizon 0.625 --out /tmp/x.jpg --target-kb 170
"""
import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

OUT_W, OUT_H = 512, 700
HORIZON_TARGET = 0.45          # 地平线在成图中的位置（0~1）
# 0.40 的依据：战场面板铺满 y=270~1275，但玩家真正能看的是 270~930（下面被战报框/导航盖住），
# 而全图 512x700 基本整张可见。所以地平线放 45% 时，地面从 45% 一直铺到画面底，
# 露出 45%~66% 这 21% 的纵深带走位，和原来地牢图（地平线约 36%）是一个量级。
SEAM_FEATHER = 3               # 接缝羽化像素，避免一条硬边


def trim_edges(im: Image.Image, side: float, bottom: float, top: float = 0.0) -> Image.Image:
    """AI 出图四周有毛边/撕纸白边，按比例裁掉，别让它在战场边缘露出来。"""
    w, h = im.size
    x0 = int(w * side)
    y0 = int(h * top)
    x1 = w - x0
    y1 = h - int(h * bottom)
    if x1 - x0 < 16 or y1 - y0 < 16:
        return im
    return im.crop((x0, y0, x1, y1))


def patch_watermark(im: Image.Image) -> Image.Image:
    """右下角水印：取正上方同尺寸区域，垂直镜像后盖上去。地面是噪点纹理，看不出补丁。"""
    a = np.asarray(im.convert("RGB"))
    h, w, _ = a.shape
    x0, y0 = int(w * 0.74), int(h * 0.935)
    bh, bw = h - y0, w - x0
    if bh <= 0 or bw <= 0:
        return im
    patch = a[y0 - bh:y0, x0:x0 + bw][::-1]           # 上方一条，翻转
    out = a.copy()
    out[y0:y0 + patch.shape[0], x0:x0 + patch.shape[1]] = patch[:bh, :bw]
    return Image.fromarray(out)


def warp_horizon(im: Image.Image, horizon: float, target: float) -> Image.Image:
    """地平线以上/以下分别重采样，让地平线精确落在 HORIZON_TARGET。"""
    w, h = im.size
    y0 = max(1, min(h - 1, int(round(h * horizon))))
    top = im.crop((0, 0, w, y0))
    bot = im.crop((0, y0, w, h))

    t_h = int(round(OUT_H * target))
    b_h = OUT_H - t_h
    f = SEAM_FEATHER

    # 上下各多留 f 行备用，接缝处按 alpha 斜坡交叉淡化
    top_r = np.asarray(top.resize((OUT_W, t_h + f), Image.LANCZOS)).astype(np.float32)
    bot_r = np.asarray(bot.resize((OUT_W, b_h + f), Image.LANCZOS)).astype(np.float32)

    a_arr = np.repeat(top_r[-1:], OUT_H, axis=0).copy()
    a_arr[:t_h + f] = top_r
    b_arr = np.repeat(bot_r[:1], OUT_H, axis=0).copy()
    bh_eff = min(bot_r.shape[0], OUT_H - t_h)
    b_arr[t_h:t_h + bh_eff] = bot_r[:bh_eff]

    yy = np.arange(OUT_H).reshape(-1, 1, 1).astype(np.float32)
    alpha = np.clip((yy - t_h) / float(max(1, 2 * f)), 0.0, 1.0)
    out = a_arr * (1 - alpha) + b_arr * alpha
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def grade(im: Image.Image, contrast: float, sat: float, gamma: float = 1.0) -> Image.Image:
    """水墨要压一版调子再进游戏：AI 出的淡墨在手机上会显得发灰、没分量。
    contrast<1 压平，>1 加对比；sat 是饱和度倍数（围绕亮度混合）。"""
    a = np.asarray(im).astype(np.float32) / 255.0
    if abs(gamma - 1.0) > 0.001:
        a = np.power(np.clip(a, 0.0, 1.0), gamma)
    a = np.clip((a - 0.5) * contrast + 0.5, 0.0, 1.0)
    if abs(sat - 1.0) > 0.001:
        luma = (a[..., 0] * 0.299 + a[..., 1] * 0.587 + a[..., 2] * 0.114)[..., None]
        a = np.clip(luma + (a - luma) * sat, 0.0, 1.0)
    return Image.fromarray((a * 255.0 + 0.5).astype(np.uint8))


def edge_burn(im: Image.Image, side: float = 0.075, top: float = 0.045,
              max_alpha: float = 0.42, tint=(98, 86, 70)) -> Image.Image:
    """AI 出图四周是没画满的纸白，进游戏会变成一圈亮边。
    用一层「墨色边界」把它压下去，看上去像画面自然收边，而不是贴图没对齐。"""
    w, h = im.size
    xs = np.arange(w, dtype=np.float32) / w
    ys = np.arange(h, dtype=np.float32) / h
    ex = np.maximum(0.0, (side - np.minimum(xs, 1 - xs)) / side) ** 1.6
    ey = np.maximum(0.0, (top - np.minimum(ys, 1 - ys)) / top) ** 1.6
    e = np.maximum(ex[None, :], ey[:, None]) * max_alpha
    a = np.asarray(im).astype(np.float32)
    t = np.array(tint, dtype=np.float32)[None, None, :]
    a = a * (1 - e[..., None]) + t * e[..., None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def save_jpeg(im: Image.Image, path: str, target_kb: int) -> int:
    """按目标体积挑质量：从 92 往下试，取第一个不超过 target_kb 的。"""
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    best = None
    for q in range(92, 59, -3):
        im.save(path, "JPEG", quality=q, optimize=True, subsampling=1)
        size = os.path.getsize(path)
        best = (q, size)
        if size <= target_kb * 1024:
            break
    return best[1]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--horizon", type=float, required=True,
                    help="源图里地平线的位置，0~1（肉眼读：可行走地面的上边缘）")
    ap.add_argument("--target-kb", type=int, default=180)
    ap.add_argument("--target-horizon", type=float, default=HORIZON_TARGET)
    ap.add_argument("--no-patch", action="store_true")
    ap.add_argument("--trim-side", type=float, default=0.035)
    ap.add_argument("--trim-bottom", type=float, default=0.03)
    ap.add_argument("--trim-top", type=float, default=0.015)
    ap.add_argument("--contrast", type=float, default=1.10)
    ap.add_argument("--sat", type=float, default=1.06)
    ap.add_argument("--gamma", type=float, default=1.0,
                    help="<1 提亮，>1 压暗；墨色发闷时用 0.85~0.92")
    ap.add_argument("--save-preview", default="")
    args = ap.parse_args()

    im = Image.open(args.src).convert("RGB")
    im = trim_edges(im, args.trim_side, args.trim_bottom, args.trim_top)
    if not args.no_patch:
        im = patch_watermark(im)
    im = warp_horizon(im, args.horizon, args.target_horizon)
    # 轻微锐化：重采样后水墨笔触会发糊
    im = im.filter(ImageFilter.UnsharpMask(radius=1.2, percent=55, threshold=2))
    im = grade(im, args.contrast, args.sat, args.gamma)
    im = edge_burn(im)

    size = save_jpeg(im, args.out, args.target_kb)
    print(f"{os.path.basename(args.out)}  {OUT_W}x{OUT_H}  {size/1024:.0f}KB  horizon={args.target_horizon:.0%}")
    if args.save_preview:
        im.save(args.save_preview, "PNG")


if __name__ == "__main__":
    sys.exit(main())
