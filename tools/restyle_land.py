#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""AI 重绘稿落地：去水印 → 缩放到游戏目标尺寸 → 压到目标体积 → 备份 → 替换。

用法：
  python3 restyle_land.py --src a.png --dst assets/backgrounds/xx.jpg --size 512x700
  python3 restyle_land.py --plan plan.json --apply
"""
import argparse
import json
import os
import shutil
import time

import numpy as np
from PIL import Image, ImageFilter

GAME = os.path.expanduser("~/Documents/Codex/2026-10-21/n/outputs/recovered-godot-project")


def strip_watermark(im, frac=(0.82, 0.930, 1.0, 1.0)):
    """抹掉右下角的生成水印：用正上方的真实画面垂直镜像填充 + 边缘羽化。

    水印是半透明白字，直接均值填充会留下灰雾，所以取「上方同宽、同高×1.3」
    的真实纹理翻折下来，纹理连续、看不出补丁。
    """
    im = im.convert("RGB")
    w, h = im.size
    x0, y0 = int(w * frac[0]), int(h * frac[1])
    x1, y1 = w, h
    rw, rh = x1 - x0, y1 - y0
    if rw <= 4 or rh <= 4:
        return im

    # 取上方 1.3 倍高度的源块，垂直翻转后贴到水印区
    sh = min(rh + int(rh * 0.3), y0)
    src = im.crop((x0, y0 - sh, x1, y0)).transpose(Image.FLIP_TOP_BOTTOM)
    src = src.resize((rw, rh), Image.LANCZOS).filter(ImageFilter.GaussianBlur(0.6))

    # 羽化蒙版：左、上两条内边界渐变；右、下贴边完全不透明
    m = np.ones((rh, rw), dtype=np.float32)
    f = max(6, int(min(rw, rh) * 0.30))
    for i in range(rh):
        m[i, :] = np.minimum(m[i, :], min(1.0, i / f))
    for j in range(rw):
        m[:, j] = np.minimum(m[:, j], min(1.0, j / f))
    mask = Image.fromarray((m * 255).astype(np.uint8))

    out = im.copy()
    out.paste(src, (x0, y0), mask)
    return out


def save_jpg(im, dst, target_kb):
    q = 92
    while q >= 60:
        im.save(dst, "JPEG", quality=q, optimize=True, progressive=True)
        kb = os.path.getsize(dst) / 1024
        if kb <= target_kb:
            return q, kb
        q -= 4
    return q + 4, os.path.getsize(dst) / 1024


def land(src, dst_rel, size, target_kb, apply):
    dst = os.path.join(GAME, dst_rel) if not os.path.isabs(dst_rel) else dst_rel
    orig_kb = os.path.getsize(dst) / 1024 if os.path.exists(dst) else 0
    im = strip_watermark(Image.open(src))
    w, h = [int(x) for x in size.lower().split("x")]
    # 生成图比例可能与目标略有差异，先居中裁到目标比例再缩放
    tw, th = w / h, im.size[0] / im.size[1]
    if abs(tw - th) > 0.005:
        if th > tw:
            nw = int(im.size[1] * tw)
            left = (im.size[0] - nw) // 2
            im = im.crop((left, 0, left + nw, im.size[1]))
        else:
            nh = int(im.size[0] / tw)
            top = (im.size[1] - nh) // 2
            im = im.crop((0, top, im.size[0], top + nh))
    im = im.resize((w, h), Image.LANCZOS)

    if not apply:
        out = os.path.join(os.path.dirname(src), "landed_" + os.path.basename(dst))
        q, kb = save_jpg(im, out, target_kb)
        print(f"[预览] {dst_rel}  原 {orig_kb:.0f}KB → {kb:.0f}KB (q={q})  -> {out}")
        return out

    stamp = time.strftime("%Y%m%d-%H%M%S")
    bk = os.path.join(GAME, ".restyle-backup", stamp, dst_rel)
    os.makedirs(os.path.dirname(bk), exist_ok=True)
    if os.path.exists(dst):
        shutil.copy2(dst, bk)
    q, kb = save_jpg(im, dst, target_kb)
    print(f"[落地] {dst_rel}  原 {orig_kb:.0f}KB → {kb:.0f}KB (q={q})  备份 {os.path.relpath(bk, GAME)}")
    return dst


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--src")
    ap.add_argument("--dst")
    ap.add_argument("--size", default="512x700")
    ap.add_argument("--max-kb", type=float, default=400)
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    if not a.src or not a.dst:
        ap.error("需要 --src 与 --dst")
    land(a.src, a.dst, a.size, a.max_kb, a.apply)


if __name__ == "__main__":
    main()
