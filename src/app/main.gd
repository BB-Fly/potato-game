extends Node

const FixedTickLoop = preload("res://src/core/fixed_tick_loop.gd")
const GameplayEventBus = preload("res://src/core/event_bus.gd")
const ContentRegistry = preload("res://src/core/registry.gd")
const ContentConfigLoader = preload("res://src/config/content_config_loader.gd")
const RunContext = preload("res://src/domain/run/run_context.gd")
const SchoolState = preload("res://src/domain/school/school_state.gd")
const ItemPoolService = preload("res://src/domain/reward/item_pool_service.gd")
const MapFlow = preload("res://src/domain/map/map_flow.gd")
const RewardService = preload("res://src/domain/reward/reward_service.gd")
const EconomyService = preload("res://src/domain/economy/economy_service.gd")
const CombatRuntime = preload("res://src/domain/combat/combat_runtime.gd")
const AudioDirector = preload("res://src/domain/audio/audio_director.gd")
const EffectRunner = preload("res://src/domain/effect/effect_runner.gd")
const AssetCatalog = preload("res://src/config/asset_catalog.gd")
const PlayableUiFactory = preload("res://src/app/playable/playable_ui_factory.gd")
const PlayableInputActions = preload("res://src/app/playable/playable_input_actions.gd")
const PlayableContentPresenter = preload("res://src/app/playable/playable_content_presenter.gd")
const PlayableMapController = preload("res://src/app/playable/playable_map_controller.gd")
const PlayableRewardController = preload("res://src/app/playable/playable_reward_controller.gd")
const CombatScenePacked = preload("res://scenes/combat_scene.tscn")

const LOGICAL_VIEWPORT_SIZE = Vector2(1280, 720)

var event_bus
var registry
var tick_loop
var run_context
var item_pool
var map_flow
var reward_service
var economy_service
var combat_runtime
var audio_director
var effect_runner
var asset_catalog

var ui_root: Control
var screen = "boot"
var route_controller: PlayableMapController
var reward_controller: PlayableRewardController
var pending_continue: Callable = Callable()

var toast_label: Label
var combat_scene: Control


func _ready() -> void:
	Engine.physics_ticks_per_second = FixedTickLoop.TICKS_PER_SECOND
	_ensure_input_actions()
	_bootstrap_architecture()
	_build_root()
	_show_starter_screen()


func _process(_delta: float) -> void:
	_update_ui_root_transform()


func _physics_process(_delta: float) -> void:
	if tick_loop != null:
		tick_loop.step()


func _bootstrap_architecture() -> void:
	event_bus = GameplayEventBus.new()
	registry = ContentRegistry.new()

	var loader = ContentConfigLoader.new()
	var load_report = loader.load_all(registry)
	if not load_report.is_empty():
		for message in load_report:
			push_warning(message)

	var character = registry.get_entry("character", "character.potato_hero")
	run_context = RunContext.new()
	run_context.initialize("character.potato_hero", "difficulty.normal", "mode.demo", 1)
	run_context.school_state = SchoolState.new()
	run_context.school_state.initialize(character.get("primary_school_id", "school.metamorph"))

	item_pool = ItemPoolService.new(registry)
	map_flow = MapFlow.new(registry, run_context)
	reward_service = RewardService.new(registry, item_pool)
	economy_service = EconomyService.new(registry)
	combat_runtime = CombatRuntime.new(registry, event_bus, run_context)
	audio_director = AudioDirector.new(registry, event_bus)
	effect_runner = EffectRunner.new(registry, event_bus)
	asset_catalog = AssetCatalog.new(registry)
	route_controller = PlayableMapController.new()
	reward_controller = PlayableRewardController.new()
	tick_loop = FixedTickLoop.new(event_bus)
	tick_loop.add_system(combat_runtime)

	map_flow.start_map("map.demo")
	event_bus.emit_event("run_started", {
		"character_id": run_context.character_id,
		"seed": run_context.seed,
	})
	print("Puritato playable slice ready. Registered types: %s" % [registry.get_registered_types()])


func _build_root() -> void:
	ui_root = Control.new()
	ui_root.name = "PlayableRoot"
	ui_root.size = LOGICAL_VIEWPORT_SIZE
	add_child(ui_root)
	_update_ui_root_transform()


