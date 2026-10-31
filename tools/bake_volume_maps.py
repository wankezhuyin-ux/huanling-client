#!/usr/bin/env python3
"""为战斗立绘烘焙「体积高度图」（volume map）。

立绘是 AI 生出来的平面插画，shader 里再怎么用明度当高度场也挖不出体积，
因为画面内部本来就是平涂。这个脚本要造一个真正的「充气」高度场。

**为什么不用距离变换（EDT）**：
EDT 的等高线是「到轮廓的距离」，等距线彼此平行，法线在整个内部是一把
放射状的扇形。用它打光，亮暗只会围着剪影转一圈 —— 看着像给贴纸描了道光边，
内部永远是平的（这正是「纸片感」的成因，调参调不掉）。

改成解**泊松方程** ∇²h = -1（内部）/ h = 0（轮廓上）：
它等价于「一张绷在轮廓上的膜，被均匀气压顶起来」。圆的解析解是抛物面
h = (R² - r²)/4 —— 梯度在正中心为零、往边缘线性变大，也就是一颗球该有的样子；
细长的胳膊腿解出来是抛物柱面，正好是一根圆管。这才是能打出体积的高度场。

    alpha 掩膜 → 泊松方程红黑 SOR 求解（多分辨率初值加速）→ 压缩到 0~1

不再掺原图明度：那点高频笔触进了法线就是一层噪点，水墨的笔意靠颜色本身就有。

输出与源图**同样的版式**（同样帧数、每帧半分辨率），这样 shader 里直接
texture(volume_tex, UV) 就能对齐——不需要额外传帧偏移。

用法：
    python3 tools/bake_volume_maps.py                # 全部 *_idle/_attack
    python3 tools/bake_volume_maps.py --only nawahuo  # 只重烤匹配的文件
    python3 tools/bake_volume_maps.py --force         # 忽略缓存全部重烤
"""

import argparse
import glob
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "assets", "sprites")
OUT_DIR = os.path.join(SRC_DIR, "vol")

FRAME_W = 256
FRAME_H = 256
SCALE = 0.5           # 输出半分辨率：体积场是低频的，半分辨率足够且省包体

# —— 泊松解 ——
SOR_OMEGA = 1.90      # 超松弛因子（128 网格接近最优）
COARSE_ITERS = 400    # 1/4 分辨率粗解
FINE_ITERS = 90       # 1/2 分辨率精解（粗解升采样当初值）
# 软压缩：h/(h+T)，把抛物面的巨大动态范围（大躯干 R² 级）压到 0~1，
# 又不改变梯度的相对走向 —— 细胳膊照样保留自己的圆柱明暗。
COMPRESS_T = 0.30
HEIGHT_GAMMA = 0.90


def sor_solve(solid: np.ndarray, h0: np.ndarray, iters: int) -> np.ndarray:
    """红黑 SOR 解 ∇²h = -1。solid 外恒为 0（Dirichlet 边界）。

    纯 numpy 向量化：每轮先把「红格」一次全更新，再更新黑格。
    红格的四个邻居全是黑格，所以这种更新等价于逐点 Gauss-Seidel，能收敛。
    """
    h = np.array(h0, dtype=np.float64)
    h[~solid] = 0.0
    yy, xx = np.indices(h.shape)
    red = ((yy + xx) & 1) == 0
    rmask = solid & red
    bmask = solid & (~red)
    for _ in range(iters):
        for mask in (rmask, bmask):
            s = (np.roll(h, 1, 0) + np.roll(h, -1, 0)
                 + np.roll(h, 1, 1) + np.roll(h, -1, 1) + 1.0) * 0.25
            h = np.where(mask, h + SOR_OMEGA * (s - h), h)
    return h


def membrane(solid: np.ndarray) -> np.ndarray:
    """多分辨率求解：1/4 粗解 → 升采样 → 1/2 精解。"""
    n = solid.shape[0]
    s4 = solid[::4, ::4]
    h4 = sor_solve(s4, np.zeros(s4.shape), COARSE_ITERS)
    h0 = np.repeat(np.repeat(h4, 4, 0), 4, 1)[:n, :n]
    return sor_solve(solid, h0, FINE_ITERS)


