class_name MapFlow
extends RefCounted

var registry
var run_context
var current_map: Dictionary = {}
var previous_area_index = -1


func _init(p_registry, p_run_context) -> void:
	registry = p_registry
	run_context = p_run_context


func start_map(map_id: String) -> bool:
	current_map = registry.get_entry("map", map_id).duplicate(true)
	if current_map.is_empty():
		push_error("Map not found: %s" % map_id)
		return false
	_realize_reward_slots()
	run_context.current_map_id = map_id
	run_context.current_area_index = 0
	previous_area_index = -1
	_sync_area_context()
	return true


func get_current_map() -> Dictionary:
	return current_map


func get_all_areas() -> Array:
	return current_map.get("areas", [])


func get_current_area() -> Dictionary:
	var areas: Array = current_map.get("areas", [])
	if run_context.current_area_index < 0 or run_context.current_area_index >= areas.size():
		return {}
	return areas[run_context.current_area_index]


func get_available_routes() -> Array:
	return get_current_area().get("routes", [])


func choose_route(route_id: String) -> Dictionary:
	for route in get_available_routes():
		if String(route.get("id", "")) == route_id:
			record_route_choice(route_id)
			return route
	return {}


func record_route_choice(route_id: String) -> void:
	run_context.route_history.append({
		"floor": run_context.floor,
		"route_id": route_id,
	})


func advance_area() -> bool:
	previous_area_index = run_context.current_area_index
	run_context.current_area_index += 1
	if run_context.current_area_index >= current_map.get("areas", []).size():
		return false
	_sync_area_context()
	return true


func consume_previous_area_index() -> int:
	var value = previous_area_index
	previous_area_index = -1
	return value


func _sync_area_context() -> void:
	var area = get_current_area()
	run_context.current_chapter_id = String(area.get("chapter_id", ""))
	run_context.floor = int(area.get("floor", run_context.current_area_index + 1))


func _realize_reward_slots() -> void:
	var areas: Array = current_map.get("areas", [])
	for area in areas:
		if typeof(area) != TYPE_DICTIONARY:
			continue
		var routes: Array = area.get("routes", [])
		for route in routes:
			if typeof(route) != TYPE_DICTIONARY:
				continue
			var nodes: Array = route.get("nodes", [])
			for node in nodes:
				if typeof(node) == TYPE_DICTIONARY:
					_realize_reward_node(area, route, node)


func _realize_reward_node(area: Dictionary, route: Dictionary, node: Dictionary) -> void:
	var options: Array = node.get("reward_options", [])
	if options.is_empty():
		return
	var picked = null
	if run_context != null and run_context.rng != null:
		picked = run_context.rng.weighted_pick(options, "weight", 1.0)
	if picked == null and not options.is_empty():
		picked = options[0]
	if typeof(picked) != TYPE_DICTIONARY:
		node.erase("reward_options")
		return

	var realized: Dictionary = picked.duplicate(true)
	realized.erase("weight")
	for key in realized.keys():
		node[key] = realized[key]
	node["realized_from_options"] = true
	node.erase("reward_options")

	if not node.has("id"):
		node["id"] = "%s.%s.%s" % [
			String(area.get("id", "area")),
			String(route.get("id", "route")),
			String(node.get("side", "node")),
		]
	if String(node.get("type", "")) == "coin" and int(node.get("gold", 0)) <= 0:
		node["gold"] = 90 + int(area.get("floor", 1)) * 45