func _update_ui_root_transform() -> void:
	if ui_root == null:
		return
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale_factor = min(viewport_size.x / LOGICAL_VIEWPORT_SIZE.x, viewport_size.y / LOGICAL_VIEWPORT_SIZE.y)
	ui_root.scale = Vector2(scale_factor, scale_factor)
	ui_root.position = (viewport_size - LOGICAL_VIEWPORT_SIZE * scale_factor) * 0.5


func _clear_screen() -> void:
	if ui_root == null:
		return
	for child in ui_root.get_children():
		ui_root.remove_child(child)
		_queue_free_if_valid(child)
	combat_scene = null
	toast_label = null


func _show_starter_screen() -> void:
	screen = "starter"
	_clear_screen()
	_add_background_path("res://assets/art/map/backgrounds/chapter_1_route_background.png")
	_add_overlay(Color(0.03, 0.025, 0.02, 0.44))
	_add_top_bar("Puritato", "Choose starting equipment")

	var title = _make_label("Initial Supply", 38, Color(1.0, 0.88, 0.48), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, 110)
	title.size = Vector2(1280, 60)
	ui_root.add_child(title)

	var offer = reward_controller.build_starter_offer(item_pool, run_context)
	_add_choice_grid(offer, Vector2(270, 230), func(content_id): _grant_content_and_continue(content_id, _complete_starter_reward))


func _complete_starter_reward() -> void:
	route_controller.reset_route()
	_show_map_screen()


func _show_map_screen() -> void:
	screen = "map"
	_clear_screen()
	_add_background_for_area(map_flow.get_current_area())
	_add_overlay(Color(0.02, 0.018, 0.014, 0.18))
	_add_top_bar("Puritato", "Floor %d  Gold %d  Weapons %d/%d  Magics %d  Items %d" % [
		run_context.floor,
		run_context.gold,
		_equipped_weapon_count(),
		run_context.inventory["weapons"].size(),
		run_context.inventory["magics"].size(),
		run_context.inventory["items"].size(),
	])

	var routes = map_flow.get_available_routes()
	for i in range(routes.size()):
		_add_route_hotspot(routes[i], i)
	for route in routes:
		_add_route_reward_nodes(route, route_controller.is_route_preview(route))
	_add_combat_node()
	_add_inventory_panel()
	_add_toast_anchor()


