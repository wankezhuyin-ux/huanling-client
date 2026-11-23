#!/usr/bin/env python3
"""素材版权核对：把「原始恢复工程.zip」当基准，逐文件比对当前工程的图片与音乐。

用法：
    python3 audit_copyright.py                 # 输出汇总并刷新 asset_copyright_inventory.csv
    python3 audit_copyright.py --summary-only  # 只看汇总，不写 CSV

每完成一批原创重制后重跑一次，CSV 里的「原版未改」数量应当递减。
基准包只作为比对物，不参与发布，也不要放进任何开源仓库。
"""

import argparse
import collections
import csv
import hashlib
import os
import zipfile
from pathlib import Path

BASE = Path(__file__).resolve().parent
ZIP_DEFAULT = BASE / "原始恢复工程.zip"
PROJECT_DEFAULT = BASE / "recovered-godot-project"
CSV_DEFAULT = BASE / "asset_copyright_inventory.csv"
ZIP_PREFIX = "recovered-godot-project/"
IMG_EXT = (".png", ".jpg", ".jpeg", ".webp")
AUDIO_EXT = (".mp3", ".ogg", ".wav")

# 已知高危 IP / 商标谐音的拼音资源名，命中即提到 P0 优先处理
IP_SLUGS = (
    "nezha", "ximenchuixue", "henrendadi", "zuozhu", "jiulama", "liushen",
    "babata", "bushihuowu", "bashen", "youerha", "zhizunbao", "anubisi",
    "xiaozhubite", "ante", "fente", "adidasi",
)

BATCH = {
    "Music": ("B1 音频重制", "P0"),
    "assets/pets": ("B2 宠物与头像", "P1"),
    "assets/portraits": ("B2 宠物与头像", "P1"),
    "assets/sprites": ("B3 战斗帧", "P1"),
    "assets/backgrounds": ("B4 场景背景", "P1"),
    "assets/background": ("B4 场景背景", "P1"),
    "assets/city": ("B4 场景背景", "P1"),
    "assets/citytb": ("B4 场景背景", "P1"),
    "assets/items": ("B5 道具与图标", "P2"),
    "assets/icons": ("B5 道具与图标", "P2"),
    "assets/gang_emblems": ("B5 道具与图标", "P2"),
    "assets/martial": ("B5 道具与图标", "P2"),
    "assets/buttons": ("B6 UI 小件", "P2"),
    "assets/medals": ("B6 UI 小件", "P2"),
    "assets/guanghuan": ("B6 UI 小件", "P2"),
    "assets/ui": ("B6 UI 小件", "P2"),
}


def md5(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def original_assets(zip_path: Path) -> dict:
    out = {}
    with zipfile.ZipFile(zip_path) as z:
        for name in z.namelist():
            if not name.startswith(ZIP_PREFIX):
                continue
            rel = name[len(ZIP_PREFIX):]
            if not (rel.startswith("assets/") or rel.startswith("Music/")):
                continue
            if name.lower().endswith(IMG_EXT + AUDIO_EXT):
                data = z.read(name)
                out[rel] = (md5(data), len(data))
    return out


def current_assets(project: Path) -> dict:
    out = {}
    for dirpath, dirnames, filenames in os.walk(project):
        dirnames[:] = [d for d in dirnames if d not in (".godot", ".git", "build")]
        for fn in filenames:
            if not fn.lower().endswith(IMG_EXT + AUDIO_EXT):
                continue
            path = Path(dirpath) / fn
            rel = path.relative_to(project).as_posix()
            if not (rel.startswith("assets/") or rel.startswith("Music/")):
                continue
            data = path.read_bytes()
            out[rel] = (md5(data), len(data))
    return out


def group_of(rel: str) -> str:
    parts = rel.split("/")
    return parts[0] + "/" + (parts[1] if len(parts) > 2 else "(root)")


def batch_of(rel: str) -> tuple:
    for key, val in BATCH.items():
        if rel.startswith(key + "/"):
            return val
    if rel.startswith(("assets/city_ink/", "assets/city_fx/", "assets/icon/")):
        return ("B0 已完成（自制）", "-")
    return ("待归类", "P2")


def advise(state: str, rel: str) -> str:
    low = rel.lower()
    derived = "_vol." in low or "/vol/" in low
    if state == "原版未改":
        if derived:
            return "原图重制后重新生成此压缩副本"
        return "需原创重制并留存生成来源与人工修改记录"
    if state == "原版有/当前缺":
        return "确认是否已废弃；若仍需要则原创制作"
    if state == "已替换":
        return "复核是否原创、补齐来源记录"
    if derived:
        return "压缩派生副本，随原图一起复核"
    return "自制，留存来源记录即可"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--zip", type=Path, default=ZIP_DEFAULT)
    ap.add_argument("--project", type=Path, default=PROJECT_DEFAULT)
    ap.add_argument("--out", type=Path, default=CSV_DEFAULT)
    ap.add_argument("--summary-only", action="store_true")
    args = ap.parse_args()

    if not args.zip.is_file():
        raise SystemExit("找不到基准包：%s" % args.zip)
    orig = original_assets(args.zip)
    cur = current_assets(args.project)

    rows = []
    stat = collections.defaultdict(lambda: [0, 0, 0, 0])
    order = {"原版未改": 0, "已替换": 1, "原版有/当前缺": 2, "新增自制": 3}
    for rel in sorted(set(orig) | set(cur)):
        o, c = orig.get(rel), cur.get(rel)
        if o and c:
            state = "原版未改" if o[0] == c[0] else "已替换"
        elif o:
            state = "原版有/当前缺"
        else:
            state = "新增自制"
        stat[group_of(rel)][order[state]] += 1
        batch, priority = batch_of(rel)
        if any(s in rel.lower() for s in IP_SLUGS):
            priority = "P0"
        rows.append((rel, group_of(rel), state, batch, priority,
                     o[1] if o else "", c[1] if c else "", advise(state, rel)))

    print("=== 素材版权核对 · %s ===" % args.project.name)
    print("原版基准 %d 项 / 当前工程 %d 项" % (len(orig), len(cur)))
    print("\n%-26s %9s %8s %8s %8s" % ("目录", "原版未改", "已替换", "原版缺", "新增"))
    total = [0, 0, 0, 0]
    for g, v in sorted(stat.items(), key=lambda kv: -kv[1][0]):
        print("%-26s %9d %8d %8d %8d" % (g, *v))
        for i in range(4):
            total[i] += v[i]
    print("%-26s %9d %8d %8d %8d" % ("合计", *total))
    need = sum(1 for r in rows if r[2] in ("原版未改", "原版有/当前缺"))
    print("\n待原创制作条目：%d 项" % need)
    p0 = sum(1 for r in rows if r[4] == "P0" and r[2] in ("原版未改", "原版有/当前缺"))
    print("其中 P0（音频 / IP 角色素材）：%d 项" % p0)

    if not args.summary_only:
        with args.out.open("w", newline="", encoding="utf-8-sig") as f:
            w = csv.writer(f)
            w.writerow(["序号", "资源路径", "类别", "状态", "施工批次", "优先级",
                        "原版字节", "当前字节", "处理建议"])
            for i, r in enumerate(rows, 1):
                w.writerow([i, *r])
        print("明细台账：%s" % args.out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
