extends RefCounted



const LegacyCraftingHall = preload("res://ui/city/crafting_hall.gd")

static func create_fullscreen(game_manager) -> Control:
	return LegacyCraftingHall.create_fullscreen(game_manager)
