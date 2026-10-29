extends RefCounted
class_name CombatReplayPlayer



var battle_system
var mine_names: PackedStringArray = PackedStringArray()
var unit_id_map: Dictionary = {}
var viewer_side: String = ""
var should_abort: Callable = Callable()
var on_hud_refresh: Callable = Callable()

var log_style: String = ""
var _bound_settle_gen: int = 0

const IMPACT_DELAY: = 0.45
const ATTACK_STEP: = 1.0
const SPLASH_STEP: = 1.2
const COMBO_STEP: = 0.5
const JOINT_STEP: = 1.2
const OPENING_SETTLE: = 0.55
const COMBO_LUNGE_SCALE: = 0.5
const PAIR_BEFORE_COMBO_STEP: = 0.68
const MONSTER_WAVE_STAGGER: = 0.06

func _capture_settle_gen() -> void :
	_bound_settle_gen = 0
	if battle_system:
		_bound_settle_gen = int(battle_system.get("_opening_settle_gen"))

func _battle_replaced() -> bool:
	if battle_system == null:
		return true
	return int(battle_system.get("_opening_settle_gen")) != _bound_settle_gen

func _should_stop() -> bool:
	if _battle_replaced():
		return true
	return should_abort.is_valid() and bool(should_abort.call())

func play_async(host: Node, battle_log: Array, server_victory: bool) -> Dictionary:
	if battle_system == null or host == null or not host.is_inside_tree():
		return {"aborted": true, "log_victory": false}
	_capture_settle_gen()
	var normalized: Array = []
	for raw in battle_log:
		if raw is Dictionary:
			normalized.append(_normalize_entry(raw))
		else:
			normalized.append(raw)
	_stamp_legacy_triple_shot_misses(normalized)
	var log_victory: = _normalized_log_victory(normalized)
	if OPENING_SETTLE > 0.0:
		await host.get_tree().create_timer(OPENING_SETTLE).timeout
	var aborted: = _should_stop()
	var i: = 0
	while i < normalized.size() and not aborted:
		if _should_stop():
			aborted = true
			break
		var item = normalized[i]
		if not (item is Dictionary):
			i += 1
			continue
		if _is_instant_entry(item):
			var instant_type: = str(item.get("type", ""))
			if _is_wild_style() and instant_type == "skill_divine_protect":
				var nxt_i: = i + 1
				if nxt_i < normalized.size() and normalized[nxt_i] is Dictionary:
					var divine_win: Array = _collect_action_window(normalized, nxt_i)
					if not divine_win.is_empty():
						var played: Array = [item]
						played.append_array(divine_win)
						var divine_shorten: = false
						var divine_after: = nxt_i + divine_win.size()
						if divine_after < normalized.size() and normalized[divine_after] is Dictionary:
							if str((normalized[divine_after] as Dictionary).get("type", "")) == "combo_attack":
								divine_shorten = true
						await _play_window_async(host, played, divine_shorten)
						if _should_stop():
							aborted = true
							break
						i = divine_after
						continue
			_apply_entry(item)
			i += 1
			if instant_type in ["victory", "defeat"]:
				break
			continue
		var win: Array = _collect_action_window(normalized, i)
		if win.is_empty():
			await _apply_entry_async(host, item)
			if _should_stop():
				aborted = true
				break
			i += 1
		else:
			var shorten_for_combo: = false
			var after: = i + win.size()
			if after < normalized.size() and normalized[after] is Dictionary:
				if str((normalized[after] as Dictionary).get("type", "")) == "combo_attack":
					shorten_for_combo = true
			await _play_window_async(host, win, shorten_for_combo)
			if _should_stop():
				aborted = true
				break
			i = after
	if battle_system and not aborted and not _battle_replaced():
		battle_system.apply_replay_battle_state(server_victory)
	if on_hud_refresh.is_valid():
		on_hud_refresh.call()
	return {"aborted": aborted, "log_victory": log_victory}

func _normalized_log_victory(normalized: Array) -> bool:
	var last_win: = false
	for item in normalized:
		if not (item is Dictionary):
			continue
		var t: = str((item as Dictionary).get("type", ""))
		if t == "victory":
			last_win = true
		elif t == "defeat":
			last_win = false
	return last_win

func _is_instant_entry(entry: Dictionary) -> bool:
	return str(entry.get("type", "")) in [
		"round", "start", "info", "unit_info", "combo_trigger", "stance_skip", 
		"kuihua_point_success", "kuihua_point_fail", "acupoint_skip", 
		"skill_armor_pierce", "skill_guard", "skill_divine_protect", "skill_self_heal", 
		"enemy_dead", "pet_dead", "player_dead", "victory", "defeat"
	]

func _is_attack_entry(entry_type: String) -> bool:
	return entry_type in [
		"attack", "triple_shot_hit", "kuihua_hit", "skill_splash", "skill_double_shot", 
		"skill_counter_attack", "skill_chase", "miss", "dodge"
	]

func _is_package_lead(entry_type: String) -> bool:
	return entry_type in ["attack", "triple_shot_hit", "kuihua_hit", "miss", "dodge"]

func _is_player_miss_entry(entry: Dictionary) -> bool:
	var t: = str(entry.get("type", ""))
	if t != "miss" and t != "dodge":
		return false
	if bool(entry.get("isPetAttack", entry.get("is_pet_attack", false))):
		return false
	return true

func _is_triple_shot_swing(entry: Dictionary) -> bool:
	var t: = str(entry.get("type", ""))
	if t == "triple_shot_hit":
		return true
	if not _is_player_miss_entry(entry):
		return false
	var skill: = str(entry.get("skill", "")).strip_edges().to_lower()
	if skill == "triple_shot":
		return true
	if int(entry.get("hitIndex", entry.get("hit_index", 0))) >= 1:
		return true
	return false

func _is_kuihua_swing(entry: Dictionary) -> bool:
	var t: = str(entry.get("type", ""))
	if t == "kuihua_hit":
		return true
	if not _is_player_miss_entry(entry):
		return false
	return str(entry.get("skill", "")).strip_edges().to_lower() == "kuihua"

func _is_package_extra_for_lead(lead: Dictionary, nxt: Dictionary) -> bool:
	var extra_type: = str(nxt.get("type", ""))
	if extra_type in ["skill_splash", "skill_double_shot"]:
		return _same_package_attacker(lead, nxt)
	if not _same_package_attacker(lead, nxt):
		return false
	if int(lead.get("round", 0)) != int(nxt.get("round", 0)) and int(lead.get("round", 0)) > 0 and int(nxt.get("round", 0)) > 0:
		return false
	if _is_triple_shot_swing(lead) and (_is_triple_shot_swing(nxt) or extra_type == "triple_shot_hit"):
		return true
	if extra_type == "triple_shot_hit" and str(lead.get("type", "")) == "triple_shot_hit":
		return true
	if _is_kuihua_swing(lead) and (_is_kuihua_swing(nxt) or extra_type == "kuihua_hit"):
		return true
	if extra_type == "kuihua_hit" and str(lead.get("type", "")) == "kuihua_hit":
		return true
	if _is_player_miss_entry(lead) and _is_player_miss_entry(nxt):
		return true
	return false

func _collect_attack_package(log_items: Array, start: int) -> Array:
	if start < 0 or start >= log_items.size():
		return []
	var lead = log_items[start]
	if not (lead is Dictionary):
		return []
	var lead_entry: Dictionary = lead
	if not _is_package_lead(str(lead_entry.get("type", ""))):
		return []
	var found_extra: = false
	var extra_count: = 0
	var end: = start + 1
	var j: = start + 1
	while j < log_items.size():
		var item = log_items[j]
		if not (item is Dictionary):
			break
		var nxt: Dictionary = item
		var t: = str(nxt.get("type", ""))
		if _is_package_extra_for_lead(lead_entry, nxt):
			if t not in ["skill_splash", "skill_double_shot"] and extra_count >= 2:
				break
			found_extra = true
			extra_count += 1
			j += 1
			end = j
			continue
		if _is_package_passthrough(t):
			j += 1
			end = j
			continue
		break
	if end <= start:
		return [lead_entry]
	var pkg: Array = []
	for k in range(start, end):
		pkg.append(log_items[k])
	return pkg

func _collect_passthrough_tail(log_items: Array, start: int) -> Array:
	var out: Array = []
	var j: = start
	while j < log_items.size():
		var item = log_items[j]
		if not (item is Dictionary):
			break
		if not _is_package_passthrough(str(item.get("type", ""))):
			break
		out.append(item)
		j += 1
	return out

func _collect_single_swing(log_items: Array, start: int) -> Array:
	if start < 0 or start >= log_items.size():
		return []
	var lead = log_items[start]
	if not (lead is Dictionary):
		return []
	var out: Array = [lead]
	out.append_array(_collect_passthrough_tail(log_items, start + 1))
	return out

func _collect_joint_window(log_items: Array, start: int) -> Array:
	var out: Array = [log_items[start]]
	var j: = start + 1
	while j < log_items.size():
		var item = log_items[j]
		if not (item is Dictionary):
			break
		var nxt: Dictionary = item
		var t: = str(nxt.get("type", ""))
		if t in ["skill_armor_pierce", "skill_guard", "skill_divine_protect"] or _is_package_passthrough(t):
			out.append(nxt)
			j += 1
			continue
		if _is_attack_entry(t) and bool(nxt.get("isJointAttack", nxt.get("is_joint_attack", false))):
			out.append(nxt)
			j += 1
			continue
		break
	return out

func _collect_combo_window(log_items: Array, start: int) -> Array:
	var out: Array = [log_items[start]]
	var j: = start + 1
	while j < log_items.size():
		var item = log_items[j]
		if not (item is Dictionary):
			break
		var nxt: Dictionary = item
		var t: = str(nxt.get("type", ""))
		if t in ["skill_armor_pierce", "skill_guard"] or _is_package_passthrough(t):
			out.append(nxt)
			j += 1
			continue
		if _is_attack_entry(t) and bool(nxt.get("isCombo", nxt.get("is_combo", false))):
			out.append(nxt)
			j += 1
			out.append_array(_collect_passthrough_tail(log_items, j))
			break
		break
	return out

func _is_wild_style() -> bool:
	return log_style == "wild" or log_style == "tower"

func _entry_is_enemy_attack(entry: Dictionary) -> bool:
	if not _is_attack_entry(str(entry.get("type", ""))):
		return false
	return bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))

