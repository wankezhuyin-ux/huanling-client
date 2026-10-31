#!/usr/bin/env python3
"""按原游戏原画基准，批量生成进化宠物的链专属水墨立绘。

为什么这样做：阶1~3 的**形体**不是我们发明的，而是原游戏原画里就有的
（蝶 → 蝶翅少女 → 羽翼仙子 → 龙形神兽）。所以做法是：
把该形态的原画当 image-to-image 参考图喂给 ImageGen，提示词只要求
「保留原图形体与构图，改成水墨淡彩」，形体 100% 对齐原游戏。

反过来做（先想形体再文生图）会跑偏 —— 上一轮就是这么把「粉衣仙子」
画成了「戴花冠的蝴蝶」的。

用法：
    python3 tools/evo_batch_prep.py --list                 # 看还差哪些
    python3 tools/evo_batch_prep.py --origin yingying      # 备好一条链的参考图+提示词
    python3 tools/evo_batch_prep.py --all                  # 全备好

产出：
    /tmp/evo_ref/{form}.png                参考图（ImageGen 的 image1）
    outputs/ai-restyle/evo/{origin}/{form}.png   最终产出
    tools/evo_batch_prompts.json          每条链每阶段的完整提示词
"""

import argparse
import json
import os

from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_ROOT = os.path.dirname(ROOT)
SRC_SPRITES = os.path.join(ROOT, "assets", "sprites")
EVO_OUT = os.path.join(OUT_ROOT, "ai-restyle", "evo")
REF_DIR = "/tmp/evo_ref"
SPEC_PATH = os.path.join(ROOT, "tools", "evolution_art_spec.json")
PROMPTS_PATH = os.path.join(ROOT, "tools", "evo_batch_prompts.json")

REF_SIZE = 768

