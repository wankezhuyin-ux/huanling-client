"""清除服务端种子数据里的原服痕迹。

线上玩家少，排行榜靠种子数据填充，而这些种子是原服抓下来的真实玩家：
昵称（人间大炮、思念…）、username（11 位手机号）、帮派名（宠爱一生、凌霄宝殿），
以及背包里 900 多个「赞助钱袋」。这些都会原样下发给客户端。

本脚本：
  1. ranking*.json  昵称重写为原创古风名，username 改为 uid 形式（去手机号）
  2. gang-list.json 帮派名 / 帮主名 / 公告重写
  3. save_seed.json 赞助钱袋合并为「钱币袋」
  4. maps.json      掉落配置里的旧钱袋名改为「钱币袋」

用法：
  python3 tools/purge_server_seed.py            # 预览
  python3 tools/purge_server_seed.py --apply
"""
import argparse
import json
import re
import shutil
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT.parent / "deploy" / "server" / "data"

BAG = ["醉剑", "1万金币袋（醉）", "神的遗愿", "风歌夜曲", "摆烂松", "人间大炮",
       "我的理想", "板砖", "立羽", "铭大大", "长空秋雁", "大橘大利", "人间事", "思念"]
COIN = "钱币袋"

# 原创古风名（两字/三字），风格与《墨境》一致
SURNAME = ["墨", "砚", "松", "竹", "云", "雪", "江", "山", "石", "林", "野", "寒",
           "青", "白", "玄", "赤", "孤", "远", "清", "微", "疏", "浅", "重", "淡"]
GIVEN = ["尘", "溪", "渊", "岚", "照", "渠", "叶", "石", "澜", "雪", "松", "鹤",
         "舟", "笛", "灯", "书", "砚", "池", "苔", "篁", "沙", "渡", "阙", "痕"]


def gen_names(n):
    out, seen = [], set()
    for i in range(len(SURNAME) * len(GIVEN)):
        a = SURNAME[i % len(SURNAME)]
        b = GIVEN[(i * 7 + i // len(SURNAME)) % len(GIVEN)]
        c = GIVEN[(i * 11 + 3) % len(GIVEN)]
        for cand in (a + b, a + c + b):
            if cand not in seen:
                seen.add(cand)
                out.append(cand)
                break
        if len(out) >= n:
            break
    return out


def backup(p: Path):
    stamp = time.strftime("%Y%m%d-%H%M%S")
    dst = ROOT / ".restyle-backup" / f"server-{stamp}" / p.name
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, dst)


def patch_rankings(apply: bool):
    names = gen_names(120)
    total = 0
    for fn in ["ranking.json", "ranking-players.json", "ranking-pets-evolution.json",
               "ranking-pets-non-evolution.json"]:
        p = DATA / fn
        d = json.loads(p.read_text(encoding="utf-8"))
        rows = d.get("rankings") or []
        for i, r in enumerate(rows):
            if not isinstance(r, dict):
                continue
            if "nickname" in r:
                r["nickname"] = names[i % len(names)]
            if "username" in r:
                r["username"] = "u%06d" % (100000 + i)
            if "gang_name" in r:
                r["gang_name"] = ""
        total += len(rows)
        if apply:
            backup(p)
            p.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"  ranking*.json: 4 个文件共 {total} 条昵称/账号已重写")


def patch_gangs(apply: bool):
    p = DATA / "gang-list.json"
    d = json.loads(p.read_text(encoding="utf-8"))
    gangs = d.get("gangs") or []
    gang_names = ["墨池", "松风阁", "残碑社", "听雪庐", "拾叶堂", "砚山会",
                  "寒渡", "竹外居", "石鼓门", "云深处", "淡墨斋", "孤峰台",
                  "临渊阁", "照野庄", "拂石居"]
    names = gen_names(40)
    for i, g in enumerate(gangs):
        g["name"] = gang_names[i % len(gang_names)]
        g["leaderName"] = names[i % len(names)]
        if "notice" in g:
            g["notice"] = "日常捐献、副本组队，欢迎同好。"
    print(f"  gang-list.json: {len(gangs)} 个帮派改名")
    if apply:
        backup(p)
        p.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")


def patch_save_seed(apply: bool):
    p = DATA / "save_seed.json"
    d = json.loads(p.read_text(encoding="utf-8"))
    # 找到存物品的容器
    changed = 0
    coin_count = 0
    removed = 0

    def walk(o):
        nonlocal changed, coin_count, removed
        if isinstance(o, dict):
            for k in list(o.keys()):
                if k in BAG:
                    v = o.pop(k)
                    removed += 1
                    changed += 1
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            keep = []
            for it in o:
                if isinstance(it, dict) and it.get("name") in BAG:
                    coin_count += int(it.get("count", 0) or 0)
                    removed += 1
                    continue
                if isinstance(it, dict) and it.get("name") == COIN:
                    coin_count += int(it.get("count", 0) or 0)
                keep.append(it)
                walk(it)
            if len(keep) != len(o):
                o[:] = keep
                changed += 1

    walk(d)
    # 把合并后的钱币袋写回第一个物品列表
    def find_items(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if isinstance(v, list) and v and isinstance(v[0], dict) and "item_type" in v[0]:
                    return v
                r = find_items(v)
                if r is not None:
                    return r
        elif isinstance(o, list):
            for v in o:
                r = find_items(v)
                if r is not None:
                    return r
        return None

    items = find_items(d)
    # 这是兜底模板（正常走 new_player_seed.json）。旧钱袋数量是原服富号的快照，
    # 合并到新号会直接送出上亿金币，所以只删不并。
    print(f"  save_seed.json: 清掉旧钱袋 {removed} 条（不合并，避免新号带巨款）")
    if apply:
        backup(p)
        p.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")


def patch_maps(apply: bool):
    p = DATA / "maps.json"
    d = json.loads(p.read_text(encoding="utf-8"))
    n = 0

    def walk(o):
        nonlocal n
        if isinstance(o, dict):
            for k in list(o.keys()):
                if k in BAG:
                    o[COIN] = o.pop(k)
                    n += 1
            for v in o.values():
                walk(v)
        elif isinstance(o, list):
            for v in o:
                walk(v)

    walk(d)
    print(f"  maps.json: 掉落表中的旧钱袋名替换 {n} 处")
    if apply:
        backup(p)
        p.write_text(json.dumps(d, ensure_ascii=False, indent=1), encoding="utf-8")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()
    print("== 清除服务端种子数据里的原服痕迹 ==")
    patch_rankings(a.apply)
    patch_gangs(a.apply)
    patch_save_seed(a.apply)
    patch_maps(a.apply)
    print("完成" + ("" if a.apply else "（预览，加 --apply 执行）"))


if __name__ == "__main__":
    main()