func _collect_action_window(log_items: Array, start: int) -> Array:
	if start < 0 or start >= log_items.size():
		return []
	var lead = log_items[start]
	if not (lead is Dictionary):
		return []
	var t: = str(lead.get("type", ""))
	if t == "joint_attack":
		return _collect_joint_window(log_items, start)
	if t == "combo_attack":
		return _collect_combo_window(log_items, start)
	if _is_wild_style() and _is_attack_entry(t):
		if _entry_is_enemy_attack(lead):
			return _collect_monster_wave_window(log_items, start)
		if not bool(lead.get("isCombo", lead.get("is_combo", false))):
			return _collect_ally_pair_window(log_items, start)
	if t in ["skill_chase", "skill_counter_attack"]:
		return _collect_single_swing(log_items, start)
	if _is_attack_entry(t):
		var pkg: Array = _collect_attack_package(log_items, start)
		var end: = start + pkg.size()
		while end < log_items.size():
			var nxt = log_items[end]
			if not (nxt is Dictionary):
				break
			var nt: = str(nxt.get("type", ""))
			if nt in ["skill_chase", "skill_counter_attack"]:
				var extra: Array = _collect_single_swing(log_items, end)
				pkg.append_array(extra)
				end += extra.size()
				continue
			break
		return pkg
	return [lead]

func _collect_ally_pair_window(log_items: Array, start: int) -> Array:
	var lead: Dictionary = log_items[start]
	var round_n: = int(lead.get("round", 0))
	var out: Array = _collect_attack_package(log_items, start)
	var j: = start + out.size()
	while j < log_items.size():
		var item = log_items[j]
		if not (item is Dictionary):
			break
		var nxt: Dictionary = item
		var nt: = str(nxt.get("type", ""))
		if nt in ["combo_attack", "joint_attack", "round", "victory", "defeat"]:
			break
		if int(nxt.get("round", 0)) != round_n and round_n > 0 and int(nxt.get("round", 0)) > 0:
			break
		if _entry_is_enemy_attack(nxt):
			break
		if bool(nxt.get("isCombo", nxt.get("is_combo", false))):
			break
		if nt in ["skill_chase", "skill_counter_attack"] or _is_attack_entry(nt):
			if nt in ["skill_chase", "skill_counter_attack"]:
				var extra: Array = _collect_single_swing(log_items, j)
				out.append_array(extra)
				j += extra.size()
				continue
			var pkg: Array = _collect_attack_package(log_items, j)
			out.append_array(pkg)
			j += pkg.size()
			continue
		if _is_package_passthrough(nt) or nt in ["skill_armor_pierce", "skill_guard", "skill_divine_protect"]:
			out.append(nxt)
			j += 1
			continue
		break
	return out

func _entry_turn_batch(entry: Dictionary) -> int:
	if not entry.has("turnBatch") and not entry.has("turn_batch"):
		return -1
	return int(entry.get("turnBatch", entry.get("turn_batch", -1)))

func _collect_monster_wave_window(log_items: Array, start: int) -> Array:
	var lead: Dictionary = log_items[start]
	var round_n: = int(lead.get("round", 0))
	var batch: = _entry_turn_batch(lead)
	var out: Array = []
	var j: = start
	while j < log_items.size():
		var item = log_items[j]
		if not (item is Dictionary):
			break
		var nxt: Dictionary = item
		var nt: = str(nxt.get("type", ""))
		if nt in ["round", "victory", "defeat", "combo_attack", "joint_attack", "combo_trigger"]:
			break
		if int(nxt.get("round", 0)) != round_n and round_n > 0 and int(nxt.get("round", 0)) > 0:
			break
		if _is_attack_entry(nt) and not _entry_is_enemy_attack(nxt) and nt not in ["skill_counter_attack", "skill_chase"]:
			break
		if _entry_is_enemy_attack(nxt):
			var nb: = _entry_turn_batch(nxt)
			if batch >= 0 and nb >= 0 and nb != batch:
				break
			var pkg: Array = _collect_attack_package(log_items, j)
			out.append_array(pkg)
			j += pkg.size()
			continue
		if nt in ["skill_counter_attack", "skill_chase"]:
			var extra: Array = _collect_single_swing(log_items, j)
			out.append_array(extra)
			j += extra.size()
			continue
		if _is_package_passthrough(nt) or nt in ["skill_armor_pierce", "skill_guard", "skill_divine_protect", "enemy_dead", "pet_dead", "player_dead"]:
			out.append(nxt)
			j += 1
			continue
		if batch >= 0 and _entry_turn_batch(nxt) == batch:
			out.append(nxt)
			j += 1
			continue
		break
	if out.is_empty():
		return [lead]
	return out

func _window_has_type(pkg: Array, entry_type: String) -> bool:
	for item in pkg:
		if item is Dictionary and str(item.get("type", "")) == entry_type:
			return true
	return false

func _window_has_triple(pkg: Array) -> bool:
	for item in pkg:
		if not (item is Dictionary):
			continue
		if _is_triple_shot_swing(item):
			return true
	return false

func _window_has_double_shot(pkg: Array) -> bool:
	for item in pkg:
		if item is Dictionary and str(item.get("type", "")) == "skill_double_shot":
			return true
	return false

func _split_follow_swings(pkg: Array) -> Dictionary:
	var main: Array = []
	var follows: Array = []
	var cur_follow: Array = []
	var in_follow: = false
	for item in pkg:
		if not (item is Dictionary):
			continue
		var t: = str(item.get("type", ""))
		if t in ["skill_chase", "skill_counter_attack"]:
			if not cur_follow.is_empty():
				follows.append(cur_follow)
			cur_follow = [item]
			in_follow = true
			continue
		if in_follow:
			cur_follow.append(item)
		else:
			main.append(item)
	if not cur_follow.is_empty():
		follows.append(cur_follow)
	return {"main": main, "follows": follows}

func _play_window_async(host: Node, pkg: Array, shorten_for_combo: bool = false) -> void :
	if pkg.is_empty() or host == null or not host.is_inside_tree():
		return
	if _should_stop():
		return
	if _window_has_type(pkg, "joint_attack"):
		await _play_joint_window_async(host, pkg)
		return
	if _window_has_type(pkg, "combo_attack") or _window_lead_is_combo(pkg):
		await _play_scaled_swing_async(host, pkg, COMBO_STEP, COMBO_LUNGE_SCALE)
		return
	var lead: Dictionary = pkg[0]
	var lead_type: = str(lead.get("type", ""))
	if lead_type in ["skill_chase", "skill_counter_attack"]:
		await _play_scaled_swing_async(host, pkg, COMBO_STEP, COMBO_LUNGE_SCALE)
		return
	if _is_wild_style() and _window_has_enemy_attack(pkg):
		await _play_monster_wave_async(host, pkg)
		return
	if _is_wild_style() and _is_attack_entry(lead_type):
		await _play_ally_pair_async(host, pkg, shorten_for_combo)
		return
	if not _is_attack_entry(lead_type):
		for item in pkg:
			if item is Dictionary:
				_apply_entry(item)
		return
	var split: Dictionary = _split_follow_swings(pkg)
	var main: Array = split.get("main", [])
	if not main.is_empty():
		await _apply_attack_package_async(host, main)
	for follow in split.get("follows", []):
		if follow is Array and not (follow as Array).is_empty():
			await _play_scaled_swing_async(host, follow, COMBO_STEP, COMBO_LUNGE_SCALE)

func _window_has_enemy_attack(pkg: Array) -> bool:
	for item in pkg:
		if item is Dictionary and _entry_is_enemy_attack(item):
			return true
	return false

func _play_ally_pair_async(host: Node, pkg: Array, shorten_for_combo: bool) -> void :
	if pkg.is_empty() or host == null or not host.is_inside_tree():
		return
	var seen: Dictionary = {}
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		if not _is_attack_entry(str(e.get("type", ""))):
			continue
		if _entry_is_enemy_attack(e):
			continue
		var key: = _entry_attacker_key(e)
		if key.is_empty() or seen.has(key):
			continue
		seen[key] = true
		var skip: = _should_skip_lunge(e)
		if not skip:
			skip = _attacker_skips_lunge_in_pkg(pkg, key)
		_apply_attacker_anim(e, skip, 1.0)
	await host.get_tree().create_timer(IMPACT_DELAY).timeout
	var splash_hl_done: = false
	var pkg_has_splash: = _package_has_splash(pkg)
	var pkg_has_triple: = _window_has_triple(pkg)
	var triple_hl_done: = false
	for item in pkg:
		if not (item is Dictionary):
			continue
		var nxt: Dictionary = item
		var t: = str(nxt.get("type", ""))
		if t in ["joint_attack", "combo_attack"]:
			_apply_entry(nxt)
			continue
		if t == "skill_splash":
			_apply_attack_damage(nxt, not splash_hl_done)
			splash_hl_done = true
		elif _is_attack_entry(t):
			var force_triple: = ( not triple_hl_done) and _is_triple_shot_swing(nxt) and not _entry_is_enemy_attack(nxt)
			if force_triple:
				triple_hl_done = true
			if pkg_has_splash:
				_apply_attack_damage(nxt, false, true, force_triple)
			elif force_triple:
				_apply_attack_damage(nxt, false, false, true)
			else:
				_apply_hit_result(nxt)
		else:
			_apply_entry(nxt)
	var step: = ATTACK_STEP
	if shorten_for_combo and not _package_has_splash(pkg):
		step = PAIR_BEFORE_COMBO_STEP
	elif _package_has_splash(pkg) or _window_has_triple(pkg):
		step = SPLASH_STEP
	await host.get_tree().create_timer(maxf(0.05, step - IMPACT_DELAY)).timeout

func _attacker_skips_lunge_in_pkg(pkg: Array, attacker_key: String) -> bool:
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		if _entry_attacker_key(e) != attacker_key:
			continue
		if _should_skip_lunge(e) or _is_triple_shot_swing(e):
			return true
	return false