func _add_route_hotspot(route: Dictionary, index: int) -> void:
	var route_id = String(route.get("id", ""))
	var is_selected = route_controller.is_route_selected(route_id)
	var locked = route_controller.is_route_locked(route_id)
	var rect = Rect2(Vector2(96, 154), Vector2(500, 414))
	if index == 1:
		rect.position.x = 684

	var panel = PanelContainer.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.add_theme_stylebox_override("panel", _style_box(
		Color(0.42, 0.28, 0.08, 0.30) if is_selected else Color(0.08, 0.055, 0.035, 0.32),
		Color(1.0, 0.86, 0.32, 0.95) if is_selected else Color(0.95, 0.72, 0.28, 0.42),
		3 if is_selected else 1,
		8
	))
	ui_root.add_child(panel)

	var button = Button.new()
	button.position = rect.position
	button.size = rect.size
	button.text = ""
	button.flat = true
	button.disabled = locked or route_controller.has_claimed_nodes()
	button.pressed.connect(_choose_route.bind(route_id))
	ui_root.add_child(button)

	var lane_text = "Left Route" if index == 0 else "Right Route"
	if is_selected:
		lane_text += " Selected"
	var label = _make_label(lane_text, 28, Color(1.0, 0.9, 0.58), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(rect.position.x, rect.position.y + 16)
	label.size = Vector2(rect.size.x, 46)
	ui_root.add_child(label)


func _add_route_reward_nodes(route: Dictionary, preview_only: bool) -> void:
	var nodes: Array = route.get("nodes", [])
	for i in range(nodes.size()):
		var node_data: Dictionary = nodes[i]
		var hint: Dictionary = node_data.get("position_hint", {})
		var pos = Vector2(float(hint.get("x", 0.5)) * 1280.0, float(hint.get("y", 0.5)) * 720.0)
		var claimed = route_controller.is_node_claimed(i)
		var button = _make_map_node_button(String(node_data.get("type", "")), pos, preview_only or claimed, Callable(self, "_click_route_reward_node").bind(i))
		if preview_only:
			button.modulate = Color(0.86, 0.86, 0.86, 0.74)
		ui_root.add_child(button)

		var label = _make_label(_node_label(node_data), 16, Color(0.86, 0.84, 0.76, 0.78) if preview_only else Color(1.0, 0.92, 0.68), HORIZONTAL_ALIGNMENT_CENTER)
		label.position = pos + Vector2(-100, 42)
		label.size = Vector2(200, 32)
		ui_root.add_child(label)


func _add_combat_node() -> void:
	var exits: Array = map_flow.get_current_area().get("shared_exit_nodes", [])
	if exits.is_empty():
		return
	var hint: Dictionary = exits[0].get("position_hint", {})
	var pos = Vector2(float(hint.get("x", 0.5)) * 1280.0, float(hint.get("y", 0.12)) * 720.0)
	var locked = route_controller.combat_locked()
	var button = _make_map_node_button("combat", pos, locked, Callable(self, "_start_combat"))
	ui_root.add_child(button)
	var label = _make_label("Combat" if not locked else "Claim route rewards first", 17, Color(1.0, 0.86, 0.54), HORIZONTAL_ALIGNMENT_CENTER)
	label.position = pos + Vector2(-140, 44)
	label.size = Vector2(280, 34)
	ui_root.add_child(label)


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


func _choose_route(route_id: String) -> void:
	if not route_controller.choose_route(map_flow, route_id):
		_show_toast("Route unavailable")
		return
	_show_map_screen()


func _click_route_reward_node(node_index: int) -> void:
	if not route_controller.can_click_reward_node(node_index):
		return
	var node_data = route_controller.get_active_node(node_index)
	if node_data.is_empty():
		return
	match String(node_data.get("type", "")):
		"coin":
			run_context.grant_gold(int(node_data.get("gold", 0)))
			_complete_route_reward_node(node_index)
		"free_weapon":
			_show_reward_choices(String(node_data.get("reward_table_id", "reward.free_weapon.start")), _complete_route_reward_node.bind(node_index))
		"random_item":
			_show_reward_choices(String(node_data.get("reward_table_id", "reward.random_item.chapter_1")), _complete_route_reward_node.bind(node_index))
		"weapon_shop", "magic_shop", "item_shop", "weapon_master", "magic_master":
			_show_shop_screen(node_data, _complete_route_reward_node.bind(node_index))
		"encounter":
			run_context.grant_gold(80 + run_context.floor * 20)
			_complete_route_reward_node(node_index)
		_:
			_complete_route_reward_node(node_index)


func _complete_route_reward_node(node_index: int) -> void:
	route_controller.claim_node(node_index)
	_show_map_screen()


func _route_rewards_complete() -> bool:
	return route_controller.rewards_complete()


func _show_reward_choices(reward_id: String, on_done: Callable) -> void:
	screen = "reward"
	_clear_screen()
	_add_background_for_area(map_flow.get_current_area())
	_add_overlay(Color(0.03, 0.025, 0.02, 0.68))
	_add_top_bar("Choose Reward", "Click an icon to pick")
	var offer = reward_controller.build_reward_offer(item_pool, run_context, reward_id)
	_add_choice_grid(offer, Vector2(270, 220), func(content_id): _grant_content_and_continue(content_id, on_done))


func _show_shop_screen(node_data: Dictionary, on_done: Callable) -> void:
	screen = "shop"
	_clear_screen()
	_add_background_for_area(map_flow.get_current_area())
	_add_overlay(Color(0.03, 0.025, 0.02, 0.72))
	_add_top_bar(_node_type_name(String(node_data.get("type", ""))), "Gold %d - click icon to buy" % run_context.gold)

	var node_type = String(node_data.get("type", ""))
	var offer = reward_controller.build_shop_offer(item_pool, run_context, node_type)
	_add_choice_grid(offer, Vector2(270, 190), func(content_id): _buy_content(content_id))

	var leave = _make_pixel_button("Leave Shop", Vector2(520, 590), Vector2(240, 56))
	leave.pressed.connect(on_done)
	ui_root.add_child(leave)


func _buy_content(content_id: String) -> void:
	var result = reward_controller.buy_content(run_context, content_id)
	_show_toast(String(result.get("message", "")))


func _add_choice_grid(entries: Array, pos: Vector2, on_pick: Callable) -> void:
	var grid = HBoxContainer.new()
	grid.position = pos
	grid.size = Vector2(740, 300)
	grid.add_theme_constant_override("separation", 20)
	ui_root.add_child(grid)
	for entry in entries:
		grid.add_child(_make_choice_card(entry, on_pick))


func _make_choice_card(entry: Dictionary, on_pick: Callable) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(230, 292)
	card.text = ""
	card.tooltip_text = _content_name(String(entry.get("id", "")))
	card.add_theme_stylebox_override("normal", _style_box(Color(0.055, 0.045, 0.035, 0.82), _rarity_color(entry), 2, 8))
	card.add_theme_stylebox_override("hover", _style_box(Color(0.18, 0.12, 0.06, 0.94), _rarity_color(entry).lightened(0.16), 3, 8))
	card.add_theme_stylebox_override("pressed", _style_box(Color(0.26, 0.16, 0.07, 0.98), _rarity_color(entry).lightened(0.22), 3, 8))
	card.pressed.connect(func(): on_pick.call(String(entry.get("id", ""))))

	var layout = VBoxContainer.new()
	layout.size = Vector2(230, 292)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 8)
	card.add_child(layout)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(170, 132)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(_content_icon_path(entry))
	layout.add_child(icon)

	var name_label = _make_label(_content_name(String(entry.get("id", ""))), 19, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.custom_minimum_size = Vector2(200, 60)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(name_label)
	return card


func _grant_content_and_continue(content_id: String, on_done: Callable) -> void:
	_grant_content(content_id)
	on_done.call()


func _grant_content(content_id: String) -> void:
	reward_controller.grant_content(run_context, content_id)


func _start_combat() -> void:
	_clear_screen()
	screen = "combat"
	combat_scene = CombatScenePacked.instantiate()
	combat_scene.connect("combat_finished", _on_combat_finished)
	ui_root.add_child(combat_scene)
	combat_scene.setup(registry, run_context, asset_catalog)


func _on_combat_finished(result: Dictionary) -> void:
	if screen != "combat":
		return
	var victory = bool(result.get("victory", false))
	if combat_scene != null and is_instance_valid(combat_scene):
		if combat_scene.has_method("cleanup"):
			combat_scene.cleanup()
		combat_scene.queue_free()
	combat_scene = null
	if victory:
		_finish_combat()
	else:
		_show_defeat_screen()


func _queue_free_if_valid(node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()


func _finish_combat() -> void:
	if map_flow.advance_area():
		route_controller.reset_route()
		_show_map_screen()
	else:
		_show_victory_screen()


func _show_defeat_screen() -> void:
	screen = "defeat"
	_clear_screen()
	_add_overlay(Color(0.08, 0.02, 0.02, 0.92))
	var title = _make_label("Defeat", 42, Color(1.0, 0.44, 0.36), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, 180)
	title.size = Vector2(1280, 70)
	ui_root.add_child(title)
	var retry = _make_pixel_button("Retry Combat", Vector2(488, 430), Vector2(304, 62))
	retry.pressed.connect(_start_combat)
	ui_root.add_child(retry)


func _show_victory_screen() -> void:
	screen = "victory"
	_clear_screen()
	_add_overlay(Color(0.03, 0.055, 0.025, 0.92))
	var title = _make_label("Run Clear", 42, Color(0.85, 1.0, 0.55), HORIZONTAL_ALIGNMENT_CENTER)
	title.position = Vector2(0, 190)
	title.size = Vector2(1280, 70)
	ui_root.add_child(title)
	var restart = _make_pixel_button("Restart", Vector2(520, 430), Vector2(240, 60))
	restart.pressed.connect(_restart_run)
	ui_root.add_child(restart)


func _restart_run() -> void:
	var character = registry.get_entry("character", "character.potato_hero")
	run_context = RunContext.new()
	run_context.initialize("character.potato_hero", "difficulty.normal", "mode.demo", randi_range(1, 999999))
	run_context.school_state = SchoolState.new()
	run_context.school_state.initialize(character.get("primary_school_id", "school.metamorph"))
	map_flow = MapFlow.new(registry, run_context)
	map_flow.start_map("map.demo")
	route_controller = PlayableMapController.new()
	reward_controller = PlayableRewardController.new()
	combat_runtime = CombatRuntime.new(registry, event_bus, run_context)
	tick_loop = FixedTickLoop.new(event_bus)
	tick_loop.add_system(combat_runtime)
	_show_starter_screen()


func _inventory_summary() -> String:
	return "Weapons: %d equipped / %d inventory    Magics: %d    Items: %d" % [
		_equipped_weapon_count(),
		run_context.inventory["weapons"].size(),
		run_context.inventory["magics"].size(),
		run_context.inventory["items"].size(),
	]


func _equipped_weapon_count() -> int:
	var count = 0
	for weapon_id in run_context.equipped_weapons:
		if weapon_id != null:
			count += 1
	return min(4, count)


func _add_background_for_area(area: Dictionary) -> void:
	var chapter = String(area.get("chapter_id", "chapter_1"))
	var path = "res://assets/art/map/backgrounds/chapter_2_route_background.png" if chapter == "chapter_2" else "res://assets/art/map/backgrounds/chapter_1_route_background.png"
	_add_background_path(path)


func _add_background_path(path: String) -> void:
	var bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture = _load_texture(path)
	ui_root.add_child(bg)


func _add_overlay(color: Color) -> void:
	var overlay = ColorRect.new()
	overlay.color = color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(overlay)


func _add_top_bar(title_text: String, detail_text: String) -> void:
	var bar = ColorRect.new()
	bar.color = Color(0.065, 0.045, 0.035, 0.88)
	bar.position = Vector2.ZERO
	bar.size = Vector2(1280, 76)
	ui_root.add_child(bar)
	var title = _make_label(title_text, 28, Color(1.0, 0.86, 0.48), HORIZONTAL_ALIGNMENT_LEFT)
	title.position = Vector2(30, 14)
	title.size = Vector2(430, 44)
	ui_root.add_child(title)
	var detail = _make_label(detail_text, 20, Color(0.95, 0.88, 0.66), HORIZONTAL_ALIGNMENT_RIGHT)
	detail.position = Vector2(470, 18)
	detail.size = Vector2(770, 38)
	ui_root.add_child(detail)


func _add_inventory_panel() -> void:
	var panel = PanelContainer.new()
	panel.position = Vector2(108, 632)
	panel.size = Vector2(1064, 62)
	panel.add_theme_stylebox_override("panel", _style_box(Color(0.08, 0.065, 0.05, 0.84), Color(0.48, 0.34, 0.18, 0.8), 1, 6))
	ui_root.add_child(panel)
	var label = _make_label(_inventory_summary(), 18, Color(0.96, 0.88, 0.68), HORIZONTAL_ALIGNMENT_CENTER)
	label.custom_minimum_size = Vector2(1040, 54)
	panel.add_child(label)


func _add_toast_anchor() -> void:
	toast_label = _make_label("", 20, Color(1.0, 0.92, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
	toast_label.position = Vector2(220, 96)
	toast_label.size = Vector2(840, 34)
	ui_root.add_child(toast_label)


func _show_toast(text: String) -> void:
	if toast_label == null or not is_instance_valid(toast_label):
		return
	toast_label.text = text
	var tween = create_tween()
	tween.bind_node(toast_label)
	toast_label.modulate = Color(1, 1, 1, 1)
	tween.tween_interval(1.2)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	return PlayableUiFactory.make_label(text, font_size, color, alignment)


func _make_pixel_button(text: String, pos: Vector2, size: Vector2) -> Button:
	return PlayableUiFactory.make_pixel_button(text, pos, size)


func _style_box(fill: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	return PlayableUiFactory.style_box(fill, border, border_width, corner_radius)


func _fill_offer_choices(entries: Array, count: int, content_type: String) -> Array:
	return reward_controller.fill_offer_choices(item_pool, run_context, entries, count, content_type)


func _content_name(content_id: String) -> String:
	return PlayableContentPresenter.content_name(content_id)


func _node_label(node_data: Dictionary) -> String:
	return PlayableContentPresenter.node_label(node_data)


func _node_type_name(node_type: String) -> String:
	return PlayableContentPresenter.node_type_name(node_type)


func _node_icon_path(node_type: String) -> String:
	return PlayableContentPresenter.node_icon_path(asset_catalog, node_type)


func _content_icon_path(entry: Dictionary) -> String:
	return PlayableContentPresenter.content_icon_path(asset_catalog, entry)


func _rarity_color(entry: Dictionary) -> Color:
	return PlayableContentPresenter.rarity_color(entry)


func _load_texture(path: String) -> Texture2D:
	return PlayableUiFactory.load_texture(path)


func _ensure_input_actions() -> void:
	PlayableInputActions.ensure_defaults()


func _ensure_action(action_name: String, keycodes: Array) -> void:
	PlayableInputActions.ensure_action(action_name, keycodes)
