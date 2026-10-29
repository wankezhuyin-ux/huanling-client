extends Node
class_name BrotherTowerBattleSync

const BrotherTowerMgr = preload("res://scripts/brother_tower/brother_tower_manager.gd")

var _gm = null
var _session_id: int = 0
var _wave: int = 1
var _is_driver: bool = false
var _pending_events: Array = []
var _last_applied_seq: int = 0
var _flush_accum: float = 0.0
var _poll_accum: float = 0.0
var _poll_in_flight: bool = false
var _flush_in_flight: bool = false
var _connected: bool = false
var _viewer_catchup_done: bool = false
var _push_op_counter: int = 0
var _retry_push_op_id: String = ""
var _viewer_skip_combat_replay: bool = false
var _last_attacker_type: String = ""
var _last_attacker_name: String = ""

const FLUSH_INTERVAL: = 0.25
const POLL_INTERVAL: = 0.4
const MAX_PUSH_BATCH: = 100
const VIEWER_CATCHUP_POLLS: = 3
const VIEWER_CATCHUP_INTERVAL: = 0.15

func setup(game_manager, session_id: int, is_driver: bool, start_wave: int) -> void :
	_gm = game_manager
	_session_id = session_id
	_is_driver = is_driver
	_wave = maxi(1, start_wave)
	_pending_events.clear()
	_last_applied_seq = 0
	_flush_accum = 0.0
	_poll_accum = 0.0
	_poll_in_flight = false
	_flush_in_flight = false
	_viewer_catchup_done = false
	_retry_push_op_id = ""
	_viewer_skip_combat_replay = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _gm == null or _gm.battle_system == null:
		return
	var bs = _gm.battle_system
	if _is_driver:
		if not bs.log_added.is_connected(_on_log_added):
			bs.log_added.connect(_on_log_added)
		if not bs.unit_turn.is_connected(_on_unit_turn):
			bs.unit_turn.connect(_on_unit_turn)
		if not bs.damage_dealt.is_connected(_on_damage_dealt):
			bs.damage_dealt.connect(_on_damage_dealt)
		if not bs.unit_died.is_connected(_on_unit_died):
			bs.unit_died.connect(_on_unit_died)
		if bs.has_signal("unit_hp_synced") and not bs.unit_hp_synced.is_connected(_on_unit_hp_synced):
			bs.unit_hp_synced.connect(_on_unit_hp_synced)
		_connected = true
		print("[BrotherTowerBattleSync] driver 就绪 session=%d wave=%d" % [_session_id, _wave])
	else:
		_poll_accum = 0.0
		_connected = true
		print("[BrotherTowerBattleSync] viewer 就绪 session=%d wave=%d，开始 catch-up poll" % [_session_id, _wave])
		_start_viewer_catching_up()

func request_poll_now() -> void :
	if _is_driver or not _connected or _poll_in_flight:
		return
	_poll_events_async()

func _start_viewer_catching_up() -> void :

	_initial_poll_events()

func teardown() -> void :
	if _gm != null and _gm.battle_system != null:
		var bs = _gm.battle_system
		if bs.log_added.is_connected(_on_log_added):
			bs.log_added.disconnect(_on_log_added)
		if bs.unit_turn.is_connected(_on_unit_turn):
			bs.unit_turn.disconnect(_on_unit_turn)
		if bs.damage_dealt.is_connected(_on_damage_dealt):
			bs.damage_dealt.disconnect(_on_damage_dealt)
		if bs.unit_died.is_connected(_on_unit_died):
			bs.unit_died.disconnect(_on_unit_died)
		if bs.has_signal("unit_hp_synced") and bs.unit_hp_synced.is_connected(_on_unit_hp_synced):
			bs.unit_hp_synced.disconnect(_on_unit_hp_synced)
	if _is_driver and _pending_events.size() > 0 and _gm != null and _gm.network != null:
		_flush_events_async()
	_connected = false
	_gm = null

func get_last_applied_seq() -> int:
	return _last_applied_seq

func set_wave(wave: int) -> void :
	_wave = maxi(1, wave)

func push_wave_start(wave: int) -> void :
	_wave = maxi(1, wave)
	_queue_event("wave_start", {"wave": _wave})
	_request_immediate_flush()

func push_wave_end(wave: int) -> void :
	_queue_event("wave_end", {"wave": wave})
	_request_immediate_flush()

func push_battle_end(victory: bool) -> void :
	_queue_event("battle_end", {"victory": victory, "wave": _wave})
	_request_immediate_flush()

