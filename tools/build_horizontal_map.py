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
# 判「可站立路面」用的行判据。前面几张都是黄土路，用 R-B 判暖色就够了；
# 但冰面（青蓝）、青石板（浅灰白）这两类根本判不出来，所以按「色调」分开判：
#   warm：R-B >= 26，黄土/砂石路
#   cold：B-R >= 18，冰面/雪道
#   pale：亮度 >= 150 且 |R-B| <= 30，青石板/白石广场
# auto 依次尝试，取第一段能判出来的。
ROAD_WARM_DIFF = 26.0
ROAD_COLD_DIFF = 18.0
ROAD_PALE_LUM = 120.0
# 饱和度阈值（0~255）：石面大约 10~30，黄土约 45~70，冰面 15~35（冰靠 cold 先命中）
ROAD_PALE_SAT = 46.0
# 同一条路会被路缘石阴影、车辙、水渍打断成几段，间隙小于这个比例就接回去
ROAD_MERGE_GAP = 0.05

# —— 「同图首尾相接」的硬指标 ——
# 战斗面板 700x1005、图片 512x700 走 STRETCH_KEEP_ASPECT_COVERED 时，
# 会被放大到 735x1005 再左右各裁 17.5px，所以真正露在接缝处的是源图第 12 列和第 499 列，
# 不是第 0 列和第 511 列。这里按可见列来量，别量成「原始边缘好看、游戏里还是有缝」。
VIS_EDGE_INSET = 12
# 边缘色差阈值，和 Game 里 BattleScrollWorld.TILEABLE_MAX_DIFF 保持一致。
SEAM_OK = 14.0


def _merge_runs(runs: list, max_gap: int) -> list:
    """合并间隔很小的相邻区间（阴影、车辙会把同一条路面切成几段）。"""
    if not runs:
        return []
    merged = [list(runs[0])]
    for start, end in runs[1:]:
        if start - merged[-1][1] - 1 <= max_gap:
            merged[-1][1] = end
        else:
            merged.append([start, end])
    return [(a, b) for a, b in merged]


def _mask_runs(mask: list) -> list:
    """把布尔序列切成连续为真的区间，返回 [(start, end), ...]（闭区间）。"""
    runs = []
    start = None
    for i, v in enumerate(mask):
        if v and start is None:
            start = i
        elif not v and start is not None:
            runs.append((start, i - 1))
            start = None
    if start is not None:
        runs.append((start, len(mask) - 1))
    return runs


def detect_road_band(im: Image.Image, tone: str = "auto") -> tuple:
    """判出「可站立路面」所在的高度带，返回 (top, bottom, tone)；判不出返回 None。

    按行找连续区间，而不是取首末行——否则上方的墙面（冰崖也是青蓝色）会被一起算进路面，
    报告出「25%~100% 全是路」这种没用的结论。区间还要求起点落在画面 30% 以下，
    并且足够厚（≥ 2% 图高），才当作一条路。
    """
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    h, w, _ = a.shape
    # 只看中间 70%：两侧有暗角/收边，会把平均值拉低
    x0, x1 = int(w * 0.15), int(w * 0.85)
    band = a[:, x0:x1]
    r = band[..., 0]
    g = band[..., 1]
    b = band[..., 2]
    warm = r.mean(axis=1) - b.mean(axis=1)
    cold = b.mean(axis=1) - r.mean(axis=1)
    lum = (r * 0.299 + g * 0.587 + b * 0.114).mean(axis=1)
    # 石面：不靠色相判（青石板带苔痕水渍，R-B 会正负跳），改判「低饱和 + 够亮」。
    # 每像素先算 (max-min)/max，再按行取平均——单看 R-B 会被墙面和苔斑带偏。
    px_max = band.max(axis=2)
    px_min = band.min(axis=2)
    sat = ((px_max - px_min) / np.maximum(px_max, 1.0)).mean(axis=1) * 255.0

    tests = {
        "warm": warm >= ROAD_WARM_DIFF,
        "cold": cold >= ROAD_COLD_DIFF,
        "pale": (lum >= ROAD_PALE_LUM) & (sat <= ROAD_PALE_SAT),
    }
    order = ["warm", "cold", "pale"] if tone == "auto" else [tone]
    y_lo = int(h * 0.30)
    min_thick = max(2, int(h * 0.02))

    candidates = []
    for name in order:
        mask = list(tests[name])
        for y in range(min(y_lo, len(mask))):
            mask[y] = False
        runs = _merge_runs(_mask_runs(mask), int(h * ROAD_MERGE_GAP))
        for run in runs:
            if run[1] - run[0] + 1 >= min_thick:
                candidates.append((name, run[0] / float(h), run[1] / float(h)))
    if not candidates:
        return None

    def foot_overlap(c):
        """候选带与脚底带的重叠比例（0~1）——路面必须罩住脚底，墙面罩不住。"""
        top, bottom = c[1], c[2]
        lo = max(top, FOOT_BAND[0])
        hi = min(bottom, FOOT_BAND[1])
        return max(0.0, hi - lo) / (FOOT_BAND[1] - FOOT_BAND[0])

    if tone == "auto":
        # 先看覆盖脚底带的能力，再看厚度：红墙/远处屋顶这类暖色大块会被脚底带淘汰。
        best = max(candidates, key=lambda c: (round(foot_overlap(c), 2), c[2] - c[1]))
        if foot_overlap(best) <= 0.0:
            # 谁都不罩脚底，就退化成「最厚的那段」，让 WARN 报出来
            best = max(candidates, key=lambda c: c[2] - c[1])
        return (best[1], best[2], best[0])
    best = max(candidates, key=lambda c: c[2] - c[1])
    return (best[1], best[2], best[0])



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