func _play_monster_wave_async(host: Node, pkg: Array) -> void :
	if pkg.is_empty() or host == null or not host.is_inside_tree() or battle_system == null:
		return
	var used_slots: Dictionary = {}
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		if not _entry_is_enemy_attack(e):
			continue
		var idx: = _wave_assign_monster_slot(e, used_slots)
		if idx < 0:
			continue
		var hit: = _resolve_living_swing_target(e, _resolve_monster_attack_hit(e))
		if hit.is_empty() or not _ensure_swing_target_alive(e, hit):
			continue
		used_slots[idx] = true
		var target_type: = str(hit.get("type", "player"))
		if target_type not in ["player", "pet", "coop_player", "coop_pet"]:
			target_type = "player"
		battle_system.apply_replay_unit_turn({
			"type": "monster", 
			"index": idx, 
			"name": str(e.get("attacker", "")), 
			"target_type": target_type, 
			"target_index": int(hit.get("index", -1)), 
			"skip_lunge": false, 
		})
	await host.get_tree().create_timer(IMPACT_DELAY).timeout
	var first_enemy_hit: = true
	var stagger_count: = 0
	for item in pkg:
		if not (item is Dictionary):
			continue
		var nxt: Dictionary = item
		var t: = str(nxt.get("type", ""))
		if _entry_is_enemy_attack(nxt):
			if not first_enemy_hit:
				await host.get_tree().create_timer(MONSTER_WAVE_STAGGER).timeout
				stagger_count += 1
			first_enemy_hit = false
			_apply_hit_result(nxt)
		elif _is_attack_entry(t):
			_apply_hit_result(nxt)
		else:
			_apply_entry(nxt)
	var used: = IMPACT_DELAY + float(stagger_count) * MONSTER_WAVE_STAGGER
	await host.get_tree().create_timer(maxf(0.05, ATTACK_STEP - used)).timeout

func _window_lead_is_combo(pkg: Array) -> bool:
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		if _is_attack_entry(str(e.get("type", ""))) and bool(e.get("isCombo", e.get("is_combo", false))):
			return true
		if str(e.get("type", "")) == "combo_attack":
			return true
	return false

func _play_joint_window_async(host: Node, pkg: Array) -> void :
	var seen_attackers: Dictionary = {}
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		var t: = str(e.get("type", ""))
		if t == "joint_attack" or t in ["skill_armor_pierce", "skill_guard"]:
			_apply_entry(e)
			continue
		if _is_attack_entry(t):
			var key: = _entry_attacker_key(e)
			if not seen_attackers.has(key):
				seen_attackers[key] = true
				_apply_attacker_anim(e, false, 1.0)
	await host.get_tree().create_timer(IMPACT_DELAY).timeout
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e2: Dictionary = item
		var t2: = str(e2.get("type", ""))
		if _is_attack_entry(t2):
			_apply_hit_result(e2)
		elif _is_package_passthrough(t2):
			_apply_entry(e2)
	await host.get_tree().create_timer(maxf(0.05, JOINT_STEP - IMPACT_DELAY)).timeout

func _play_scaled_swing_async(host: Node, pkg: Array, step: float, lunge_scale: float) -> void :
	var swung: = false
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		var t: = str(e.get("type", ""))
		if t == "combo_attack":
			_apply_entry(e)
			continue
		if t in ["skill_armor_pierce", "skill_guard"]:
			_apply_entry(e)
			continue
		if _is_attack_entry(t) and not swung:
			_apply_attacker_anim(e, false, lunge_scale)
			swung = true
	var impact: = IMPACT_DELAY * maxf(0.25, lunge_scale)
	await host.get_tree().create_timer(impact).timeout
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e2: Dictionary = item
		var t2: = str(e2.get("type", ""))
		if t2 == "combo_attack":
			continue
		if _is_attack_entry(t2):
			_apply_hit_result(e2)
		elif _is_package_passthrough(t2) or t2 in ["skill_armor_pierce", "skill_guard"]:
			if t2 not in ["skill_armor_pierce", "skill_guard"]:
				_apply_entry(e2)
	await host.get_tree().create_timer(maxf(0.05, step - impact)).timeout

func _entry_is_skill_swing(entry_type: String) -> bool:
	return entry_type in ["skill_splash", "skill_double_shot", "triple_shot_hit", "kuihua_hit"]

func _package_skips_lunge(pkg: Array) -> bool:
	var player_misses: = 0
	for item in pkg:
		if not (item is Dictionary):
			continue
		var e: Dictionary = item
		if _entry_is_skill_swing(str(e.get("type", ""))) or _is_triple_shot_swing(e) or _is_kuihua_swing(e):
			return true
		if _is_player_miss_entry(e):
			player_misses += 1
	return player_misses >= 2

func _should_skip_lunge(entry: Dictionary) -> bool:
	return _entry_is_skill_swing(str(entry.get("type", ""))) or _is_triple_shot_swing(entry) or _is_kuihua_swing(entry)

func _is_package_passthrough(entry_type: String) -> bool:
	return entry_type in [
		"skill_armor_pierce", "skill_guard", "skill_divine_protect", "skill_life_steal", 
		"kuihua_point_success", "kuihua_point_fail", 
		"enemy_dead", "pet_dead", "player_dead"
	]

func _wave_assign_monster_slot(entry: Dictionary, used_slots: Dictionary) -> int:
	var bs = battle_system
	if bs == null:
		return -1
	var idx: = int(entry.get("attackerIndex", entry.get("attacker_index", -1)))
	if idx >= 0 and idx < bs.monsters.size() and not used_slots.has(idx) and bs.is_monster_alive(bs.monsters[idx]):
		return idx
	for i in range(bs.monsters.size()):
		if used_slots.has(i):
			continue
		if not bs.is_monster_alive(bs.monsters[i]):
			continue
		return i
	return -1

func _wave_monster_key(entry: Dictionary) -> String:
	if not _entry_is_enemy_attack(entry):
		return ""
	var idx: = int(entry.get("attackerIndex", entry.get("attacker_index", -1)))
	if idx >= 0:
		return "monster:%d" % idx
	var slot: = _resolve_attacker(entry)
	if str(slot.get("type", "")) != "monster":
		return ""
	var resolved: = int(slot.get("index", -1))
	if resolved < 0:
		return ""
	return "monster:%d" % resolved

func _wave_monster_key_unique(entry: Dictionary, seen: Dictionary) -> String:
	var key: = _wave_monster_key(entry)
	if key.is_empty():
		return ""
	if not seen.has(key):
		return key
	var bs = battle_system
	if bs == null:
		return ""
	for i in range(bs.monsters.size()):
		var alt: = "monster:%d" % i
		if seen.has(alt):
			continue
		if not bs.is_monster_alive(bs.monsters[i]):
			continue
		return alt
	return ""

func _apply_death_entry(entry: Dictionary, entry_type: String) -> void :
	var bs = battle_system
	if bs == null:
		return
	var dead_name: = str(entry.get("name", entry.get("target", "")))
	var id_slot: = _slot_from_id(str(entry.get("targetId", "")))
	if not id_slot.is_empty():
		bs.apply_replay_unit_died(dead_name, true, str(id_slot.get("type", "")), int(id_slot.get("index", -1)))
		return
	if entry_type == "pet_dead":
		bs.apply_replay_unit_died(dead_name, true, "pet", -1)
		return
	if entry_type == "player_dead":
		bs.apply_replay_unit_died(dead_name, true, "player", -1)
		return
	var idx: = int(entry.get("targetIndex", entry.get("target_index", -1)))
	bs.apply_replay_unit_died(dead_name, true, "monster", idx)

func _entry_attacker_key(entry: Dictionary) -> String:
	var aid: = str(entry.get("attackerId", "")).strip_edges()
	if not aid.is_empty():
		return aid
	return _norm_unit_name(str(entry.get("attacker", "")))

func _same_package_attacker(lead: Dictionary, other: Dictionary) -> bool:
	var a: = _entry_attacker_key(lead)
	var b: = _entry_attacker_key(other)
	if a.is_empty() or b.is_empty():
		return false
	return a == b

func _apply_hit_result(entry: Dictionary) -> void :
	var entry_type: = str(entry.get("type", ""))
	if entry_type in ["miss", "dodge"]:
		_apply_miss_float(entry)
	elif _is_attack_entry(entry_type):
		_apply_attack_damage(entry)
	else:
		_apply_entry(entry)

func _apply_attack_package_async(host: Node, pkg: Array) -> void :
	if pkg.is_empty() or host == null or not host.is_inside_tree():
		return
	var lead: = {}
	for item in pkg:
		if item is Dictionary and _is_attack_entry(str(item.get("type", ""))):
			lead = item
			break
	if lead.is_empty() and pkg[0] is Dictionary:
		lead = pkg[0]
	if lead.is_empty():
		return
	var skip_lunge: = _package_skips_lunge(pkg) or _window_has_triple(pkg) or _window_has_double_shot(pkg)
	_apply_attacker_anim(lead, skip_lunge, 1.0)
	await host.get_tree().create_timer(IMPACT_DELAY).timeout
	var splash_hl_done: = false
	var pkg_has_splash: = _package_has_splash(pkg)
	var pkg_has_triple: = _window_has_triple(pkg)
	var triple_hl_done: = false
	for item in pkg:
		if not (item is Dictionary):
			continue
		var nxt: Dictionary = item
		var t: = str(nxt.get("type", ""))
		if t in ["joint_attack", "combo_attack"]:
			_apply_entry(nxt)
			continue
		if t == "skill_splash":
			_apply_attack_damage(nxt, not splash_hl_done)
			splash_hl_done = true
		elif _is_attack_entry(t):
			var force_triple: = ( not triple_hl_done) and _is_triple_shot_swing(nxt) and not _entry_is_enemy_attack(nxt)
			if force_triple:
				triple_hl_done = true
			if pkg_has_splash:
				_apply_attack_damage(nxt, false, true, force_triple)
			elif force_triple:
				_apply_attack_damage(nxt, false, false, true)
			else:
				_apply_hit_result(nxt)
		else:
			_apply_entry(nxt)
	var step: = ATTACK_STEP
	if _package_has_splash(pkg) or _window_has_triple(pkg):
		step = SPLASH_STEP
	await host.get_tree().create_timer(maxf(0.05, step - IMPACT_DELAY)).timeout

func _package_has_splash(pkg: Array) -> bool:
	for item in pkg:
		if item is Dictionary and str(item.get("type", "")) == "skill_splash":
			return true
	return false