func push_all_cleared() -> void :
	_queue_event("all_cleared", {"wave": _wave})
	_request_immediate_flush()

func flush_now() -> void :
	if _is_driver:
		await _flush_events_async()

func _request_immediate_flush() -> void :
	if _is_driver:
		_flush_events_async()

func _process(delta: float) -> void :
	if not _connected or _gm == null:
		return
	if _is_driver:
		_flush_accum += delta
		if _flush_accum >= FLUSH_INTERVAL and _pending_events.size() > 0 and not _flush_in_flight:
			_flush_accum = 0.0
			_flush_events_async()
	else:

		_poll_accum += delta
		if _poll_accum >= POLL_INTERVAL and not _poll_in_flight:
			_poll_accum = 0.0
			_poll_events_async()

func _queue_event(event_type: String, payload: Dictionary) -> void :
	if not _is_driver:
		return
	_pending_events.append({
		"wave": _wave, 
		"eventType": event_type, 
		"payload": payload, 
	})

func _on_log_added(message: String, highlight: Dictionary) -> void :
	var payload: = {
		"message": message, 
		"highlight": highlight, 
	}
	var skill_anchor: = ""
	if str(highlight.get("type", "")) == "skill":
		skill_anchor = str(highlight.get("anchor", ""))
	if not skill_anchor.is_empty():
		payload["attacker_type"] = skill_anchor
	elif not _last_attacker_type.is_empty():
		payload["attacker_type"] = _last_attacker_type
	if not _last_attacker_name.is_empty():
		payload["attacker_name"] = _last_attacker_name
	_queue_event("log", payload)

func _on_unit_turn(unit: Dictionary) -> void :
	_last_attacker_type = str(unit.get("type", ""))
	_last_attacker_name = str(unit.get("name", ""))
	_queue_event("unit_turn", {
		"type": _last_attacker_type, 
		"name": _last_attacker_name, 
		"index": int(unit.get("index", -1)), 
		"skip_lunge": bool(unit.get("skip_lunge", false)), 
		"lunge_time_scale": float(unit.get("lunge_time_scale", 1.0)), 
		"target_type": str(unit.get("target_type", "")), 
		"target_index": int(unit.get("target_index", -1)), 
	})

func _on_damage_dealt(
	attacker: String, 
	target: String, 
	damage: int, 
	is_critical: bool, 
	hit_target_type: String, 
	hit_target_index: int, 
	element_tag: String = "", 
	is_armor_pierce: bool = false, 
	is_counter: bool = false
) -> void :
	if _gm == null or _gm.battle_system == null:
		return
	var hp_after: int = _gm.battle_system.get_replay_unit_hp(hit_target_type, hit_target_index)
	_queue_event("damage", {
		"attacker": attacker, 
		"target": target, 
		"damage": damage, 
		"is_critical": is_critical, 
		"hit_target_type": hit_target_type, 
		"hit_target_index": hit_target_index, 
		"element_tag": element_tag, 
		"is_armor_pierce": is_armor_pierce, 
		"is_counter": is_counter, 
		"target_hp_after": hp_after, 
	})

func _on_unit_died(unit_name: String) -> void :
	var resolved: = _resolve_died_unit_on_driver(unit_name)
	_queue_event("unit_died", {
		"unit_name": unit_name, 
		"hit_target_type": str(resolved.get("hit_target_type", "")), 
		"hit_target_index": int(resolved.get("hit_target_index", -1)), 
	})

func _on_unit_hp_synced(hit_target_type: String, hit_target_index: int, hp_after: int) -> void :
	_queue_event("hp_sync", {
		"hit_target_type": hit_target_type, 
		"hit_target_index": hit_target_index, 
		"target_hp_after": hp_after, 
	})

func _resolve_died_unit_on_driver(unit_name: String) -> Dictionary:
	if _gm == null or _gm.battle_system == null:
		return {}
	var bs = _gm.battle_system
	var dead: = str(unit_name).strip_edges()
	if dead.is_empty():
		return {}
	if bs.player and str(bs.player.player_name).strip_edges() == dead:
		return {"hit_target_type": "player", "hit_target_index": 0}
	if bs.active_pet and str(bs.active_pet.pet_name).strip_edges() == dead:
		return {"hit_target_type": "pet", "hit_target_index": 0}
	for i in range(bs.coop_units.size()):
		var cu = bs.coop_units[i]
		if cu != null and str(cu.display_name).strip_edges() == dead:
			return {"hit_target_type": str(cu.unit_type), "hit_target_index": i}
	for i in range(bs.monsters.size()):
		var m = bs.monsters[i]
		var mname: = ""
		if m is Dictionary:
			mname = str(m.get("monster_name", m.get("name", "")))
		elif m != null:
			if "monster_name" in m:
				mname = str(m.monster_name)
			elif "name" in m:
				mname = str(m.name)
		if mname.strip_edges() == dead:
			return {"hit_target_type": "monster", "hit_target_index": i}
	return {}

