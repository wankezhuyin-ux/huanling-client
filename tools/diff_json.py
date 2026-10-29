#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
深度 JSON 比对：忽略 camelCase / snake_case 命名差异，逐字段对比。
用法: python3 diff_json.py <A.json> <B.json> [--max 80] [--ctx]
"""
import json
import re
import sys


def norm_key(k):
    """把 camelCase / snake_case 统一成小写无下划线形式"""
    return re.sub(r"[_\-]", "", str(k)).lower()


def build_map(obj):
    if not isinstance(obj, dict):
        return obj
    return {norm_key(k): (k, v) for k, v in obj.items()}


def short(v, n=90):
    if isinstance(v, (dict, list)):
        s = json.dumps(v, ensure_ascii=False)
    else:
        s = str(v)
    return s if len(s) <= n else s[:n] + "..."


def walk(a, b, path, out, depth=0):
    if depth > 12:
        return
    if isinstance(a, dict) and isinstance(b, dict):
        ma, mb = build_map(a), build_map(b)
        for nk in ma:
            if nk not in mb:
                out.append(("ONLY_A", path + "/" + ma[nk][0], short(ma[nk][1]), ""))
        for nk in mb:
            if nk not in ma:
                out.append(("ONLY_B", path + "/" + mb[nk][0], "", short(mb[nk][1])))
        for nk in ma:
            if nk in mb:
                ka, va = ma[nk]
                kb, vb = mb[nk]
                # 键名大小写/风格不同也算差异（记录但单独标记）
                if ka != kb:
                    out.append(("KEY_STYLE", path + "/" + ka, ka, kb))
                walk(va, vb, path + "/" + ka, out, depth + 1)
        return
    if isinstance(a, list) and isinstance(b, list):
        if len(a) != len(b):
            out.append(("LEN", path, "len=%d" % len(a), "len=%d" % len(b)))
        for i in range(min(len(a), len(b))):
            walk(a[i], b[i], "%s[%d]" % (path, i), out, depth + 1)
        if len(a) > len(b):
            for i in range(len(b), min(len(a), len(b) + 3)):
                out.append(("ONLY_A", "%s[%d]" % (path, i), short(a[i], 60), ""))
        elif len(b) > len(a):
            for i in range(len(a), min(len(b), len(a) + 3)):
                out.append(("ONLY_B", "%s[%d]" % (path, i), "", short(b[i], 60)))
        return
    if isinstance(a, dict) != isinstance(b, dict) or isinstance(a, list) != isinstance(b, list):
        out.append(("TYPE", path, type(a).__name__, type(b).__name__))
        return
    if a != b:
        out.append(("VALUE", path, short(a), short(b)))


def main():
    pa, pb = sys.argv[1], sys.argv[2]
    mx = 80
    ctx = "--ctx" in sys.argv
    for i, a in enumerate(sys.argv):
        if a == "--max" and i + 1 < len(sys.argv):
            mx = int(sys.argv[i + 1])
    A = json.load(open(pa))
    B = json.load(open(pb))
    out = []
    walk(A, B, "", out)
    counts = {}
    for kind, *_ in out:
        counts[kind] = counts.get(kind, 0) + 1
    print("差异总数 %d  %s" % (len(out), counts))
    print()
    order = ["ONLY_A", "ONLY_B", "TYPE", "LEN", "VALUE", "KEY_STYLE"]
    for kind in order:
        items = [x for x in out if x[0] == kind]
        if not items:
            continue
        print("##### %s (%d) #####" % (kind, len(items)))
        for _, path, va, vb in items[:mx]:
            if kind == "KEY_STYLE":
                print("  %-64s  A键=%s  B键=%s" % (path, va, vb))
            elif kind == "ONLY_A":
                print("  %-64s  A=%s" % (path, va))
            elif kind == "ONLY_B":
                print("  %-64s  B=%s" % (path, vb))
            else:
                print("  %-64s  A=%s  B=%s" % (path, va, vb))
        if len(items) > mx:
            print("  ...(还有 %d 条)" % (len(items) - mx))
        print()


if __name__ == "__main__":
    main()
