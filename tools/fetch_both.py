#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
双端采集：分别登录原版服务器与本地服务器，拉取同样的端点集合，落地为 JSON。
用法: python3 fetch_both.py <outdir>
"""
import json
import os
import ssl
import sys
import urllib.request
import urllib.error

ORIG = "http://101.42.200.***:3000"
MINE = "http://119.91.135.99:3000"

ORIG_CRED = {"clientVersion": "2.6.0", "username": "hlzhuyin", "password": "zhuguli520"}
MINE_CRED = {"clientVersion": "2.5.9", "username": "emu2026", "password": "emu2026test"}

ENDPOINTS = [
    ("gameplay_runtime_config", "/api/gameplay/runtime-config"),
    ("drop_config", "/api/economy/drop-config"),
    ("festival_config", "/api/festival/runtime-config"),
    ("user_info", "/api/user/info"),
    ("save_download", "/api/save/download"),
    ("noble_info", "/api/noble/info"),
    ("gang_titles", "/api/gang/titles"),
    ("gang_buffs", "/api/gang/buffs"),
    ("arena_titles", "/api/arena/titles"),
    ("xianmo_titles", "/api/xianmo/titles"),
    ("tower_info", "/api/tower/info"),
    ("martial_info", "/api/martial/info"),
    ("suit_dungeon_info", "/api/suit-dungeon/info"),
    ("signin7_info", "/api/signin7/info"),
    ("ranking", "/api/ranking"),
    ("version_check", "/api/version/check?version=2.6.0"),
]


def req(url, token=None, body=None, timeout=25):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    data = None
    if body is not None:
        data = json.dumps(body).encode()
    r = urllib.request.Request(url, data=data, headers=headers,
                               method="POST" if data is not None else "GET")
    try:
        with urllib.request.urlopen(r, timeout=timeout) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, e.read()
    except Exception as e:
        return -1, str(e).encode()


def collect(name, base, cred, outdir):
    d = os.path.join(outdir, name)
    os.makedirs(d, exist_ok=True)
    st, raw = req(base + "/api/login", body=cred)
    if st != 200:
        print("[%s] 登录失败 %s %s" % (name, st, raw[:200]))
        return None
    login = json.loads(raw)
    token = login.get("token")
    json.dump(login, open(os.path.join(d, "_login.json"), "w"), ensure_ascii=False, indent=1)
    print("[%s] 登录成功 userId=%s nickname=%s" % (name, login.get("userId"), login.get("nickname")))
    for key, ep in ENDPOINTS:
        st, raw = req(base + ep, token=token)
        fn = os.path.join(d, key + ".json")
        if st == 200:
            try:
                obj = json.loads(raw)
                json.dump(obj, open(fn, "w"), ensure_ascii=False, indent=1)
                print("  %-24s %s  %d bytes -> %s.json" % (key, st, len(raw), key))
            except Exception as e:
                open(fn + ".txt", "wb").write(raw)
                print("  %-24s %s  非JSON %d bytes (%s)" % (key, st, len(raw), e))
        else:
            open(fn + ".txt", "wb").write(raw)
            print("  %-24s %s  %d bytes (失败, 存txt)" % (key, st, len(raw)))
    return token


def main():
    outdir = sys.argv[1] if len(sys.argv) > 1 else "capture"
    os.makedirs(outdir, exist_ok=True)
    collect("orig", ORIG, ORIG_CRED, outdir)
    collect("mine", MINE, MINE_CRED, outdir)
    print("完成 ->", outdir)


if __name__ == "__main__":
    main()
