class_name RouteMapScene
extends Control

signal route_selected(route_id: String)
signal reward_node_selected(route_id: String, node_index: int)
signal combat_requested

const PlayableUiFactory = preload("res://src/app/playable/playable_ui_factory.gd")
const PlayableContentPresenter = preload("res://src/app/playable/playable_content_presenter.gd")

const LOGICAL_VIEWPORT_SIZE = Vector2(1280, 720)
const DEFAULT_FLOOR_HEIGHT = 720.0
const SCROLL_STEP = 96.0
const SCROLL_SPEED = 860.0

var map_flow
var route_controller
var run_context
var asset_catalog

var map_width = LOGICAL_VIEWPORT_SIZE.x
var floor_height = DEFAULT_FLOOR_HEIGHT
var total_map_height = DEFAULT_FLOOR_HEIGHT
var scroll_offset = 0.0
var target_scroll_offset = 0.0
var foreground_scroll_factor = 1.035
var route_history_by_floor: Dictionary = {}
var reward_history_by_key: Dictionary = {}

var background_layer: Control
var state_layer: Control
var content_layer: Control
var fog_layer: Control
var foreground_layer: Control

@onready var background: TextureRect = $Background
@onready var overlay: ColorRect = $Overlay
@onready var generated: Control = $Generated
@onready var area_definitions: Node = $AreaDefinitions


func setup(p_map_flow, p_route_controller, p_run_context, p_asset_catalog) -> void:
	map_flow = p_map_flow
	route_controller = p_route_controller
	run_context = p_run_context
	asset_catalog = p_asset_catalog
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	generated.clip_contents = true
	background.visible = false
	overlay.visible = false
	if area_definitions is CanvasItem:
		(area_definitions as CanvasItem).visible = false

	var previous_index = -1
	if map_flow != null and map_flow.has_method("consume_previous_area_index"):
		previous_index = map_flow.consume_previous_area_index()
	render(previous_index)
	set_process(true)


