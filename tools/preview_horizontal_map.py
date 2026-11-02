#!/usr/bin/env python3
"""用真实战斗截图当底版，把新背景按游戏里的 COVERED 规则贴进去，生成效果预演图。

为什么不用直接跑游戏截图：本机登录流程要连线上服，截图脚本这次没找到登录页。
所以退一步，用「真截图 + 真 UI 底板 + 真贴图几何」合成，误差只在光照和无渐显层。

几何依据（ui/main_ui.tscn）：
  BattlePanel: offset_left=10, top=270, right=-10, bottom=-5 → 700 x 1005（720x1280 下）
  BattleBackground: STRETCH_KEEP_ASPECT_COVERED, 居中 → 512x700 缩到 735x1005，左右各裁 17px
玩家真正看得见的战区下沿 = 战报框上边 930（以下是战报/按钮/导航）
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

BASE = "/Users/a1111/WorkBuddy/2026-10-22-23-24-31/战斗画面_全部恢复原版.png"
OUT_DIR = "/Users/a1111/WorkBuddy/2026-10-22-23-24-31/outputs/horizontal-maps/preview"

PANEL = (10, 270, 710, 1275)     # 战场面板矩形
VISIBLE_BOTTOM = 930             # 战报框上沿 = 玩家可见下沿
CHROME_TOP = 270                 # 顶部信息栏下沿
CHROME_BAR = 1065                # 按钮行上沿
HORIZON = 0.45                   # 成图地平线位置

FONT_CANDIDATES = [
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/STHeiti Medium.ttc",
    "/System/Library/Fonts/Hiragino Sans GB.ttc",
]


def font(size: int):
    for p in FONT_CANDIDATES:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except OSError:
                continue
    return ImageFont.load_default()


def fit_cover(tex: Image.Image, w: int, h: int) -> Image.Image:
    tw, th = tex.size
    s = max(w / tw, h / th)
    r = tex.resize((int(round(tw * s)), int(round(th * s))), Image.LANCZOS)
    rw, rh = r.size
    x0 = (rw - w) // 2
    y0 = (rh - h) // 2
    return r.crop((x0, y0, x0 + w, y0 + h))


def apply_vignette(img: Image.Image) -> Image.Image:
    """按 main_ui 的暗角遮罩参数复刻（径向渐变，中心 0.05 → 边缘 0.55）。"""
    w, h = img.size
    xs = (np.arange(w, dtype=np.float32) / w - 0.5) * 2
    ys = (np.arange(h, dtype=np.float32) / h - 0.5) * 2
    d = np.sqrt(xs[None, :] ** 2 + ys[:, None] ** 2)
    knots = [(0.0, 0.05), (0.10, 0.05), (0.352, 0.175), (0.618, 0.396), (0.82, 0.55), (1.6, 0.55)]
    alpha = np.interp(d, [k[0] for k in knots], [k[1] for k in knots]).astype(np.float32)
    a = np.asarray(img).astype(np.float32)
    a *= (1 - alpha)[:, :, None]
    return Image.fromarray(np.clip(a, 0, 255).astype(np.uint8))


def compose(bg_path: str, guides: bool, out_path: str):
    base = Image.open(BASE).convert("RGB")
    bg = fit_cover(Image.open(bg_path).convert("RGB"), PANEL[2] - PANEL[0], PANEL[3] - PANEL[1])

    canvas = base.copy()
    canvas.paste(apply_vignette(bg), (PANEL[0], PANEL[1]))

    # 把顶部信息栏 / 战报框 / 底部按钮+导航 原样贴回（这些都是盖在战场上的 UI）
    canvas.paste(base.crop((0, 0, 720, CHROME_TOP)), (0, 0))
    canvas.paste(base.crop((0, VISIBLE_BOTTOM - 5, 720, CHROME_BAR)), (0, VISIBLE_BOTTOM - 5))
    canvas.paste(base.crop((0, CHROME_BAR, 720, 1280)), (0, CHROME_BAR))

    if guides:
        d = ImageDraw.Draw(canvas)
        fy = PANEL[1] + int((PANEL[3] - PANEL[1]) * HORIZON)
        # 地平线
        for x in range(PANEL[0], PANEL[2], 26):
            d.line([(x, fy), (x + 13, fy)], fill=(255, 214, 90), width=2)
        d.text((PANEL[0] + 8, fy - 26), f"地平线 {int(HORIZON*100)}%", font=font(20), fill=(255, 214, 90))
        # 可见下沿
        for x in range(PANEL[0], PANEL[2], 26):
            d.line([(x, VISIBLE_BOTTOM), (x + 13, VISIBLE_BOTTOM)], fill=(120, 226, 255), width=2)
        d.text((PANEL[0] + 8, VISIBLE_BOTTOM - 28), "战区可见下沿（以下是战报框）",
               font=font(18), fill=(120, 226, 255))

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    canvas.save(out_path, "PNG")
    return out_path


def side_by_side(old: str, new: str, out_path: str, title_old="原图", title_new="水墨横版"):
    ims = [Image.open(p).convert("RGB") for p in (old, new)]
    w = sum(i.width for i in ims) + 24
    h = max(i.height for i in ims) + 46
    canvas = Image.new("RGB", (w, h), (24, 22, 20))
    d = ImageDraw.Draw(canvas)
    x = 0
    for im, t in zip(ims, (title_old, title_new)):
        canvas.paste(im, (x, 40))
        d.text((x + 10, 10), t, font=font(22), fill=(235, 228, 214))
        x += im.width + 24
    canvas.save(out_path, "PNG")
    return out_path


def main():
    new_dir = "/Users/a1111/WorkBuddy/2026-10-22-23-24-31/outputs/horizontal-maps/new"
    old_dir = os.path.expanduser(
        "~/Documents/Codex/2026-10-21/n/outputs/recovered-godot-project/assets/backgrounds")
    pairs = [("浮影水城外郊", "浮影水城外郊"), ("徘徊林", "徘徊林")]
    made = []
    for new_name, only in pairs:
        bg_new = os.path.join(new_dir, f"{new_name}.jpg")
        bg_old = os.path.join(old_dir, f"{only}.jpg")
        made.append(compose(bg_new, False, os.path.join(OUT_DIR, f"游戏内预演_{new_name}.png")))
        made.append(compose(bg_new, True, os.path.join(OUT_DIR, f"游戏内预演_{new_name}_带标线.png")))
        made.append(side_by_side(bg_old, bg_new, os.path.join(OUT_DIR, f"平面对照_{new_name}.png")))
    for p in made:
        print(p)


if __name__ == "__main__":
    sys.exit(main())
