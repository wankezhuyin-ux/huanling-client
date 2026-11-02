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
HORIZON_TARGET = 0.36          # 地平线在成图中的位置（0~1）
# 0.36 的依据（实机量出来的，别再往上调）：
#   战斗单位的 y 是面板内写死的绝对像素，4 排阵型纵向跨度 288px：
#     后排 TOP 78 / 二排 LEADER 174 / 前排 MEMBER 270（玩家宠物在这） / 最前 BOTTOM 366
#   脚底 ≈ wrap.y + 208（96px 精灵 + 18 偏移 + 名字条余量），即脚底 626~918。
#   面板全局 y=340 起、可见下沿 930。地平线一旦高于「二排脚底 722」，
#   后排怪物就会飘在地平线以上（站在雾里/城墙上）。
#   → 地平线必须 ≤ (722-340)/1005 ≈ 38%。取 36% 留 20px 余量。
#   同时 BOTTOM 脚底 918 不会被战报框（930）切到脚。
SEAM_FEATHER = 3               # 接缝羽化像素，避免一条硬边

# —— 「人站在主道上」的硬指标 ——
# 实机量出来的：人物/宠物的脚底落在图高 52.7%~61.7%（4 排阵型的脚底是 45%~70%，
# 但真正会出现在画面里的那几排集中在这一带）。所以黄土主道必须至少盖住这一段，
# 而且上沿要高于 52.7%、下沿低于 61.7%，否则看起来就是「站在草地上」。
FOOT_BAND = (0.527, 0.617)
# 主道建议带：比脚底带上下各留 ~6%，同时不越过可见下沿 66%（再往下被战报框挡住）。
ROAD_TARGET = (0.46, 0.68)
# 判「土路」用的行判据：整行平均 R-B 大于这个值，视为暖色土面。
ROAD_WARM_DIFF = 26.0


def detect_road_band(im: Image.Image) -> tuple:
    """按「暖色偏黄」判出土路所在的高度带，返回 (top, bottom) 比例；判不出返回 None。"""
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    h, w, _ = a.shape
    # 只看中间 70%：两侧有暗角/收边，会把平均值拉低
    x0, x1 = int(w * 0.15), int(w * 0.85)
    band = a[:, x0:x1]
    warm = band[..., 0].mean(axis=1) - band[..., 2].mean(axis=1)
    ys = [y for y in range(int(h * 0.30), h) if warm[y] >= ROAD_WARM_DIFF]
    if not ys:
        return None
    return (ys[0] / float(h), ys[-1] / float(h))



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
    if side > 0.0:
        ex = np.maximum(0.0, (side - np.minimum(xs, 1 - xs)) / side) ** 1.6
    else:
        ex = np.zeros(w, dtype=np.float32)
    if top > 0.0:
        ey = np.maximum(0.0, (top - np.minimum(ys, 1 - ys)) / top) ** 1.6
    else:
        ey = np.zeros(h, dtype=np.float32)
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
    ap.add_argument("--burn-side", type=float, default=0.075,
                    help="左右墨色收边的宽度（占图宽比例）。做横向卷轴时必须给 0："
                         "拼接处是 A 的右边缘贴着镜像图的左边缘，两边都压黑会变成一条滑动的黑杠")
    ap.add_argument("--burn-top", type=float, default=0.045,
                    help="上下墨色收边的高度（占图高比例）")
    ap.add_argument("--save-preview", default="")
    ap.add_argument("--check-road", action="store_true",
                    help="检一遍土路是否盖住人物脚底那一带（52.7%%~61.7%%）")
    args = ap.parse_args()

    im = Image.open(args.src).convert("RGB")
    im = trim_edges(im, args.trim_side, args.trim_bottom, args.trim_top)
    if not args.no_patch:
        im = patch_watermark(im)
    im = warp_horizon(im, args.horizon, args.target_horizon)
    # 轻微锐化：重采样后水墨笔触会发糊
    im = im.filter(ImageFilter.UnsharpMask(radius=1.2, percent=55, threshold=2))
    im = grade(im, args.contrast, args.sat, args.gamma)
    if args.burn_side > 0.0 or args.burn_top > 0.0:
        im = edge_burn(im, args.burn_side, args.burn_top)

    size = save_jpeg(im, args.out, args.target_kb)
    print(f"{os.path.basename(args.out)}  {OUT_W}x{OUT_H}  {size/1024:.0f}KB  horizon={args.target_horizon:.0%}")
    if args.check_road:
        band = detect_road_band(im)
        if band is None:
            print("  [主道] 没检出土路（整行都不够暖）—— 人和宠会站在草上，重画时把主道画宽一点")
        else:
            top, bot = band
            covers_foot = top <= FOOT_BAND[0] and bot >= FOOT_BAND[1]
            print("  [主道] y=%.0f%%~%.0f%%  脚底带 %.0f%%~%.0f%%  %s" % (
                top * 100, bot * 100, FOOT_BAND[0] * 100, FOOT_BAND[1] * 100,
                "OK（站得住）" if covers_foot else "WARN（脚会踩在草上，建议主道上沿 ≤%.0f%%、下沿 ≥%.0f%%）"
                % (FOOT_BAND[0] * 100, FOOT_BAND[1] * 100)))
    if args.save_preview:
        im.save(args.save_preview, "PNG")


if __name__ == "__main__":
    sys.exit(main())