func _flush_events_async() -> void :
	if not _is_driver or _pending_events.size() == 0 or _flush_in_flight:
		return
	if _gm == null or _gm.network == null or _session_id <= 0:
		return
	_flush_in_flight = true
	var batch: Array = _pending_events.duplicate()
	if batch.size() > MAX_PUSH_BATCH:
		batch = batch.slice(0, MAX_PUSH_BATCH)

	var op_id: = _retry_push_op_id
	if op_id.is_empty():
		_push_op_counter += 1
		op_id = "bt_ev_%d_%d_%d" % [_session_id, _wave, _push_op_counter]
		_retry_push_op_id = op_id
	var result: Dictionary = await _gm.network.wait_brother_tower_push_battle_events(_session_id, op_id, batch)
	_flush_in_flight = false
	if bool(result.get("ok", false)):
		var remove_n: = mini(batch.size(), _pending_events.size())
		for _i in remove_n:
			_pending_events.pop_front()
		_retry_push_op_id = ""
		print("[BrotherTowerBattleSync] push 成功 session=%d wave=%d sent=%d remain=%d" % [_session_id, _wave, batch.size(), _pending_events.size()])
	else:
		push_warning("[BrotherTowerBattleSync] push 失败 session=%d wave=%d sent=%d op=%s err=%s" % [_session_id, _wave, batch.size(), op_id, str(result.get("err", ""))])

func _initial_poll_events() -> void :

	for i in range(VIEWER_CATCHUP_POLLS):
		print("[BrotherTowerBattleSync] catch-up poll %d/%d session=%d since=%d" % [i + 1, VIEWER_CATCHUP_POLLS, _session_id, _last_applied_seq])
		await _poll_events_async()
		if i == 0:
			_viewer_catchup_done = true
		if i < VIEWER_CATCHUP_POLLS - 1:
			var tree: = get_tree()
			if tree:
				await tree.create_timer(VIEWER_CATCHUP_INTERVAL).timeout
	_viewer_catchup_done = true
	print("[BrotherTowerBattleSync] catch-up 完成 session=%d last_seq=%d" % [_session_id, _last_applied_seq])

func _poll_events_async() -> void :
	if _is_driver or _poll_in_flight:
		return
	if _gm == null or _gm.network == null or _session_id <= 0:
		var has_net: = _gm != null and _gm.network != null
		push_warning("[BrotherTowerBattleSync] poll 跳过 session=%d has_gm=%s has_net=%s" % [_session_id, _gm != null, has_net])
		return
	_poll_in_flight = true
	print("[BrotherTowerBattleSync] poll 开始 session=%d since=%d" % [_session_id, _last_applied_seq])
	var data: Dictionary = await _gm.network.wait_brother_tower_fetch_battle_events(_session_id, _last_applied_seq)
	_poll_in_flight = false
	if not bool(data.get("ok", false)):
		push_warning("[BrotherTowerBattleSync] 拉取事件失败 session=%d since=%d err=%s" % [_session_id, _last_applied_seq, str(data.get("err", ""))])
		return
	var events: Array = data.get("events", [])
	if events == null or not events is Array:
		print("[BrotherTowerBattleSync] poll 响应无 events 数组 session=%d" % _session_id)
		return
	print("[BrotherTowerBattleSync] poll 完成 session=%d since=%d got=%d" % [_session_id, _last_applied_seq, events.size()])
	if events.is_empty() and _last_applied_seq == 0:
		print("[BrotherTowerBattleSync] 暂无事件 session=%d，等待队长推进" % _session_id)
		return
	var applied: = 0
	var skip_combat_after_terminal: = false
	for ev in events:
		if not ev is Dictionary:
			continue
		var seq: = int(ev.get("seq", 0))
		if seq <= _last_applied_seq:
			continue
		var event_type: = str(ev.get("eventType", ev.get("event_type", "")))
		if skip_combat_after_terminal and _is_viewer_combat_event_type(event_type):
			_last_applied_seq = seq
			continue
		_apply_viewer_event(ev)
		_last_applied_seq = seq
		applied += 1
		if _is_final_wave_terminal_event(ev):
			skip_combat_after_terminal = true
			_viewer_skip_combat_replay = true
	if applied > 0:
		print("[BrotherTowerBattleSync] viewer 应用 %d 条事件 session=%d last_seq=%d" % [applied, _session_id, _last_applied_seq])

