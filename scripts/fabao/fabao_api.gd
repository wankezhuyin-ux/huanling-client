extends RefCounted
class_name FabaoApi



static func set_difficulty(tier_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_set_difficulty(tier_id)


static func synthesize(tier_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_synthesize(tier_id)


static func equip(fabao_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_equip(fabao_id)


static func unequip() -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_unequip()


static func store_warehouse(fabao_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_store_warehouse(fabao_id)


static func retrieve_warehouse(fabao_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_retrieve_warehouse(fabao_id)


static func discard(fabao_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_discard(fabao_id)


static func dismantle(fabao_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_dismantle(fabao_id)


static func reroll(fabao_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_reroll(fabao_id)


static func reroll_confirm(token: String, apply: bool) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_reroll_confirm(token, apply)


static func reset_affixes(fabao_id: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_reset(fabao_id)


static func reset_confirm(token: String, apply: bool) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_reset_confirm(token, apply)


static func lock_affix(fabao_id: String, group: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_lock_affix(fabao_id, group)


static func unlock_affix(fabao_id: String, group: String) -> void :
	if GameManager.instance and GameManager.instance.fabao_manager:
		GameManager.instance.fabao_manager.request_unlock_affix(fabao_id, group)
