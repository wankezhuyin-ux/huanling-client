#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""逐张比对：当前工作区的资源 vs 原游戏 APK 解包出来的资源。

为什么要比「实际文件内容」而不是比 .import 里的 md5：
.import 里记录的 md5 只有在 Godot 真正重新导入过之后才会更新。
之前用 shutil.copy2 覆盖素材会保留旧 mtime，Godot 认为「源文件没变」就不重导，
.import 里留着**原版的 md5**，而磁盘上已经是换皮后的 PNG ——
只看 .import 会得出「全部一致」的错误结论。

原包那边只能拿到 .ctex（Godot 导入缓存），拿不到原始 PNG，
所以这里用原包 .import 里记录的 md5 当基准（那个是原包自己导入时算的，可信）。
"""
import hashlib
import os
import re
import sys

ORIG_IMP = "/Users/a1111/Documents/Codex/2026-10-21/n/work/apk-inspection/unpacked/assets/assets"
CUR_ASSETS = "/Users/a1111/Documents/Codex/2026-10-21/n/outputs/recovered-godot-project/assets"

CTEX_MD5 = re.compile(r"imported/.*?-([0-9a-f]{32})\.ctex")

# 子目录 -> 源文件后缀
TARGETS = [
    ("pets", ".png"),
    ("sprites", ".png"),
    ("backgrounds", ".jpg"),
    ("portraits", ".png"),
    ("background", ".jpg"),
    ("items", ".png"),
    ("icons", ".png"),
]


def orig_md5(sub: str, name: str, suf: str) -> str | None:
    """原包 .import 里记录的 ctex md5 = 原版源文件的 md5。"""
    p = os.path.join(ORIG_IMP, sub, name + suf + ".import")
    if not os.path.exists(p):
        return None
    with open(p, encoding="utf-8", errors="ignore") as f:
        m = CTEX_MD5.search(f.read())
    return m.group(1) if m else None


def file_md5(p: str) -> str | None:
    if not os.path.exists(p):
        return None
    with open(p, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def main() -> int:
    bad_total = 0
    report = []
    for sub, suf in TARGETS:
        od = os.path.join(ORIG_IMP, sub)
        if not os.path.isdir(od):
            continue
        # 原包里的文件名形如 xxx.png.import，去掉两层后缀得到 xxx
        names = sorted(
            os.path.splitext(os.path.splitext(f)[0])[0]
            for f in os.listdir(od)
            if f.endswith(suf + ".import")
        )
        same = diff = miss = 0
        diffs, misses = [], []
        for n in names:
            o = orig_md5(sub, n, suf)
            c = file_md5(os.path.join(CUR_ASSETS, sub, n + suf))
            if c is None:
                miss += 1
                misses.append(n)
            elif o == c:
                same += 1
            else:
                diff += 1
                diffs.append(n)
        bad_total += diff + miss
        print(f"[{sub}] 原包 {len(names)} | 一致 {same} | 不一致 {diff} | 缺失 {miss}")
        if diffs:
            print(f"    不一致: {diffs}")
        if misses:
            print(f"    缺失:   {misses}")
        report.append((sub, diffs, misses))
    print(f"\n合计对不上: {bad_total}")
    return 0 if bad_total == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
