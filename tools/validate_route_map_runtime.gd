extends SceneTree

const ContentRegistry = preload("res://src/core/registry.gd")
const ContentConfigLoader = preload("res://src/config/content_config_loader.gd")
const RunContext = preload("res://src/domain/run/run_context.gd")
const SchoolState = preload("res://src/domain/school/school_state.gd")
const MapFlow = preload("res://src/domain/map/map_flow.gd")
const AssetCatalog = preload("res://src/config/asset_catalog.gd")
const PlayableInputActions = preload("res://src/app/playable/playable_input_actions.gd")
const PlayableMapController = preload("res://src/app/playable/playable_map_controller.gd")
const RouteMapScenePacked = preload("res://scenes/route_map_scene.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	PlayableInputActions.ensure_defaults()

	var registry = ContentRegistry.new()
	var loader = ContentConfigLoader.new()
	var warnings = loader.load_all(registry)
	if not warnings.is_empty():
		_fail("Content warnings: %s" % [warnings])
		return

	var character = registry.get_entry("character", "character.potato_hero")
	var run_context = RunContext.new()
	run_context.initialize("character.potato_hero", "difficulty.normal", "mode.demo", 1)
	run_context.school_state = SchoolState.new()
	run_context.school_state.initialize(character.get("primary_school_id", "school.metamorph"))

	var map_flow = MapFlow.new(registry, run_context)
	if not map_flow.start_map("map.demo"):
		_fail("Could not start map.demo")
		return

	var current_map = map_flow.get_current_map()
	var presentation: Dictionary = current_map.get("presentation", {})
	var canvas: Dictionary = presentation.get("canvas", {})
	if int(canvas.get("height", 0)) != 4320:
		_fail("Expected full-run canvas height 4320")
		return

	var area = map_flow.get_current_area()
	var left_node: Dictionary = area.get("routes", [])[0].get("nodes", [])[0]
	var right_node: Dictionary = area.get("routes", [])[1].get("nodes", [])[0]
	if left_node.has("reward_options") or right_node.has("reward_options"):
		_fail("Reward options were not realized at map start")
		return
	if String(left_node.get("type", "")).is_empty() or String(right_node.get("type", "")).is_empty():
		_fail("Realized start reward nodes need concrete types")
		return

	var route_controller = PlayableMapController.new()
	if not route_controller.can_click_reward_node(area, "left", 0):
		_fail("Left start reward should be claimable before route choice")
		return
	if not route_controller.can_click_reward_node(area, "right", 0):
		_fail("Right start reward should be claimable before route choice")
		return
	route_controller.claim_node("left", 0)
	if not route_controller.combat_locked(area):
		_fail("Combat should stay locked until both start rewards are claimed")
		return
	route_controller.claim_node("right", 0)
	if route_controller.combat_locked(area):
		_fail("Combat should unlock after both start rewards are claimed")
		return

	var route_map_scene = RouteMapScenePacked.instantiate()
	get_root().add_child(route_map_scene)
	route_map_scene.setup(map_flow, route_controller, run_context, AssetCatalog.new(registry))
	if route_map_scene.total_map_height != 4320.0:
		_fail("Route map scene did not read full-run canvas height")
		return
	if route_map_scene.get_node("Generated").get_child_count() == 0:
		_fail("Route map scene did not generate runtime layers")
		return

	print("Route map runtime validation passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
