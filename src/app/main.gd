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
const RouteMapScenePacked = preload("res://scenes/route_map_scene.tscn")

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
var active_shop_node_data: Dictionary = {}
var active_shop_stock: Array = []
var active_shop_sold: Dictionary = {}
var active_shop_on_done: Callable = Callable()

var toast_label: Label
var combat_scene: Control
var route_map_scene


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
	route_map_scene = null
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
	route_map_scene = RouteMapScenePacked.instantiate()
	route_map_scene.connect("route_selected", _choose_route)
	route_map_scene.connect("reward_node_selected", _click_route_reward_node)
	route_map_scene.connect("combat_requested", _start_combat)
	ui_root.add_child(route_map_scene)
	route_map_scene.setup(map_flow, route_controller, run_context, asset_catalog)
	_add_top_bar("Puritato", "Floor %d  Gold %d  Weapons %d/%d  Magics %d  Items %d" % [
		run_context.floor,
		run_context.gold,
		_equipped_weapon_count(),
		run_context.inventory["weapons"].size(),
		run_context.inventory["magics"].size(),
		run_context.inventory["items"].size(),
	])
	_add_inventory_panel()
	_add_toast_anchor()


func _choose_route(route_id: String) -> void:
	var route_chosen = false
	if route_map_scene != null and is_instance_valid(route_map_scene) and route_map_scene.has_method("choose_route"):
		route_chosen = route_map_scene.choose_route(route_id)
	else:
		route_chosen = route_controller.choose_route(map_flow, route_id)
	if not route_chosen:
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
	active_shop_node_data = node_data.duplicate(true)
	active_shop_on_done = on_done
	active_shop_sold.clear()
	var shop_id = _shop_id_for_node(active_shop_node_data)
	var shop_entry = registry.get_entry("shop", shop_id)
	var stock_count = int(shop_entry.get("stock_count", 3))
	var node_type = String(active_shop_node_data.get("type", ""))
	active_shop_stock = reward_controller.build_shop_offer(item_pool, run_context, node_type, stock_count)
	_render_shop_screen()


func _render_shop_screen() -> void:
	_clear_screen()
	_add_background_for_area(map_flow.get_current_area())
	_add_overlay(Color(0.03, 0.025, 0.02, 0.72))
	_add_top_bar(_node_type_name(String(active_shop_node_data.get("type", ""))), "Gold %d - click goods to buy" % run_context.gold)
	_add_shop_grid()

	var leave = _make_pixel_button("Leave Shop", Vector2(520, 590), Vector2(240, 56))
	leave.pressed.connect(_leave_active_shop)
	ui_root.add_child(leave)
	_add_toast_anchor()


func _leave_active_shop() -> void:
	var on_done = active_shop_on_done
	active_shop_node_data.clear()
	active_shop_stock.clear()
	active_shop_sold.clear()
	active_shop_on_done = Callable()
	if on_done.is_valid():
		on_done.call()


func _buy_shop_stock(stock_index: int) -> void:
	if stock_index < 0 or stock_index >= active_shop_stock.size():
		return
	if active_shop_sold.has(stock_index):
		return
	var entry: Dictionary = active_shop_stock[stock_index]
	var shop_id = _shop_id_for_node(active_shop_node_data)
	var price = economy_service.price_for_entry(run_context, shop_id, entry)
	var result = reward_controller.buy_content(run_context, String(entry.get("id", "")), price, shop_id)
	if bool(result.get("success", false)):
		active_shop_sold[stock_index] = true
		_render_shop_screen()
	_show_toast(String(result.get("message", "")))


func _shop_id_for_node(node_data: Dictionary) -> String:
	var shop_id = String(node_data.get("shop_id", ""))
	if not shop_id.is_empty():
		return shop_id
	var node_type = String(node_data.get("type", ""))
	if node_type.contains("weapon"):
		return "shop.weapon.default"
	if node_type.contains("magic"):
		return "shop.magic.default"
	return "shop.item.default"


func _add_choice_grid(entries: Array, pos: Vector2, on_pick: Callable) -> void:
	var grid = HBoxContainer.new()
	grid.position = pos
	grid.size = Vector2(740, 300)
	grid.add_theme_constant_override("separation", 20)
	ui_root.add_child(grid)
	for entry in entries:
		grid.add_child(_make_choice_card(entry, on_pick))


func _add_shop_grid() -> void:
	var visible_indices: Array = []
	for i in range(active_shop_stock.size()):
		if not active_shop_sold.has(i):
			visible_indices.append(i)

	if visible_indices.is_empty():
		var sold_out = _make_label("Sold Out", 38, Color(1.0, 0.84, 0.42), HORIZONTAL_ALIGNMENT_CENTER)
		sold_out.position = Vector2(0, 310)
		sold_out.size = Vector2(1280, 70)
		ui_root.add_child(sold_out)
		return

	var grid = GridContainer.new()
	grid.position = Vector2(92, 152)
	grid.size = Vector2(1096, 360)
	grid.columns = min(5, visible_indices.size())
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 18)
	ui_root.add_child(grid)
	for stock_index in visible_indices:
		grid.add_child(_make_shop_card(stock_index, active_shop_stock[stock_index]))


func _make_shop_card(stock_index: int, entry: Dictionary) -> Control:
	var price = economy_service.price_for_entry(run_context, _shop_id_for_node(active_shop_node_data), entry)
	var affordable = run_context.can_spend_gold(price)
	var card = Button.new()
	card.custom_minimum_size = Vector2(204, 306)
	card.text = ""
	card.tooltip_text = "%s - %d gold" % [_content_name(String(entry.get("id", ""))), price]
	card.modulate = Color(1, 1, 1, 1) if affordable else Color(0.72, 0.72, 0.72, 0.86)
	card.add_theme_stylebox_override("normal", _style_box(Color(0.055, 0.045, 0.035, 0.88), _rarity_color(entry), 2, 8))
	card.add_theme_stylebox_override("hover", _style_box(Color(0.18, 0.12, 0.06, 0.96), _rarity_color(entry).lightened(0.16), 3, 8))
	card.add_theme_stylebox_override("pressed", _style_box(Color(0.26, 0.16, 0.07, 0.98), _rarity_color(entry).lightened(0.22), 3, 8))
	card.pressed.connect(_buy_shop_stock.bind(stock_index))

	var layout = VBoxContainer.new()
	layout.size = Vector2(204, 306)
	layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 8)
	card.add_child(layout)

	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(156, 118)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = _load_texture(_content_icon_path(entry))
	layout.add_child(icon)

	var name_label = _make_label(_content_name(String(entry.get("id", ""))), 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.custom_minimum_size = Vector2(184, 58)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(name_label)

	var price_badge = HBoxContainer.new()
	price_badge.custom_minimum_size = Vector2(166, 44)
	price_badge.alignment = BoxContainer.ALIGNMENT_CENTER
	price_badge.add_theme_constant_override("separation", 6)
	layout.add_child(price_badge)

	var coin = TextureRect.new()
	coin.custom_minimum_size = Vector2(32, 32)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.texture = _load_texture(asset_catalog.resolve_asset_path("ui.currency.gold.icon", "res://assets/art/ui/currency_gold.png"))
	price_badge.add_child(coin)

	var price_label = _make_label(str(price), 22, Color(1.0, 0.86, 0.42) if affordable else Color(1.0, 0.42, 0.34), HORIZONTAL_ALIGNMENT_LEFT)
	price_label.custom_minimum_size = Vector2(92, 38)
	price_badge.add_child(price_label)
	return card


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
