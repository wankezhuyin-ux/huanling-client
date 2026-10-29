extends Node





func _ready() -> void :
	var bridge_path: = "res://addons/godot_mcp/game_bridge/mcp_game_bridge.gd"
	if not ResourceLoader.exists(bridge_path):
		return
	var bridge_script: = load(bridge_path) as Script
	if bridge_script == null:
		return
	var impl: = Node.new()
	impl.name = "MCPGameBridgeImpl"
	impl.set_script(bridge_script)
	add_child(impl)
