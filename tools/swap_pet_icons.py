#!/usr/bin/env python3
"""从新的战斗立绘派生 128x128 宠物图标，替换 assets/pets/ 里的旧画风图标。

背景：新水墨立绘已经落在 assets/sprites/{id}_idle.png（图集，每帧 256x256），
但背包 / 宠物详情 / 阵容这些界面用的还是 assets/pets/{id}.png（128x128，原游戏旧画风），
于是同一只宠物在战斗里是新水墨、在列表里还是旧画风。

做法：取立绘第 0 帧 → 裁掉透明边 → 等比缩放居中放进 128x128（留白边距）。
这样图标和战斗立绘天然是同一只、同一个画风，不会两张皮。

用法：
    python3 tools/swap_pet_icons.py --dry-run     # 只统计会改哪些
    python3 tools/swap_pet_icons.py               # 真替换（旧图备份到 outputs/）
    python3 tools/swap_pet_icons.py --margin=4    # 留白边距（设计像素）
"""

import argparse
import json
import os
import shutil

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES = os.path.join(ROOT, "assets", "sprites")
PETS = os.path.join(ROOT, "assets", "pets")
BACKUP = os.path.join(os.path.dirname(ROOT), "assets_backup", "pets_icons_old")

ICON_SIZE = 128
FRAME = 256


def trim_and_fit(img: Image.Image, size: int, margin: int) -> Image.Image:
    """裁透明边 → 等比缩放 → 居中放进 size×size 的透明底。"""
    rgba = img.convert("RGBA")
    bbox = rgba.split()[3].getbbox()
    if bbox is None:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cropped = rgba.crop(bbox)
    inner = size - margin * 2
    scale = min(inner / cropped.width, inner / cropped.height)
    nw, nh = max(1, int(round(cropped.width * scale))), max(1, int(round(cropped.height * scale)))
    small = cropped.resize((nw, nh), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(small, ((size - nw) // 2, (size - nh) // 2), small)
    return canvas


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--margin", type=int, default=6)
    ap.add_argument("--only", default="", help="只处理 id 含该子串的")
    args = ap.parse_args()

    sheets = sorted(f for f in os.listdir(SPRITES) if f.endswith("_idle.png"))
    done, skipped, missing = 0, 0, []
    for f in sheets:
        pid = f[: -len("_idle.png")]
        if args.only and args.only not in pid:
            continue
        icon_path = os.path.join(PETS, pid + ".png")
        sheet_path = os.path.join(SPRITES, f)
        if not os.path.exists(icon_path):
            missing.append(pid)
            continue
        sheet = Image.open(sheet_path)
        if sheet.width < FRAME:
            skipped += 1
            continue
        frame0 = sheet.crop((0, 0, FRAME, FRAME))
        new_icon = trim_and_fit(frame0, ICON_SIZE, args.margin)
        if args.dry_run:
            done += 1
            continue
        # 备份旧图（只备份一次）
        bak = os.path.join(BACKUP, pid + ".png")
        if not os.path.exists(bak):
            os.makedirs(BACKUP, exist_ok=True)
            shutil.copy2(icon_path, bak)
        new_icon.save(icon_path, optimize=True)
        done += 1
    print("处理 %d 张，跳过 %d 张（无对应图标 %d 个）" % (done, skipped, len(missing)))
    if missing:
        print("  无旧图标、这次没生成：", missing[:12], "..." if len(missing) > 12 else "")
    if not args.dry_run:
        print("旧图标备份：", BACKUP)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
