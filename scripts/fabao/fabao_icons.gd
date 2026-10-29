extends RefCounted
class_name FabaoIcons

const ICON_DIR: = "res://assets/items/fabao/"
const FabaoConfigRef = preload("res://scripts/fabao/fabao_config.gd")

const FILE_BY_TIER: = {
	"normal": "icon_fabao_normal.png", 
	"hard": "icon_fabao_hard.png", 
	"hell": "icon_fabao_hell.png", 
	"epic": "icon_fabao_epic.png", 
	"legend": "icon_fabao_legend.png", 
	"supreme": "icon_fabao_supreme.png", 
	"chaos": "icon_fabao_chaos.png", 
	"wushang": "icon_fabao_wushang.png", 
	"memorial_2026": "icon_fabao_memorial_2026.png", 
}
const FRAG_FILE_BY_TIER: = {
	"normal": "icon_frag_fabao_normal.png", 
	"hard": "icon_frag_fabao_hard.png", 
	"hell": "icon_frag_fabao_hell.png", 
	"epic": "icon_frag_fabao_epic.png", 
	"legend": "icon_frag_fabao_legend.png", 
	"supreme": "icon_frag_fabao_supreme.png", 
	"chaos": "icon_frag_fabao_chaos.png", 
	"wushang": "icon_frag_fabao_wushang.png", 
	"memorial_2026": "icon_frag_fabao_memorial_2026.png", 
}

static var _cache: Dictionary = {}


static func tex_for_item_name(item_name: String) -> Texture2D:
	var n: = item_name.strip_edges()
	if n.is_empty():
		return null
	for tid in FabaoConfigRef.all_template_ids():
		if n == FabaoConfigRef.fragment_item_name(tid):
			return _load(str(FRAG_FILE_BY_TIER.get(tid, "")))
		if n == FabaoConfigRef.fabao_item_name(tid):
			return _load(str(FILE_BY_TIER.get(tid, "")))
	return null


static func tex_for_tier(tier_id: String, fragment: bool = false) -> Texture2D:
	var tid: = FabaoConfigRef.normalize_tier(tier_id)
	var fn: = str((FRAG_FILE_BY_TIER if fragment else FILE_BY_TIER).get(tid, ""))
	return _load(fn)


static func _load(file_name: String) -> Texture2D:
	if file_name.is_empty():
		return null
	var path: = ICON_DIR + file_name
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_cache[path] = tex
	return tex
