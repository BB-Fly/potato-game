class_name RouteMapCombatNode
extends Marker2D

@export var node_id = ""
@export var reward_table_id = "reward.combat.default"


func to_combat_node_data() -> Dictionary:
	var data = {
		"id": node_id,
		"type": "combat",
		"position": {"x": position.x, "y": position.y},
	}
	if not reward_table_id.is_empty():
		data["reward_table_id"] = reward_table_id
	return data
