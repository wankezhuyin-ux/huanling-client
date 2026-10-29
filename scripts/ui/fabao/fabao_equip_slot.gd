extends RefCounted
class_name FabaoEquipSlot

const FabaoConfigRef = preload("res://scripts/fabao/fabao_config.gd")
const FabaoIconsRef = preload("res://scripts/fabao/fabao_icons.gd")
const InventoryGridCell = preload("res://scripts/ui/inventory_grid_cell.gd")
const TouchScrollUtils = preload("res://scripts/ui/touch_scroll_utils.gd")
const FabaoApiRef = preload("res://scripts/fabao/fabao_api.gd")
const FabaoBagPanel = preload("res://scripts/ui/fabao/fabao_bag_panel.gd")


static func make_cell(side: int) -> Control:
	var inst = null
	if GameManager.instance and GameManager.instance.fabao_manager:
		inst = GameManager.instance.fabao_manager.equipped_fabao
	if inst == null or not (inst is Dictionary):
		var empty: = InventoryGridCell.make_empty(side, "法宝", InventoryGridCell.EQUIP_SLOT_BORDER)
		_bind_empty_hint(empty)
		return empty
	var cap: Dictionary = (inst as Dictionary).duplicate(true)
	var display_name: = str(cap.get("name", FabaoConfigRef.fabao_item_name(str(cap.get("tier", "normal")))))
	var tex: = FabaoIconsRef.tex_for_tier(str(cap.get("tier", "normal")), false)
	return InventoryGridCell.make_filled(
		side, tex, display_name, 0, InventoryGridCell.EQUIP_SLOT_BORDER, 
		func(): FabaoBagPanel.show_detail(cap, true), 
		Color.WHITE, false, "", true, "", ""
	)


static func _bind_empty_hint(cell: Control) -> void :
	TouchScrollUtils.bind_tap(cell, func():
		var gm = GameManager.instance
		if gm == null or not gm.has_method("_find_main_ui_node"):
			return
		var ui = gm._find_main_ui_node()
		if ui != null and ui.has_method("_show_game_alert"):
			ui._show_game_alert("请在下方人物装备格子中选择法宝穿戴", "提示")
	)
