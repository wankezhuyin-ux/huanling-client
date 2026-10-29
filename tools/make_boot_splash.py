#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 Godot 引擎启动闪屏（boot splash）用的整张图。

Godot 4 的 boot splash 只能吃一张位图，所以标题是「画」出来的而不是排版的。
输出：assets/icon/boot_splash.png（1440x2560，纯黑底，等比缩放显示）

注意：文案/字体改了以后要重跑本脚本，并用
  Godot --headless --path . --import
重新导入，否则导出的还是旧图。
"""

from PIL import Image, ImageDraw, ImageFont

W, H = 1440, 2560
CENTER_Y_RATIO = 0.475
BLACK = (0, 0, 0, 255)
GOLD = (227, 197, 140, 255)
GOLD_DIM = (156, 127, 82, 255)

PROJ = __import__("os").path.dirname(__import__("os").path.dirname(
    __import__("os").path.abspath(__file__)))
ICON = PROJ + "/assets/icon/logo_mark.png"
TITLE_ART = PROJ + "/assets/icon/title_calligraphy.png"
F_SUB_PATH = PROJ + "/assets/fonts/ink_serif.otf"

layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(layer)

logo = Image.open(ICON).convert("RGBA")
logo = logo.crop(logo.getchannel("A").getbbox())
LOGO_SIZE = 470
logo = logo.resize((LOGO_SIZE, LOGO_SIZE), Image.LANCZOS)

# 标题用用户手绘的书法图，不再用字体排
art = Image.open(TITLE_ART).convert("RGBA")
art = art.crop(art.getchannel("A").getbbox())
ART_W = 780
art = art.resize((ART_W, round(art.height * ART_W / art.width)), Image.LANCZOS)

F_SUB = ImageFont.truetype(F_SUB_PATH, 58)
sub = "养宠修仙"
SSP = 30


def measure(text, font, sp):
    return sum(font.getlength(c) for c in text) + sp * (len(text) - 1)


def draw_spaced(text, cy, font, sp, fill):
    x = (W - measure(text, font, sp)) / 2
    asc, desc = font.getmetrics()
    for ch in text:
        d.text((x, cy - (asc + desc) / 2), ch, font=font, fill=fill)
        x += font.getlength(ch) + sp


y = 300
layer.alpha_composite(logo, (int((W - LOGO_SIZE) / 2), y))
ry = y + LOGO_SIZE + 96
layer.alpha_composite(art, (int((W - ART_W) / 2), ry))

# 书法图下面一道细金线 + 菱形，再下面副标题（和登录页同一套分隔写法）
ly = ry + art.height + 54
d.line([(W / 2 - 40, ly), (W / 2 - 12, ly)], fill=GOLD_DIM, width=3)
d.line([(W / 2 + 12, ly), (W / 2 + 40, ly)], fill=GOLD_DIM, width=3)
d.polygon([(W / 2, ly - 10), (W / 2 + 10, ly), (W / 2, ly + 10), (W / 2 - 10, ly)],
          outline=GOLD_DIM, width=3)
draw_spaced(sub, ly + 78, F_SUB, SSP, GOLD_DIM)

l, t, r, b = layer.getbbox()
cw, ch = r - l, b - t
canvas = Image.new("RGB", (W, H), (0, 0, 0))
crop = layer.crop((l, t, r, b))
canvas.paste(crop, (int((W - cw) / 2), int(CENTER_Y_RATIO * H - ch / 2)), crop)
canvas.save(PROJ + "/assets/icon/boot_splash.png")
print("boot_splash 内容 %dx%d，占屏宽 %.1f%%" % (cw, ch, cw / W * 100))
