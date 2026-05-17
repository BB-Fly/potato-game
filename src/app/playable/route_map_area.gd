class_name RouteMapArea
extends Node2D

@export var area_id = ""
@export var chapter_id = "chapter_1"
@export var floor = 1
@export var background_path = "res://assets/art/map/backgrounds/chapter_1_route_background.png"
@export var run_victory_on_clear = false


func to_area_data() -> Dictionary:
	var routes: Array = []
	var routes_root = get_node_or_null("Routes")
	if routes_root != null:
		for child in routes_root.get_children():
			if child.has_method("to_route_data"):
				routes.append(child.to_route_data())

	var shared_exit_nodes: Array = []
	var combat_root = get_node_or_null("CombatNodes")
	if combat_root != null:
		for child in combat_root.get_children():
			if child.has_method("to_combat_node_data"):
				shared_exit_nodes.append(child.to_combat_node_data())

	return {
		"id": area_id,
		"chapter_id": chapter_id,
		"floor": floor,
		"background_path": background_path,
		"routes": routes,
		"shared_exit_nodes": shared_exit_nodes,
		"run_victory_on_clear": run_victory_on_clear,
	}