func _is_viewer_combat_event_type(event_type: String) -> bool:
	return event_type in ["damage", "unit_turn", "unit_died", "hp_sync"]

func _is_final_wave_terminal_event(ev: Dictionary) -> bool:
	if _gm == null:
		return false
	var event_type: = str(ev.get("eventType", ev.get("event_type", "")))
	if event_type == "all_cleared":
		return int(_gm.brother_tower_current_wave) >= _gm.get_brother_tower_wave_count()
	if event_type != "battle_end":
		return false
	var payload: Dictionary = ev.get("payload", {}) if ev.get("payload") is Dictionary else {}
	if not bool(payload.get("victory", false)):
		return false
	var wave: = int(payload.get("wave", _gm.brother_tower_current_wave))
	return wave >= _gm.get_brother_tower_wave_count()

func _should_skip_viewer_combat_event(ev: Dictionary, event_type: String) -> bool:
	if _gm == null:
		return true
	if _viewer_skip_combat_replay and _is_viewer_combat_event_type(event_type):
		return true
	if event_type not in ["damage", "unit_turn", "unit_died", "hp_sync"]:
		return false
	if _gm.is_brother_tower_settling:
		return true
	if not _gm.in_battle:
		return true
	var ev_wave: = int(ev.get("wave", 0))
	var current_wave: int = int(_gm.brother_tower_current_wave)
	if ev_wave > 0 and ev_wave != current_wave:
		return true
	return false

func _apply_viewer_event(ev: Dictionary) -> void :
	if _gm == null or _gm.battle_system == null:
		return
	var event_type: = str(ev.get("eventType", ev.get("event_type", "")))
	if _should_skip_viewer_combat_event(ev, event_type):
		return
	var payload: Dictionary = ev.get("payload", {}) if ev.get("payload") is Dictionary else {}
	var bs = _gm.battle_system
	match event_type:
		"wave_start":
			var w: = maxi(1, int(payload.get("wave", 1)))
			_wave = w
			if w != _gm.brother_tower_current_wave or not _gm.in_battle:
				BrotherTowerMgr.heal_all_battle_allies(_gm)
				_gm.call_deferred("_begin_viewer_wave_from_sync", w)
		"log":
			var msg: = str(payload.get("message", ""))
			var hl: Dictionary = payload.get("highlight", {}) if payload.get("highlight") is Dictionary else {}
			hl = _fix_viewer_log_highlight_anchor(_remap_highlight_for_viewer(hl), payload, msg)
			bs.apply_replay_log(msg, hl)
		"unit_turn":
			bs.apply_replay_unit_turn(_remap_unit_turn_for_viewer(payload))
		"damage":
			bs.apply_replay_damage_event(_remap_damage_for_viewer(payload))
		"hp_sync":
			bs.apply_replay_hp_sync(_remap_damage_for_viewer(payload))
		"unit_died":
			var died_payload: = _remap_unit_died_for_viewer(payload)
			bs.apply_replay_unit_died(
				str(died_payload.get("unit_name", "")), 
				false, 
				str(died_payload.get("hit_target_type", "")), 
				int(died_payload.get("hit_target_index", -1))
			)
		"wave_end":
			pass
		"battle_end":
			var victory: = bool(payload.get("victory", false))
			var wave: = int(payload.get("wave", 0))
			bs.apply_replay_battle_state(victory)
			_gm._on_viewer_battle_end_from_sync(victory, wave)
		"all_cleared":
			_gm._on_viewer_all_cleared_from_sync()

func _fix_viewer_log_highlight_anchor(highlight: Dictionary, payload: Dictionary, message: String) -> Dictionary:
	if highlight.is_empty() or str(highlight.get("type", "")) != "skill":
		return highlight
	var remapped_anchor: = str(highlight.get("anchor", ""))
	if not remapped_anchor.is_empty():
		return highlight
	var attacker_type: = str(payload.get("attacker_type", ""))
	if attacker_type.is_empty():
		attacker_type = _infer_log_attacker_type_from_message(message)
	if attacker_type.is_empty():
		return highlight
	var out: = highlight.duplicate(true)
	out["anchor"] = _remap_skill_anchor_for_viewer(attacker_type)
	return out

