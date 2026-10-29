#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按游戏里的真实坐标算一遍战场站位，用真实立绘和背景合成对比图。

改前 / 改后两张，坐标公式与 ui/main_ui.gd 里的
_battle_grid_monster_slot_pos / _battle_grid_ally_slot_pos 保持一致，
调参时不用反复进游戏截图。
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
SLANT_Y = 34.0
SLANT_X_PULL = 14.0
SLANT_ROW_X = 22.0
PERSP_NEAR, PERSP_FAR = 1.0, 0.86
PERSP_Y_NEAR, PERSP_Y_FAR = 440.0, 40.0


def clamp(v, lo, hi):
    return max(lo, min(hi, v))


def monster_pos(idx, total, new_layout):
    per_col = 4 if total > 6 else 3
    col = idx // per_col
    role = min(idx % per_col, per_col - 1)
    row = [ROW_MEMBER, ROW_LEADER, ROW_RESERVE_BOTTOM, 0][role]
    y = 270.0 + (row - ROW_MEMBER) * MON_ROW_STEP + WILD_Y
    x = COL0_X + col * COL_STEP
    if new_layout:
        y -= col * SLANT_Y
        x -= col * SLANT_X_PULL
        x -= (row - ROW_MEMBER) * SLANT_ROW_X
    return x, y


def ally_pos(is_pet, new_layout):
    x = (ALLY_PET_X if is_pet else ALLY_PLAYER_X) + ALLY_SHIFT_X
    y = 270.0 + (8.0 if (is_pet and new_layout) else 0.0)
    return x, y


def persp_scale(y):
    t = clamp((y - PERSP_Y_FAR) / (PERSP_Y_NEAR - PERSP_Y_FAR), 0.0, 1.0)
    return PERSP_FAR + (PERSP_NEAR - PERSP_FAR) * t


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


def compose(new_layout, monsters):
    bg = Image.open(os.path.join(ROOT, "assets/backgrounds/迷踪林.jpg")).convert("RGB")
    bg = cover(bg, W, H).convert("RGBA")
    shade = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    units = []
    px, py = ally_pos(False, new_layout)
    units.append(("assets/portraits/player.png", px + 50, py + 100, 128, 1.0))
    qx, qy = ally_pos(True, new_layout)
    units.append(("assets/pets/nawahuo.png", qx + 60, qy + 126, 104, persp_scale(qy)))

    total = len(monsters)
    for i, pid in enumerate(monsters):
        mx, my = monster_pos(i, total, new_layout)
        s = persp_scale(my) if new_layout else 1.0
        units.append((f"assets/pets/{pid}.png", mx + 65, my + 126, 96 * s, s))

    for path, cx, foot, h, _s in units:
        draw_shadow(shade, cx, foot - 4, h * 0.85)

    shade = shade.filter(ImageFilter.GaussianBlur(4))
    bg.alpha_composite(shade)

    for path, cx, foot, h, _s in units:
        im, pos = load_unit(os.path.join(ROOT, path), cx, foot, h)
        bg.alpha_composite(im, pos)

    d = ImageDraw.Draw(bg)
    if new_layout:
        pts = []
        for i in range(len(monsters)):
            mx, my = monster_pos(i, len(monsters), True)
            pts.append((mx + 65, my + 66))
        pts.sort(key=lambda p: (p[1], p[0]))
        if len(pts) > 1:
            d.line(pts, fill=(210, 90, 60, 120), width=2)
    return bg.convert("RGB")


def main():
    monsters = ["linlin", "duxing", "yùlíntù", "xiǎodīngdōng", "lèngtóuqīng"]
    old = compose(False, monsters)
    new = compose(True, monsters)

    gap = 34
    canvas = Image.new("RGB", (W, H * 2 + gap + 96), (24, 22, 20))
    canvas.paste(old, (0, 52))
    canvas.paste(new, (0, 52 + H + gap))

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
    d.text((24, 14), "改前：怪物竖着贴在同一列上", fill=(235, 230, 222), font=f)
    d.text((24, 52 + H + gap - 38), "改后：斜阵 + 近大远小 + 脚下墨影", fill=(235, 230, 222), font=f)

    out = os.path.join(ROOT, "docs/站位对比.png")
    canvas.save(out)
    print("已生成", os.path.relpath(out, ROOT), canvas.size)


if __name__ == "__main__":
    main()
