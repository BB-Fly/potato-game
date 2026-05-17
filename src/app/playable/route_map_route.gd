class_name RouteMapRoute
extends Control

@export var route_id = "left"
@export var display_lane = "left"


func to_route_data() -> Dictionary:
	var nodes: Array = []
	var rewards_root = get_node_or_null("RewardNodes")
	if rewards_root != null:
		for child in rewards_root.get_children():
			if child.has_method("to_reward_node_data"):
				nodes.append(child.to_reward_node_data())
	return {
		"id": route_id,
		"display_lane": display_lane,
		"nodes": nodes,
	}
