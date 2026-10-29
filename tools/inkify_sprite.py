"""战斗帧/立绘的水墨化处理（程序化，保持帧对齐）。

原理：不重画结构，只做墨色重映射——把彩色压成五级墨阶（焦/浓/重/淡/清），
保留少量原始色相（石绿、赭石）作为点缀，再叠一层宣纸纤维噪声。
透明通道原样保留，帧边界不动，所以动画不会闪。

用法：
  python3 inkify_sprite.py --src a.png --dst b.png
  python3 inkify_sprite.py --ids nawahuo,linlin --apply
"""
import argparse
import os
import shutil

import numpy as np
from PIL import Image, ImageFilter

GAME = os.path.expanduser("~/Documents/Codex/2026-10-21/n/outputs/recovered-godot-project")

# 五级墨阶：焦、浓、重、淡、清
INK = np.array([
    [28, 26, 24],
    [72, 66, 58],
    [116, 106, 94],
    [166, 154, 140],
    [212, 202, 186],
], dtype=np.float32)


def inkify(im, keep_color=0.30, posterize=True, paper=5.0):
    im = im.convert("RGBA")
    arr = np.asarray(im).astype(np.float32)
    rgb, alpha = arr[..., :3], arr[..., 3:]

    lum = rgb @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    # 去饱和：往灰度收，但留 keep_color 比例的原始色相
    gray = np.repeat(lum[..., None], 3, axis=2)
    base = gray * (1 - keep_color) + rgb * keep_color

    # 把亮度映射到五级墨阶
    l0, l1 = float(lum.min()), float(lum.max())
    t = (lum - l0) / max(1e-6, (l1 - l0))
    idx = np.clip((t * 4.999).astype(np.int32), 0, 4)
    ink = INK[idx]

    # 保留一点原始色的走向：按 base 与灰度的差做微调
    tint = (base - gray) * 0.55
    out = ink + tint

    if not posterize:
        # 不量化时改用连续映射，笔画更细腻
        cont = INK[0][None, None, :] * 0 + (INK[-1] - INK[0])[None, None, :] * t[..., None] + INK[0]
        out = cont * 0.5 + out * 0.5

    # 宣纸纤维噪声
    rng = np.random.default_rng(7)
    noise = rng.normal(0, paper, lum.shape)[..., None]
    out = out + noise

    out = np.clip(out, 0, 255)
    res = np.concatenate([out, alpha], axis=2).astype(np.uint8)
    img = Image.fromarray(res, "RGBA")
    # 墨线强化：轻微锐化，让轮廓更挺
    rgb_im = img.convert("RGB").filter(ImageFilter.UnsharpMask(radius=1.2, percent=70, threshold=2))
    rgb_im = rgb_im.convert("RGBA")
    rgb_im.putalpha(img.split()[-1])
    return rgb_im


def process(src, dst, **kw):
    im = Image.open(src)
    out = inkify(im, **kw)
    out.save(dst)
    return dst


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src")
    ap.add_argument("--dst")
    ap.add_argument("--ids", help="逗号分隔的怪物 id，处理 pets 与 sprites 下全部文件")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--keep-color", type=float, default=0.30)
    a = ap.parse_args()

    if a.ids:
        ids = [x.strip() for x in a.ids.split(",") if x.strip()]
        jobs = []
        for pid in ids:
            for sub in ("pets", "sprites"):
                d = os.path.join(GAME, "assets", sub)
                for f in sorted(os.listdir(d)):
                    if f.startswith(pid) and f.endswith(".png"):
                        jobs.append(os.path.join(d, f))
        print(f"待处理 {len(jobs)} 个文件")
        for p in jobs:
            rel = os.path.relpath(p, GAME)
            out = p.replace(".png", "_ink.png") if not a.apply else p
            process(p, out, keep_color=a.keep_color)
            if a.apply:
                print("  覆盖", rel)
        if not a.apply:
            print("预览完成（未替换）；--apply 才会覆盖原文件")
        return

    if not a.src or not a.dst:
        ap.error("需要 --src/--dst 或 --ids")
    process(a.src, a.dst, keep_color=a.keep_color)
    print("ok", a.dst)


if __name__ == "__main__":
    main()
