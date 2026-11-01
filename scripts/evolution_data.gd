extends Node
class_name EvolutionData






const EVOLUTION_DATA = {

	"yingying": {
		"name": "盈盈", 
		"normal_evolution": ["yingying", "yu_yi", "fen_yi_xian_zi", "huan_yun_shou"], 
		"mutant_evolution": ["yingying", "ling_shan", "bai_yi_xian_zi", "ao_xue_shou"]
	}, 
	"linlin": {
		"name": "琳琳", 
		"normal_evolution": ["linlin", "ni_chang", "lv_yi_xian_zi", "di_cang_shou"], 
		"mutant_evolution": ["linlin", "yu_yi", "fen_yi_xian_zi", "huan_yun_shou"]
	}, 
	"zhenzhen": {
		"name": "珍珍", 
		"normal_evolution": ["zhenzhen", "ling_shan", "bai_yi_xian_zi", "ao_xue_shou"], 
		"mutant_evolution": ["zhenzhen", "ni_chang", "lv_yi_xian_zi", "di_cang_shou"]
	}, 
	"dan_dan_yu": {
		"name": "蛋蛋鱼", 
		"normal_evolution": ["dan_dan_yu", "yu_wa_wa", "ling_bo_xian_zi", "cang_ming_shen_nv"], 
		"mutant_evolution": ["dan_dan_yu", "yu_mei_mei", "zhu_lang_xian_zi", "han_hai_xian_ji"]
	}, 
	"wan_zi_yu": {
		"name": "丸子鱼", 
		"normal_evolution": ["wan_zi_yu", "yu_niu_niu", "xi_shui_xian_zi", "yao_shui_ling_zun"], 
		"mutant_evolution": ["wan_zi_yu", "yu_wa_wa", "ling_bo_xian_zi", "cang_ming_shen_nv"]
	}, 
	"ping_pang_yu": {
		"name": "乒乓鱼", 
		"normal_evolution": ["ping_pang_yu", "yu_mei_mei", "zhu_lang_xian_zi", "han_hai_xian_ji"], 
		"mutant_evolution": ["ping_pang_yu", "yu_niu_niu", "xi_shui_xian_zi", "yao_shui_ling_zun"]
	}, 


	"cong_cong": {
		"name": "匆匆", 
		"normal_evolution": ["cong_cong", "aoririquan", "duoluotianlang", "huo_yao_jing"], 
		"mutant_evolution": ["cong_cong", "niefengquan", "huanbiantianlang", "zi_yi"]
	}, 
	"xi_pi": {
		"name": "西皮", 
		"normal_evolution": ["xi_pi", "zhuiyingquan", "qibiantianlang", "lv_yao"], 
		"mutant_evolution": ["xi_pi", "aoririquan", "duoluotianlang", "huo_yao_jing"]
	}, 
	"wang_wang": {
		"name": "旺旺", 
		"normal_evolution": ["wang_wang", "niefengquan", "huanbiantianlang", "zi_yi"], 
		"mutant_evolution": ["wang_wang", "zhuiyingquan", "qibiantianlang", "lv_yao"]
	}, 
	"a_di_da_si": {
		"name": "阿弟达斯", 
		"normal_evolution": ["a_di_da_si", "a_ge_liu_si", "a_nu_bi_si", "chao_ji_a_nu"], 
		"mutant_evolution": []
	}, 
	"baiguzhanshi": {
		"name": "白骨战士", 
		"normal_evolution": ["baiguzhanshi", "wanglingwushi", "zhaohunshizhe", "xiaowushi"], 
		"mutant_evolution": ["baiguzhanshi", "silingwushi", "gouhunshizhe", "xiaomoshi"]
	}, 
	"kulouzhanshi": {
		"name": "骷髅战士", 
		"normal_evolution": ["kulouzhanshi", "silingwushi", "gouhunshizhe", "xiaomoshi"], 
		"mutant_evolution": ["kulouzhanshi", "zhonglingwushi", "shehunshizhe", "xiaofashi"]
	}, 
	"chongshengzhanshi": {
		"name": "重生战士", 
		"normal_evolution": ["chongshengzhanshi", "zhonglingwushi", "shehunshizhe", "xiaofashi"], 
		"mutant_evolution": ["chongshengzhanshi", "wanglingwushi", "zhaohunshizhe", "xiaowushi"]
	}, 


	"luluniao": {
		"name": "露露鸟", 
		"normal_evolution": ["luluniao", "fuyejiu", "xuefenghuang", "chilong"], 
		"mutant_evolution": ["luluniao", "yulujiu", "huofenghuang", "jinxielong"]
	}, 
	"nununiao": {
		"name": "努努鸟", 
		"normal_evolution": ["nununiao", "yulujiu", "huofenghuang", "jinxielong"], 
		"mutant_evolution": ["nununiao", "miwuju", "lanfenghuang", "lanmiaolong"]
	}, 
	"duduniao": {
		"name": "嘟嘟鸟", 
		"normal_evolution": ["duduniao", "miwuju", "lanfenghuang", "lanmiaolong"], 
		"mutant_evolution": ["duduniao", "fuyejiu", "xuefenghuang", "chilong"]
	}, 
	"shuijinger": {
		"name": "水晶儿", 
		"normal_evolution": ["shuijinger", "jingtianshi", "mengjingling", "huanjinggang"], 
		"mutant_evolution": ["shuijinger", "mengtianshi", "mengjinggang", "liuyitianshi"]
	}, 
	"mengjinger": {
		"name": "梦晶儿", 
		"normal_evolution": ["mengjinger", "mengtianshi", "mengjinggang", "liuyitianshi"], 
		"mutant_evolution": ["mengjinger", "jingtianshi", "mengjingling", "huanjinggang"]
	}, 


	"lu_lu": {
		"name": "鲁鲁", 
		"normal_evolution": ["lu_lu", "gang_lei_fei", "zhong_yue_shen_yuan", "zhi_zun_bao"], 
		"mutant_evolution": ["lu_lu", "ben_lei_fei", "dong_yue_shen_yuan", "zhi_zun_lin"]
	}, 
	"tao_tao": {
		"name": "淘淘", 
		"normal_evolution": ["tao_tao", "hou_lei_fei", "xi_yue_shen_yuan", "zhi_zun_cao"], 
		"mutant_evolution": ["tao_tao", "gang_lei_fei", "zhong_yue_shen_yuan", "zhi_zun_bao"]
	}, 
	"meng_meng": {
		"name": "蒙蒙", 
		"normal_evolution": ["meng_meng", "ben_lei_fei", "dong_yue_shen_yuan", "zhi_zun_lin"], 
		"mutant_evolution": ["meng_meng", "hou_lei_fei", "xi_yue_shen_yuan", "zhi_zun_cao"]
	}, 


	"fu_di_long": {
		"name": "伏地龙", 
		"normal_evolution": ["fu_di_long", "wu_qi_long", "hei_long_shi", "hong_fa_yao_ji"], 
		"mutant_evolution": ["fu_di_long", "bao_lan_long", "qing_long_shi", "lan_fa_mo_ji"]
	}, 
	"wen_di_long": {
		"name": "纹地龙", 
		"normal_evolution": ["wen_di_long", "huang_jin_long", "huang_long_shi", "bai_fa_she_ji"], 
		"mutant_evolution": ["wen_di_long", "wu_qi_long", "hei_long_shi", "hong_fa_yao_ji"]
	}, 
	"shun_di_long": {
		"name": "瞬地龙", 
		"normal_evolution": ["shun_di_long", "bao_lan_long", "qing_long_shi", "lan_fa_mo_ji"], 
		"mutant_evolution": ["shun_di_long", "huang_jin_long", "huang_long_shi", "bai_fa_she_ji"]
	}, 
	"xiaozhubite": {
		"name": "小猪比特", 
		"normal_evolution": ["xiaozhubite", "zhongshanzhu", "nanbatian", "bajie"], 
		"mutant_evolution": ["xiaozhubite", "nangongzhu", "xiaobawang", "bujie"]
	}, 
	"xiaozhuanante": {
		"name": "小猪安特", 
		"normal_evolution": ["xiaozhuanante", "ximenzhu", "beibatian", "yijie"], 
		"mutant_evolution": ["xiaozhuanante", "zhongshanzhu", "nanbatian", "bajie"]
	}, 
	"xiaozhufente": {
		"name": "小猪芬特", 
		"normal_evolution": ["xiaozhufente", "nangongzhu", "xiaobawang", "bujie"], 
		"mutant_evolution": ["xiaozhufente", "ximenzhu", "beibatian", "yijie"]
	}
}


