class_name MapFlow
extends RefCounted

var registry
var run_context
var current_map: Dictionary = {}


func _init(p_registry, p_run_context) -> void:
	registry = p_registry
	run_context = p_run_context


func start_map(map_id: String) -> bool:
	current_map = registry.get_entry("map", map_id)
	if current_map.is_empty():
		push_error("Map not found: %s" % map_id)
		return false
	run_context.current_map_id = map_id
	run_context.current_area_index = 0
	_sync_area_context()
	return true


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
			run_context.route_history.append({
				"floor": run_context.floor,
				"route_id": route_id,
			})
			return route
	return {}


func advance_area() -> bool:
	run_context.current_area_index += 1
	if run_context.current_area_index >= current_map.get("areas", []).size():
		return false
	_sync_area_context()
	return true


func _sync_area_context() -> void:
	var area = get_current_area()
	run_context.current_chapter_id = String(area.get("chapter_id", ""))
	run_context.floor = int(area.get("floor", run_context.current_area_index + 1))

