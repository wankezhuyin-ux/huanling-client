#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 AI 生成的怪物立绘落地：抠白底 → 裁主体 → 存 128 立绘 → 生成帧条。

用法：
  python3 land_monster.py --id linlin --src raw.png [--apply]
不传 --apply 只写 build/preview，不动 assets。

帧数按原素材保持（游戏代码是按帧数切图的，不能变）。
"""
import argparse
import json
import os
import shutil
import time

from PIL import Image

import make_frames

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 原素材帧数：idle / attack。改这里等于改动画长度，必须和游戏里的切图逻辑一致。
FRAMES = {
    "linlin": (2, 3),
    "duxing": (3, 3),
    "yùlíntù": (3, 3),
    "xiǎodīngdōng": (3, 3),
    "lèngtóuqīng": (3, 3),
}

PORTRAIT_SIZE = 128
PORTRAIT_BODY_H = 112
PORTRAIT_BASE_Y = 124
FRAME_H = 140


def build_portrait(src: str) -> Image.Image:
    im = Image.open(src).convert("RGBA")
    if im.getchannel("A").getextrema()[0] > 200:
        im = make_frames.cut_white(im)
    bb = im.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if bb:
        im = im.crop(bb)
    s = PORTRAIT_BODY_H / im.height
    im = im.resize((max(1, round(im.width * s)), PORTRAIT_BODY_H), Image.LANCZOS)
    if im.width > PORTRAIT_SIZE:
        s2 = PORTRAIT_SIZE / im.width
        im = im.resize((PORTRAIT_SIZE, max(1, round(im.height * s2))), Image.LANCZOS)
    canvas = Image.new("RGBA", (PORTRAIT_SIZE, PORTRAIT_SIZE), (0, 0, 0, 0))
    x = (PORTRAIT_SIZE - im.width) // 2
    y = PORTRAIT_BASE_Y - im.height
    canvas.paste(im, (x, y), im)
    return canvas


def land(sprite_id: str, src: str, apply_it: bool) -> dict:
    idle_n, atk_n = FRAMES[sprite_id]
    portrait = build_portrait(src)
    out_dir = os.path.join(ROOT, "build/preview" if not apply_it else "assets")
    if not apply_it:
        os.makedirs(out_dir, exist_ok=True)
        p = os.path.join(out_dir, f"{sprite_id}.png")
        portrait.save(p)
        print(f"[预览] 立绘 {p}  {portrait.size}")
        return {"id": sprite_id, "preview": p}

    stamp = time.strftime("%Y%m%d-%H%M%S")
    targets = [
        os.path.join(ROOT, "assets/pets", f"{sprite_id}.png"),
        os.path.join(ROOT, "assets/sprites", f"{sprite_id}_idle.png"),
        os.path.join(ROOT, "assets/sprites", f"{sprite_id}_attack.png"),
    ]
    for t in targets:
        if os.path.exists(t):
            bk = os.path.join(ROOT, ".restyle-backup", "monster-" + stamp, os.path.relpath(t, ROOT))
            os.makedirs(os.path.dirname(bk), exist_ok=True)
            shutil.copy2(t, bk)

    portrait.save(targets[0])
    make_frames.build(src, "idle", idle_n, 256, FRAME_H).save(targets[1])
    make_frames.build(src, "attack", atk_n, 256, FRAME_H).save(targets[2])
    for t in targets:
        print(f"[落地] {os.path.relpath(t, ROOT)}  {Image.open(t).size}")
    return {"id": sprite_id, "files": [os.path.relpath(t, ROOT) for t in targets]}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--plan", help="JSON: [{id, src}]")
    ap.add_argument("--id")
    ap.add_argument("--src")
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    jobs = json.load(open(a.plan, encoding="utf-8")) if a.plan else [{"id": a.id, "src": a.src}]
    for job in jobs:
        land(job["id"], job["src"], a.apply)


if __name__ == "__main__":
    main()
