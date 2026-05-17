class_name RouteMapRewardNode
extends Marker2D

@export_enum("free_weapon", "random_item", "coin", "weapon_shop", "magic_shop", "item_shop", "weapon_master", "magic_master", "encounter") var node_type = "coin"
@export var reward_table_id = ""
@export var shop_id = ""
@export var encounter_pool_id = ""
@export var gold = 0
@export var side = ""


func to_reward_node_data() -> Dictionary:
	var data = {
		"type": node_type,
		"side": side,
		"position": {"x": position.x, "y": position.y},
	}
	if not reward_table_id.is_empty():
		data["reward_table_id"] = reward_table_id
	if not shop_id.is_empty():
		data["shop_id"] = shop_id
	if not encounter_pool_id.is_empty():
		data["encounter_pool_id"] = encounter_pool_id
	if gold > 0:
		data["gold"] = gold
	return data