const LEGACY_MUTANT_EVOLUTION = {
	"yingying": ["yingying", "ling_shan", "lv_yi_xian_zi", "di_cang_shou"], 
	"linlin": ["linlin", "yu_yi", "bai_yi_xian_zi", "ao_xue_shou"], 
	"zhenzhen": ["zhenzhen", "ni_chang", "fen_yi_xian_zi", "huan_yun_shou"], 
	"dan_dan_yu": ["dan_dan_yu", "yu_mei_mei", "xi_shui_xian_zi", "yao_shui_ling_zun"], 
	"wan_zi_yu": ["wan_zi_yu", "yu_wa_wa", "zhu_lang_xian_zi", "han_hai_xian_ji"], 
	"ping_pang_yu": ["ping_pang_yu", "yu_niu_niu", "ling_bo_xian_zi", "cang_ming_shen_nv"], 
	"cong_cong": ["cong_cong", "niefengquan", "qibiantianlang", "lv_yao"], 
	"xi_pi": ["xi_pi", "aoririquan", "huanbiantianlang", "zi_yi"], 
	"wang_wang": ["wang_wang", "zhuiyingquan", "duoluotianlang", "huo_yao_jing"], 
	"baiguzhanshi": ["baiguzhanshi", "silingwushi", "gouhunshizhe", "xiaomoshi"], 
	"kulouzhanshi": ["kulouzhanshi", "zhonglingwushi", "shehunshizhe", "xiaofashi"], 
	"xiaozhubite": ["xiaozhubite", "nangongzhu", "beibatian", "yijie"], 
	"xiaozhuanante": ["xiaozhuanante", "zhongshanzhu", "xiaobawang", "bujie"], 
	"xiaozhufente": ["xiaozhufente", "ximenzhu", "nanbatian", "bajie"], 
}