def crop_center_aspect(im: Image.Image, ratio: float) -> Image.Image:
    """把图居中裁成指定宽高比。

    为什么需要：warp_horizon 是「横向压到 512 宽」，它不做裁切——喂一张 1536x1024 的
    横幅进去，整幅会被横向压扁三倍。超宽构图（长卷）必须先按目标比例裁出一段竖构图，
    再进地平线重采样。裁中间不裁两边，是因为长卷的左右两端本来就是「可以继续延伸」的部分，
    真正有内容的中段才该留下。
    """
    if ratio <= 0.0:
        return im
    w, h = im.size
    cur = w / float(h)
    if abs(cur - ratio) < 0.005:
        return im
    if cur > ratio:                      # 太宽 → 裁左右
        nw = max(16, int(round(h * ratio)))
        x0 = (w - nw) // 2
        return im.crop((x0, 0, x0 + nw, h))
    nh = max(16, int(round(w / ratio)))  # 太高 → 裁上下
    y0 = (h - nh) // 2
    return im.crop((0, y0, w, y0 + nh))


def edge_diff(im: Image.Image, inset: int = 0) -> float:
    """左右两列的平均通道差（0~255 口径）。inset>0 时按 COVERED 裁切后的可见边缘量，
    因为游戏里 512 宽的图会被放大到 735 再左右各裁 17.5px，真正露在接缝处的是第 12 列和第 499 列。"""
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    h, w, _ = a.shape
    x0 = min(inset, w // 2 - 1)
    x1 = w - 1 - x0
    return float(np.abs(a[:, x0] - a[:, x1]).mean())


def detect_period(im: Image.Image, band: tuple = (0.20, 0.36), lo: int = 28, hi: int = 96) -> int:
    """估建筑/垛口这类「有固定节奏」的水平周期（像素）。

    在 band（画面高度比例）里取每列均值做一维自相关，取差最小的位移。
    band 默认压在墙体那一带（0.20~0.36）；纯雾/纯树林这段没有节奏，返回 0。
    lo 不能太小——砖缝本身也有十几像素的重复，会把垛口的真周期盖掉。
    """
    a = np.asarray(im.convert("L")).astype(np.float32)
    h, w = a.shape
    prof = a[int(h * band[0]):int(h * band[1]), :].mean(axis=0)
    prof = prof - prof.mean()
    if float(np.abs(prof).max()) < 6.0:
        return 0
    best_d, best_s = 1e18, 0
    for s in range(lo, min(hi, w // 3)):
        d = float(np.abs(prof[s:] - prof[:w - s]).mean())
        if d < best_d:
            best_d, best_s = d, s
    # 强度 = 1 - 残差/起伏。城墙 0.4 上下，树林/雾气约 0（自己跟自己都对不上），
    # 不过这一关的话「对齐」会把好图裁歪，所以宁可跳过。
    strength = 1.0 - best_d / max(float(prof.std()), 1e-6)
    if strength < 0.30:
        return 0
    return best_s


def align_period(im: Image.Image, period: int) -> Image.Image:
    """把画幅裁成周期的整数倍，再缩放回原宽度。

    这样首尾正好差整数个垛口，同图拼接时图案是连续往下走的，
    不需要大面积羽化（羽化会把一个垛口擦成"缺牙"）。
    """
    if period <= 0:
        return im
    w, h = im.size
    n = w // period
    if n < 6:
        return im
    cw = n * period
    x0 = (w - cw) // 2
    return im.crop((x0, 0, x0 + cw, h)).resize((w, h), Image.LANCZOS)


def edge_match(im: Image.Image, width: int) -> Image.Image:
    """把左右两条边羽化成**同一份内容**，让「同图首尾相接」真正无接缝。

    做法不是压黑也不是裁切，而是让第 0 列和第 w-1 列取两张边缘的均值，然后从边缘向里
    用余弦斜坡（外 1 内 0）过渡回原图。结果是：接缝处两边像素完全相同（差 0.0），
    而羽化带里只是把两边内容按比例混了一点——只要画的时候两端都是雾/远景，
    混起来看不出痕迹；两端如果不是同类内容，会看到一层薄薄的鬼影，
    这时候要回去重画，而不是把 width 调大。
    """
    a = np.asarray(im.convert("RGB")).astype(np.float32)
    h, w, _ = a.shape
    n = max(1, min(width, w // 2 - 1))
    for x in range(n):
        # 权重：最外列 1.0，向内衰减到 0
        wgt = 0.5 * (np.cos(np.pi * x / float(n)) + 1.0)
        avg = 0.5 * (a[:, x] + a[:, w - 1 - x])
        a[:, x] = a[:, x] * (1.0 - wgt) + avg * wgt
        a[:, w - 1 - x] = a[:, w - 1 - x] * (1.0 - wgt) + avg * wgt
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
                    help="检一遍路面是否盖住人物脚底那一带（52.7%%~61.7%%）")
    ap.add_argument("--road-tone", default="auto", choices=["auto", "warm", "cold", "pale"],
                    help="路面色调：warm 黄土/砂石、cold 冰面/雪道、pale 青石板/白石；auto 依次尝试")
    ap.add_argument("--edge-match", type=int, default=0, metavar="PX",
                    help="把左右边缘羽化成同一份内容（羽化带宽 PX 像素），让同图首尾相接无接缝。"
                         "前提是两端画的是同类东西（雾/远景），否则会出现鬼影")
    ap.add_argument("--period-align", action="store_true",
                    help="把画幅裁成「建筑节奏整数倍」再缩放回来：城墙垛口/栏杆这类有固定周期的图，"
                         "首尾会正好差整数个节奏，同图拼接不用大面积羽化也不会缺牙")
    ap.add_argument("--check-seam", action="store_true",
                    help="量左右边缘色差：<15 才算能走「重复铺」且不用压阴影带")
    ap.add_argument("--crop-aspect", type=float, default=0.0, metavar="R",
                    help="居中裁成宽高比 R 再处理（如 0.7314 = 512/700）。喂超宽长卷时必须给，"
                         "否则会被横向压扁。0 表示不裁")
    args = ap.parse_args()

    im = Image.open(args.src).convert("RGB")
    im = trim_edges(im, args.trim_side, args.trim_bottom, args.trim_top)
    if args.crop_aspect > 0.0:
        im = crop_center_aspect(im, args.crop_aspect)
    if not args.no_patch:
        im = patch_watermark(im)
    im = warp_horizon(im, args.horizon, args.target_horizon)
    # 轻微锐化：重采样后水墨笔触会发糊
    im = im.filter(ImageFilter.UnsharpMask(radius=1.2, percent=55, threshold=2))
    im = grade(im, args.contrast, args.sat, args.gamma)
    if args.burn_side > 0.0 or args.burn_top > 0.0:
        im = edge_burn(im, args.burn_side, args.burn_top)

    # 接缝：先量原始边缘色差，再做（可选的）边缘同质化。顺序不能反，
    # 否则量到的是羽化后的 0.0，等于没检。
    if args.period_align:
        period = detect_period(im)
        if period > 0:
            im = align_period(im, period)
            print("  [周期] 检出 %.0fpx 节奏，画幅已对齐到整数倍（羽化带可以给得很小）" % period)
        else:
            print("  [周期] 没检出明显节奏（纯雾/树林），跳过对齐")

    seam_before = edge_diff(im, 0)
    seam_before_vis = edge_diff(im, VIS_EDGE_INSET)
    if args.edge_match > 0:
        if args.burn_side > 0.0:
            print("  [接缝] 警告：--burn-side>0 会在左右压出墨边，和 --edge-match 相冲，卷轴图应给 0")
        im = edge_match(im, args.edge_match)
    seam_after = edge_diff(im, 0)

    size = save_jpeg(im, args.out, args.target_kb)
    print(f"{os.path.basename(args.out)}  {OUT_W}x{OUT_H}  {size/1024:.0f}KB  horizon={args.target_horizon:.0%}")
    if args.check_seam or args.edge_match > 0:
        verdict = "可重复铺（不用镜像、不用阴影带）" if seam_after <= SEAM_OK else "边缘还对不上 → 仍走镜像"
        print("  [接缝] 原始边缘差 %.1f（可见边缘 %.1f）→ 处理后 %.1f   %s" % (
            seam_before, seam_before_vis, seam_after, verdict))
    if args.check_road:
        band = detect_road_band(im, args.road_tone)
        tone_label = {"warm": "暖色路面", "cold": "冷色路面", "pale": "浅色石面"}
        if band is None:
            print("  [主道] 没检出连续路面（暖/冷/浅三种色调都对不上）—— 人和宠会站在背景上，重画时把主道画宽一点")
        else:
            top, bot, tone = band
            covers_foot = top <= FOOT_BAND[0] and bot >= FOOT_BAND[1]
            print("  [主道] %s y=%.0f%%~%.0f%%  脚底带 %.0f%%~%.0f%%  %s" % (
                tone_label.get(tone, tone), top * 100, bot * 100,
                FOOT_BAND[0] * 100, FOOT_BAND[1] * 100,
                "OK（站得住）" if covers_foot else "WARN（脚会踩在背景上，建议主道上沿 ≤%.0f%%、下沿 ≥%.0f%%）"
                % (FOOT_BAND[0] * 100, FOOT_BAND[1] * 100)))
    if args.save_preview:
        im.save(args.save_preview, "PNG")


if __name__ == "__main__":
    sys.exit(main())
