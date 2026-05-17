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
	var content_id = String(entry.get("id", ""))
	match content_id:
		"monster.metamorph.sprouting_potato":
			return "res://assets/art/source/sprouting_potato/sprouting_potato-1.png"
		"monster.metamorph.mushroom_spore":
			return "res://assets/art/source/enemy_pack_01/mushroom_spore/mushroom_spore-1.png"
		"monster.metamorph.bomb_fruitling":
			return "res://assets/art/source/enemy_pack_01/bomb_fruitling/bomb_fruitling-1.png"
	var refs = entry.get("asset_refs", {})
	if typeof(refs) == TYPE_DICTIONARY and refs.has("sprite"):
		return asset_catalog.resolve_asset_path(String(refs["sprite"]), "res://icon.svg")
	return "res://icon.svg"


static func enemy_frame_paths(content_id: String) -> Array:
	match content_id:
		"monster.metamorph.sprouting_potato":
			return [
				"res://assets/art/source/sprouting_potato/sprouting_potato-1.png",
				"res://assets/art/source/sprouting_potato/sprouting_potato-2.png",
				"res://assets/art/source/sprouting_potato/sprouting_potato-3.png",
				"res://assets/art/source/sprouting_potato/sprouting_potato-4.png",
			]
		"monster.metamorph.mushroom_spore":
			return [
				"res://assets/art/source/enemy_pack_01/mushroom_spore/mushroom_spore-1.png",
				"res://assets/art/source/enemy_pack_01/mushroom_spore/mushroom_spore-2.png",
				"res://assets/art/source/enemy_pack_01/mushroom_spore/mushroom_spore-3.png",
				"res://assets/art/source/enemy_pack_01/mushroom_spore/mushroom_spore-4.png",
			]
		"monster.metamorph.bomb_fruitling":
			return [
				"res://assets/art/source/enemy_pack_01/bomb_fruitling/bomb_fruitling-1.png",
				"res://assets/art/source/enemy_pack_01/bomb_fruitling/bomb_fruitling-2.png",
				"res://assets/art/source/enemy_pack_01/bomb_fruitling/bomb_fruitling-3.png",
				"res://assets/art/source/enemy_pack_01/bomb_fruitling/bomb_fruitling-4.png",
			]
		"boss.demo_pollution_source":
			return [
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-1.png",
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-2.png",
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-3.png",
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-4.png",
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-5.png",
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-6.png",
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-7.png",
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-8.png",
				"res://assets/art/source/boss_pollution_source/boss_pollution_source-9.png",
			]
	return []


static func rarity_color(entry: Dictionary) -> Color:
	match String(entry.get("rarity", "common")):
		"legendary":
			return Color(0.96, 0.62, 0.2)
		"rare":
			return Color(0.38, 0.6, 1.0)
		_:
			return Color(0.68, 0.82, 0.58)