func _infer_log_attacker_type_from_message(message: String) -> String:
	var plain: = _strip_bbcode_for_log_match(message)
	var skill_idx: = plain.find("【一击三伤】")
	var atk_idx: = plain.find(" 攻击")
	var cut: = plain.length()
	if skill_idx >= 0:
		cut = skill_idx
	elif atk_idx >= 0:
		cut = atk_idx
	var attacker_name: = plain.substr(0, cut).strip_edges()
	if attacker_name.is_empty() or _gm == null or _gm.battle_system == null:
		return ""
	var bs = _gm.battle_system
	if bs.player and str(bs.player.player_name) == attacker_name:
		return "player"
	for cu in bs.coop_units:
		if cu != null and str(cu.display_name) == attacker_name:
			return str(cu.unit_type) if "unit_type" in cu else "coop_player"
	if bs.active_pet and str(bs.active_pet.pet_name) == attacker_name:
		return "pet"
	return ""

func _strip_bbcode_for_log_match(message: String) -> String:
	var out: = str(message)
	while true:
		var start: = out.find("[")
		if start < 0:
			break
		var end: = out.find("]", start)
		if end < 0:
			break
		out = out.substr(0, start) + out.substr(end + 1)
	return out

func _remap_highlight_for_viewer(highlight: Dictionary) -> Dictionary:
	if highlight.is_empty():
		return highlight
	if str(highlight.get("type", "")) != "skill":
		return highlight
	var out: = highlight.duplicate(true)
	var anchor: = str(out.get("anchor", "pet"))
	out["anchor"] = _remap_skill_anchor_for_viewer(anchor)
	return out

func _remap_skill_anchor_for_viewer(anchor: String) -> String:
	match anchor:
		"pet":
			return "coop_pet"
		"coop_pet":
			return "pet"
		"player":
			return "coop_player"
		"coop_player":
			return "player"
		_:
			return anchor

func _remap_hit_for_viewer(hit_type: String, hit_index: int) -> Dictionary:
	match hit_type:
		"player":
			return {"hit_target_type": "coop_player", "hit_target_index": 0}
		"pet":
			return {"hit_target_type": "coop_pet", "hit_target_index": _leader_coop_pet_index()}
		"coop_player":
			return {"hit_target_type": "player", "hit_target_index": 0}
		"coop_pet":
			return {"hit_target_type": "pet", "hit_target_index": 0}
		"monster":
			return {"hit_target_type": "monster", "hit_target_index": hit_index}
	return {"hit_target_type": hit_type, "hit_target_index": hit_index}

func _leader_coop_pet_index() -> int:
	if _gm == null or _gm.battle_system == null:
		return 0
	for i in range(_gm.battle_system.coop_units.size()):
		var cu = _gm.battle_system.coop_units[i]
		if cu != null and str(cu.unit_type) == "coop_pet":
			return i
	return 0

func _remap_unit_turn_for_viewer(payload: Dictionary) -> Dictionary:
	var hit_type: = str(payload.get("type", ""))
	var hit_index: = int(payload.get("index", -1))
	var mapped: = _remap_hit_for_viewer(hit_type, hit_index)
	return {
		"type": mapped.get("hit_target_type", hit_type), 
		"name": str(payload.get("name", "")), 
		"index": int(mapped.get("hit_target_index", hit_index)), 
		"skip_lunge": bool(payload.get("skip_lunge", false)), 
		"lunge_time_scale": float(payload.get("lunge_time_scale", 1.0)), 
		"target_type": str(payload.get("target_type", "")), 
		"target_index": int(payload.get("target_index", -1)), 
	}

func _remap_damage_for_viewer(payload: Dictionary) -> Dictionary:
	var hit_type: = str(payload.get("hit_target_type", ""))
	var hit_index: = int(payload.get("hit_target_index", -1))
	var mapped: = _remap_hit_for_viewer(hit_type, hit_index)
	var out: = payload.duplicate(true)
	out["hit_target_type"] = mapped.get("hit_target_type", hit_type)
	out["hit_target_index"] = int(mapped.get("hit_target_index", hit_index))
	return out

func _remap_unit_died_for_viewer(payload: Dictionary) -> Dictionary:
	var out: = payload.duplicate(true)
	var hit_type: = str(payload.get("hit_target_type", ""))
	if hit_type.is_empty():
		return out
	var hit_index: = int(payload.get("hit_target_index", -1))
	var mapped: = _remap_hit_for_viewer(hit_type, hit_index)
	out["hit_target_type"] = mapped.get("hit_target_type", hit_type)
	out["hit_target_index"] = int(mapped.get("hit_target_index", hit_index))
	return out