func _stamp_legacy_triple_shot_misses(log_items: Array) -> void :
	var i: = 0
	while i < log_items.size():
		var pkg: Array = _collect_attack_package(log_items, i)
		if pkg.size() <= 1 or not _package_skips_lunge(pkg):
			i += 1
			continue
		var arrow: = 0
		for item in pkg:
			if not (item is Dictionary):
				continue
			var e: Dictionary = item
			if not (_is_triple_shot_swing(e) or _is_player_miss_entry(e)):
				continue
			var existing: = int(e.get("hitIndex", e.get("hit_index", 0)))
			if existing >= 1:
				arrow = existing
			else:
				arrow += 1
				e["skill"] = "triple_shot"
				e["hitIndex"] = arrow
		i += pkg.size()

func _apply_entry_async(host: Node, entry: Dictionary) -> void :
	if _should_stop():
		return
	var entry_type: = str(entry.get("type", ""))
	if _is_attack_entry(entry_type):
		var skip: = _should_skip_lunge(entry)
		var scale: = COMBO_LUNGE_SCALE if entry_type in ["skill_chase", "skill_counter_attack"] else 1.0
		_apply_attacker_anim(entry, skip, scale)
		var impact: = IMPACT_DELAY * (scale if scale < 1.0 else 1.0)
		await host.get_tree().create_timer(impact).timeout
		if _should_stop():
			return
		if entry_type in ["miss", "dodge"]:
			_apply_miss_float(entry)
		else:
			_apply_attack_damage(entry)
		var step: = ATTACK_STEP
		if _is_triple_shot_swing(entry) or entry_type == "skill_splash":
			step = SPLASH_STEP
		elif entry_type in ["skill_chase", "skill_counter_attack"]:
			step = COMBO_STEP
		await host.get_tree().create_timer(maxf(0.05, step - impact)).timeout
		return
	_apply_entry(entry)

func _step_delay(_entry_type: String) -> float:
	return 0.0

func _name_is_mine(unit_name: String) -> bool:
	var n: = _norm_unit_name(unit_name)
	if n.is_empty():
		return false
	for x in mine_names:
		if n == _norm_unit_name(x):
			return true
	return false

func _side_from_unit_id(unit_id: String) -> String:
	var s: = unit_id.strip_edges()
	if s.begins_with("A_"):
		return "A"
	if s.begins_with("B_"):
		return "B"
	return str(s.split("_")[0]) if s.find("_") >= 0 else ""

func _slot_from_id(unit_id: String) -> Dictionary:
	var id: = unit_id.strip_edges()
	if id.is_empty() or unit_id_map.is_empty():
		return {}
	var slot = unit_id_map.get(id, {})
	if slot is Dictionary and not slot.is_empty():
		return (slot as Dictionary).duplicate()
	return {}

func _highlight_for_entry(entry: Dictionary, slot: Dictionary = {}) -> Dictionary:
	var t: = str(entry.get("type", ""))
	var anchor: = "pet"
	var at: = str(slot.get("type", ""))
	if at in ["player", "pet", "coop_player", "coop_pet", "monster"]:
		anchor = at
	var idx: = int(slot.get("index", -1))
	match t:
		"skill_splash":
			return BattleSystem._skill_highlight("溅射", anchor, 0, idx)
		"skill_double_shot":
			return BattleSystem._skill_highlight("连射", anchor, 0, idx)
		"triple_shot_hit":
			return {}
		"skill_counter_attack":
			return BattleSystem._skill_highlight("反击", anchor, 0, idx)
		"skill_chase":
			return BattleSystem._skill_highlight("追击", anchor, 0, idx)
		"skill_armor_pierce":
			return BattleSystem._skill_highlight("破甲", anchor, 0, idx)
		"skill_guard":
			return BattleSystem._skill_highlight("格挡", anchor, 0, idx)
		"skill_divine_protect":
			return BattleSystem._skill_highlight("神佑", anchor, 0, idx)
		"skill_self_heal":
			var heal_amt: = int(entry.get("hpRestored", entry.get("hp_restored", entry.get("heal", 0))))
			var heal_anchor: = str(slot.get("type", ""))
			if heal_anchor not in ["player", "pet", "coop_player", "coop_pet", "monster"]:
				heal_anchor = "pet"
			return BattleSystem._skill_highlight("自愈", heal_anchor, heal_amt, idx)
		"kuihua_point_success", "kuihua_point_fail":
			return {}
		"skill_life_steal":
			var steal_name: = str(entry.get("skillName", entry.get("skill_name", "吸血")))
			var steal_heal: = int(entry.get("hpRestored", entry.get("hp_restored", 0)))
			var steal_anchor: = str(slot.get("type", ""))
			if steal_anchor not in ["player", "pet", "coop_player", "coop_pet"]:
				steal_anchor = "pet" if bool(entry.get("isPetAttack", entry.get("is_pet_attack", false))) else "player"
			return BattleSystem._skill_highlight(steal_name, steal_anchor, steal_heal, idx)
		_:
			return {}

func _should_show_triple_shot_banner(entry: Dictionary) -> bool:
	if str(entry.get("type", "")) == "triple_shot_hit":
		return false
	if str(entry.get("skillName", entry.get("skill_name", ""))) == "三锋齐下":
		return true
	return str(entry.get("skill", "")).to_lower() == "triple_shot"

func _normalize_entry(raw: Dictionary) -> Dictionary:
	var n: Dictionary = raw.duplicate(true)
	var t: = str(n.get("type", ""))
	if t == "round_start":
		n["type"] = "round"
		n["round"] = int(n.get("round", 0))
	elif t == "battle_start":
		n["type"] = "info"
		n["message"] = str(n.get("text", n.get("message", "对决开始")))
	elif t == "battle_end":
		n["type"] = "info"
		n["message"] = str(n.get("text", n.get("message", "对决结束")))
	if str(n.get("attacker", "")).is_empty():
		n["attacker"] = str(n.get("attackerName", ""))
	if str(n.get("target", "")).is_empty():
		n["target"] = str(n.get("targetName", n.get("name", "")))
	var aid: = str(n.get("attackerId", "")).strip_edges()
	var aside: = str(n.get("attackerSide", "")).strip_edges()
	if aside.is_empty():
		aside = _side_from_unit_id(aid)
	if not aid.is_empty() and not viewer_side.is_empty() and not aside.is_empty():
		n["isEnemyAttack"] = aside != viewer_side
	elif not n.has("isEnemyAttack") and not n.has("is_enemy_attack"):
		var atk_name: = str(n.get("attacker", "")).strip_edges()
		if not atk_name.is_empty() and t not in ["enemy_dead", "pet_dead", "player_dead", "defeat"]:
			n["isEnemyAttack"] = not _name_is_mine(atk_name)
	if t == "defeat":
		var nm: = str(n.get("targetName", n.get("name", n.get("target", "")))).strip_edges()
		var end_text: = str(n.get("text", n.get("message", ""))).strip_edges()
		if nm.is_empty() and (end_text.find("战斗失败") >= 0 or str(n.get("targetId", "")).strip_edges().is_empty()):
			n["type"] = "defeat"
			n["message"] = end_text if not end_text.is_empty() else "战斗失败"
			return n
		n["name"] = nm
		var tid: = str(n.get("targetId", "")).strip_edges()
		var tside: = str(n.get("targetSide", "")).strip_edges()
		if tside.is_empty():
			tside = _side_from_unit_id(tid)
		var mine_dead: = false
		if not tid.is_empty() and not viewer_side.is_empty() and not tside.is_empty():
			mine_dead = tside == viewer_side
		else:
			mine_dead = _name_is_mine(nm)
		n["type"] = "player_dead" if mine_dead else "enemy_dead"
	return n

func _apply_entry(entry: Dictionary) -> void :
	var bs = battle_system
	if bs == null or _battle_replaced():
		return
	var entry_type: = str(entry.get("type", ""))
	match entry_type:
		"round", "start", "info", "combo_trigger", "combo_attack", "joint_attack", "stance_skip", "kuihua_point_success", "kuihua_point_fail", "acupoint_skip", "skill_armor_pierce", "skill_guard", "unit_info":
			if _is_wild_style() and entry_type in ["start", "info"]:
				var raw_info: = str(entry.get("message", entry.get("text", ""))).strip_edges()
				if raw_info.is_empty() or raw_info == "战斗开始" or raw_info == "对决开始":
					return
			var msg: = format_message(entry)
			if not msg.is_empty():
				var atk: = _resolve_attacker(entry)
				bs.apply_replay_log(msg, _highlight_for_entry(entry, atk))
			if entry_type == "kuihua_point_success":
				_emit_acupoint_seal_visual(entry, true)
			elif entry_type == "acupoint_skip":
				_emit_acupoint_seal_visual(entry, int(entry.get("remain", 0)) > 0)
		"attack", "triple_shot_hit", "kuihua_hit", "skill_splash", "skill_double_shot", "skill_counter_attack", "skill_chase":
			_apply_attack_damage(entry)
		"skill_divine_protect", "skill_life_steal":
			_apply_divine(entry)
		"skill_self_heal":
			_apply_self_heal(entry)
		"miss", "dodge":
			_apply_attacker_anim(entry)
			_apply_miss_float(entry)
		"enemy_dead", "pet_dead", "player_dead":
			_emit_acupoint_seal_visual(entry, false)
			_apply_death_entry(entry, entry_type)
			var dead_msg: = format_message(entry)
			if not dead_msg.is_empty():
				bs.apply_replay_log(dead_msg)
			if entry_type == "player_dead":
				bs.apply_replay_log("[color=#ff9966]⚠ 修士已力竭，仅灵兽继续作战[/color]")
		"victory", "defeat":
			var end_msg: = format_message(entry)
			if not end_msg.is_empty():
				bs.apply_replay_log(end_msg)
		_:
			var fallback: = format_message(entry)
			if fallback.is_empty():
				fallback = str(entry.get("message", entry.get("text", ""))).strip_edges()
			if not fallback.is_empty():
				bs.apply_replay_log(fallback)
	if entry_type in [
		"attack", "triple_shot_hit", "kuihua_hit", "skill_splash", "skill_double_shot", "skill_counter_attack", "skill_chase", 
		"skill_divine_protect", "skill_life_steal", "skill_self_heal", "skill_armor_pierce", "skill_guard", "enemy_dead", "pet_dead", "player_dead"
	]:
		if on_hud_refresh.is_valid():
			on_hud_refresh.call()

