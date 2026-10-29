extends RefCounted
class_name PlayerCharacterConfig

const SWITCH_COST_GOLD: = 500000000
const MIN_ID: = 0
const MAX_ID: = 6
const BATTLE_SPRITE_FRAME_SIZE: = 256
const DEFAULT_BATTLE_VISUAL_SIZE: = 256.0
const ALT_BATTLE_VISUAL_SIZE: = 200.0
const DEFAULT_BATTLE_STATIC_SCALE_FACTOR: = 0.7

const _AVATAR_TX_NAMES: = {
	0: "playertx", 
	1: "playertx1", 
	2: "playertx2", 
	3: "playertx3", 
	4: "playertx4", 
	5: "playertx5", 
	6: "playertx6", 
}

const _STATIC_NAMES: = {
	0: "player", 
	1: "player1", 
	2: "player2", 
	3: "player3", 
	4: "player4", 
	5: "player5", 
	6: "player6", 
}

const _DEFEATED_NAMES: = {
	0: "playerdead", 
	1: "playerdead1", 
	2: "playerdead2", 
	3: "playerdead3", 
	4: "playerdead4", 
	5: "playerdead5", 
	6: "playerdead6", 
}

static func normalize_id(raw: Variant) -> int:
	var id: = int(raw)
	if not is_valid_id(id):
		return 0
	return id

static func is_valid_id(id: int) -> bool:
	return id >= MIN_ID and id <= MAX_ID

static func get_all_ids() -> Array[int]:
	var ids: Array[int] = []
	for i in range(MIN_ID, MAX_ID + 1):
		ids.append(i)
	return ids

static func get_display_name(id: int) -> String:
	var cid: = normalize_id(id)
	if cid == 0:
		return "默认角色"
	return "角色%d" % cid

static func get_avatar_tx_name(id: int) -> String:
	var cid: = normalize_id(id)
	return str(_AVATAR_TX_NAMES.get(cid, _AVATAR_TX_NAMES[0]))

static func get_avatar_tx_path(id: int) -> String:
	return "res://assets/portraits/%s.png" % get_avatar_tx_name(id)

static func get_static_name(id: int) -> String:
	var cid: = normalize_id(id)
	return str(_STATIC_NAMES.get(cid, _STATIC_NAMES[0]))

static func get_static_path(id: int) -> String:
	return "res://assets/portraits/%s.png" % get_static_name(id)

static func get_defeated_name(id: int) -> String:
	var cid: = normalize_id(id)
	return str(_DEFEATED_NAMES.get(cid, _DEFEATED_NAMES[0]))

static func get_defeated_path(id: int) -> String:
	return "res://assets/portraits/%s.png" % get_defeated_name(id)

static func get_sprite_id(id: int) -> String:
	return get_static_name(id)

static func get_battle_visual_size(id: int) -> float:
	return DEFAULT_BATTLE_VISUAL_SIZE if normalize_id(id) == 0 else ALT_BATTLE_VISUAL_SIZE

static func get_battle_sprite_scale(id: int) -> float:
	return get_battle_visual_size(id) / float(BATTLE_SPRITE_FRAME_SIZE)

static func get_battle_static_display_height(id: int) -> float:
	var cid: = normalize_id(id)
	if cid == 0:
		return DEFAULT_BATTLE_VISUAL_SIZE * DEFAULT_BATTLE_STATIC_SCALE_FACTOR
	return ALT_BATTLE_VISUAL_SIZE

static func get_battle_layout_center() -> Vector2:
	return Vector2(DEFAULT_BATTLE_VISUAL_SIZE * 0.5, DEFAULT_BATTLE_VISUAL_SIZE * 0.5)

static func get_battle_sprite_position_offset(id: int) -> Vector2:
	var pad: = (DEFAULT_BATTLE_VISUAL_SIZE - get_battle_visual_size(id)) * 0.5
	return Vector2(pad, pad)
