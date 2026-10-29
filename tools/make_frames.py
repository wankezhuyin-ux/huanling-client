"""用单张立绘程序化生成战斗帧条（idle / attack）。

思路：不再逐帧描原版，而是拿一张全新立绘，按自己定的节奏做位移/缩放/倾斜/
冲击墨迹，生成与原来同尺寸、同帧数的帧条。游戏代码零改动。

因为所有帧来自同一张源图，帧间绝不会变形或闪烁。

用法：
  python3 make_frames.py --src portrait.png --kind idle   --frames 3 --dst out.png
  python3 make_frames.py --src portrait.png --kind attack --frames 4 --dst out.png
参数：
  --height  角色在 256 帧里的目标高度（像素）
  --size    帧边长，默认 256（与原素材一致）
"""
import argparse
import math
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def cut_white(im, thresh=36):
    """从四角泛洪，把连通的近白背景抠成透明。"""
    im = im.convert("RGB")
    w, h = im.size
    sentinel = (255, 0, 255)
    px = im.load()
    for corner in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if sum(abs(a - b) for a, b in zip(px[corner], (255, 255, 255))) < 60:
            ImageDraw.floodfill(im, corner, sentinel, thresh=thresh)
    arr = np.asarray(im).astype(np.int16)
    mask = np.abs(arr - np.array(sentinel)).sum(axis=2) < 12
    if mask.mean() > 0.95:  # 没有可抠的白底
        return im.convert("RGBA")
    alpha = np.where(mask, 0, 255).astype(np.uint8)
    a = Image.fromarray(alpha).filter(ImageFilter.MinFilter(3))
    rgb = arr.astype(np.uint8)
    rgb[mask] = 0
    return Image.fromarray(np.dstack([rgb, np.asarray(a)]), "RGBA")


def load_sticker(src, target_h):
    """返回裁好、缩放到目标高度的 RGBA 角色贴图。"""
    im = Image.open(src).convert("RGBA")
    if im.getchannel("A").getextrema()[0] > 200:  # 全不透明，尝试抠白
        im = cut_white(im)
    bb = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if bb:
        im = im.crop(bb)
    s = target_h / im.height
    return im.resize((max(1, round(im.width * s)), target_h), Image.LANCZOS)


def place(sticker, size, dx=0.0, dy=0.0, scale=1.0, rot=0.0, base_y=None):
    """缩放 + 绕自身中心旋转，再按实际脚底对齐，保证帧间脚下不漂。"""
    w = max(1, round(sticker.width * scale))
    h = max(1, round(sticker.height * scale))
    im = sticker.resize((w, h), Image.LANCZOS)
    if abs(rot) > 0.01:
        im = im.rotate(rot, resample=Image.BICUBIC, expand=True)
        bb = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
        if bb:
            im = im.crop(bb)
    base_y = size - 58 if base_y is None else base_y
    x = round((size - im.width) / 2 + dx)
    y = round(base_y - im.height + dy)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(im, (x, y), im)
    return canvas


def ink_slash(size, cx, cy, length, seed=7):
    """画三道飞白墨条，表示出手方向。"""
    rng = np.random.default_rng(seed)
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    for k in range(3):
        y0 = cy + (k - 1) * 9 + rng.integers(-3, 4)
        x0 = cx
        x1 = cx + length * (0.75 + 0.25 * rng.random())
        th = max(1, 4 - k)
        d.line([(x0, y0), (x1, y0 + rng.integers(-6, 7))], fill=(28, 26, 24, 200 - k * 45), width=th)
    for _ in range(7):
        px = cx + int(rng.integers(0, int(length * 0.9)))
        py = cy + int(rng.integers(-16, 17))
        r = int(rng.integers(1, 4))
        d.ellipse([px - r, py - r, px + r, py + r], fill=(30, 28, 26, 170))
    return layer.filter(ImageFilter.GaussianBlur(0.6))


def build(src, kind, frames, size=256, height=150):
    st = load_sticker(src, height)
    out = Image.new("RGBA", (size * frames, size), (0, 0, 0, 0))
    if kind == "idle":
        # 呼吸：上下浮动 + 极轻微缩放 + 微幅摇摆，脚底不动
        plan = []
        for i in range(frames):
            ph = math.sin(2 * math.pi * i / frames)
            plan.append((0.0, -2.0 * abs(ph), 1.0 + 0.020 * ph, 1.0 * ph))
        plan = [(0, dx, dy, sc, rt) for dx, dy, sc, rt in plan]
    else:
        # 蓄力 → 前冲 → 出手 → 回位
        seq = [
            (-8.0, 2.0, 0.955, -6.0),
            (7.0, -4.0, 1.045, 7.0),
            (15.0, -2.0, 1.070, 4.0),
            (4.0, 0.0, 1.000, 1.0),
        ]
        plan = [(0, dx, dy, sc, rt) for dx, dy, sc, rt in seq]
        if frames != len(plan):
            plan = [plan[i % len(plan)] for i in range(frames)]
    for i, (_, dx, dy, sc, rt) in enumerate(plan):
        f = place(st, size, dx=dx, dy=dy, scale=sc, rot=rt)
        if kind == "attack" and i == 2:
            f = Image.alpha_composite(f, ink_slash(size, int(size * 0.62), int(size * 0.54), 60))
        out.paste(f, (i * size, 0))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src", required=True)
    ap.add_argument("--kind", choices=["idle", "attack"], required=True)
    ap.add_argument("--frames", type=int, required=True)
    ap.add_argument("--dst", required=True)
    ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--height", type=int, default=196)
    a = ap.parse_args()
    im = build(a.src, a.kind, a.frames, a.size, a.height)
    os.makedirs(os.path.dirname(os.path.abspath(a.dst)), exist_ok=True)
    im.save(a.dst)
    print(f"{a.dst}  {im.size}  {a.frames} 帧")


if __name__ == "__main__":
    main()