func _apply_self_heal(entry: Dictionary) -> void :
	var prepared: = entry.duplicate(true)
	var who: = str(prepared.get("target", "")).strip_edges()
	if who.is_empty():
		who = str(prepared.get("attacker", "")).strip_edges()
		prepared["target"] = who
	if int(prepared.get("hpRestored", prepared.get("hp_restored", 0))) <= 0:
		var heal_amt: = int(prepared.get("heal", 0))
		if heal_amt > 0:
			prepared["hpRestored"] = heal_amt
	if str(prepared.get("targetKind", prepared.get("target_kind", ""))).strip_edges().is_empty() and str(prepared.get("targetId", "")).strip_edges().is_empty():
		var bs = battle_system
		if bs != null and bs.active_pet != null and bs._replay_ally_unit_name_matches(who, str(bs.active_pet.pet_name)):
			prepared["targetKind"] = "pet"
			prepared["isPetAttack"] = true
			prepared["isEnemyAttack"] = false
		elif bs != null and bs.player != null and bs._replay_ally_unit_name_matches(who, str(bs.player.player_name)):
			prepared["targetKind"] = "player"
			prepared["isEnemyAttack"] = false
		else:
			var coop: = _resolve_coop_by_name(who)
			if not coop.is_empty():
				prepared["targetKind"] = str(coop.get("type", ""))
				prepared["targetIndex"] = int(coop.get("index", -1))
				prepared["isEnemyAttack"] = false
			else:
				var mhit: = _find_monster_by_name(who, true)
				if not mhit.is_empty():
					prepared["targetKind"] = "monster"
					prepared["targetIndex"] = int(mhit.get("index", 0))
					prepared["isEnemyAttack"] = false
	_apply_divine(prepared)

func _apply_divine(entry: Dictionary) -> void :
	var bs = battle_system
	var msg: = format_message(entry)
	if not msg.is_empty():
		var atk: = _resolve_attacker(entry)
		bs.apply_replay_log(msg, _highlight_for_entry(entry, atk))
	var hit: = _resolve_unit_slot(entry, true)
	if hit.is_empty():
		return
	var hit_type: = str(hit.get("type", ""))
	var hit_idx: = int(hit.get("index", -1))
	var hp_after: = int(entry.get("targetHp", entry.get("hpRestored", entry.get("hp_restored", -1))))
	if _is_wild_style() and hit_type in ["player", "pet"]:
		var cur: int = int(bs.get_replay_unit_hp(hit_type, hit_idx))
		var tmax: = int(entry.get("targetMaxHp", entry.get("target_max_hp", 0)))
		if tmax > 0 and hp_after >= 0:
			var cap: int = cur
			if hit_type == "player" and bs.player and bs.player.has_method("get_max_hp"):
				cap = int(bs.player.get_max_hp())
			elif hit_type == "pet" and bs.active_pet and bs.active_pet.has_method("get_final_max_hp_with_equipment"):
				cap = int(bs.active_pet.get_final_max_hp_with_equipment())
			hp_after = clampi(int(round(float(cap) * float(hp_after) / float(tmax))), 0, cap)
			hp_after = maxi(cur, hp_after)
		elif hp_after >= 0:
			hp_after = maxi(cur, hp_after)
	if hp_after >= 0:
		bs.apply_replay_hp_sync({
			"hit_target_type": hit_type, 
			"hit_target_index": hit_idx, 
			"target_hp_after": hp_after, 
		})

func _entry_is_combo_swing(entry: Dictionary) -> bool:
	if str(entry.get("type", "")) == "combo_attack":
		return true
	return bool(entry.get("isCombo", entry.get("is_combo", false)))

func _first_alive_monster_slot() -> Dictionary:
	var bs = battle_system
	if bs == null:
		return {}
	for i in range(bs.monsters.size()):
		if bs.get_replay_unit_hp("monster", i) > 0:
			return {"type": "monster", "index": i}
	return {}

func _first_living_ally_slot() -> Dictionary:
	var bs = battle_system
	if bs == null:
		return {}
	if bs.get_replay_unit_hp("player", -1) > 0:
		return {"type": "player", "index": -1}
	if bs.get_replay_unit_hp("pet", -1) > 0:
		return {"type": "pet", "index": -1}
	return {}


func _wild_locked_monster_slot(entry: Dictionary) -> Dictionary:
	if not _is_wild_style() or _is_monster_attacker(entry):
		return {}
	var kind: = str(entry.get("targetKind", entry.get("target_kind", ""))).strip_edges().to_lower()
	if kind != "" and kind != "monster":
		return {}
	var idx: = int(entry.get("targetIndex", entry.get("target_index", -1)))
	if idx < 0 or battle_system == null or idx >= battle_system.monsters.size():
		return {}
	return {"type": "monster", "index": idx}


func _resolve_living_swing_target(entry: Dictionary, hit: Dictionary) -> Dictionary:
	var locked: = _wild_locked_monster_slot(entry)
	if not locked.is_empty():
		return locked
	var bs = battle_system
	if bs == null:
		return {}
	var logged: = int(entry.get("targetHp", entry.get("target_hp", -1)))
	if not hit.is_empty():
		var client_hp: = int(bs.get_replay_unit_hp(str(hit.get("type", "")), int(hit.get("index", -1))))
		if client_hp > 0 or logged > 0:
			return hit
	if _is_monster_attacker(entry):
		return _first_living_ally_slot()
	return _first_alive_monster_slot()


func _ensure_swing_target_alive(entry: Dictionary, hit: Dictionary) -> bool:
	var bs = battle_system
	if bs == null or hit.is_empty():
		return false
	var hit_type: = str(hit.get("type", ""))
	var hit_idx: = int(hit.get("index", -1))
	if bs.get_replay_unit_hp(hit_type, hit_idx) > 0:
		return true
	if int(entry.get("targetHp", entry.get("target_hp", -1))) <= 0:
		return false
	bs.set_replay_unit_hp(hit_type, hit_idx, 1)
	return bs.get_replay_unit_hp(hit_type, hit_idx) > 0

func _combo_living_hit_slot(entry: Dictionary, hit: Dictionary) -> Dictionary:
	var locked: = _wild_locked_monster_slot(entry)
	if not locked.is_empty():
		return locked
	if not _is_wild_style() or not _entry_is_combo_swing(entry):
		return hit
	var bs = battle_system
	if bs == null:
		return hit
	if not hit.is_empty():
		var ht: = str(hit.get("type", ""))
		var hi: = int(hit.get("index", -1))
		if ht == "monster" and bs.get_replay_unit_hp(ht, hi) > 0:
			return hit
	return _first_alive_monster_slot()

func _apply_miss_float(entry: Dictionary) -> void :
	var bs = battle_system
	if bs == null:
		return
	var miss_msg: = format_message(entry)
	if not miss_msg.is_empty():
		var miss_hl: = {}
		if str(entry.get("skill", "")).to_lower() == "kuihua" and int(entry.get("hitIndex", entry.get("hit_index", 1))) <= 1:
			var kuihua_atk: = _resolve_attacker(entry)
			var kuihua_anchor: = str(kuihua_atk.get("type", "player"))
			if kuihua_anchor not in ["player", "pet", "coop_player", "coop_pet", "monster"]:
				kuihua_anchor = "player"
			miss_hl = BattleSystem._skill_highlight("葵花点穴", kuihua_anchor, 0, int(kuihua_atk.get("index", -1)))
		bs.apply_replay_log(miss_msg, miss_hl)
	var target_name: = str(entry.get("target", ""))
	var hit: = _resolve_living_swing_target(entry, _combo_living_hit_slot(entry, _resolve_unit_slot(entry, true)))
	if hit.is_empty():
		return
	var hit_type: = str(hit.get("type", ""))
	var hit_idx: = int(hit.get("index", -1))
	if bs.get_replay_unit_hp(hit_type, hit_idx) <= 0:
		return
	var miss_hp_after: = int(entry.get("targetHp", entry.get("target_hp", -1)))
	if _is_wild_style() and hit_type in ["player", "pet"]:
		miss_hp_after = bs.get_replay_unit_hp(hit_type, hit_idx)
	bs.apply_replay_damage_event({
		"attacker": str(entry.get("attacker", "")), 
		"target": target_name, 
		"damage": 0, 
		"is_critical": false, 
		"hit_target_type": hit_type, 
		"hit_target_index": hit_idx, 
		"target_hp_after": miss_hp_after, 
		"element_tag": "", 
		"is_armor_pierce": false, 
		"is_counter": false, 
	})
	if on_hud_refresh.is_valid():
		on_hud_refresh.call()

func _replay_client_hp_cap(hit_type: String, hit_idx: int) -> int:
	var bs = battle_system
	if bs == null:
		return 0
	if hit_type == "player" and bs.player:
		if bs.player.has_method("get_max_hp"):
			return maxi(0, int(bs.player.get_max_hp()))
		return maxi(0, int(bs.player.max_hp))
	if hit_type == "pet" and bs.active_pet:
		if bs.active_pet.has_method("get_final_max_hp_with_equipment"):
			return maxi(0, int(bs.active_pet.get_final_max_hp_with_equipment()))
		return maxi(0, int(bs.active_pet.max_hp))
	if hit_type == "monster" and hit_idx >= 0 and hit_idx < bs.monsters.size():
		return maxi(0, int(bs._get_monster_stat(bs.monsters[hit_idx], "max_hp", 0)))
	return 0


func _scale_wild_replay_hp_after(entry: Dictionary, hit_type: String, hit_idx: int, logged_hp: int, dmg: int) -> int:
	var bs = battle_system
	var cur: = -1
	if bs:
		cur = int(bs.get_replay_unit_hp(hit_type, hit_idx))
	var tmax: = int(entry.get("targetMaxHp", entry.get("target_max_hp", 0)))
	var cap: = _replay_client_hp_cap(hit_type, hit_idx)
	if tmax > 0 and logged_hp >= 0 and cap > 0:
		return clampi(int(round(float(cap) * float(logged_hp) / float(tmax))), 0, cap)
	if cur >= 0:
		return maxi(0, cur - maxi(0, dmg))
	return logged_hp

