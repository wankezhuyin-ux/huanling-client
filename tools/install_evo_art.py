#!/usr/bin/env python3
"""把「进化宠物的链专属美术」装进游戏。

为什么需要：进化形态 id 在不同链之间是**复用**的 —— yu_yi 既是盈盈（紫蝶）的
普通形态，也是赤翅蛾的变异形态。一张图共用，就等于「蝴蝶进化成了蛾子」，
那不是进化是换物种。所以美术按「原物种 + 形态」出图，落到 assets/sprites/evo/。

输入约定（生图产出放这里）：
    outputs/ai-restyle/evo/{origin}/{form}.png     单张 1024 左右的方图（透明底）

安装产物：
    assets/sprites/evo/{origin}_{form}_idle.png     2 帧待机（呼吸循环）
    assets/sprites/evo/{origin}_{form}_attack.png   3 帧攻击（起手/前冲/收势）
    assets/pets/evo/{origin}_{form}.png             128x128 背包图标
    assets/sprites/vol/evo/{origin}_{form}_*_vol.png  体积图（由 bake_volume_maps.py 烘）

客户端查图优先级：链专属图 → 共用形态图 → 旧图（都不会开天窗）。

用法：
    python3 tools/install_evo_art.py --origin yingying      # 装一条链
    python3 tools/install_evo_art.py --all                 # 装全部已产出的
"""

import argparse
import glob
import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_ROOT = os.path.join(os.path.dirname(ROOT), "ai-restyle", "evo")
SPRITES = os.path.join(ROOT, "assets", "sprites", "evo")
PETS = os.path.join(ROOT, "assets", "pets", "evo")

FRAME = 256
IDLE_FRAMES = 2
ATTACK_FRAMES = 3
ICON = 128


def fit_frame(img: Image.Image, scale: float = 1.0, dx: float = 0.0, dy: float = 0.0) -> Image.Image:
    """把一张方图放进 256x256 帧：等比缩放、底部居中（脚底对齐），可微调。"""
    im = img.convert("RGBA")
    bb = im.split()[3].getbbox()
    if bb:
        im = im.crop(bb)
    inner = int(FRAME * 0.86 * scale)
    s = min(inner / im.width, inner / im.height)
    nw, nh = max(1, int(im.width * s)), max(1, int(im.height * s))
    im = im.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (FRAME, FRAME), (0, 0, 0, 0))
    canvas.alpha_composite(im, ((FRAME - nw) // 2 + int(dx), FRAME - nh + int(dy)))
    return canvas


def build_idle(src: Image.Image) -> Image.Image:
    """待机：轻微呼吸（缩放 + 上下浮动），循环两帧。"""
    sheet = Image.new("RGBA", (FRAME * IDLE_FRAMES, FRAME), (0, 0, 0, 0))
    for i in range(IDLE_FRAMES):
        k = 1.0 if i == 0 else 1.035
        dy = 0 if i == 0 else -3
        sheet.alpha_composite(fit_frame(src, scale=k, dy=dy), (i * FRAME, 0))
    return sheet


def build_attack(src: Image.Image) -> Image.Image:
    """攻击：起手（后仰微缩）→ 前冲放大前移 → 收势。"""
    sheet = Image.new("RGBA", (FRAME * ATTACK_FRAMES, FRAME), (0, 0, 0, 0))
    poses = [(0.97, -6, 4), (1.10, 16, 0), (1.02, 4, 0)]
    for i, (k, dx, dy) in enumerate(poses):
        sheet.alpha_composite(fit_frame(src, scale=k, dx=dx, dy=dy), (i * FRAME, 0))
    return sheet


def build_icon(src: Image.Image) -> Image.Image:
    im = src.convert("RGBA")
    bb = im.split()[3].getbbox()
    if bb:
        im = im.crop(bb)
    inner = ICON - 12
    s = min(inner / im.width, inner / im.height)
    im = im.resize((max(1, int(im.width * s)), max(1, int(im.height * s))), Image.LANCZOS)
    canvas = Image.new("RGBA", (ICON, ICON), (0, 0, 0, 0))
    canvas.alpha_composite(im, ((ICON - im.width) // 2, (ICON - im.height) // 2))
    return canvas


def install(origin: str, forms: list) -> int:
    os.makedirs(SPRITES, exist_ok=True)
    os.makedirs(PETS, exist_ok=True)
    n = 0
    for form in forms:
        src_path = os.path.join(SRC_ROOT, origin, form + ".png")
        if not os.path.exists(src_path):
            continue
        src = Image.open(src_path)
        base = "%s_%s" % (origin.lower(), form.lower())
        build_idle(src).save(os.path.join(SPRITES, base + "_idle.png"), optimize=True)
        build_attack(src).save(os.path.join(SPRITES, base + "_attack.png"), optimize=True)
        build_icon(src).save(os.path.join(PETS, base + ".png"), optimize=True)
        n += 1
    return n


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--origin", default="")
    ap.add_argument("--all", action="store_true")
    args = ap.parse_args()

    origins = []
    if args.all or not args.origin:
        origins = sorted(os.listdir(SRC_ROOT)) if os.path.isdir(SRC_ROOT) else []
    else:
        origins = [args.origin]

    total = 0
    for o in origins:
        d = os.path.join(SRC_ROOT, o)
        if not os.path.isdir(d):
            continue
        forms = sorted(os.path.splitext(f)[0] for f in os.listdir(d) if f.endswith(".png"))
        if not forms:
            continue
        n = install(o, forms)
        total += n
        print("  %-16s 装入 %d 个形态：%s" % (o, n, ", ".join(forms)))
    print("共装入 %d 个链专属形态" % total)
    print("下一步：烘体积图 —— python3 tools/bake_volume_maps.py --only %s --force" % (origins[0] if origins else "<origin>"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