static func is_evolution_origin_pet_id(pet_id: String) -> bool:
	return EVOLUTION_DATA.has(pet_id)

static func is_evolution_pet(pet_id: String) -> bool:
	if EVOLUTION_DATA.has(pet_id):
		return true
	for key in EVOLUTION_DATA:
		var data = EVOLUTION_DATA[key]
		var normal_chain = data.get("normal_evolution", [])
		var mutant_chain = data.get("mutant_evolution", [])
		if pet_id in normal_chain or pet_id in mutant_chain:
			return true
	for key in LEGACY_MUTANT_EVOLUTION:
		var legacy_chain = LEGACY_MUTANT_EVOLUTION[key]
		if pet_id in legacy_chain:
			return true
	return false

static func get_evolution_data(pet_id: String) -> Dictionary:
	if EVOLUTION_DATA.has(pet_id):
		return EVOLUTION_DATA[pet_id]
	for key in EVOLUTION_DATA:
		var data = EVOLUTION_DATA[key]
		var normal_chain = data.get("normal_evolution", [])
		var mutant_chain = data.get("mutant_evolution", [])
		if pet_id in normal_chain or pet_id in mutant_chain:
			return data
	for key in LEGACY_MUTANT_EVOLUTION:
		if pet_id in LEGACY_MUTANT_EVOLUTION[key]:
			return EVOLUTION_DATA.get(key, {})
	return {}

