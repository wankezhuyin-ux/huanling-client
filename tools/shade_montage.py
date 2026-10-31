#!/usr/bin/env python3
"""把若干张 ink_sprite_preview 预览拼成对比长图。

每张预览是「原图 | 着色器」的 2-up，这里只取右半（着色器）裁出角色，
可选把第一格换成原图做基准，再横排、贴标签。

用法：
  python3 tools/shade_montage.py --out=/tmp/m.png --cell=300 \
      "原图|/tmp/n4_banbanhu.png|0" "A|/tmp/n4_banbanhu.png" "B|/tmp/v2.png"
"""
import sys
from PIL import Image, ImageDraw, ImageFont

BG = (194, 189, 179)


def cell_of(path, side):
    im = Image.open(path).convert("RGB")
    # 左半面板起点 x=40，右半面板起点 x=480，角色 440x440 落在 y 60..500
    x0 = 40 if side == "0" else 480
    return im.crop((x0, 60, x0 + 440, 500))


def main(argv):
    out = "/tmp/montage.png"
    size = 300
    cells = []
    for a in argv:
        if a.startswith("--out="):
            out = a[6:]
        elif a.startswith("--cell="):
            size = int(a[7:])
        elif "|" in a:
            cells.append(a.split("|"))
    if not cells:
        print("没有输入")
        return
    gap = 10
    W = len(cells) * (size + gap) + gap
    H = size + 46
    canvas = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/PingFang.ttc", 22)
    except Exception:
        font = ImageFont.load_default()
    for i, parts in enumerate(cells):
        label, path = parts[0], parts[1]
        side = parts[2] if len(parts) > 2 else "1"
        img = cell_of(path, side).resize((size, size), Image.LANCZOS)
        x = gap + i * (size + gap)
        canvas.paste(img, (x, gap))
        d.text((x + 8, gap + 4), label, fill=(30, 28, 26), font=font)
    canvas.save(out)
    print("saved:", out, canvas.size)


if __name__ == "__main__":
    main(sys.argv[1:])
