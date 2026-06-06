class_name PlayableContentPresenter
extends RefCounted


static func content_name(content_id: String) -> String:
	var known = {
		"character.potato_hero": "Potato Hero",
		"weapon.metamorph.fries": "Fries Staff",
		"magic.metamorph.comprehensive_development": "Comprehensive Development",
		"item.metamorph.potato_enhancement": "Potato Enhancement",
		"monster.metamorph.sprouting_potato": "Sprouting Potato",
		"monster.metamorph.mushroom_spore": "Mushroom Spore",
		"monster.metamorph.bomb_fruitling": "Bomb Fruitling",
		"boss.demo_pollution_source": "Pollution Source",
	}
	if known.has(content_id):
		return known[content_id]
	var parts = content_id.split(".")
	return String(parts[parts.size() - 1]).capitalize() if parts.size() > 0 else content_id


static func node_label(node_data: Dictionary) -> String:
	var node_type = String(node_data.get("type", ""))
	if node_type == "coin":
		return "Gold +%d" % int(node_data.get("gold", 0))
	return node_type_name(node_type)


static func node_type_name(node_type: String) -> String:
	var names = {
		"free_weapon": "Free Weapon",
		"random_item": "Random Item",
		"coin": "Gold",
		"weapon_shop": "Weapon Shop",
		"magic_shop": "Magic Shop",
		"item_shop": "Item Shop",
		"weapon_master": "Weapon Master",
		"magic_master": "Magic Master",
		"encounter": "Encounter",
		"combat": "Combat",
	}
	return names.get(node_type, node_type)


static func node_icon_path(asset_catalog, node_type: String) -> String:
	return asset_catalog.resolve_asset_path("map.node.%s.icon" % node_type, "res://icon.svg")


static func content_icon_path(asset_catalog, entry: Dictionary) -> String:
	var refs = entry.get("asset_refs", {})
	if typeof(refs) == TYPE_DICTIONARY:
		if refs.has("icon"):
			return asset_catalog.resolve_asset_path(String(refs["icon"]), "res://icon.svg")
		if refs.has("sprite"):
			return asset_catalog.resolve_asset_path(String(refs["sprite"]), "res://icon.svg")
	return "res://icon.svg"


static func content_sprite_path(asset_catalog, entry: Dictionary) -> String:
	var refs = entry.get("asset_refs", {})
	if typeof(refs) == TYPE_DICTIONARY and refs.has("sprite"):
		return asset_catalog.resolve_asset_path(String(refs["sprite"]), "res://icon.svg")
	return "res://icon.svg"


static func sheet_frame_ref(path: String, columns: int, rows: int, frame_index: int) -> Dictionary:
	return {
		"path": path,
		"columns": columns,
		"rows": rows,
		"frame_index": frame_index,
	}


static func sheet_frame_refs(path: String, columns: int, rows: int, frame_count: int, start_index: int = 0) -> Array:
	var frames: Array = []
	for i in range(frame_count):
		frames.append(sheet_frame_ref(path, columns, rows, start_index + i))
	return frames


static func content_frame_refs(asset_catalog, entry: Dictionary) -> Array:
	var content_id = String(entry.get("id", ""))
	var sprite_path = content_sprite_path(asset_catalog, entry)
	match content_id:
		"monster.metamorph.sprouting_potato":
			return sheet_frame_refs(sprite_path, 2, 2, 4)
		"monster.metamorph.mushroom_spore":
			return sheet_frame_refs(sprite_path, 2, 2, 4)
		"monster.metamorph.bomb_fruitling":
			return sheet_frame_refs(sprite_path, 2, 2, 4)
		"boss.demo_pollution_source":
			return sheet_frame_refs(sprite_path, 3, 3, 9)
	return []


static func rarity_color(entry: Dictionary) -> Color:
	match String(entry.get("rarity", "common")):
		"legendary":
			return Color(0.96, 0.62, 0.2)
		"rare":
			return Color(0.38, 0.6, 1.0)
		_:
			return Color(0.68, 0.82, 0.58)
