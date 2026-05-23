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


func selection_mode_for_area(area: Dictionary) -> String:
	return String(area.get("selection_mode", "choose_one_route"))


func is_collect_all_area(area: Dictionary) -> bool:
	return selection_mode_for_area(area) == "collect_all"


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


func is_node_claimed(route_id, node_index = null) -> bool:
	if node_index == null:
		return bool(claimed_route_nodes.get(int(route_id), false))
	return bool(claimed_route_nodes.get(_node_key(String(route_id), int(node_index)), false))


func can_click_reward_node(area_or_node_index, route_id = "", node_index = null) -> bool:
	if node_index == null:
		var legacy_index = int(area_or_node_index)
		if selected_route_id.is_empty() or claimed_route_nodes.has(legacy_index):
			return false
		var legacy_nodes: Array = active_route.get("nodes", [])
		return legacy_index >= 0 and legacy_index < legacy_nodes.size()

	var area: Dictionary = area_or_node_index
	var index = int(node_index)
	var route_key = String(route_id)
	if is_node_claimed(route_key, index):
		return false
	if is_collect_all_area(area):
		return not _node_from_area(area, route_key, index).is_empty()
	if selected_route_id.is_empty() or selected_route_id != route_key:
		return false
	var nodes: Array = active_route.get("nodes", [])
	return index >= 0 and index < nodes.size()


func get_active_node(area_or_node_index, route_id = "", node_index = null) -> Dictionary:
	if node_index == null:
		var legacy_index = int(area_or_node_index)
		var legacy_nodes: Array = active_route.get("nodes", [])
		if legacy_index < 0 or legacy_index >= legacy_nodes.size():
			return {}
		return legacy_nodes[legacy_index]

	var area: Dictionary = area_or_node_index
	var route_key = String(route_id)
	var index = int(node_index)
	if is_collect_all_area(area):
		return _node_from_area(area, route_key, index)
	if route_key != selected_route_id:
		return {}
	var nodes: Array = active_route.get("nodes", [])
	if index < 0 or index >= nodes.size():
		return {}
	return nodes[index]


func claim_node(route_id, node_index = null) -> void:
	if node_index == null:
		claimed_route_nodes[int(route_id)] = true
		return
	claimed_route_nodes[_node_key(String(route_id), int(node_index))] = true


func rewards_complete(area: Dictionary = {}) -> bool:
	if not area.is_empty() and is_collect_all_area(area):
		var total = 0
		for route in area.get("routes", []):
			for _node in route.get("nodes", []):
				total += 1
		return total > 0 and claimed_route_nodes.size() >= total
	if active_route.is_empty():
		return false
	return claimed_route_nodes.size() >= active_route.get("nodes", []).size()


func combat_locked(area: Dictionary = {}) -> bool:
	if not area.is_empty() and is_collect_all_area(area):
		return not rewards_complete(area)
	return selected_route_id.is_empty() or not rewards_complete(area)


func _node_key(route_id: String, node_index: int) -> String:
	return "%s:%d" % [route_id, node_index]


func _node_from_area(area: Dictionary, route_id: String, node_index: int) -> Dictionary:
	for route in area.get("routes", []):
		if String(route.get("id", "")) != route_id:
			continue
		var nodes: Array = route.get("nodes", [])
		if node_index >= 0 and node_index < nodes.size():
			return nodes[node_index]
	return {}
