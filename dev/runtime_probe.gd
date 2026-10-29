extends SceneTree
func _initialize() -> void:
	print("LOCAL_RUNTIME_PROBE_OK ", Engine.get_version_info().string)
	quit()
