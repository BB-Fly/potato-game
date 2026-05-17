class_name PlayableMapController
extends RefCounted

var active_route: Dictionary = {}
var selected_route_id = ""
var claimed_route_nodes: Dictionary = {}


func reset_route() -> void:
	active_route = {}
	selected_route_id = ""
	claimed_route_nodes.clear()


func choose_route(map_flow, route_id: String) -> bool:
	if not selected_route_id.is_empty() and not claimed_route_nodes.is_empty():
		return false
	var route = map_flow.choose_route(route_id)
	if route.is_empty():
		return false
	active_route = route
	selected_route_id = route_id
	claimed_route_nodes.clear()
	return true


func choose_route_data(map_flow, route: Dictionary) -> bool:
	if not selected_route_id.is_empty() and not claimed_route_nodes.is_empty():
		return false
	if route.is_empty():
		return false
	var route_id = String(route.get("id", ""))
	if route_id.is_empty():
		return false
	if map_flow != null and map_flow.has_method("record_route_choice"):
		map_flow.record_route_choice(route_id)
	active_route = route
	selected_route_id = route_id
	claimed_route_nodes.clear()
	return true


func is_route_selected(route_id: String) -> bool:
	return route_id == selected_route_id


func is_route_locked(route_id: String) -> bool:
	return not selected_route_id.is_empty() and route_id != selected_route_id


func is_route_preview(route: Dictionary) -> bool:
	return String(route.get("id", "")) != selected_route_id


func has_claimed_nodes() -> bool:
	return not claimed_route_nodes.is_empty()


func has_selected_route() -> bool:
	return not selected_route_id.is_empty()


func is_node_claimed(node_index: int) -> bool:
	return bool(claimed_route_nodes.get(node_index, false))


func can_click_reward_node(node_index: int) -> bool:
	if selected_route_id.is_empty() or claimed_route_nodes.has(node_index):
		return false
	var nodes: Array = active_route.get("nodes", [])
	return node_index >= 0 and node_index < nodes.size()


func get_active_node(node_index: int) -> Dictionary:
	var nodes: Array = active_route.get("nodes", [])
	if node_index < 0 or node_index >= nodes.size():
		return {}
	return nodes[node_index]


func claim_node(node_index: int) -> void:
	claimed_route_nodes[node_index] = true


func rewards_complete() -> bool:
	if active_route.is_empty():
		return false
	return claimed_route_nodes.size() >= active_route.get("nodes", []).size()


func combat_locked() -> bool:
	return selected_route_id.is_empty() or not rewards_complete()