func _process(delta: float) -> void:
	if abs(scroll_offset - target_scroll_offset) > 0.5:
		scroll_offset = lerp(scroll_offset, target_scroll_offset, min(1.0, delta * 8.0))
		_apply_scroll()

	var stick = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(stick) > 0.18:
		_adjust_scroll(stick * SCROLL_SPEED * delta)
	if Input.is_action_just_pressed("map_snap_up"):
		_snap_to_relative_floor(1)
	if Input.is_action_just_pressed("map_snap_down"):
		_snap_to_relative_floor(-1)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_adjust_scroll(-SCROLL_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_adjust_scroll(SCROLL_STEP)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		_adjust_scroll(-(event as InputEventMouseMotion).relative.y)


func render(previous_area_index: int = -1) -> void:
	if map_flow == null or route_controller == null:
		return
	_clear_generated()
	_read_layout()
	_index_histories()
	_make_layers()
	_add_map_background()

	var areas = _areas()
	for area_index in range(areas.size()):
		var area: Dictionary = areas[area_index]
		_add_area_state_underlay(area_index)
		_add_floor_badge(area, area_index)
		for route_index in range(area.get("routes", []).size()):
			var route: Dictionary = area.get("routes", [])[route_index]
			_add_route_hotspot(area, area_index, route, route_index)
			_add_route_reward_nodes(area, area_index, route)
		_add_combat_node(area, area_index)
	for area_index in range(areas.size()):
		_add_area_fog(area_index)

	_add_map_foreground()
	_focus_current_area(previous_area_index)


func choose_route(route_id: String) -> bool:
	var route = get_route_data(route_id)
	if route.is_empty():
		return route_controller.choose_route(map_flow, route_id)
	return route_controller.choose_route_data(map_flow, route)


func get_route_data(route_id: String) -> Dictionary:
	for route in get_current_area_data().get("routes", []):
		if String(route.get("id", "")) == route_id:
			return route
	return {}


func get_current_area_data() -> Dictionary:
	if map_flow == null:
		return {}
	return map_flow.get_current_area()


func _clear_generated() -> void:
	for child in generated.get_children():
		generated.remove_child(child)
		child.queue_free()
	background_layer = null
	state_layer = null
	content_layer = null
	fog_layer = null
	foreground_layer = null


func _read_layout() -> void:
	var current_map = _current_map()
	var presentation: Dictionary = current_map.get("presentation", {})
	var canvas: Dictionary = presentation.get("canvas", {})
	var areas = _areas()
	map_width = float(canvas.get("width", LOGICAL_VIEWPORT_SIZE.x))
	floor_height = float(canvas.get("floor_height", DEFAULT_FLOOR_HEIGHT))
	total_map_height = float(canvas.get("height", max(1, areas.size()) * floor_height))
	var art_layers: Dictionary = presentation.get("art_layers", {})
	foreground_scroll_factor = float(art_layers.get("foreground_scroll_factor", 1.035))


func _index_histories() -> void:
	route_history_by_floor.clear()
	reward_history_by_key.clear()
	if run_context == null:
		return
	for entry in run_context.route_history:
		if typeof(entry) == TYPE_DICTIONARY:
			route_history_by_floor[int(entry.get("floor", -1))] = String(entry.get("route_id", ""))
	for entry in run_context.reward_history:
		if typeof(entry) == TYPE_DICTIONARY:
			reward_history_by_key[_history_key(String(entry.get("area_id", "")), String(entry.get("route_id", "")), int(entry.get("node_index", -1)))] = true


func _make_layers() -> void:
	for layer_name in ["BackgroundLayer", "StateLayer", "ContentLayer", "FogLayer", "ForegroundLayer"]:
		var layer = Control.new()
		layer.name = layer_name
		layer.position = Vector2.ZERO
		layer.size = Vector2(map_width, total_map_height)
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		generated.add_child(layer)
		match layer_name:
			"BackgroundLayer":
				background_layer = layer
			"StateLayer":
				state_layer = layer
			"ContentLayer":
				content_layer = layer
			"FogLayer":
				fog_layer = layer
			"ForegroundLayer":
				foreground_layer = layer


func _add_map_background() -> void:
	var presentation: Dictionary = _current_map().get("presentation", {})
	var art_layers: Dictionary = presentation.get("art_layers", {})
	var full_path = String(art_layers.get("background_path", ""))
	if not full_path.is_empty():
		var full_background = _make_texture_rect(full_path, Vector2(map_width, total_map_height))
		background_layer.add_child(full_background)
		return

	var areas = _areas()
	for area_index in range(areas.size()):
		var area: Dictionary = areas[area_index]
		var rect = _area_rect(area_index)
		var band = _make_texture_rect(_background_path_for_area(area), rect.size)
		band.position = rect.position
		background_layer.add_child(band)


func _add_map_foreground() -> void:
	var presentation: Dictionary = _current_map().get("presentation", {})
	var art_layers: Dictionary = presentation.get("art_layers", {})
	var foreground_path = String(art_layers.get("foreground_path", ""))
	if foreground_path.is_empty():
		return
	var front = _make_texture_rect(foreground_path, Vector2(map_width, total_map_height))
	front.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foreground_layer.add_child(front)


func _add_area_state_underlay(area_index: int) -> void:
	var state = _area_state(area_index)
	if state == "current":
		return
	var rect = _area_rect(area_index)
	var color = Color(0.01, 0.01, 0.012, 0.46) if state == "past" else Color(0.045, 0.025, 0.075, 0.35)
	var tint = ColorRect.new()
	tint.position = rect.position
	tint.size = rect.size
	tint.color = color
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state_layer.add_child(tint)


func _add_area_fog(area_index: int) -> void:
	if _area_state(area_index) != "future":
		return
	var rect = _area_rect(area_index)
	var fog = ColorRect.new()
	fog.position = rect.position
	fog.size = rect.size
	fog.color = Color(0.075, 0.045, 0.12, 0.48)
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog_layer.add_child(fog)


func _add_floor_badge(area: Dictionary, area_index: int) -> void:
	var rect = _area_rect(area_index)
	var state = _area_state(area_index)
	var badge = PanelContainer.new()
	badge.position = rect.position + Vector2(24, 92)
	badge.size = Vector2(154, 38)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill = Color(0.08, 0.055, 0.035, 0.68) if state == "current" else Color(0.025, 0.02, 0.025, 0.44)
	var border = Color(0.92, 0.68, 0.26, 0.8) if state == "current" else Color(0.42, 0.35, 0.32, 0.45)
	badge.add_theme_stylebox_override("panel", _style_box(fill, border, 1, 6))
	content_layer.add_child(badge)

	var label = _make_label("Floor %d" % int(area.get("floor", area_index + 1)), 16, Color(1.0, 0.88, 0.58, 0.92), HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(132, 24)
	badge.add_child(label)


func _add_route_hotspot(area: Dictionary, area_index: int, route: Dictionary, route_index: int) -> void:
	if _area_state(area_index) != "current":
		return
	if route_controller.is_collect_all_area(area):
		return

	var route_id = String(route.get("id", ""))
	var is_selected = route_controller.is_route_selected(route_id)
	var locked = route_controller.is_route_locked(route_id)
	var rect = _route_hotspot_rect(route, route_index, area_index)

	var panel = PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill = Color(0.43, 0.28, 0.08, 0.22) if is_selected else Color(0.08, 0.055, 0.035, 0.10)
	var border = Color(1.0, 0.88, 0.32, 0.62) if is_selected else Color(1.0, 0.78, 0.28, 0.28)
	if locked:
		fill = Color(0.02, 0.018, 0.02, 0.30)
		border = Color(0.22, 0.20, 0.18, 0.42)
	panel.add_theme_stylebox_override("panel", _style_box(fill, border, 2 if is_selected else 1, 10))
	content_layer.add_child(panel)

	var button = Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = ""
	button.flat = true
	button.disabled = locked or route_controller.has_claimed_nodes() or is_selected
	button.tooltip_text = "Choose %s route" % route_id.capitalize()
	button.pressed.connect(_emit_route_selected.bind(route_id))
	content_layer.add_child(button)


func _add_route_reward_nodes(area: Dictionary, area_index: int, route: Dictionary) -> void:
	var nodes: Array = route.get("nodes", [])
	var route_id = String(route.get("id", ""))
	for node_index in range(nodes.size()):
		var node_data: Dictionary = nodes[node_index]
		var pos = _node_world_position(area_index, node_data)
		var button = _make_map_node_button(
			String(node_data.get("type", "")),
			pos,
			_node_disabled(area, area_index, route_id, node_index),
			_emit_reward_node_selected.bind(route_id, node_index)
		)
		button.tooltip_text = _node_label(node_data)
		button.modulate = _node_modulate(area, area_index, route_id, node_index)
		content_layer.add_child(button)

		if _node_claimed(area, area_index, route_id, node_index):
			_add_claim_marker(pos)


func _add_combat_node(area: Dictionary, area_index: int) -> void:
	var exits: Array = area.get("shared_exit_nodes", [])
	if exits.is_empty():
		return
	var node_data: Dictionary = exits[0]
	var pos = _node_world_position(area_index, node_data, Vector2(0.5, 0.12))
	var locked = _area_state(area_index) != "current" or route_controller.combat_locked(area)
	var button = _make_map_node_button("combat", pos, locked, _emit_combat_requested)
	button.tooltip_text = "Combat gate" if not locked else "Claim route rewards first"
	button.modulate = Color(1, 1, 1, 1) if _area_state(area_index) == "current" else Color(0.52, 0.52, 0.52, 0.54)
	content_layer.add_child(button)


func _add_claim_marker(pos: Vector2) -> void:
	var marker_path = ""
	if asset_catalog != null:
		marker_path = asset_catalog.resolve_asset_path("map.node.selected_marker", "")
	if marker_path.is_empty():
		return
	var marker = TextureRect.new()
	marker.position = pos - Vector2(48, 48)
	marker.size = Vector2(96, 96)
	marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marker.texture = _load_texture(marker_path)
	marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_layer.add_child(marker)


func _node_disabled(area: Dictionary, area_index: int, route_id: String, node_index: int) -> bool:
	if _area_state(area_index) != "current":
		return true
	return not route_controller.can_click_reward_node(area, route_id, node_index)


func _node_modulate(area: Dictionary, area_index: int, route_id: String, node_index: int) -> Color:
	var state = _area_state(area_index)
	if state == "future":
		return Color(0.58, 0.55, 0.68, 0.34)
	if state == "past":
		return Color(0.48, 0.48, 0.48, 0.50)
	if _node_claimed(area, area_index, route_id, node_index):
		return Color(0.62, 0.62, 0.60, 0.58)
	if route_controller.is_collect_all_area(area):
		return Color(1, 1, 1, 1)
	if route_controller.has_selected_route():
		return Color(1, 1, 1, 1) if route_controller.is_route_selected(route_id) else Color(0.54, 0.54, 0.54, 0.42)
	return Color(0.92, 0.92, 0.90, 0.76)


func _node_claimed(area: Dictionary, area_index: int, route_id: String, node_index: int) -> bool:
	if _area_state(area_index) == "current":
		return route_controller.is_node_claimed(route_id, node_index)
	return bool(reward_history_by_key.get(_history_key(String(area.get("id", "")), route_id, node_index), false))


func _route_hotspot_rect(route: Dictionary, route_index: int, area_index: int) -> Rect2:
	var area_y = _area_rect(area_index).position.y
	var hotspot: Dictionary = route.get("hotspot", {})
	if not hotspot.is_empty():
		return Rect2(
			Vector2(float(hotspot.get("x", 0)), area_y + float(hotspot.get("y", 0))),
			Vector2(float(hotspot.get("w", 1)), float(hotspot.get("h", 1)))
		)

	var local = Rect2(Vector2(88, 164), Vector2(502, 392))
	if route_index == 1:
		local.position.x = 690
	return Rect2(local.position + Vector2(0, area_y), local.size)


func _node_world_position(area_index: int, node_data: Dictionary, default_hint: Vector2 = Vector2(0.5, 0.5)) -> Vector2:
	var area_y = _area_rect(area_index).position.y
	var position_data: Dictionary = node_data.get("position", {})
	if not position_data.is_empty():
		return Vector2(float(position_data.get("x", default_hint.x)), area_y + float(position_data.get("y", default_hint.y)))
	var hint: Dictionary = node_data.get("position_hint", {})
	var x = float(hint.get("x", default_hint.x)) * map_width
	var y = float(hint.get("y", default_hint.y)) * floor_height
	return Vector2(x, area_y + y)


func _focus_current_area(previous_area_index: int = -1) -> void:
	var current_index = _current_area_index()
	if current_index < 0:
		target_scroll_offset = 0.0
		scroll_offset = 0.0
		_apply_scroll()
		return
	target_scroll_offset = _scroll_for_area_index(current_index)
	if previous_area_index >= 0:
		scroll_offset = _scroll_for_area_index(previous_area_index)
	else:
		scroll_offset = target_scroll_offset
	_apply_scroll()


func _adjust_scroll(delta: float) -> void:
	target_scroll_offset = clamp(target_scroll_offset + delta, 0.0, _max_scroll())


func _snap_to_relative_floor(direction: int) -> void:
	var areas = _areas()
	if areas.is_empty():
		return
	var current_from_scroll = int(round((total_map_height - floor_height - target_scroll_offset) / floor_height))
	var next_index = int(clamp(current_from_scroll + direction, 0, areas.size() - 1))
	target_scroll_offset = _scroll_for_area_index(next_index)


func _apply_scroll() -> void:
	scroll_offset = clamp(scroll_offset, 0.0, _max_scroll())
	target_scroll_offset = clamp(target_scroll_offset, 0.0, _max_scroll())
	for layer in [background_layer, state_layer, content_layer, fog_layer]:
		if layer != null:
			layer.position = Vector2(0, -scroll_offset)
	if foreground_layer != null:
		foreground_layer.position = Vector2(0, -scroll_offset * foreground_scroll_factor)


func _scroll_for_area_index(area_index: int) -> float:
	return clamp(_area_rect(area_index).position.y, 0.0, _max_scroll())


func _max_scroll() -> float:
	return max(0.0, total_map_height - LOGICAL_VIEWPORT_SIZE.y)


func _area_rect(area_index: int) -> Rect2:
	var y = total_map_height - float(area_index + 1) * floor_height
	return Rect2(Vector2(0, y), Vector2(map_width, floor_height))


func _area_state(area_index: int) -> String:
	var current_index = _current_area_index()
	if area_index < current_index:
		return "past"
	if area_index == current_index:
		return "current"
	return "future"


func _current_area_index() -> int:
	if run_context == null:
		return 0
	return int(run_context.current_area_index)


func _areas() -> Array:
	if map_flow == null:
		return []
	if map_flow.has_method("get_all_areas"):
		return map_flow.get_all_areas()
	return _current_map().get("areas", [])


func _current_map() -> Dictionary:
	if map_flow == null:
		return {}
	if map_flow.has_method("get_current_map"):
		return map_flow.get_current_map()
	return map_flow.current_map


func _history_key(area_id: String, route_id: String, node_index: int) -> String:
	return "%s:%s:%d" % [area_id, route_id, node_index]


func _background_path_for_area(area: Dictionary) -> String:
	var path = String(area.get("background_path", ""))
	if not path.is_empty():
		return path
	var chapter = String(area.get("chapter_id", "chapter_1"))
	return "res://assets/art/map/backgrounds/chapter_2_route_background.png" if chapter == "chapter_2" else "res://assets/art/map/backgrounds/chapter_1_route_background.png"


func _make_texture_rect(path: String, rect_size: Vector2) -> TextureRect:
	var texture_rect = TextureRect.new()
	texture_rect.size = rect_size
	texture_rect.texture = _load_texture(path)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect


func _make_map_node_button(node_type: String, pos: Vector2, disabled: bool, on_pressed: Callable) -> Button:
	var button = Button.new()
	button.position = pos - Vector2(38, 38)
	button.size = Vector2(76, 76)
	button.icon = _load_texture(_node_icon_path(node_type))
	button.expand_icon = true
	button.disabled = disabled
	button.add_theme_stylebox_override("normal", _style_box(Color(0.08, 0.055, 0.03, 0.42), Color(1.0, 0.82, 0.32, 0.78), 2, 38))
	button.add_theme_stylebox_override("hover", _style_box(Color(0.36, 0.24, 0.08, 0.7), Color(1.0, 0.92, 0.42, 1.0), 3, 38))
	button.add_theme_stylebox_override("pressed", _style_box(Color(0.52, 0.34, 0.08, 0.78), Color(1.0, 0.92, 0.42, 1.0), 3, 38))
	button.add_theme_stylebox_override("disabled", _style_box(Color(0.02, 0.018, 0.02, 0.34), Color(0.38, 0.34, 0.30, 0.36), 1, 38))
	button.pressed.connect(on_pressed)
	return button


func _emit_route_selected(route_id: String) -> void:
	route_selected.emit(route_id)


func _emit_reward_node_selected(route_id: String, node_index: int) -> void:
	reward_node_selected.emit(route_id, node_index)


func _emit_combat_requested() -> void:
	combat_requested.emit()


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	return PlayableUiFactory.make_label(text, font_size, color, alignment)


func _style_box(fill: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	return PlayableUiFactory.style_box(fill, border, border_width, corner_radius)


func _node_label(node_data: Dictionary) -> String:
	return PlayableContentPresenter.node_label(node_data)


func _node_icon_path(node_type: String) -> String:
	if asset_catalog == null:
		return "res://icon.svg"
	return PlayableContentPresenter.node_icon_path(asset_catalog, node_type)


func _load_texture(path: String) -> Texture2D:
	return PlayableUiFactory.load_texture(path)
