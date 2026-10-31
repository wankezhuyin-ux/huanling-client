#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按游戏里的真实坐标算一遍战场站位，用真实立绘和背景合成对比图。

坐标公式与 ui/main_ui.gd 里的
_battle_grid_monster_slot_pos / _battle_grid_ally_slot_pos 保持一致，
调参时不用反复进游戏截图。

站位已回退原版网格布局：敌方按「列 + 行」铺（每列 3~4 只），
我方主角与宠物各占一格、行号相同（左右相邻），没有斜阵也没有近大远小。
"""
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 720, 470

# 与 main_ui.gd 对齐
ROW_MEMBER, ROW_LEADER, ROW_RESERVE_BOTTOM = 2, 1, 3
ROW_STEP = 135.0
MON_ROW_STEP = 96.0
COL_STEP = 135.0
COL0_X = 415.0
ALLY_PLAYER_X = -5.0
ALLY_PET_X = 120.0
ALLY_SHIFT_X = 30.0
WILD_Y = -13.0


def monster_pos(idx, total):
    per_col = 4 if total > 6 else 3
    col = idx // per_col
    role = min(idx % per_col, per_col - 1)
    row = [ROW_MEMBER, ROW_LEADER, ROW_RESERVE_BOTTOM, 0][role]
    y = 270.0 + (row - ROW_MEMBER) * MON_ROW_STEP + WILD_Y
    x = COL0_X + col * COL_STEP
    return x, y


def ally_pos(is_pet):
    x = (ALLY_PET_X if is_pet else ALLY_PLAYER_X) + ALLY_SHIFT_X
    y = 270.0
    return x, y


def load_unit(path, cx, foot_y, height):
    im = Image.open(path).convert("RGBA")
    r = height / im.height
    im = im.resize((max(1, int(im.width * r)), int(height)), Image.LANCZOS)
    return im, (int(cx - im.width / 2), int(foot_y - height))


def draw_shadow(layer, cx, foot_y, width, strength=95):
    d = ImageDraw.Draw(layer)
    rh = max(6, int(width * 0.22))
    d.ellipse([cx - width / 2, foot_y - rh / 2, cx + width / 2, foot_y + rh / 2],
              fill=(20, 18, 16, strength))


def cover(im, w, h):
    r = max(w / im.width, h / im.height)
    im = im.resize((int(im.width * r), int(im.height * r)), Image.LANCZOS)
    x = (im.width - w) // 2
    y = (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def compose(monsters):
    bg = Image.open(os.path.join(ROOT, "assets/backgrounds/迷踪林.jpg")).convert("RGB")
    bg = cover(bg, W, H).convert("RGBA")
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    units = []
    px, py = ally_pos(False)
    units.append(("assets/portraits/player.png", px + 50, py + 100, 128))
    qx, qy = ally_pos(True)
    units.append(("assets/pets/nawahuo.png", qx + 60, qy + 126, 104))

    total = len(monsters)
    for i, pid in enumerate(monsters):
        mx, my = monster_pos(i, total)
        units.append((f"assets/pets/{pid}.png", mx + 65, my + 126, 96))

    for path, cx, foot, h in units:
        draw_shadow(shade, cx, foot - 4, h * 0.85)

    shade = shade.filter(ImageFilter.GaussianBlur(4))
    bg.alpha_composite(shade)

    for path, cx, foot, h in units:
        im, pos = load_unit(os.path.join(ROOT, path), cx, foot, h)
        bg.alpha_composite(im, pos)

    return bg.convert("RGB")


def main():
    monsters = ["linlin", "duxing", "yùlíntù", "xiǎodīngdōng", "lèngtóuqīng"]
    shot = compose(monsters)

    gap = 34
    canvas = Image.new("RGB", (W, H + gap + 96), (24, 22, 20))
    canvas.paste(shot, (0, 52))

    d = ImageDraw.Draw(canvas)
    f = None
    for path, idx in (("/System/Library/Fonts/PingFang.ttc", 2),
                      ("/System/Library/Fonts/PingFang.ttc", 0),
                      ("/System/Library/Fonts/Hiragino Sans GB.ttc", 0),
                      ("/System/Library/Fonts/STHeiti Light.ttc", 0)):
        try:
            f = ImageFont.truetype(path, 22, index=idx)
            break
        except Exception:
            continue
    if f is None:
        f = ImageFont.load_default()
    d.text((24, 14), "原版站位：怪物按列铺开，我方角色与宠物左右相邻", fill=(235, 230, 222), font=f)

    out = os.path.join(ROOT, "docs/站位对比.png")
    canvas.save(out)
    print("已生成", os.path.relpath(out, ROOT), canvas.size)


if __name__ == "__main__":
    main()