def frame_height(frame_rgba: np.ndarray) -> np.ndarray:
    """单帧 → 0~1 高度场。"""
    a = frame_rgba[:, :, 3].astype(np.float64) / 255.0
    solid = a > 0.45
    if not solid.any():
        return np.zeros(a.shape, dtype=np.float32)

    h = membrane(solid)
    pmax = float(h[solid].max())
    if pmax <= 1e-6:
        return np.zeros(a.shape, dtype=np.float32)

    # 先按本帧最高点归一：不同体型的立绘都得到同样强度的打光
    hn = h / pmax
    hn = hn / (hn + COMPRESS_T)
    hn = np.clip(hn / (1.0 / (1.0 + COMPRESS_T)), 0.0, 1.0) ** HEIGHT_GAMMA
    hn = hn * np.clip(a * 1.6, 0.0, 1.0)   # 软边处往 0 收，避免边缘出一圈硬坎
    return hn.astype(np.float32)


def bake_one(src_path: str, out_path: str) -> bool:
    im = Image.open(src_path).convert("RGBA")
    w, h = im.size
    frames = w // FRAME_W
    if frames < 1:
        return False

    out_w = max(1, int(round(w * SCALE)))
    out_h = max(1, int(round(h * SCALE)))
    out = np.zeros((out_h, out_w), dtype=np.float32)

    for fi in range(frames):
        tile = im.crop((fi * FRAME_W, 0, (fi + 1) * FRAME_W, FRAME_H))
        tile = tile.resize((int(FRAME_W * SCALE), int(FRAME_H * SCALE)), Image.BOX)
        arr = np.asarray(tile, dtype=np.uint8)
        field = frame_height(arr)
        fw = int(FRAME_W * SCALE)
        fh = int(FRAME_H * SCALE)
        out[0:fh, fi * fw:(fi + 1) * fw] = field[:fh, :fw]

    img = Image.fromarray(np.clip(out * 255.0, 0, 255).astype(np.uint8), mode="L")
    # 轻微模糊：距离场在半分辨率下会有阶梯，抹一下法线才顺
    img = img.filter(ImageFilter.GaussianBlur(1.1))
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    img.save(out_path, optimize=True)
    return True


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", default="", help="只处理文件名包含该子串的源图")
    ap.add_argument("--force", action="store_true", help="忽略已存在的输出")
    args = ap.parse_args()

    # 递归：进化宠物的链专属图放在 assets/sprites/evo/ 下
    srcs = sorted(glob.glob(os.path.join(SRC_DIR, "**", "*_idle.png"), recursive=True))
    srcs += sorted(glob.glob(os.path.join(SRC_DIR, "**", "*_attack.png"), recursive=True))
    if args.only:
        srcs = [p for p in srcs if args.only in os.path.basename(p)]

    made = 0
    skipped = 0
    total_bytes = 0
    for p in srcs:
        stem = os.path.splitext(os.path.basename(p))[0]
        # 源图在 assets/sprites/evo/x.png → 体积图在 assets/sprites/vol/evo/x_vol.png
        rel = os.path.relpath(os.path.dirname(p), SRC_DIR)
        out_dir = OUT_DIR if rel == "." else os.path.join(OUT_DIR, rel)
        out = os.path.join(out_dir, stem + "_vol.png")
        if not args.force and os.path.exists(out) and os.path.getmtime(out) >= os.path.getmtime(p):
            skipped += 1
            continue
        if bake_one(p, out):
            made += 1
            total_bytes += os.path.getsize(out)
    print("烘焙 %d 张，跳过 %d 张，新增 %.1f MB" % (made, skipped, total_bytes / 1048576.0))
    print("输出目录：", OUT_DIR)
    return 0


if __name__ == "__main__":
    sys.exit(main())
