#!/usr/bin/env python3
"""主城背景图底部接缝修复。

bg_ink.jpg 在 y≈1679 处有一条贯穿全宽的水平硬边：上方是山石/地面的浅色雾化边缘，
下方接着一段更暗、带镜像重影的画面（做雾底时的镜像延展），两者直接拼接，
在游戏里就是用户看到的「右下角断层」。

做法：让雾从接缝上方一点点「涨上来」，把接缝和下方的镜像重影一起吃掉 ——
不交叉混合（那会做出更怪的对称重影），而是按 y 归一化后整体溶进雾色。
雾色取接缝下方 120px 处的纯雾带，横向大半径模糊，只保留缓慢明暗起伏。

用法：
  python3 tools/fix_bg_seam.py --dry    # 只输出 /tmp 预览
  python3 tools/fix_bg_seam.py          # 写回原图（先备份 .bak-seam）
"""
import os
import shutil
import sys

import numpy as np
from PIL import Image, ImageFilter

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(PROJ, "assets/city_ink/bg_ink.jpg")
PREVIEW = "/tmp/bg_ink_seam_fixed.jpg"

SEAM_Y = 1679
FADE_UP = 110       # 接缝以上多少像素开始起雾
FADE_DOWN = 150     # 接缝以下多少像素彻底成雾


def smoothstep(t):
    t = np.clip(t, 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def main():
    dry = "--dry" in sys.argv
    img = Image.open(SRC).convert("RGB")
    a = np.asarray(img).astype(np.float32)
    h, w, _ = a.shape

    # 雾色参考：接缝下方「已经是纯雾」的窄带
    ref = a[SEAM_Y + 130:SEAM_Y + 220].mean(axis=0)            # (w,3)
    ref_img = Image.fromarray(ref.clip(0, 255).astype(np.uint8).reshape(1, w, 3))
    ref_img = ref_img.filter(ImageFilter.GaussianBlur(24))
    fog_row = np.asarray(ref_img).astype(np.float32).reshape(w, 3)

    out = a.copy()
    y_start = SEAM_Y - FADE_UP
    y_end = SEAM_Y + FADE_DOWN
    for y in range(max(0, y_start), min(h, y_end)):
        if y <= SEAM_Y:
            # 接缝以上：雾从 0 涨到 0.92，接缝处两侧都已几乎全被雾盖住
            t = (y - y_start) / float(SEAM_Y - y_start)
            alpha = 0.92 * smoothstep(t)
        else:
            # 接缝以下：0.92 → 1，把残留的镜像重影彻底压掉
            t = (y - SEAM_Y) / float(y_end - SEAM_Y)
            alpha = 0.92 + 0.08 * smoothstep(t)
        out[y] = a[y] * (1.0 - alpha) + fog_row * alpha

    res = Image.fromarray(out.clip(0, 255).astype(np.uint8))
    if dry:
        res.save(PREVIEW, quality=95)
        print("dry-run ->", PREVIEW)
    else:
        bak = SRC + ".bak-seam"
        if not os.path.exists(bak):
            shutil.copyfile(SRC, bak)
            print("备份原图 ->", bak)
        res.save(SRC, quality=95, subsampling=0)
        print("已写回", SRC)

    g = np.asarray(res.convert("L"), dtype=np.int16)
    d2 = np.abs(np.diff(g, axis=0))
    print("接缝跳变占比（修复前 y=1678 为 0.65）:")
    for y in (SEAM_Y - 1, SEAM_Y, SEAM_Y + 1):
        print("  y=%d %.3f" % (y, (d2[y] > 8).mean()))


if __name__ == "__main__":
    main()