static func get_evolution_chain_for_pet(pet_id: String, is_mutant: bool, mutation_count: int = 0) -> Array:
	var origin: = get_evolution_origin(pet_id)
	return get_evolution_chain_by_origin(origin, is_mutant, mutation_count)

static func get_evolution_origin(pet_id: String) -> String:
	if EVOLUTION_DATA.has(pet_id):
		return pet_id
	for key in EVOLUTION_DATA:
		var data = EVOLUTION_DATA[key]
		var normal_chain = data.get("normal_evolution", [])
		var mutant_chain = data.get("mutant_evolution", [])
		if pet_id in normal_chain or pet_id in mutant_chain:
			return key
	for key in LEGACY_MUTANT_EVOLUTION:
		if pet_id in LEGACY_MUTANT_EVOLUTION[key]:
			return key
	return ""

static func get_evolution_chain_by_origin(origin_id: String, is_mutant: bool, mutation_count: int = 0) -> Array:
	var data = EVOLUTION_DATA.get(origin_id, {})
	if data.is_empty():
		return []
	if not is_mutant:
		return data.get("normal_evolution", [])

	if clampi(mutation_count, 0, 2) == 0 and LEGACY_MUTANT_EVOLUTION.has(origin_id):
		return LEGACY_MUTANT_EVOLUTION[origin_id]
	return data.get("mutant_evolution", [])

static func get_evolution_stage(pet_id: String, evolution_chain: Array) -> int:
	return evolution_chain.find(pet_id)


static func find_pet_evolution_binding(pet_id: String) -> Dictionary:
	var pid: = str(pet_id).strip_edges()
	if pid.is_empty():
		return {}
	for origin in EVOLUTION_DATA:
		var data: Dictionary = EVOLUTION_DATA[origin]
		var normal_chain: Array = data.get("normal_evolution", [])
		var mutant_chain: Array = data.get("mutant_evolution", [])
		var normal_idx: = normal_chain.find(pid)
		if normal_idx >= 0:
			return {
				"origin": origin, 
				"is_mutant": false, 
				"stage": normal_idx, 
				"chain": normal_chain, 
			}
		var mutant_idx: = mutant_chain.find(pid)
		if mutant_idx >= 0:
			return {
				"origin": origin, 
				"is_mutant": true, 
				"stage": mutant_idx, 
				"chain": mutant_chain, 
			}
	for origin in LEGACY_MUTANT_EVOLUTION:
		var legacy_chain: Array = LEGACY_MUTANT_EVOLUTION[origin]
		var legacy_idx: = legacy_chain.find(pid)
		if legacy_idx >= 0:
			return {
				"origin": origin, 
				"is_mutant": true, 
				"stage": legacy_idx, 
				"chain": legacy_chain, 
			}
	return {}

static func can_mutate(pet_id: String) -> bool:
	var origin: = pet_id
	if not EVOLUTION_DATA.has(pet_id):
		origin = get_evolution_origin(pet_id)
	if origin.is_empty():
		return false


	var data = EVOLUTION_DATA.get(origin, {})
	var mutant = data.get("mutant_evolution", [])
	if mutant.size() > 0:
		return true
	var legacy = LEGACY_MUTANT_EVOLUTION.get(origin, [])
	return legacy.size() > 0

static func get_next_evolution(pet_id: String, is_mutant: bool = false, mutation_count: int = 0) -> String:
	var origin: = get_evolution_origin(pet_id)
	var chain: = get_evolution_chain_by_origin(origin, is_mutant, mutation_count)
	var stage = chain.find(pet_id)
	if stage >= 0 and stage < chain.size() - 1:
		return chain[stage + 1]
	return ""

static func get_evolution_required_level(pet_id: String, is_mutant: bool = false) -> int:
	return 500