# 每个形态 id 的「形体关键词」——直接抄原画看到的形象，
# 提示词里用它锁住形体，防止 ImageGen 自由发挥。
FORM_SHAPE = {
    # —— 蝶蛾族 ——
    "yu_yi": "一个人形少女，背后横展开一对紫色宽圆蝴蝶翅膀，绿色圆头，紫色短发",
    "ni_chang": "一个人形少女，背后横展开一对彩虹色宽翅，绿色短卷发，纤细人身",
    "ling_shan": "一个人形少女，背后横展开一对蓝色蝴蝶翅膀，紫色短发，纤细人身",
    "fen_yi_xian_zi": "一位腾空的人形仙子，穿粉色长裙，身后放射状展开八片白色羽翼",
    "lv_yi_xian_zi": "一位腾空的人形仙子，穿绿色长裙，身后放射状展开八片青绿羽翼",
    "bai_yi_xian_zi": "一位腾空的人形仙子，穿白色长裙，身后放射状展开八片白色羽翼",
    "huan_yun_shou": "一条赤红色长身四足神龙，鹿角，蛇形长身，脊背骨刺，腹部淡金",
    "di_cang_shou": "一只黑金色甲壳巨兽，牛头独角，四足粗壮，背脊带金色纹路",
    "ao_xue_shou": "一条银白色带冰蓝纹的长身四足神龙，头生冰晶角冠，脊背锯齿冰棱",
    # —— 金尾鱼族 ——
    "yu_wa_wa": "一个上半身人、鱼尾的少女，红发，肩披轻纱，鱼尾下垂",
    "yu_mei_mei": "一个上半身人、鱼尾的少女，紫发，肩披轻纱，鱼尾下垂",
    "yu_niu_niu": "一个上半身人、鱼尾的少女，绿发，肩披轻纱，鱼尾下垂",
    "ling_bo_xian_zi": "一位人鱼仙子，鱼尾，双手捧一枚发光宝珠，头上有珊瑚状头饰",
    "zhu_lang_xian_zi": "一位人鱼仙子，鱼尾，身旁伴一株珊瑚，法杖拄地",
    "xi_shui_xian_zi": "一位人鱼仙子，鱼尾，双手结印，水纹环绕身周",
    "cang_ming_shen_nv": "一位端坐的人鱼神女，鱼尾，披帛环绕，头戴高冠，手托火焰宝珠",
    "han_hai_xian_ji": "一位人鱼神姬，鱼尾，身后巨浪翻涌，手持三叉戟",
    "yao_shui_ling_zun": "一位人鱼灵尊，鱼尾，周身水灵环绕，衣袂翻飞",
    # —— 猴族 ——
    "aoririquan": "一只紫毛四足狼犬，尖耳，尾巴蓬松",
    "zhuiyingquan": "一只黄黑相间的四足狼犬，尖耳，尾巴蓬松",
    "niefengquan": "一只白毛四足狼犬，尖耳，尾巴蓬松",
    "duoluotianlang": "一只巨大的紫色魔狼，獠牙外露，鬃毛竖立",
    "qibiantianlang": "一只巨大的黄绿色魔狼，獠牙外露，鬃毛竖立",
    "huanbiantianlang": "一只巨大的灰色魔狼，獠牙外露，鬃毛竖立",
    "huo_yao_jing": "一个人立背翼的赤红色妖狐，双足直立，背生大翼，尖耳长尾",
    "lv_yao": "一个人立背翼的黄绿色妖狐，双足直立，背生大翼，尖耳长尾",
    "zi_yi": "一个人立背翼的紫色妖狐，双足直立，背生大翼，尖耳长尾",
    # —— 熊猫族 ——
    "a_ge_liu_si": "一只直立行走的熊猫战士，戴头盔，双手各持一面圆盾",
    "a_nu_bi_si": "一只肌肉发达的直立熊猫力士，赤膊，双拳缠绕绷带",
    "chao_ji_a_nu": "一只狂暴的巨型熊猫，肌肉虬结，周身缠绕黑气",
    # —— 骷髅族 ——
    "wanglingwushi": "一个骷髅武士，白骨身躯，披红色斗篷，手持圆盾与短剑",
    "silingwushi": "一个骷髅武士，白骨身躯，披黄绿护具，手持圆盾与短剑",
    "zhonglingwushi": "一个骷髅武士，白骨身躯，披幽蓝护具，手持圆盾与短剑",
    "zhaohunshizhe": "一个兜帽遮面的刺客，斗篷罩住全身，只露双眼，手持短刃",
    "gouhunshizhe": "一个兜帽遮面的刺客，斗篷罩住全身，只露双眼，手持短刃",
    "shehunshizhe": "一个兜帽遮面的刺客，斗篷罩住全身，只露双眼，手持短刃",
    "xiaowushi": "一位戴尖帽的小巫师，袍服宽大，手持法杖",
    "xiaomoshi": "一位戴尖帽的小巫师，袍服宽大，手持法杖",
    "xiaofashi": "一位戴尖帽的小法师，袍服宽大，手持法杖",
    # —— 小鸟族 ——
    "fuyejiu": "一只橙色小鸟，短喙，尾羽三根并张开，腹部浅黄",
    "yulujiu": "一只红色小鸟，短喙，尾羽三根并张开，腹部浅黄",
    "miwuju": "一只蓝色小鸟，短喙，尾羽三根并张开，腹部浅黄",
    "xuefenghuang": "一只白色凤凰，长翎垂落，展翅，尾羽如瀑",
    "huofenghuang": "一只赤红凤凰，长翎垂落，展翅，尾羽如瀑",
    "lanfenghuang": "一只蓝色凤凰，长翎垂落，展翅，尾羽如瀑",
    "chilong": "一条粉红色东方龙，鹿角，蛇形长身，细长四爪",
    "jinxielong": "一条金色东方龙，鹿角，蛇形长身，细长四爪",
    "lanmiaolong": "一条蓝色东方龙，鹿角，蛇形长身，细长四爪",
    # —— 水晶族 ——
    "jingtianshi": "一块巨大的蓝色多面水晶，棱角锐利，内部有光",
    "mengtianshi": "一块巨大的紫色多面水晶，棱角锐利，内部有光",
    "mengjingling": "一个人形的水晶精灵，半透明身躯，晶面切割，尖耳",
    "mengjinggang": "一个人形的水晶精灵，半透明身躯，晶面切割，尖耳",
    "huanjinggang": "一个身穿水晶铠甲的晶体战士，棱面装甲包裹全身",
    "liuyitianshi": "一个身披水晶羽翼的天石，晶体身躯背生六翼",
    # —— 猴王族 ——
    "gang_lei_fei": "一只棕色小猴直立成战士形，双手高举铁锤",
    "hou_lei_fei": "一只黄绿色小猴直立成战士形，双手高举铁锤",
    "ben_lei_fei": "一只黑色小猴直立成战士形，双手高举铁锤",
    "zhong_yue_shen_yuan": "一只披甲巨猿，肌肉虬结，双目金光",
    "xi_yue_shen_yuan": "一只披甲巨猿，肌肉虬结，双目金光",
    "dong_yue_shen_yuan": "一只披甲巨猿，肌肉虬结，双目金光",
    "zhi_zun_bao": "一位金甲神猴，头戴凤翅紫金冠，披金甲持棒",
    "zhi_zun_cao": "一位金甲武士，头戴金冠，手持长棍",
    "zhi_zun_lin": "一位金甲弓手，头戴金冠，手持长弓",
    # —— 龙族 ——
    "wu_qi_long": "一条黑色东方龙，鹿角，蛇形长身，粗壮四爪",
    "huang_jin_long": "一条金色东方龙，鹿角，蛇形长身，粗壮四爪",
    "bao_lan_long": "一条宝蓝色东方龙，鹿角，蛇形长身，粗壮四爪",
    "hei_long_shi": "一只黑色龙狮，狮首龙身，鬃毛竖立，四足粗壮",
    "huang_long_shi": "一只金色龙狮，狮首龙身，鬃毛竖立，四足粗壮",
    "qing_long_shi": "一只青色龙狮，狮首龙身，鬃毛竖立，四足粗壮",
    "hong_fa_yao_ji": "一位红发龙族妖姬，人身龙角，红发披散，衣袍赤红",
    "bai_fa_she_ji": "一位白发龙族妖姬，人身龙角，白发披散，衣袍月白",
    "lan_fa_mo_ji": "一位蓝发龙族魔姬，人身龙角，蓝发披散，衣袍靛蓝",
    # —— 小猪族 ——
    "zhongshanzhu": "一只粉色大猪，背上鬃毛，肩头一片青菜叶，圆滚身形",
    "ximenzhu": "一只褐色大猪，背上鬃毛，肩头一片青菜叶，圆滚身形",
    "nangongzhu": "一只紫色大猪，背上鬃毛，肩头一片青菜叶，圆滚身形",
    "nanbatian": "一只猪头人身的猪战士，肌肉发达，光膀，拳套缠绕",
    "beibatian": "一只猪头人身的猪战士，肌肉发达，光膀，拳套缠绕",
    "xiaobawang": "一只猪头人身的猪战士，肌肉发达，光膀，拳套缠绕",
    "bajie": "一位猪头人身的猪王，戴王冠，披袍持九齿钉耙",
    "yijie": "一位猪头人身的猪王，戴王冠，披袍持九齿钉耙",
    "bujie": "一位猪头人身的猪王，戴王冠，披袍持九齿钉耙",
}