func _apply_attack_damage(entry: Dictionary, show_skill_highlight: bool = true, splash_hit_fx: bool = false, force_triple_banner: bool = false) -> void :
	var bs = battle_system
	if bs == null or _battle_replaced():
		return
	var orig_hit: = _resolve_unit_slot(entry, true)
	if _is_monster_attacker(entry):
		var ally_hit: = _resolve_monster_attack_hit(entry)
		if not ally_hit.is_empty():
			orig_hit = ally_hit
	var hit: = _resolve_living_swing_target(entry, _combo_living_hit_slot(entry, orig_hit))
	if hit.is_empty():
		return
	var hit_type: = str(hit.get("type", ""))
	var hit_idx: = int(hit.get("index", -1))
	var logged_hp: = int(entry.get("targetHp", entry.get("target_hp", -1)))
	if bs.get_replay_unit_hp(hit_type, hit_idx) <= 0 and logged_hp <= 0:
		return
	var target_name: = str(entry.get("target", ""))
	var hp_after: = logged_hp
	var retargeted: = orig_hit.is_empty() or str(orig_hit.get("type", "")) != hit_type or int(orig_hit.get("index", -1)) != hit_idx
	var dmg: = int(entry.get("damage", 0))
	if retargeted:
		if hit_type == "monster" and hit_idx >= 0 and hit_idx < bs.monsters.size():
			target_name = str(bs._get_monster_stat(bs.monsters[hit_idx], "monster_name", bs._get_monster_stat(bs.monsters[hit_idx], "name", target_name)))
		hp_after = maxi(0, bs.get_replay_unit_hp(hit_type, hit_idx) - dmg)
	elif _is_wild_style():
		hp_after = _scale_wild_replay_hp_after(entry, hit_type, hit_idx, logged_hp, dmg)
	var cur_hp: = int(bs.get_replay_unit_hp(hit_type, hit_idx))
	if dmg > 0 and cur_hp > 0 and (hp_after < 0 or hp_after == cur_hp):
		hp_after = maxi(0, cur_hp - dmg)
	var log_msg: = format_message(entry)
	var hl: = {}
	if show_skill_highlight:
		hl = _highlight_for_entry(entry, _resolve_attacker(entry))
	if str(entry.get("type", "")) == "skill_splash" or splash_hit_fx:
		hl = BattleSystem._attach_splash_hit_fx(hl, hit_idx)
		hl["hit_fx_type"] = hit_type
	if str(entry.get("type", "")) == "kuihua_hit" and int(entry.get("hitIndex", entry.get("hit_index", 1))) <= 1:
		var kuihua_atk: = _resolve_attacker(entry)
		var kuihua_anchor: = str(kuihua_atk.get("type", "player"))
		if kuihua_anchor not in ["player", "pet", "coop_player", "coop_pet", "monster"]:
			kuihua_anchor = "player"
		var kuihua_hl: Dictionary = BattleSystem._skill_highlight("葵花点穴", kuihua_anchor, 0, int(kuihua_atk.get("index", -1)))
		for k in kuihua_hl.keys():
			hl[k] = kuihua_hl[k]
	if force_triple_banner or (show_skill_highlight and _should_show_triple_shot_banner(entry)):
		var atk: = _resolve_attacker(entry)
		var t_anchor: = str(atk.get("type", "player"))
		if t_anchor not in ["player", "pet", "coop_player", "coop_pet", "monster"]:
			t_anchor = "player"
		var triple_hl: Dictionary = BattleSystem._skill_highlight("三锋齐下", t_anchor, 0, int(atk.get("index", -1)))
		for k in triple_hl.keys():
			hl[k] = triple_hl[k]
	if not log_msg.is_empty() or not hl.is_empty():
		bs.apply_replay_log(log_msg, hl)
	bs.apply_replay_damage_event({
		"attacker": str(entry.get("attacker", "")), 
		"target": target_name, 
		"damage": int(entry.get("damage", 0)), 
		"is_critical": bool(entry.get("isCritical", entry.get("is_critical", false))), 
		"hit_target_type": hit_type, 
		"hit_target_index": hit_idx, 
		"target_hp_after": hp_after, 
		"element_tag": str(entry.get("elementMsg", entry.get("element_msg", ""))), 
		"is_armor_pierce": bool(entry.get("isArmorPierce", entry.get("is_armor_pierce", false))), 
		"is_counter": bool(entry.get("isCounter", false)) or str(entry.get("type", "")) == "skill_counter_attack", 
	})
	if on_hud_refresh.is_valid():
		on_hud_refresh.call()

func _is_monster_attacker(entry: Dictionary) -> bool:
	var kind: = str(entry.get("attackerKind", "")).strip_edges().to_lower()
	if kind == "monster":
		return true
	return bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))

func _resolve_monster_attack_hit(entry: Dictionary) -> Dictionary:
	var kind: = str(entry.get("targetKind", "")).strip_edges().to_lower()
	if kind == "player":
		return {"type": "player", "index": -1}
	if kind == "pet":
		return {"type": "pet", "index": -1}
	if kind in ["coop_player", "coop_pet"]:
		return {"type": kind, "index": -1}
	var unit_name: = str(entry.get("target", "")).strip_edges()
	var hit: = _resolve_hit(unit_name, true)
	if str(hit.get("type", "")) == "monster":
		return {}
	return hit

func _apply_attacker_anim(entry: Dictionary, force_skip_lunge: bool = false, lunge_time_scale: float = 1.0) -> void :
	var attacker_unit: = _resolve_attacker(entry)
	if attacker_unit.is_empty() or battle_system == null:
		return
	if force_skip_lunge or _should_skip_lunge(entry):
		attacker_unit["skip_lunge"] = true
	if lunge_time_scale > 0.0 and lunge_time_scale != 1.0:
		attacker_unit["lunge_time_scale"] = lunge_time_scale
	var hit: Dictionary
	if _is_monster_attacker(entry):
		hit = _resolve_monster_attack_hit(entry)
	else:
		hit = _combo_living_hit_slot(entry, _resolve_unit_slot(entry, true))
	hit = _resolve_living_swing_target(entry, hit)
	if hit.is_empty() or not _ensure_swing_target_alive(entry, hit):
		return
	attacker_unit["target_type"] = str(hit.get("type", ""))
	attacker_unit["target_index"] = int(hit.get("index", -1))
	battle_system.apply_replay_unit_turn(attacker_unit)

func _norm_unit_name(unit_name: String) -> String:
	var s: = unit_name.strip_edges()
	if s.begins_with("敌方灵兽·"):
		s = s.substr("敌方灵兽·".length())
	elif s.begins_with("我方灵兽·"):
		s = s.substr("我方灵兽·".length())
	elif s.begins_with("我方·"):
		s = s.substr("我方·".length())
	return s.strip_edges()

func _find_monster_by_name(unit_name: String, prefer_pet: bool) -> Dictionary:
	var bs = battle_system
	var want: = _norm_unit_name(unit_name)
	if want.is_empty() or bs == null:
		return {}
	var pet_hit: = {}
	var player_hit: = {}
	var any_hit: = {}
	var first_alive: = {}
	var wild: = _is_wild_style()
	for i in range(bs.monsters.size()):
		var m = bs.monsters[i]
		if wild and not bs.is_monster_alive(m):
			continue
		var mname: = str(bs._get_monster_stat(m, "monster_name", bs._get_monster_stat(m, "name", ""))).strip_edges()
		if mname.is_empty():
			continue
		if mname != unit_name.strip_edges() and _norm_unit_name(mname) != want:
			continue
		var hit: = {"type": "monster", "index": i}
		if first_alive.is_empty():
			first_alive = hit
		any_hit = hit
		var role: = str(bs._get_monster_stat(m, "arena_role", "")).strip_edges()
		if role == "pet":
			pet_hit = hit
		elif role == "player":
			player_hit = hit
	if wild:
		if not first_alive.is_empty():
			return first_alive
		return any_hit
	if prefer_pet and not pet_hit.is_empty():
		return pet_hit
	if not prefer_pet and not player_hit.is_empty():
		return player_hit
	if not pet_hit.is_empty():
		return pet_hit
	if not player_hit.is_empty():
		return player_hit
	return any_hit

func _resolve_kind_index_slot(entry: Dictionary, as_target: bool) -> Dictionary:
	var kind: = str(entry.get("targetKind" if as_target else "attackerKind", "")).strip_edges().to_lower()
	var idx: = int(entry.get("targetIndex" if as_target else "attackerIndex", entry.get("target_index" if as_target else "attacker_index", -1)))
	var unit_name: = str(entry.get("target" if as_target else "attacker", "")).strip_edges()
	if kind == "player":
		return {"type": "player", "index": -1, "name": unit_name}
	if kind == "pet":
		return {"type": "pet", "index": -1, "name": unit_name}
	if kind == "coop_pet" or kind == "coop_player":
		if idx >= 0:
			return {"type": kind, "index": idx, "name": unit_name}
	if kind == "monster":
		var bs = battle_system
		if bs != null and idx >= 0 and idx < bs.monsters.size():
			return {"type": "monster", "index": idx, "name": unit_name}
	if not _is_wild_style():
		return {}
	if as_target and _is_monster_attacker(entry):
		return {}
	if as_target and not bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false))):
		var bs2 = battle_system
		if bs2 != null and idx >= 0 and idx < bs2.monsters.size():
			return {"type": "monster", "index": idx, "name": unit_name}
	if not as_target and bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false))):
		var bs3 = battle_system
		if bs3 != null and idx >= 0 and idx < bs3.monsters.size():
			return {"type": "monster", "index": idx, "name": unit_name}
	return {}

func _resolve_unit_slot(entry: Dictionary, as_target: bool) -> Dictionary:
	var id_key: = "targetId" if as_target else "attackerId"
	var slot: = _slot_from_id(str(entry.get(id_key, "")))
	if not slot.is_empty():
		if as_target and _is_monster_attacker(entry) and str(slot.get("type", "")) == "monster":
			slot = {}
		else:
			slot["name"] = str(entry.get("target" if as_target else "attacker", ""))
			return slot
	if _is_wild_style() and as_target:
		var locked: = _wild_locked_monster_slot(entry)
		if not locked.is_empty():
			locked["name"] = str(entry.get("target", ""))
			return locked
	var indexed: = _resolve_kind_index_slot(entry, as_target)
	if not indexed.is_empty():
		if as_target and _is_monster_attacker(entry) and str(indexed.get("type", "")) == "monster":
			pass
		else:
			return indexed
	var unit_name: = str(entry.get("target" if as_target else "attacker", "")).strip_edges()
	var is_enemy: = bool(entry.get("isEnemyAttack", false))
	if as_target:
		return _resolve_hit(unit_name, is_enemy)
	return _resolve_attacker_by_name(unit_name, is_enemy, bool(entry.get("isPetAttack", entry.get("is_pet_attack", false))))

func _resolve_attacker(entry: Dictionary) -> Dictionary:
	return _resolve_unit_slot(entry, false)

