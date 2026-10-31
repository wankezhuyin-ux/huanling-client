#!/usr/bin/env python3
"""背景图可平铺检测。

战斗卷轴把同一张背景左右重复拼接做无限平移。AI 生图时如果按
「左边缘 = 右边缘」（无缝平铺图）生成，拼接处天然对齐，游戏里会
自动不压接缝阴影带（scripts/ui/battle_scroll_world.gd 的
_is_tileable，阈值 TILEABLE_MAX_DIFF=14）。

本脚本用与游戏完全相同的口径批量检测 assets/backgrounds/：
  左右各取 2 列、每 4 行采样一次、RGB 平均绝对差（0~255）。
  avg <= 14  → PASS（可平铺，接缝对齐）
  avg >  14  → FAIL（老图，游戏内用阴影带兜底）

用法：
  python3 tools/check_bg_tileable.py                # 全量检测 + 汇总
  python3 tools/check_bg_tileable.py --threshold 10 # 自定阈值
  python3 tools/check_bg_tileable.py --worst 20     # 只看最差的 20 张
"""
import argparse
import glob
import os
import sys

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("需要 pillow + numpy：pip3 install pillow numpy")
    sys.exit(1)

BG_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "backgrounds")
STRIP = 2          # 与游戏内 TILEABLE_EDGE_STRIP 一致
ROW_STEP = 4       # 与游戏内采样步长一致
DEFAULT_THRESHOLD = 14.0


def edge_diff(path: str) -> float:
    im = Image.open(path).convert("RGB")
    a = np.asarray(im, dtype=np.float32)
    h, w = a.shape[0], a.shape[1]
    if w < 64 or h < 32:
        return 255.0
    left = a[:, :STRIP, :]
    right = a[:, w - 1:w - 1 - STRIP:-1, :]  # 右侧 STRIP 列，顺序翻转后与左侧对位
    d = np.abs(left - right).mean(axis=(0, 1))  # 每通道平均差
    return float(d.mean())


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--threshold", type=float, default=DEFAULT_THRESHOLD)
    ap.add_argument("--worst", type=int, default=0, help="只列出最差的 N 张")
    args = ap.parse_args()

    paths = sorted(
        p for p in glob.glob(os.path.join(BG_DIR, "*.jpg"))
        + glob.glob(os.path.join(BG_DIR, "*.png"))
    )
    if not paths:
        print("没找到背景图：", os.path.abspath(BG_DIR))
        sys.exit(1)

    results = []
    for p in paths:
        try:
            results.append((os.path.basename(p), edge_diff(p)))
        except Exception as e:  # noqa: BLE001
            print(f"  跳过 {p}: {e}")

    ok = [(n, d) for n, d in results if d <= args.threshold]
    bad = [(n, d) for n, d in results if d > args.threshold]
    ok.sort(key=lambda x: x[1])
    bad.sort(key=lambda x: -x[1])

    show = bad if args.worst else ok + bad
    for n, d in (bad[: args.worst] if args.worst else show):
        tag = "PASS" if d <= args.threshold else "FAIL"
        print(f"  [{tag}] {n:28s} 边缘差={d:6.2f}")

    print(
        f"\n共 {len(results)} 张：可平铺 {len(ok)} 张 / 待重生成 {len(bad)} 张"
        f"（阈值 {args.threshold:g}）"
    )
    if bad:
        print("FAIL 的图在游戏里仍走阴影带兜底；按「左边缘=右边缘」重新生成后即变 PASS。")


if __name__ == "__main__":
    main()
