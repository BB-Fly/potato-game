class_name RouteMapScene
extends Control

signal route_selected(route_id: String)
signal reward_node_selected(node_index: int)
signal combat_requested

const PlayableUiFactory = preload("res://src/app/playable/playable_ui_factory.gd")
const PlayableContentPresenter = preload("res://src/app/playable/playable_content_presenter.gd")

var map_flow
var route_controller
var run_context
var asset_catalog

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
	render()


func render() -> void:
	if map_flow == null or route_controller == null:
		return
	_clear_generated()
	var area_node = _current_area_node()
	var area: Dictionary = get_current_area_data()
	_set_background_for_area(area)

	var routes: Array = area.get("routes", [])
	for i in range(routes.size()):
		var route: Dictionary = routes[i]
		var route_root = _route_root_for(route, i, area_node)
		_add_route_hotspot(route, i, route_root)
	for i in range(routes.size()):
		var route: Dictionary = routes[i]
		_add_route_reward_nodes(route, _route_root_for(route, i, area_node))
	_add_combat_node(area, area_node)


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
	var area_node = _current_area_node()
	if area_node != null and area_node.has_method("to_area_data"):
		return area_node.to_area_data()
	return map_flow.get_current_area()


func _clear_generated() -> void:
	for child in generated.get_children():
		generated.remove_child(child)
		child.queue_free()


func _set_background_for_area(area: Dictionary) -> void:
	var path = String(area.get("background_path", ""))
	if path.is_empty():
		var chapter = String(area.get("chapter_id", "chapter_1"))
		path = "res://assets/art/map/backgrounds/chapter_2_route_background.png" if chapter == "chapter_2" else "res://assets/art/map/backgrounds/chapter_1_route_background.png"
	background.texture = _load_texture(path)


func _current_area_node():
	var current_area = map_flow.get_current_area()
	var area_id = String(current_area.get("id", ""))
	for child in area_definitions.get_children():
		if child.has_method("to_area_data") and String(child.get("area_id")) == area_id:
			return child
	return null


func _route_root_for(route: Dictionary, index: int, area_node) -> Control:
	if area_node != null:
		var routes_root = area_node.get_node_or_null("Routes")
		if routes_root != null:
			for child in routes_root.get_children():
				if child is Control and child.has_method("to_route_data") and String(child.get("route_id")) == String(route.get("id", "")):
					return child
	return null


func _add_route_hotspot(route: Dictionary, index: int, route_root: Control) -> void:
	var route_id = String(route.get("id", ""))
	var is_selected = route_controller.is_route_selected(route_id)
	var locked = route_controller.is_route_locked(route_id)
	var rect = _hotspot_rect(route_root, index)

	var panel = PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style_box(
		Color(0.42, 0.28, 0.08, 0.30) if is_selected else Color(0.08, 0.055, 0.035, 0.32),
		Color(1.0, 0.86, 0.32, 0.95) if is_selected else Color(0.95, 0.72, 0.28, 0.42),
		3 if is_selected else 1,
		8
	))
	generated.add_child(panel)

	var button = Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = ""
	button.flat = true
	button.disabled = locked or route_controller.has_claimed_nodes() or is_selected
	button.pressed.connect(_emit_route_selected.bind(route_id))
	generated.add_child(button)

	var lane_text = "Left Route" if index == 0 else "Right Route"
	if is_selected:
		lane_text += " Selected"
	var label = _make_label(lane_text, 28, Color(1.0, 0.9, 0.58), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(rect.position.x, rect.position.y + 16)
	label.size = Vector2(rect.size.x, 46)
	generated.add_child(label)


func _add_route_reward_nodes(route: Dictionary, route_root: Control) -> void:
	var route_id = String(route.get("id", ""))
	var preview_only = not route_controller.is_route_selected(route_id)
	var nodes: Array = route.get("nodes", [])
	for i in range(nodes.size()):
		var node_data: Dictionary = nodes[i]
		var pos = _reward_node_position(route_root, i, node_data)
		var claimed = route_controller.is_node_claimed(i)
		var button = _make_map_node_button(
			String(node_data.get("type", "")),
			pos,
			preview_only or claimed,
			_emit_reward_node_selected.bind(i)
		)
		if preview_only:
			button.modulate = Color(0.86, 0.86, 0.86, 0.74)
		generated.add_child(button)

		var label = _make_label(
			_node_label(node_data),
			16,
			Color(0.86, 0.84, 0.76, 0.78) if preview_only else Color(1.0, 0.92, 0.68),
			HORIZONTAL_ALIGNMENT_CENTER
		)
		label.position = pos + Vector2(-100, 42)
		label.size = Vector2(200, 32)
		generated.add_child(label)


func _add_combat_node(area: Dictionary, area_node) -> void:
	var exits: Array = area.get("shared_exit_nodes", [])
	if exits.is_empty():
		return
	var pos = _combat_node_position(area_node, exits[0])
	var locked = route_controller.combat_locked()
	var button = _make_map_node_button("combat", pos, locked, _emit_combat_requested)
	generated.add_child(button)

	var label = _make_label("Combat" if not locked else "Claim route rewards first", 17, Color(1.0, 0.86, 0.54), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = pos + Vector2(-140, 44)
	label.size = Vector2(280, 34)
	generated.add_child(label)


func _hotspot_rect(route_root: Control, index: int) -> Rect2:
	if route_root == null:
		var fallback = Rect2(Vector2(96, 154), Vector2(500, 414))
		if index == 1:
			fallback.position.x = 684
		return fallback
	var hotspot = route_root.get_node_or_null("Hotspot") as Control
	if hotspot == null:
		return Rect2(_local_position_from_node(route_root), route_root.size)
	return Rect2(_local_position_from_node(hotspot), hotspot.size)


func _reward_node_position(route_root: Control, node_index: int, node_data: Dictionary) -> Vector2:
	if route_root != null:
		var rewards_root = route_root.get_node_or_null("RewardNodes")
		if rewards_root != null and node_index < rewards_root.get_child_count():
			return _local_position_from_node(rewards_root.get_child(node_index))
	var position_data: Dictionary = node_data.get("position", {})
	if not position_data.is_empty():
		return Vector2(float(position_data.get("x", 0.5)), float(position_data.get("y", 0.5)))
	var hint: Dictionary = node_data.get("position_hint", {})
	return Vector2(float(hint.get("x", 0.5)) * 1280.0, float(hint.get("y", 0.5)) * 720.0)


func _combat_node_position(area_node, node_data: Dictionary) -> Vector2:
	if area_node != null:
		var combat_root = area_node.get_node_or_null("CombatNodes")
		if combat_root != null and combat_root.get_child_count() > 0:
			return _local_position_from_node(combat_root.get_child(0))
	var position_data: Dictionary = node_data.get("position", {})
	if not position_data.is_empty():
		return Vector2(float(position_data.get("x", 0.5)), float(position_data.get("y", 0.12)))
	var hint: Dictionary = node_data.get("position_hint", {})
	return Vector2(float(hint.get("x", 0.5)) * 1280.0, float(hint.get("y", 0.12)) * 720.0)


func _local_position_from_node(node: Node) -> Vector2:
	var pos = Vector2.ZERO
	var current = node
	while current != null and current != self:
		if current is Node2D:
			pos += (current as Node2D).position
		elif current is Control:
			pos += (current as Control).position
		current = current.get_parent()
	return pos


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
	button.pressed.connect(on_pressed)
	return button


func _emit_route_selected(route_id: String) -> void:
	route_selected.emit(route_id)


func _emit_reward_node_selected(node_index: int) -> void:
	reward_node_selected.emit(node_index)


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