# 不能变成什么 —— 按形态类别给禁止项
FORBID = {
    "humanoid": "不要变成一只鸟、不要给她加翅膀以外的新器官",
    "winged_fairy": "不要变成一只鸟、不要给她加蝴蝶翅膀",
    "quadruped": "不要变成人形、不要给它加翅膀",
    "dragon": "不要变成人形、不是长翅膀的鸟",
    "bird": "不要变成人形、不要给它加四肢",
    "humanoid_beast": "不要变成人形躯干加兽头的拼接怪",
    "crystal": "不要变成普通的石头或金属块",
    "fish_tail": "不要变成完全人形的少女",
}

# 水墨对应色：形态描述里出现的颜色词 → 淡彩水墨的近似色
INK_COLOR = {
    "紫": "淡紫（花青调）", "紫色": "淡紫（花青调）",
    "蓝": "花青", "蓝色": "花青",
    "绿": "石绿", "绿色": "石绿",
    "红": "朱砂", "赤": "朱砂", "赤红": "朱砂",
    "粉": "胭脂粉", "粉色": "胭脂粉",
    "白": "月白", "白色": "月白",
    "金": "藤黄", "金色": "藤黄",
    "灰": "淡墨灰",
    "黄": "藤黄",
    "彩虹": "淡彩渐层（花青+藤黄+胭脂）",
    "青": "石青",
}
BRANCH_TONE = {
    "normal": "整体色调偏暖、灵气外放。",
    "mutant": "整体色调偏冷、气质内敛。",
}


def shape_of(form_id: str) -> str:
    return FORM_SHAPE.get(form_id, "")


def forbid_of(desc: str) -> str:
    if "蝶翅" in desc or "蝴蝶翅膀" in desc:
        return "它必须还是人形少女加这对翅膀，不要变成一只真正的蝴蝶、不要全身覆羽"
    if "人形" in desc and "翼" in desc:
        return FORBID["winged_fairy"]
    if "人形" in desc:
        return FORBID["humanoid"]
    if "龙" in desc:
        return FORBID["dragon"]
    if "凤凰" in desc or "鸟" in desc:
        return FORBID["bird"]
    if "水晶" in desc or "晶体" in desc:
        return FORBID["crystal"]
    if "鱼尾" in desc:
        return FORBID["fish_tail"]
    if "四足" in desc or "狼" in desc or "猪" in desc or "熊猫" in desc:
        return FORBID["quadruped"]
    return FORBID["humanoid_beast"]


