extends Node
class_name AssetManager

static var _instance: AssetManager = null
static var _initialized: bool = false

var icons: Dictionary = {}
var portraits: Dictionary = {}
var pets: Dictionary = {}
var items: Dictionary = {}
var buttons: Dictionary = {}

const ASSETS_PATH = "res://assets/"
const ICONS_PATH = ASSETS_PATH + "icons/"
const PORTRAITS_PATH = ASSETS_PATH + "portraits/"
const PETS_PATH = ASSETS_PATH + "pets/"
const ITEMS_PATH = ASSETS_PATH + "items/"
const BUTTONS_PATH = ASSETS_PATH + "buttons/"
const MANIFEST_PATH = "res://assets/asset_manifest.json"

func _init():
	_instance = self

static func get_instance() -> AssetManager:
	if _instance == null:
		_instance = AssetManager.new()
	if not _initialized:
		_instance.load_all_assets()
		_initialized = true
	return _instance

func load_all_assets():
	print("[AssetManager] 开始加载资源...")

	var manifest = _load_manifest()
	if manifest.is_empty():
		print("[AssetManager] 未找到资源清单，尝试直接扫描目录...")
		_load_directory(ICONS_PATH, icons, "icons")
		_load_directory(PORTRAITS_PATH, portraits, "portraits")
		_load_directory(PETS_PATH, pets, "pets")
		_load_directory(ITEMS_PATH, items, "items")
		_load_directory(BUTTONS_PATH, buttons, "buttons")
	else:
		_load_from_manifest(manifest, "icons", icons)
		_load_from_manifest(manifest, "portraits", portraits)
		_load_from_manifest(manifest, "pets", pets)
		_load_from_manifest(manifest, "items", items)
		_load_from_manifest(manifest, "buttons", buttons)

	print("[AssetManager] 资源加载完成: portraits=%d, pets=%d" % [portraits.size(), pets.size()])

func _load_manifest() -> Dictionary:
	if not ResourceLoader.exists(MANIFEST_PATH):
		print("[AssetManager] 资源清单文件不存在: ", MANIFEST_PATH)
		return {}

	var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		print("[AssetManager] 无法打开资源清单文件")
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		print("[AssetManager] 资源清单JSON解析失败: ", json.get_error_message())
		return {}

	return json.data

func _load_from_manifest(manifest: Dictionary, category: String, target_dict: Dictionary):
	var list = manifest.get(category, [])
	var count = 0
	for item in list:
		var asset_name = item.get("name", "").to_lower()
		var asset_path = item.get("path", "")
		if asset_name != "" and asset_path != "":
			if ResourceLoader.exists(asset_path):
				var texture = load(asset_path)
				if texture:
					target_dict[asset_name] = texture
					count += 1
	if count > 0:
		print("[AssetManager] 从清单加载 %s: %d 个资源" % [category, count])

func _load_directory(path: String, target_dict: Dictionary, category: String):
	var dir = DirAccess.open(path)
	if dir == null:
		print("[AssetManager] 无法打开目录: ", path)
		return

	var count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			if file_name.ends_with(".png") or file_name.ends_with(".jpg") or file_name.ends_with(".webp"):
				var asset_name = file_name.get_basename().to_lower()
				var full_path = path + file_name
				if ResourceLoader.exists(full_path):
					var texture = load(full_path)
					if texture:
						target_dict[asset_name] = texture
						count += 1
		file_name = dir.get_next()
	dir.list_dir_end()
	print("[AssetManager] 从 %s 加载了 %d 个资源" % [category, count])

func get_icon(name: String) -> Texture2D:
	return icons.get(name.to_lower(), null)

func get_portrait(name: String) -> Texture2D:
	return portraits.get(name.to_lower(), null)


func get_monster(name: String) -> Texture2D:
	return get_pet(name)

func get_pet(name: String) -> Texture2D:
	return pets.get(name.to_lower(), null)

func get_item(name: String) -> Texture2D:
	return items.get(name.to_lower(), null)

func get_button(name: String) -> Texture2D:
	return buttons.get(name.to_lower(), null)

func get_pet_texture(pet_id: String) -> Texture2D:
	var id = pet_id.to_lower()

	if pets.has(id):
		return pets[id]

	var texture = _try_load_texture(PETS_PATH + id + ".png")
	if texture:
		pets[id] = texture
		return texture

	return null


func get_monster_texture(monster_id: String) -> Texture2D:
	return get_pet_texture(monster_id)

func _try_load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null

func reload_assets():
	icons.clear()
	portraits.clear()
	pets.clear()
	items.clear()
	buttons.clear()
	_initialized = false
	load_all_assets()
	_initialized = true

static func get_color_rect_with_texture(texture: Texture2D, size: Vector2 = Vector2(50, 50)) -> Control:
	if texture:
		var rect = TextureRect.new()
		rect.texture = texture
		rect.custom_minimum_size = size
		rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return rect
	else:
		var rect = ColorRect.new()
		rect.custom_minimum_size = size
		rect.color = Color(0.5, 0.5, 0.5)
		return rect
