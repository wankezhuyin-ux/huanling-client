#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""重绘主城竖吊牌（plaque_*.png 里的竖排文字）。

为什么要重绘：
  1. 竖排字紧贴着上方那个淡金小胶囊（间距只有 1px），看着像挤在一起；
  2. 「宠物园」是后补的一块牌子，笔画比别的牌子更粗更亮，同一屏里不一致。

做法：不重做美术，只重排文字。
  · 上方淡金胶囊、木牌外投影原样保留；
  · 木牌牌面重画：这块牌子实测是「竖向线性渐变 + 横向基本平坦」的方块
    （x 22..85、干净行横向标准差 < 2），按底边干净行拟合一条渐变线即可还原，
    不需要去猜被字盖住的地方；
  · 旧字笔画是**同时写在 alpha 通道里**的（字缘 201、牌面 248）。只擦 RGB、alpha 留原样，
    背景会顺着字形轮廓透出来 —— 看起来像"鬼影"，其实是透明度造成的，所以牌面 alpha 要重写；
  · 文字统一用包里的衬线粗体重排，颜色取宠物园那块牌的实测值 (250,240,212)；
  · 首字顶端从 cap_bottom+1 下移到 cap_bottom+1+GAP，留出一段空气。

画布尺寸保持不变，`ui/city_ink_data.gd` 里的 pos/size 不用动。
"""
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
ART = os.path.join(PROJ, "assets/city_ink")
FONT = os.path.join(PROJ, "assets/fonts/ink_serif_bold.otf")

SIZE = 42          # 字号（实测宠物园那块牌就是这个）
LEADING = 39       # 每字占高，字体 42 时的紧排
GAP = 13           # 首字与胶囊底边的间距（原来只有 1）
FILL = (250, 240, 212)
SHADOW = (10, 7, 4, 120)
SHADOW_OFF = (0, 2)
BOARD_ALPHA = 248.0
BOARD_EXTEND = 12     # 牌面往下多画 12px（吃掉原来 canvas 底部的投影留白）
TOP_SHADE_ROWS = 10   # 胶囊压在牌顶的投影，重画后要补回来，否则牌子像浮在胶囊外面

NAMES = {
    "plaque_arena.png": "竞技",
    "plaque_challenge.png": "闯天关",
    "plaque_dungeon.png": "副本挑战",
    "plaque_forge.png": "打造坊",
    "plaque_furnace.png": "乾坤炉",
    "plaque_martial.png": "武道馆",
    "plaque_pet.png": "宠物园",
    "plaque_sect.png": "帮派",
    "plaque_shop.png": "商店街",
    "plaque_tower.png": "生死塔",
    "plaque_treasure.png": "藏宝洞",
    "plaque_war.png": "仙魔挑战",
}


def cap_bottom(lum: np.ndarray) -> int:
    rows = np.where(lum.mean(axis=1) > 120)[0]
    return int(rows.max()) if rows.size else 0


def board_bounds(alpha: np.ndarray, cap: int):
    mid_row = alpha[min(alpha.shape[0] - 1, 150)]
    cols = np.where(mid_row > 200)[0]
    x0, x1 = (int(cols.min()), int(cols.max()) + 1) if cols.size else (22, 86)
    # 底边用整行 alpha 的高分位判断：字缘 alpha 只有 201，用中位数会被笔画带下去，90 分位才是牌面值
    row_alpha = np.percentile(alpha[:, x0 + 1:x1 - 1], 90, axis=1)
    y_end = alpha.shape[0]
    for y in range(cap + 30, alpha.shape[0]):
        if row_alpha[y] < 235:
            y_end = y
            break
    return x0, x1, y_end


def rebuild_board(rgb: np.ndarray, alpha: np.ndarray, cap: int, n_chars: int):
    """重画牌面：竖向渐变 + 圆角 + 投影 + 固定 alpha。"""
    from PIL import ImageFilter
    h, w = rgb.shape[:2]
    x0, x1, y_end = board_bounds(alpha, cap)
    y0 = cap + 1
    out, out_a = rgb.copy(), alpha.copy()

    # 配色：用底边几行没字的地方拟合「颜色 ~ y」，再往上下推
    # 取底部「文字以下、牌底以上」的干净行来拟合。不能用固定几行：
    # 字多的牌子（副本挑战 4 个字）字一直压到牌底附近，取错行会把字色当牌色，
    # 拟合出来的渐变一路推上去，牌子就变成上面发白的一片（宠物园那块就踩过这个坑）。
    fit_start = min(y_end - 6, cap + 1 + n_chars * 40 + 3)
    fit_end = y_end - 3
    if fit_end - fit_start < 4:
        fit_start = fit_end - 4
    fit_rows = np.arange(max(y0, fit_start), fit_end)
    samples = np.median(out[fit_rows][:, x0 + 4:x1 - 4], axis=1)
    ys = fit_rows.astype(np.float32)
    coef = [np.polyfit(ys, samples[:, i], 1) for i in range(3)]

    # 牌底往下接 12px：原来 canvas 底部那 22px 全是投影留白，
    # 把牌面吃进来一点，正好腾出「字离胶囊远一点」的空间，不影响 SIGNS 里的尺寸。
    y_board = min(h - 2, y_end + BOARD_EXTEND)
    target_y = np.arange(y0, y_board).astype(np.float32)
    grad = np.stack([np.polyval(coef[i], target_y) for i in range(3)], axis=1)
    shade = np.ones(target_y.shape[0], dtype=np.float32)
    n_shade = min(TOP_SHADE_ROWS, shade.size)
    shade[:n_shade] = np.linspace(0.72, 1.0, n_shade)
    grad = np.clip(grad * shade[:, None], 0, 255)

    # 圆角遮罩（只在底部两角，半径 6）
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([x0, y0 - 10, x1 - 1, y_board], radius=6, fill=255)
    m = np.asarray(mask).astype(np.float32) / 255.0
    m[:y0] = 0.0

    # 投影：遮罩下移 4px 再模糊
    sm = Image.fromarray((m * 255).astype(np.uint8), "L").transform(
        (w, h), Image.AFFINE, (1, 0, 0, 0, 1, -4), resample=Image.BILINEAR).filter(ImageFilter.GaussianBlur(4))
    sma = np.asarray(sm).astype(np.float32) / 255.0 * 95.0

    out[y0:] = np.array([16, 13, 9], dtype=np.float32)[None, None, :]
    out[y0:y_board] = grad[:, None, :]
    out_a[y0:] = 0.0
    out_a[y0:y_board] = BOARD_ALPHA * m[y0:y_board]
    out_a[y0:] = np.maximum(out_a[y0:], sma[y0:])
    # 圆角处 alpha 为 0，RGB 填什么都不影响观感
    return out, out_a, (x0, x1, y0, y_board)


def render_text(text: str, w: int, h: int, top: int) -> Image.Image:
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    font = ImageFont.truetype(FONT, SIZE)
    y = top
    for ch in text:
        bb = d.textbbox((0, 0), ch, font=font)
        gw = bb[2] - bb[0]
        x = (w - gw) / 2 - bb[0]
        d.text((x, y - bb[1] + SHADOW_OFF[1]), ch, font=font, fill=SHADOW)
        d.text((x, y - bb[1]), ch, font=font, fill=FILL)
        y += LEADING
    return layer


def main() -> int:
    files = sorted(f for f in os.listdir(ART) if f.startswith("plaque_") and f.endswith(".png"))
    only = sys.argv[1:] or files
    for f in only:
        path = os.path.join(ART, f)
        im = Image.open(path).convert("RGBA")
        a = np.asarray(im).astype(np.float32)
        rgb, alpha = a[..., :3].copy(), a[..., 3].copy()
        lum = 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]
        cap = cap_bottom(lum)
        clean, clean_a, box = rebuild_board(rgb, alpha, cap, len(NAMES.get(f, "")))
        base = Image.fromarray(np.dstack([np.clip(clean, 0, 255), clean_a]).astype(np.uint8), "RGBA")

        label = NAMES.get(f)
        if label is None:
            print("跳过（没有文案）:", f)
            continue
        need = len(label) * LEADING
        top = cap + 1 + GAP
        if top + need > box[3] - 4:
            print("警告: %s 文字可能压到牌底（top=%d need=%d 牌底=%d）" % (f, top, need, box[3]))
        base.alpha_composite(render_text(label, im.width, im.height, top))
        base.save(path)
        print("%-24s %dx%d 牌面 x%d..%d y%d..%d cap=%d 文字 top=%d 高=%d 底余量=%d"
              % (f, im.width, im.height, box[0], box[1], box[2], box[3],
                 cap, top, need, box[3] - (top + need)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