func _resolve_attacker_by_name(attacker_name: String, is_enemy: bool, prefer_pet: bool) -> Dictionary:
	if attacker_name.is_empty():
		return {}
	prefer_pet = prefer_pet or attacker_name.find("灵兽") >= 0
	if is_enemy:
		var hit: = _find_monster_by_name(attacker_name, prefer_pet)
		if hit.is_empty():
			return {}
		return {"type": str(hit.get("type", "")), "index": int(hit.get("index", -1)), "name": attacker_name}
	var coop: = _resolve_coop_by_name(attacker_name)
	if not coop.is_empty():
		return coop
	var bs = battle_system
	if bs and bs.player and bs._replay_ally_unit_name_matches(attacker_name, str(bs.player.player_name)):
		return {"type": "player", "index": -1, "name": attacker_name}
	if bs and bs.active_pet and bs._replay_ally_unit_name_matches(attacker_name, str(bs.active_pet.pet_name)):
		return {"type": "pet", "index": -1, "name": attacker_name}
	return {}

func _resolve_coop_by_name(unit_name: String) -> Dictionary:
	var bs = battle_system
	if bs == null:
		return {}
	for i in range(bs.coop_units.size()):
		var cu = bs.coop_units[i]
		if cu == null:
			continue
		var dn: = str(cu.display_name) if "display_name" in cu else ""
		if dn.is_empty() and cu.has_method("get"):
			dn = str(cu.get("display_name"))
		if bs._replay_ally_unit_name_matches(unit_name, dn):
			return {"type": str(cu.unit_type), "index": i, "name": unit_name}
	return {}

func _resolve_hit(unit_name: String, is_enemy_attack: bool) -> Dictionary:
	var bs = battle_system
	var name_str: = unit_name.strip_edges()
	if name_str.is_empty() or bs == null:
		return {}
	if is_enemy_attack:
		if bs.player and bs._replay_ally_unit_name_matches(name_str, str(bs.player.player_name)):
			return {"type": "player", "index": -1}
		if bs.active_pet and bs._replay_ally_unit_name_matches(name_str, str(bs.active_pet.pet_name)):
			return {"type": "pet", "index": -1}
		var coop: = _resolve_coop_by_name(name_str)
		if not coop.is_empty():
			return coop
	else:
		var prefer_pet: = name_str.find("灵兽") >= 0
		var mhit: = _find_monster_by_name(name_str, prefer_pet)
		if not mhit.is_empty():
			return mhit
		for i in range(bs.monsters.size()):
			if bs._replay_monster_name_matches_strict(name_str, bs.monsters[i]):
				return {"type": "monster", "index": i}
	return {}

func _resolve_hit_auto(unit_name: String, is_enemy_attack_hint: bool = false) -> Dictionary:
	return _resolve_hit(unit_name, is_enemy_attack_hint)

func _emit_acupoint_seal_visual(entry: Dictionary, sealed: bool) -> void :
	var bs = battle_system
	if bs == null or not bs.has_signal("acupoint_seal_changed"):
		return
	var slot: = _resolve_unit_slot(entry, true)
	if slot.is_empty():
		var named: = str(entry.get("target", entry.get("name", entry.get("targetName", "")))).strip_edges()
		if named.is_empty():
			return
		var entry_type: = str(entry.get("type", ""))
		var as_enemy: = bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))
		if entry_type == "enemy_dead":
			as_enemy = false
		elif entry_type in ["player_dead", "pet_dead"]:
			as_enemy = true
		slot = _resolve_hit(named, as_enemy)
	if slot.is_empty():
		return
	bs.acupoint_seal_changed.emit(str(slot.get("type", "")), int(slot.get("index", -1)), sealed)

func format_message(entry: Dictionary) -> String:
	if _is_wild_style():
		return _format_message_wild(entry)
	var entry_type: = str(entry.get("type", ""))
	var preset: = str(entry.get("message", "")).strip_edges()
	if preset.is_empty():
		preset = str(entry.get("text", "")).strip_edges()
	var crit_mark: = "（暴击）" if bool(entry.get("isCritical", entry.get("is_critical", false))) else ""
	match entry_type:
		"unit_info":
			var uname: = str(entry.get("name", entry.get("nickname", "单位")))
			var atk: = int(entry.get("attack", 0))
			var df: = int(entry.get("defense", 0))
			var agi: = int(entry.get("agility", 0))
			var hp: = int(entry.get("maxHp", entry.get("hp", 0)))
			if atk <= 0 and df <= 0 and agi <= 0 and hp <= 0:
				return "[color=#bfbfcc]参战 %s  属性未知[/color]" % uname
			var side: = str(entry.get("side", ""))
			var tag: = "遭遇" if ( not viewer_side.is_empty() and side != viewer_side) else "参战"
			return "[color=#c4b5fd]%s %s  └ 属性 攻:%d 防:%d 敏:%d 血:%d[/color]" % [tag, uname, atk, df, agi, hp]
		"round":
			return "[color=#88ccff]—— 第 %d 回合 ——[/color]" % int(entry.get("round", 0))
		"combo_trigger":
			if preset.is_empty():
				preset = "★ 连击触发! 你和宠物的敏捷都高于所有敌人! ★"
			return "[color=#ffd43b]%s[/color]" % preset
		"combo_attack":
			return "[color=#ffd43b]  ⚡ 【%s】连击！[/color]" % str(entry.get("attacker", "?"))
		"joint_attack":
			return "[color=#4dd0e1]  🔗 ★ 合击触发！【%s】和【%s】联手攻击【%s】！[/color]" % [
				str(entry.get("player", "你")), 
				str(entry.get("pet", "灵兽")), 
				str(entry.get("target", "敌人")), 
			]
		"kuihua_point_success":
			return "[color=#e6f35a]  ✨ 【%s】对【%s】施展点穴成功！[/color]" % [str(entry.get("attacker", "我方")), str(entry.get("target", "敌人"))]
		"kuihua_point_fail":
			return "[color=#bfbfcc]  ⚪ 【%s】对【%s】施展点穴失败。[/color]" % [str(entry.get("attacker", "我方")), str(entry.get("target", "敌人"))]
		"acupoint_skip":
			return "[color=#ffcc66]  ⛔ 【%s】被点穴封脉，本回合无法行动（剩余%d回合）[/color]" % [str(entry.get("target", "目标")), int(entry.get("remain", 0))]
		"miss", "dodge":
			var color: = "#ff9999" if bool(entry.get("isEnemyAttack", false)) else "#66ff66"
			var action: = "被闪避" if entry_type == "dodge" else "未命中"
			if _is_triple_shot_swing(entry):
				var arrow_n: = int(entry.get("hitIndex", entry.get("hit_index", 0)))
				if arrow_n <= 0:
					arrow_n = 1
				return "[color=%s]  💨 【三锋齐下】第 %d 箭【%s】攻击【%s】，%s！[/color]" % [
					color, arrow_n, str(entry.get("attacker", "?")), str(entry.get("target", "?")), action
				]
			return "[color=%s]  💨 【%s】攻击【%s】，%s！[/color]" % [color, str(entry.get("attacker", "?")), str(entry.get("target", "?")), action]
		"attack", "triple_shot_hit", "kuihua_hit":
			var attacker: = str(entry.get("attacker", "?"))
			var target: = str(entry.get("target", "?"))
			var damage: = int(entry.get("damage", 0))
			var target_hp: = int(entry.get("targetHp", entry.get("target_hp", 0)))
			var target_max_hp: = int(entry.get("targetMaxHp", entry.get("target_max_hp", 100)))
			var hp_percent: = float(target_hp) / float(maxi(target_max_hp, 1)) * 100.0
			var element_msg: = str(entry.get("elementMsg", entry.get("element_msg", "")))
			var is_enemy2: = bool(entry.get("isEnemyAttack", false))
			var color2: = "#ff9999" if is_enemy2 else "#66ff66"
			var prefix: = "  "
			if entry_type == "triple_shot_hit":
				prefix = "  🏹 "
			elif entry_type == "kuihua_hit":
				prefix = "  【葵花点穴】"
			var crit_text: = " %s" % crit_mark if not crit_mark.is_empty() else ""
			var combo_text: = " 连击！" if bool(entry.get("isCombo", entry.get("is_combo", false))) else ""
			var joint_text: = " 合击！" if bool(entry.get("isJointAttack", entry.get("is_joint_attack", false))) else ""
			var base_text: = "%s【%s】攻击【%s】，造成 %d 伤害！%s%s%s(HP: %d/%d %.1f%%)" % [
				prefix, attacker, target, damage, combo_text, joint_text, crit_text, target_hp, target_max_hp, hp_percent
			]
			if not element_msg.is_empty():
				base_text += " 【%s】" % element_msg
			return "[color=%s]%s[/color]" % [color2, base_text]
		"skill_splash":
			var sthp: = int(entry.get("targetHp", 0))
			var stmh: = int(entry.get("targetMaxHp", 1))
			return "[color=#8ce0ff]  💧 【溅射】【%s】波及【%s】，造成 %d 伤害%s（目标剩余 HP %d/%d，约 %.0f%%）[/color]" % [
				str(entry.get("attacker", "?")), str(entry.get("target", "?")), int(entry.get("damage", 0)), 
				(" %s" % crit_mark) if not crit_mark.is_empty() else "", sthp, stmh, 
				float(sthp) / float(maxi(stmh, 1)) * 100.0
			]
		"skill_double_shot":
			return "[color=#ffd173]  🎯 【连射】第 %d 段：【%s】命中【%s】，%d 伤害%s[/color]" % [
				int(entry.get("hitIndex", 0)), str(entry.get("attacker", "?")), str(entry.get("target", "?")), 
				int(entry.get("damage", 0)), (" %s" % crit_mark) if not crit_mark.is_empty() else ""
			]
		"skill_divine_protect":
			return "[color=#bfff8c]  ✨ 【神佑】【%s】触发，恢复生命约 %d[/color]" % [str(entry.get("target", "灵兽")), int(entry.get("hpRestored", 0))]
		"skill_self_heal":
			return "[color=#69db7c]  ✦ 【自愈】【%s】回复 %d 点生命[/color]" % [
				str(entry.get("attacker", entry.get("target", "灵兽"))), 
				int(entry.get("hpRestored", entry.get("heal", 0)))
			]
		"skill_taunt":
			return "[color=yellow]  【嘲讽】【%s】吸引敌方攻击[/color]" % str(entry.get("attacker", entry.get("target", "灵兽")))
		"skill_loyal":
			return "[color=yellow]  【忠心】【%s】替主人承受攻击[/color]" % str(entry.get("attacker", entry.get("target", "灵兽")))
		"skill_life_steal":
			return _format_life_steal_line(entry)
		"skill_counter_attack":
			return "[color=#ffa673]  ⚡ 【反击】【%s】反击【%s】，%d 伤害%s[/color]" % [
				str(entry.get("attacker", "?")), str(entry.get("target", "?")), int(entry.get("damage", 0)), 
				(" %s" % crit_mark) if not crit_mark.is_empty() else ""
			]
		"skill_chase":
			return "[color=#ffa673]  ⚡ 【追击】【%s】追击【%s】，%d 伤害%s[/color]" % [
				str(entry.get("attacker", "?")), str(entry.get("target", "?")), int(entry.get("damage", 0)), 
				(" %s" % crit_mark) if not crit_mark.is_empty() else ""
			]
		"skill_armor_pierce":
			return "[color=#ffd173]  ⚔ 【破甲】【%s】本下忽视对方一半防御[/color]" % str(entry.get("attacker", "灵兽"))
		"skill_guard":
			return "[color=#74c0fc]  🛡 【格挡】【%s】减免部分伤害[/color]" % str(entry.get("target", "灵兽"))
		"enemy_dead", "pet_dead", "player_dead":
			return "[color=#ffd43b]  💀 【%s】被击败！[/color]" % str(entry.get("name", "单位"))
		"start", "info":
			return preset
		"victory":
			return preset if not preset.is_empty() else "战斗胜利"
		"defeat":
			return preset if not preset.is_empty() else "战斗失败"
		_:
			return preset

