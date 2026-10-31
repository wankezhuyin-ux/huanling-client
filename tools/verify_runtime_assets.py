#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""权威校验：运行时真正用的贴图 vs 原游戏 APK 的贴图。

关键点（踩过的坑）：
1. **不能只看源文件的 md5**。.import 里记录的 md5 只有 Godot 真正重新导入过才更新。
   用 shutil.copy2 覆盖素材会保留旧 mtime → Godot 认为「源文件没变」→ 不重导 →
   .import 留着原版 md5，磁盘上却是换皮后的 PNG。只看 .import 会得出「全部一致」的错误结论。
2. **不能只看源文件本身**。运行时读的是 .godot/imported/*.ctex，
   源 PNG 与 ctex 可能不同步（stale）。
3. **必须按 .import 里 path= 实际指向的那份 ctex 比**。同名 key 在 imported 目录里
   可能有多份（不同 md5），取错一份会得出错误结论。

所以本脚本：
  原包侧：从原包 xxx.png.import 里读出 path= 指向的 ctex，算它的字节 md5
  当前侧：从当前 xxx.png.import 里读出 path= 指向的 ctex，算它的字节 md5
  两者字节 md5 相同 == 运行时用的是同一张图

用法：
  python3 tools/verify_runtime_assets.py [--subs=pets,sprites,backgrounds,...]
"""
import argparse
import os
import re
import sys

PROJ = "/Users/a1111/Documents/Codex/2026-10-21/n/outputs/recovered-godot-project"
ORIG_ASSETS = ("/Users/a1111/Documents/Codex/2026-10-21/n/work/apk-inspection/"
               "unpacked/assets/assets")
ORIG_IMPORTED = ("/Users/a1111/Documents/Codex/2026-10-21/n/work/apk-inspection/"
                 "unpacked/assets/.godot/imported")

CTEX_IN_IMPORT = re.compile(r'imported/([^"]+\.ctex)')

# 这 9 只 IP 侵权宠物是有意删除的（commit cd3bf57 清理），不算「对不上」
EXPECTED_MISSING_PETS = {
    "babata", "bashen", "buzhihuowu", "henrendadi", "jiulama",
    "liushen", "ximenchuixue", "youerha", "zuozhu",
}
# 立绘里对应的 18 个文件（idle + attack）
EXPECTED_MISSING_SPRITES = {
    f"{p}_{k}" for p in EXPECTED_MISSING_PETS for k in ("idle", "attack")
}


def ctex_from_import(import_path: str) -> str | None:
    if not os.path.exists(import_path):
        return None
    with open(import_path, encoding="utf-8", errors="ignore") as f:
        m = CTEX_IN_IMPORT.search(f.read())
    return m.group(1) if m else None


def md5_of(path: str) -> str | None:
    if not os.path.exists(path):
        return None
    import hashlib
    with open(path, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def scan(sub: str, suf: str):
    """返回 (一致, 不一致列表, 缺失列表, 多出列表)"""
    od = os.path.join(ORIG_ASSETS, sub)
    cd = os.path.join(PROJ, "assets", sub)
    if not os.path.isdir(od) or not os.path.isdir(cd):
        return 0, [], [], []

    orig_names = set()
    for f in os.listdir(od):
        if f.endswith(suf + ".import"):
            orig_names.add(f[: -len(suf + ".import")])
    cur_names = set()
    for f in os.listdir(cd):
        if f.endswith(suf):
            cur_names.add(f[: -len(suf)])

    same, diffs, misses, extras = 0, [], [], []
    for n in sorted(orig_names):
        o_ctex = ctex_from_import(os.path.join(od, n + suf + ".import"))
        c_ctex = ctex_from_import(os.path.join(cd, n + suf + ".import"))
        if c_ctex is None:
            misses.append(n)
            continue
        o_md5 = md5_of(os.path.join(ORIG_IMPORTED, o_ctex)) if o_ctex else None
        c_md5 = md5_of(os.path.join(PROJ, ".godot", "imported", c_ctex))
        if o_md5 is None or c_md5 is None:
            misses.append(n)
        elif o_md5 == c_md5:
            same += 1
        else:
            diffs.append(n)
    for n in sorted(cur_names - orig_names):
        extras.append(n)
    return same, diffs, misses, extras


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--subs", default="pets,sprites,backgrounds,portraits,items,icons")
    args = ap.parse_args()

    total_diff = 0
    for sub in args.subs.split(","):
        sub = sub.strip()
        suf = ".jpg" if sub == "backgrounds" else ".png"
        same, diffs, misses, extras = scan(sub, suf)
        # 有意删除的 IP 侵权宠物（commit cd3bf57）不算「对不上」
        if sub == "pets":
            expected_miss = [m for m in misses if m in EXPECTED_MISSING_PETS]
        elif sub == "sprites":
            expected_miss = [m for m in misses if m in EXPECTED_MISSING_SPRITES]
        else:
            expected_miss = []
        real_miss = [m for m in misses if m not in expected_miss]
        flag = "" if not (diffs or real_miss) else "  ← 有问题"
        print(f"[{sub:<12}] 一致 {same:>4} | 不一致 {len(diffs):>3} | "
              f"缺失 {len(misses):>3}（有意删 {len(expected_miss)}）{flag}")
        for d in diffs:
            print("      不一致:", d)
        for m in real_miss:
            print("      缺失:  ", m)

        # pets/sprites 里多出来的：核对是否与原包一致（原包有、baseline 没有的）
        if extras:
            print(f"      当前多出 {len(extras)} 个（需确认与原包一致）: {extras[:6]}")

        total_diff += len(diffs) + len(real_miss)

    print(f"\n与原包对不上: {total_diff}")
    return 0 if total_diff == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
