"""把逐帧 AI 重绘稿装配回战斗帧条。

流程：抠白底 → 裁到角色包围盒 → 缩放到原帧包围盒尺寸 → 贴回原位置 → 拼条。
这样动画的位置与比例完全不动，只有画风变化，不会跳帧。

用法：
  python3 assemble_frames.py --orig assets/sprites/nawahuo_attack.png \
      --redraws dir1,dir2,dir3,dir4 --dst out.png
"""
import argparse
import glob
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def cut_white(im, thresh=36):
    """从四角泛洪，把连通的近白背景抠成透明。"""
    im = im.convert("RGB")
    w, h = im.size
    sentinel = (255, 0, 255)
    px = im.load()
    for corner in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        if sum(abs(a - b) for a, b in zip(px[corner], (255, 255, 255))) < 60:
            ImageDraw.floodfill(im, corner, sentinel, thresh=thresh)
    arr = np.asarray(im).astype(np.int16)
    mask = (np.abs(arr - np.array(sentinel)).sum(axis=2) < 12)
    alpha = np.where(mask, 0, 255).astype(np.uint8)
    # 轻微收缩边缘，避免白边
    a = Image.fromarray(alpha).filter(ImageFilter.MinFilter(3))
    rgb = arr.astype(np.uint8)
    rgb[mask] = 0
    out = np.dstack([rgb, np.asarray(a)])
    return Image.fromarray(out, "RGBA")


def bbox_of(im, eps=8):
    a = im.split()[-1].point(lambda v: 255 if v > eps else 0)
    return a.getbbox()


def assemble(orig_path, redraw_paths, dst):
    strip = Image.open(orig_path).convert("RGBA")
    W, H = strip.size
    fw = H
    n = W // fw
    if len(redraw_paths) != n:
        raise SystemExit(f"帧数不匹配：原图 {n} 帧，重绘 {len(redraw_paths)} 张")
    out = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for i, rp in enumerate(redraw_paths):
        src_frame = strip.crop((i * fw, 0, (i + 1) * fw, H))
        tb = bbox_of(src_frame)
        if tb is None:
            out.paste(src_frame, (i * fw, 0))
            continue
        r = cut_white(Image.open(rp))
        rb = bbox_of(r)
        if rb is None:
            out.paste(src_frame, (i * fw, 0))
            continue
        r = r.crop(rb)
        tw, th = tb[2] - tb[0], tb[3] - tb[1]
        r = r.resize((tw, th), Image.LANCZOS)
        out.paste(r, (i * fw + tb[0], tb[1]), r)
        print(f"  帧{i}: 原bbox {tb} → 重绘 {rb} 缩放至 {tw}x{th}")
    out.save(dst)
    print("写入", dst)
    return dst


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--orig", required=True)
    ap.add_argument("--redraws", required=True)
    ap.add_argument("--dst", required=True)
    a = ap.parse_args()
    rp = []
    for d in a.redraws.split(","):
        fs = sorted(glob.glob(os.path.join(d, "*.png")))
        if not fs:
            raise SystemExit("目录无图: " + d)
        rp.append(fs[0])
    assemble(a.orig, rp, a.dst)


if __name__ == "__main__":
    main()