func _wild_player_name() -> String:
	if mine_names.size() > 0:
		var n: = str(mine_names[0]).strip_edges()
		if not n.is_empty():
			return n
	return "你"

func _wild_pet_name() -> String:
	if mine_names.size() > 1:
		var n: = str(mine_names[1]).strip_edges()
		if not n.is_empty():
			return n
	return "灵兽"

func _format_life_steal_line(entry: Dictionary) -> String:
	var who: = str(entry.get("attacker", entry.get("target", "修士")))
	var amt: = int(entry.get("hpRestored", entry.get("hp_restored", 0)))
	var skill_name: = str(entry.get("skillName", entry.get("skill_name", "")))
	if skill_name == "以墨养墨":
		return "[color=#69db7c]%s【以墨养墨】吸血回复 %d 点生命[/color]" % [who, amt]
	return "[color=#69db7c]✦吸血触发![/color] %s 回复 %d 点生命" % [who, amt]

func _wild_crit_suffix(entry: Dictionary) -> String:
	if bool(entry.get("isCritical", entry.get("is_critical", false))):
		return " [color=#ff922b]（暴击）[/color]"
	return ""

func _wild_element_suffix(entry: Dictionary) -> String:
	var element_msg: = str(entry.get("elementMsg", entry.get("element_msg", ""))).strip_edges()
	if element_msg.is_empty():
		return ""
	return " %s" % element_msg

func _format_wild_attack_line(entry: Dictionary) -> String:
	var attacker: = str(entry.get("attacker", "?"))
	var target: = str(entry.get("target", "?"))
	var damage: = int(entry.get("damage", 0))
	var entry_type: = str(entry.get("type", ""))
	var is_enemy: = bool(entry.get("isEnemyAttack", entry.get("is_enemy_attack", false)))
	var is_pet: = bool(entry.get("isPetAttack", entry.get("is_pet_attack", false)))
	var triple: = _is_triple_shot_swing(entry) or entry_type == "triple_shot_hit"
	var kuihua: = _is_kuihua_swing(entry) or entry_type == "kuihua_hit"
	var hit_index: = int(entry.get("hitIndex", entry.get("hit_index", 0)))
	var show_triple: = triple and not kuihua and (entry_type == "triple_shot_hit" or hit_index > 1)
	var msg: = ""
	if is_enemy:
		msg = "[color=orange]%s[/color] 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [attacker, target, damage]
	elif kuihua:
		msg = "%s【葵花点穴】攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [attacker, target, damage]
	elif show_triple:
		msg = "%s【三锋齐下】攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [attacker, target, damage]
	elif is_pet:
		msg = "[color=green]%s[/color] 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [attacker, target, damage]
	else:
		msg = "%s 攻击 %s, 造成 [color=red]%d[/color] 点伤害" % [attacker, target, damage]
	msg += _wild_crit_suffix(entry)
	msg += _wild_element_suffix(entry)
	if bool(entry.get("defendCut", entry.get("defend_cut", false))):
		msg += " [color=#74c0fc]（防御减伤）[/color]"
	return msg

func _format_message_wild(entry: Dictionary) -> String:
	var entry_type: = str(entry.get("type", ""))
	var preset: = str(entry.get("message", "")).strip_edges()
	if preset.is_empty():
		preset = str(entry.get("text", "")).strip_edges()
	match entry_type:
		"unit_info":
			return ""
		"round":
			return "--- 第 %d 回合 ---" % int(entry.get("round", 0))
		"info", "start":
			if preset.is_empty():
				return ""
			if preset == "战斗开始" or preset == "对决开始":
				return ""
			return "[color=#8898aa]%s[/color]" % preset
		"combo_trigger":
			if preset.is_empty():
				preset = "★ 连击触发! 你和宠物的敏捷都高于所有敌人! ★"
			return "[color=#69db7c]%s[/color]" % preset
		"combo_attack":
			var pet_n: = str(entry.get("attacker", _wild_pet_name()))
			return "[color=#69db7c]%s 连击追击 %s![/color]" % [_wild_player_name(), pet_n]
		"joint_attack":
			var pn: = str(entry.get("player", entry.get("attacker", _wild_player_name())))
			var petn: = str(entry.get("pet", _wild_pet_name()))
			var tgt: = str(entry.get("target", "敌人"))
			return "[color=#69db7c]★ 合击触发! %s 和 %s 联手攻击 %s! ★[/color]" % [pn, petn, tgt]
		"miss", "dodge":
			var attacker: = str(entry.get("attacker", "?"))
			var target: = str(entry.get("target", "?"))
			if bool(entry.get("isEnemyAttack", false)):
				return "[color=orange]%s[/color] 攻击 %s, [color=cyan]被闪避了![/color]" % [attacker, target]
			return "%s 攻击 %s, [color=gray]但是未命中![/color]" % [attacker, target]
		"attack", "triple_shot_hit", "kuihua_hit":
			return _format_wild_attack_line(entry)
		"skill_splash":
			return "[color=yellow]✦溅射触发![/color] %s 对 %s 造成 [color=red]%d[/color] 点溅射伤害%s%s" % [
				str(entry.get("attacker", "?")), str(entry.get("target", "?")), int(entry.get("damage", 0)), 
				_wild_crit_suffix(entry), _wild_element_suffix(entry)
			]
		"skill_double_shot":
			return "[color=green]%s[/color] 攻击 %s, 造成 [color=red]%d[/color] 点伤害%s%s" % [
				str(entry.get("attacker", "?")), str(entry.get("target", "?")), int(entry.get("damage", 0)), 
				_wild_crit_suffix(entry), _wild_element_suffix(entry)
			]
		"skill_divine_protect":
			return "[color=#bfff8c]✨ 【神佑】%s 触发，恢复生命[/color]" % str(entry.get("target", "灵兽"))
		"skill_self_heal":
			return "[color=#69db7c]✦自愈触发![/color] %s 回复 %d 点生命" % [
				str(entry.get("attacker", entry.get("target", "灵兽"))), 
				int(entry.get("hpRestored", entry.get("heal", 0)))
			]
		"skill_taunt":
			return "[color=yellow]%s 触发【嘲讽】，吸引了怪物注意![/color]" % str(entry.get("attacker", entry.get("target", "灵兽")))
		"skill_loyal":
			return "[color=yellow]%s 触发【忠心】，替主人承受攻击![/color]" % str(entry.get("attacker", entry.get("target", "灵兽")))
		"skill_counter_attack":
			return "[color=yellow]%s[/color] 触发【反击】，对 %s 造成 [color=red]%d[/color] 点伤害!%s%s" % [
				str(entry.get("attacker", "?")), str(entry.get("target", "?")), int(entry.get("damage", 0)), 
				_wild_crit_suffix(entry), _wild_element_suffix(entry)
			]
		"skill_chase":
			return "[color=yellow]✦追击触发![/color] %s 对 %s 造成 [color=red]%d[/color] 点追击伤害%s%s" % [
				str(entry.get("attacker", "?")), str(entry.get("target", "?")), int(entry.get("damage", 0)), 
				_wild_crit_suffix(entry), _wild_element_suffix(entry)
			]
		"skill_armor_pierce":
			return "[color=yellow]%s[/color] 本下忽视对方一半防御" % str(entry.get("attacker", "灵兽"))
		"skill_guard":
			return "[color=#74c0fc]【格挡】%s 减免部分伤害[/color]" % str(entry.get("target", "灵兽"))
		"enemy_dead", "pet_dead":
			return "[color=#ffd43b]%s 被击败了![/color]" % str(entry.get("name", entry.get("target", "单位")))
		"player_dead":
			return "[color=red]%s 被击败了![/color]" % str(entry.get("name", entry.get("target", "修士")))
		"victory":
			return "=== [color=yellow]★ 战斗胜利! ★[/color] ==="
		"defeat":
			return "=== [color=red]战斗失败...[/color] ==="
		"start", "info":
			return preset
		"kuihua_point_success":
			return "[color=#e6f35a]✨ %s 施展【葵花点穴】得手！%s 接下来两回合无法行动[/color]" % [str(entry.get("attacker", "我方")), str(entry.get("target", "敌人"))]
		"kuihua_point_fail":
			return "[color=#bfbfcc]%s 施展【葵花点穴】未能封住 %s 经脉[/color]" % [str(entry.get("attacker", "我方")), str(entry.get("target", "敌人"))]
		"skill_life_steal":
			return _format_life_steal_line(entry)
		"acupoint_skip":
			return "[color=#ffcc66]%s 被点穴封脉，本回合无法行动[/color]" % str(entry.get("target", "目标"))
		"stance_skip":
			if preset.is_empty():
				return ""
			return "[color=#74c0fc]%s[/color]" % preset
		_:
			return preset