def make_ref(form_id: str) -> str:
    """从原画取第 0 帧做参考图。"""
    src = os.path.join(SRC_SPRITES, "%s_idle.png" % form_id)
    if not os.path.exists(src):
        return ""
    im = Image.open(src).convert("RGBA").crop((0, 0, 256, 256))
    bb = im.split()[3].getbbox()
    if bb:
        im = im.crop(bb)
    im = im.resize((REF_SIZE, REF_SIZE), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=2, percent=90, threshold=2))
    os.makedirs(REF_DIR, exist_ok=True)
    out = os.path.join(REF_DIR, "%s.png" % form_id)
    im.save(out)
    return out


def ink_colors(desc: str) -> str:
    """从形态描述里提取颜色词，映射到淡彩水墨色。"""
    # 长词优先（"紫色" 要先于 "紫" 命中，否则会把 "紫色" 拆成 "紫"+"色"）
    found = []
    for cn in ("彩虹", "赤红", "紫色", "绿色", "蓝色", "粉色", "白色", "金色", "银白",
               "紫", "蓝", "绿", "红", "粉", "白", "金", "灰", "黄", "青"):
        if cn not in desc:
            continue
        # 已经命中过更长的词就不再重复
        if any(cn in f for f in found):
            continue
        found = [f for f in found if cn not in f]
        found.append(cn)
    if not found:
        return "墨色为主，辅以淡彩"
    out = []
    for c in found[:4]:
        v = INK_COLOR.get(c, c)
        if v not in out:
            out.append(v)
    return "、".join(out)


def build_prompt(form_id: str, branch: str) -> str:
    desc = shape_of(form_id)
    if not desc:
        return ""
    wc = ink_colors(desc)
    return (
        "把这张角色立绘重绘成东方工笔淡彩水墨风格（宣纸质感，墨线勾边，矿物颜料淡染），"
        "但必须严格保留原图的构图、姿态与造型特征：%s。"
        "绝对不要改变它的形体类别——它必须还是「%s」这一类形象，%s。"
        "不要加皇冠或光环。保留原图的整体配色关系，转成淡彩水墨的%s。%s"
        "透明背景，主体居中，全身完整入画。" % (
            desc, desc[:14], forbid_of(desc), wc, BRANCH_TONE[branch])
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--origin", default="")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--list", action="store_true")
    args = ap.parse_args()

    spec = json.load(open(SPEC_PATH, encoding="utf-8"))
    chains = spec["chains"]
    os.makedirs(REF_DIR, exist_ok=True)

    if args.list:
        done = 0
        total = 0
        for origin, c in chains.items():
            for br, b in c["branches"].items():
                for st in b["stages"]:
                    total += 1
                    p = os.path.join(EVO_OUT, origin, "%s.png" % st["form_id"])
                    if os.path.exists(p):
                        done += 1
        print("链专属形态 %d/%d 已产出，缺 %d" % (done, total, total - done))
        for origin, c in chains.items():
            miss = []
            for br, b in c["branches"].items():
                for st in b["stages"]:
                    if not os.path.exists(os.path.join(EVO_OUT, origin, "%s.png" % st["form_id"])):
                        miss.append("%s/%s" % (br, st["form_id"]))
            if miss:
                print("  %-18s %s" % (origin, ", ".join(miss)))
        return 0

    targets = list(chains.keys()) if (args.all or not args.origin) else [args.origin]
    prompts = {}
    if os.path.exists(PROMPTS_PATH):
        prompts = json.load(open(PROMPTS_PATH, encoding="utf-8"))
    n = 0
    for origin in targets:
        c = chains.get(origin)
        if c is None:
            continue
        for br, b in c["branches"].items():
            for st in b["stages"]:
                fid = st["form_id"]
                ref = make_ref(fid)
                pr = build_prompt(fid, br)
                if not ref or not pr:
                    print("  跳过 %s/%s（缺形体描述或原画）" % (origin, fid))
                    continue
                prompts.setdefault(origin, {}).setdefault(br, {})[fid] = {
                    "ref": ref, "prompt": pr, "stage": st["stage"], "proto": st["proto"],
                }
                n += 1
    json.dump(prompts, open(PROMPTS_PATH, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print("备好 %d 个形态的参考图与提示词 → %s" % (n, PROMPTS_PATH))
    print("参考图目录：", REF_DIR)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
