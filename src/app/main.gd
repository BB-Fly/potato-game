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

const LOGICAL_VIEWPORT_SIZE = Vector2(1280, 720)
const COMBAT_ARENA_RECT = Rect2(Vector2(48, 118), Vector2(1184, 560))
const PLAYER_SPEED = 235.0
const PLAYER_TOUCH_RADIUS = 30.0
const ENEMY_TOUCH_RADIUS = 58.0
const WEAPON_RANGE = 285.0
const WEAPON_ATTACK_SECONDS = 0.72
const MOB_PHASE_SECONDS = 22.0
const MOB_SPAWN_SECONDS = 1.55

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
var active_route: Dictionary = {}
var selected_route_id = ""
var claimed_route_nodes: Dictionary = {}
var pending_continue: Callable = Callable()

var toast_label: Label
var combat_layer: Control
var combat_fx_layer: Control
var combat_hud_label: Label
var combat_hint_label: Label
var combat_player_hp_bar: ProgressBar
var combat_mana_bar: ProgressBar
var combat_boss_hp_bar: ProgressBar
var combat_player_sprite: TextureRect
var combat_boss_sprite: TextureRect
var combat_weapon_sprites: Array = []
var magic_slot_nodes: Array = []

var player_pos = Vector2.ZERO
var player_hp = 100.0
var player_max_hp = 100.0
var player_mana = 0.0
var player_max_mana = 0.0
var player_mana_regen = 0.0
var player_attack_timer = 0.0
var idle_time = 0.0
var facing_direction = 1
var is_player_moving = false

var enemies: Array = []
var boss_enemy: Dictionary = {}
var boss_spawned = false
var boss_ability_timer = 8.0
var boss_cast_timer = 0.0
var boss_projectiles: Array = []
var mob_spawn_timer = 0.0
var combat_elapsed = 0.0
var magic_cooldowns: Array = []
var floating_texts: Array = []


func _ready() -> void:
	Engine.physics_ticks_per_second = FixedTickLoop.TICKS_PER_SECOND
	_ensure_input_actions()
	_bootstrap_architecture()
	_build_root()
	_show_starter_screen()


func _process(delta: float) -> void:
	_update_ui_root_transform()
	if screen == "combat":
		_update_combat(delta)
	_update_floating_texts(delta)


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
		child.queue_free()
	enemies.clear()
	boss_projectiles.clear()
	floating_texts.clear()
	combat_weapon_sprites.clear()
	magic_slot_nodes.clear()
	combat_layer = null
	combat_fx_layer = null
	combat_player_sprite = null
	combat_boss_sprite = null
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

	var offer = _fill_offer_choices(item_pool.roll_offer(run_context, "weapon", {
		"count": 3,
		"duplicate_policy": "avoid_same_offer",
		"guarantees": [{"slot": 0, "school": "character_primary"}],
	}), 3, "weapon")
	_add_choice_grid(offer, Vector2(270, 230), func(content_id): _grant_content_and_continue(content_id, _complete_starter_reward))


func _complete_starter_reward() -> void:
	selected_route_id = ""
	active_route = {}
	claimed_route_nodes.clear()
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
		_add_route_reward_nodes(route, String(route.get("id", "")) != selected_route_id)
	_add_combat_node()
	_add_inventory_panel()
	_add_toast_anchor()


func _add_route_hotspot(route: Dictionary, index: int) -> void:
	var route_id = String(route.get("id", ""))
	var is_selected = route_id == selected_route_id
	var locked = not selected_route_id.is_empty() and not is_selected
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
	button.disabled = locked or not claimed_route_nodes.is_empty()
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
		var claimed = bool(claimed_route_nodes.get(i, false))
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
	var locked = selected_route_id.is_empty() or not _route_rewards_complete()
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
	if not selected_route_id.is_empty() and not claimed_route_nodes.is_empty():
		return
	active_route = map_flow.choose_route(route_id)
	if active_route.is_empty():
		_show_toast("Route unavailable")
		return
	selected_route_id = route_id
	claimed_route_nodes.clear()
	_show_map_screen()


func _click_route_reward_node(node_index: int) -> void:
	if selected_route_id.is_empty() or claimed_route_nodes.has(node_index):
		return
	var nodes: Array = active_route.get("nodes", [])
	if node_index < 0 or node_index >= nodes.size():
		return
	var node_data: Dictionary = nodes[node_index]
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
	claimed_route_nodes[node_index] = true
	_show_map_screen()


func _route_rewards_complete() -> bool:
	if active_route.is_empty():
		return false
	return claimed_route_nodes.size() >= active_route.get("nodes", []).size()


func _show_reward_choices(reward_id: String, on_done: Callable) -> void:
	screen = "reward"
	_clear_screen()
	_add_background_for_area(map_flow.get_current_area())
	_add_overlay(Color(0.03, 0.025, 0.02, 0.68))
	_add_top_bar("Choose Reward", "Click an icon to pick")
	var content_type = "item"
	if reward_id.contains("weapon"):
		content_type = "weapon"
	var offer = _fill_offer_choices(item_pool.roll_offer(run_context, content_type, {
		"count": 3,
		"duplicate_policy": "avoid_same_offer",
		"guarantees": [{"slot": 0, "school": "character_primary"}],
	}), 3, content_type)
	_add_choice_grid(offer, Vector2(270, 220), func(content_id): _grant_content_and_continue(content_id, on_done))


func _show_shop_screen(node_data: Dictionary, on_done: Callable) -> void:
	screen = "shop"
	_clear_screen()
	_add_background_for_area(map_flow.get_current_area())
	_add_overlay(Color(0.03, 0.025, 0.02, 0.72))
	_add_top_bar(_node_type_name(String(node_data.get("type", ""))), "Gold %d - click icon to buy" % run_context.gold)

	var node_type = String(node_data.get("type", ""))
	var content_type = "item"
	if node_type.contains("weapon"):
		content_type = "weapon"
	elif node_type.contains("magic"):
		content_type = "magic"
	var offer = _fill_offer_choices(item_pool.roll_offer(run_context, content_type, {
		"count": 3,
		"duplicate_policy": "avoid_same_offer",
		"guarantees": [{"slot": 0, "school": "character_primary"}],
	}), 3, content_type)
	_add_choice_grid(offer, Vector2(270, 190), func(content_id): _buy_content(content_id))

	var leave = _make_pixel_button("Leave Shop", Vector2(520, 590), Vector2(240, 56))
	leave.pressed.connect(on_done)
	ui_root.add_child(leave)


func _buy_content(content_id: String) -> void:
	var price = 120 + run_context.floor * 35
	if not run_context.spend_gold(price):
		_show_toast("Not enough gold")
		return
	_grant_content(content_id)
	_show_toast("Purchased")


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
	if content_id.begins_with("weapon."):
		run_context.add_weapon(content_id)
	elif content_id.begins_with("magic."):
		run_context.add_magic(content_id)
	elif content_id.begins_with("item."):
		run_context.add_item(content_id)


func _start_combat() -> void:
	screen = "combat"
	_clear_screen()
	_add_background_path("res://assets/art/map/backgrounds/chapter_1_route_background.png")
	_add_overlay(Color(0.06, 0.05, 0.035, 0.18))
	combat_layer = Control.new()
	combat_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(combat_layer)
	combat_fx_layer = Control.new()
	combat_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.add_child(combat_fx_layer)

	player_max_hp = 110.0 + run_context.inventory["items"].size() * 10.0
	player_hp = player_max_hp
	player_max_mana = 80.0 + run_context.inventory["magics"].size() * 25.0
	player_mana = player_max_mana
	player_mana_regen = 12.0
	player_pos = Vector2(640, 410)
	player_attack_timer = 0.35
	mob_spawn_timer = 0.1
	combat_elapsed = 0.0
	boss_spawned = false
	boss_enemy = {}
	boss_ability_timer = 8.0
	boss_cast_timer = 0.0
	magic_cooldowns = [0.0, 0.0, 0.0, 0.0]

	combat_player_sprite = _make_sprite("res://assets/art/source/potato_hero_idle_handless/idle-1.png", Vector2(86, 86))
	combat_layer.add_child(combat_player_sprite)
	_update_sprite_position(combat_player_sprite, player_pos)
	_build_weapon_sprites()
	_add_combat_hud()


func _add_combat_hud() -> void:
	combat_hud_label = _make_label("", 20, Color(1.0, 0.92, 0.68), HORIZONTAL_ALIGNMENT_LEFT)
	combat_hud_label.position = Vector2(32, 26)
	combat_hud_label.size = Vector2(720, 34)
	ui_root.add_child(combat_hud_label)
	combat_hint_label = _make_label("Move: WASD / Arrows    Magic: Q E R F", 18, Color(1.0, 0.92, 0.68), HORIZONTAL_ALIGNMENT_RIGHT)
	combat_hint_label.position = Vector2(720, 28)
	combat_hint_label.size = Vector2(520, 30)
	ui_root.add_child(combat_hint_label)
	combat_player_hp_bar = _make_bar(Vector2(32, 68), Vector2(350, 22), Color(0.58, 0.88, 0.28))
	ui_root.add_child(combat_player_hp_bar)
	combat_mana_bar = _make_bar(Vector2(32, 96), Vector2(350, 16), Color(0.35, 0.55, 1.0))
	ui_root.add_child(combat_mana_bar)
	combat_boss_hp_bar = _make_bar(Vector2(430, 68), Vector2(420, 18), Color(0.92, 0.24, 0.28))
	combat_boss_hp_bar.visible = false
	ui_root.add_child(combat_boss_hp_bar)
	var keys = ["Q", "E", "R", "F"]
	for i in range(4):
		var slot = _make_label(keys[i], 18, Color(0.95, 0.88, 0.68), HORIZONTAL_ALIGNMENT_CENTER)
		slot.position = Vector2(930 + i * 72, 76)
		slot.size = Vector2(58, 58)
		slot.add_theme_stylebox_override("normal", _style_box(Color(0.08, 0.06, 0.045, 0.86), Color(0.38, 0.54, 1.0, 0.8), 2, 6))
		ui_root.add_child(slot)
		magic_slot_nodes.append(slot)


func _update_combat(delta: float) -> void:
	combat_elapsed += delta
	idle_time += delta
	player_mana = min(player_max_mana, player_mana + player_mana_regen * delta)
	_update_player_movement(delta)
	_update_player_attack(delta)
	_update_magic_input()
	_update_magic_cooldowns(delta)
	_update_spawning(delta)
	_update_enemies(delta)
	_update_boss_ability(delta)
	_update_boss_projectiles(delta)
	_update_player_visual()
	_update_weapon_visuals()
	_update_combat_hud()
	if player_hp <= 0.0:
		_show_defeat_screen()


func _update_player_movement(delta: float) -> void:
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	is_player_moving = input_vector.length() > 0.01
	if is_player_moving:
		input_vector = input_vector.normalized()
		if abs(input_vector.x) > 0.05:
			facing_direction = -1 if input_vector.x > 0.0 else 1
		player_pos += input_vector * PLAYER_SPEED * delta
		player_pos.x = clamp(player_pos.x, COMBAT_ARENA_RECT.position.x, COMBAT_ARENA_RECT.position.x + COMBAT_ARENA_RECT.size.x)
		player_pos.y = clamp(player_pos.y, COMBAT_ARENA_RECT.position.y, COMBAT_ARENA_RECT.position.y + COMBAT_ARENA_RECT.size.y)


func _update_player_visual() -> void:
	if combat_player_sprite == null:
		return
	var frame = int(floor(idle_time * (9.0 if is_player_moving else 5.0))) % 4 + 1
	var path = "res://assets/art/source/potato_hero_walk_handless/right-%d.png" % frame if is_player_moving else "res://assets/art/source/potato_hero_idle_handless/idle-%d.png" % frame
	combat_player_sprite.texture = _load_texture(path)
	combat_player_sprite.flip_h = facing_direction > 0
	var pulse = sin(idle_time * (11.0 if is_player_moving else 5.0))
	combat_player_sprite.scale = Vector2(1.0 + pulse * 0.035, 1.0 - pulse * 0.03)
	combat_player_sprite.rotation_degrees = 0.0
	_update_sprite_position(combat_player_sprite, player_pos)


func _build_weapon_sprites() -> void:
	for weapon in combat_weapon_sprites:
		if is_instance_valid(weapon):
			weapon.queue_free()
	combat_weapon_sprites.clear()
	var count = _equipped_weapon_count()
	for i in range(count):
		var weapon = _make_sprite("res://assets/art/sprites/weapons/fries.png", Vector2(92, 92))
		combat_layer.add_child(weapon)
		combat_weapon_sprites.append(weapon)


func _update_weapon_visuals() -> void:
	var offsets = _weapon_layout_offsets(combat_weapon_sprites.size())
	for i in range(combat_weapon_sprites.size()):
		var weapon: TextureRect = combat_weapon_sprites[i]
		var offset: Vector2 = offsets[i]
		offset.x *= -1 if facing_direction > 0 else 1
		weapon.flip_h = facing_direction > 0
		weapon.rotation_degrees = (-24.0 + i * 8.0) * (-1 if facing_direction > 0 else 1)
		_update_sprite_position(weapon, player_pos + offset)


func _weapon_layout_offsets(count: int) -> Array:
	var base = [Vector2(72, 2), Vector2(-72, 2), Vector2(48, -48), Vector2(-48, -48)]
	return base.slice(0, clamp(count, 0, base.size()))


func _update_player_attack(delta: float) -> void:
	player_attack_timer -= delta
	if player_attack_timer > 0.0:
		return
	player_attack_timer = WEAPON_ATTACK_SECONDS
	var target = _nearest_enemy()
	if target.is_empty():
		return
	var attack_vector: Vector2 = target["pos"] - player_pos
	if attack_vector.length() > WEAPON_RANGE:
		return
	var damage = 22.0 + max(0, _equipped_weapon_count() - 1) * 10.0
	target["hp"] = float(target.get("hp", 1.0)) - damage
	_flash_attack(target["pos"], attack_vector)
	if float(target["hp"]) <= 0.0:
		_kill_enemy(target)


func _update_magic_input() -> void:
	for i in range(4):
		if Input.is_action_just_pressed("cast_magic_%d" % i):
			_try_cast_magic(i)


func _try_cast_magic(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= run_context.equipped_magics.size():
		return
	if run_context.equipped_magics[slot_index] == null:
		_show_toast("No magic in slot %d" % (slot_index + 1))
		return
	if magic_cooldowns[slot_index] > 0.0:
		return
	var cost = 28.0
	if player_mana < cost:
		_show_toast("Not enough mana")
		return
	player_mana -= cost
	magic_cooldowns[slot_index] = 5.0
	for enemy in enemies.duplicate():
		if player_pos.distance_to(enemy["pos"]) <= 240.0:
			enemy["hp"] = float(enemy.get("hp", 1.0)) - 52.0
			_flash_magic(enemy["pos"])
			if float(enemy["hp"]) <= 0.0:
				_kill_enemy(enemy)


func _update_magic_cooldowns(delta: float) -> void:
	for i in range(magic_cooldowns.size()):
		magic_cooldowns[i] = max(0.0, magic_cooldowns[i] - delta)


func _update_spawning(delta: float) -> void:
	if not boss_spawned and combat_elapsed >= MOB_PHASE_SECONDS:
		_spawn_boss()
	mob_spawn_timer -= delta
	if mob_spawn_timer <= 0.0 and enemies.size() < 14:
		mob_spawn_timer = MOB_SPAWN_SECONDS
		_spawn_mob()


func _spawn_mob() -> void:
	var ids = ["monster.metamorph.sprouting_potato", "monster.metamorph.mushroom_spore", "monster.metamorph.bomb_fruitling"]
	var id = ids[randi_range(0, ids.size() - 1)]
	var entry = registry.get_entry("monster", id)
	var stats: Dictionary = entry.get("stats", {})
	var node = _make_sprite(_content_sprite_path(entry), Vector2(58, 58))
	combat_layer.add_child(node)
	var pos = _random_edge_position()
	var enemy = {
		"id": id,
		"node": node,
		"pos": pos,
		"hp": float(stats.get("max_health", 40)),
		"attack": float(stats.get("attack", 5)),
		"speed": float(stats.get("move_speed", 65)),
		"touch_timer": 0.0,
		"frames": _enemy_frame_paths(id),
		"frame_index": 0,
		"frame_timer": 0.0,
		"anim_time": 0.0,
		"is_boss": false,
	}
	enemies.append(enemy)
	_update_sprite_position(node, pos)


func _spawn_boss() -> void:
	boss_spawned = true
	var entry = registry.get_entry("boss", "boss.demo_pollution_source")
	var stats: Dictionary = entry.get("stats", {})
	var node = _make_sprite("res://assets/art/source/boss_pollution_source/boss_pollution_source-1.png", Vector2(132, 132))
	combat_layer.add_child(node)
	boss_enemy = {
		"id": "boss.demo_pollution_source",
		"node": node,
		"pos": Vector2(640, 176),
		"hp": float(stats.get("max_health", 300)),
		"max_hp": float(stats.get("max_health", 300)),
		"attack": float(stats.get("attack", 10)),
		"speed": float(stats.get("move_speed", 80)),
		"touch_timer": 0.0,
		"frames": _enemy_frame_paths("boss.demo_pollution_source"),
		"frame_index": 0,
		"frame_timer": 0.0,
		"anim_time": 0.0,
		"is_boss": true,
	}
	enemies.append(boss_enemy)
	combat_boss_sprite = node
	_update_sprite_position(node, boss_enemy["pos"])


func _update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		if not enemy.has("node") or not is_instance_valid(enemy["node"]):
			enemies.erase(enemy)
			continue
		var pos: Vector2 = enemy["pos"]
		var direction = player_pos - pos
		var distance = direction.length()
		if distance > 8.0:
			pos += direction.normalized() * float(enemy.get("speed", 60.0)) * delta
		enemy["pos"] = pos
		_update_sprite_position(enemy["node"], pos)
		_update_enemy_animation(enemy, delta)
		enemy["touch_timer"] = max(0.0, float(enemy.get("touch_timer", 0.0)) - delta)
		if distance <= ENEMY_TOUCH_RADIUS and float(enemy["touch_timer"]) <= 0.0:
			var damage = float(enemy.get("attack", 3.0))
			player_hp -= damage
			enemy["touch_timer"] = 0.85
			_float_text("-%d" % int(damage), player_pos + Vector2(0, -52), Color(1.0, 0.36, 0.28))


func _update_enemy_animation(enemy: Dictionary, delta: float) -> void:
	var node: TextureRect = enemy.get("node", null)
	if node == null or not is_instance_valid(node):
		return
	var pos: Vector2 = enemy.get("pos", Vector2.ZERO)
	node.flip_h = pos.x < player_pos.x
	enemy["anim_time"] = float(enemy.get("anim_time", 0.0)) + delta
	if bool(enemy.get("is_boss", false)) and boss_cast_timer > 0.0:
		var cast_frames = [
			"res://assets/art/source/boss_pollution_source/boss_pollution_source-7.png",
			"res://assets/art/source/boss_pollution_source/boss_pollution_source-8.png",
			"res://assets/art/source/boss_pollution_source/boss_pollution_source-9.png",
		]
		node.texture = _load_texture(cast_frames[int(floor(float(enemy["anim_time"]) * 12.0)) % cast_frames.size()])
		var cast_pulse = sin(float(enemy["anim_time"]) * 18.0)
		node.scale = Vector2(1.18 + cast_pulse * 0.08, 1.12 - cast_pulse * 0.04)
		node.rotation_degrees = 0.0
		return
	var frames: Array = enemy.get("frames", [])
	if not frames.is_empty():
		enemy["frame_timer"] = float(enemy.get("frame_timer", 0.0)) - delta
		if float(enemy["frame_timer"]) <= 0.0:
			enemy["frame_timer"] = 0.16 if not bool(enemy.get("is_boss", false)) else 0.11
			enemy["frame_index"] = (int(enemy.get("frame_index", 0)) + 1) % frames.size()
			node.texture = _load_texture(String(frames[int(enemy["frame_index"])]))
	var pulse = sin(float(enemy["anim_time"]) * (5.0 if not bool(enemy.get("is_boss", false)) else 3.0))
	node.scale = Vector2(1.0 + pulse * 0.035, 1.0 - pulse * 0.025)
	node.rotation_degrees = 0.0


func _update_boss_ability(delta: float) -> void:
	if not boss_spawned or boss_enemy.is_empty() or screen != "combat":
		return
	boss_ability_timer -= delta
	boss_cast_timer = max(0.0, boss_cast_timer - delta)
	if boss_ability_timer <= 0.0:
		boss_ability_timer = 8.0
		boss_cast_timer = 0.65
		_play_boss_cast_motion()
		get_tree().create_timer(0.32).timeout.connect(_spawn_boss_radial_projectiles)


func _play_boss_cast_motion() -> void:
	if combat_boss_sprite == null or not is_instance_valid(combat_boss_sprite) or combat_fx_layer == null:
		return
	combat_boss_sprite.texture = _load_texture("res://assets/art/source/boss_pollution_source/boss_pollution_source-7.png")
	var warning = _make_sprite("res://assets/art/source/enemy_pack_01/boss_pollution_source_warning/boss_pollution_source_warning-1.png", Vector2(96, 96))
	_update_sprite_position(warning, boss_enemy.get("pos", Vector2.ZERO) + Vector2(0, -88))
	combat_fx_layer.add_child(warning)
	var tween = create_tween()
	tween.tween_property(combat_boss_sprite, "scale", Vector2(1.32, 1.18), 0.18)
	tween.tween_property(combat_boss_sprite, "scale", Vector2(1.0, 1.0), 0.28)
	tween.parallel().tween_property(warning, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func(): warning.queue_free())


func _spawn_boss_radial_projectiles() -> void:
	if screen != "combat" or not boss_spawned or boss_enemy.is_empty() or combat_layer == null:
		return
	var center: Vector2 = boss_enemy.get("pos", Vector2.ZERO)
	var damage = float(boss_enemy.get("attack", 10.0))
	for i in range(16):
		var angle = TAU * float(i) / 16.0
		var direction = Vector2(cos(angle), sin(angle))
		var node = _make_sprite("res://assets/art/source/magic_vfx/magic_vfx-2.png", Vector2(34, 34))
		node.modulate = Color(0.85, 0.58, 1.0, 0.95)
		_update_sprite_position(node, center + direction * 72.0)
		combat_layer.add_child(node)
		boss_projectiles.append({
			"node": node,
			"pos": center + direction * 72.0,
			"velocity": direction * 225.0,
			"damage": damage,
			"radius": 18.0,
			"life": 5.0,
			"anim_time": 0.0,
		})


func _update_boss_projectiles(delta: float) -> void:
	for projectile in boss_projectiles.duplicate():
		if not projectile.has("node") or not is_instance_valid(projectile["node"]):
			boss_projectiles.erase(projectile)
			continue
		projectile["life"] = float(projectile.get("life", 0.0)) - delta
		projectile["anim_time"] = float(projectile.get("anim_time", 0.0)) + delta
		projectile["pos"] = projectile["pos"] + projectile["velocity"] * delta
		var node: TextureRect = projectile["node"]
		node.rotation += delta * 7.0
		var pulse = sin(float(projectile["anim_time"]) * 9.0)
		node.scale = Vector2(1.0 + pulse * 0.08, 1.0 + pulse * 0.08)
		_update_sprite_position(node, projectile["pos"])
		var expired = float(projectile["life"]) <= 0.0 or not COMBAT_ARENA_RECT.grow(96.0).has_point(projectile["pos"])
		if not expired and player_pos.distance_to(projectile["pos"]) <= float(projectile["radius"]) + PLAYER_TOUCH_RADIUS:
			player_hp -= float(projectile["damage"])
			_float_text("-%d" % int(projectile["damage"]), player_pos + Vector2(0, -52), Color(1.0, 0.36, 0.28))
			expired = true
		if expired:
			node.queue_free()
			boss_projectiles.erase(projectile)


func _nearest_enemy() -> Dictionary:
	var best: Dictionary = {}
	var best_distance = INF
	for enemy in enemies:
		var distance = player_pos.distance_to(enemy["pos"])
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _kill_enemy(enemy: Dictionary) -> void:
	if enemy.has("node") and is_instance_valid(enemy["node"]):
		enemy["node"].queue_free()
	enemies.erase(enemy)
	if bool(enemy.get("is_boss", false)):
		boss_enemy = {}
		boss_spawned = false
		_finish_combat()


func _finish_combat() -> void:
	if map_flow.advance_area():
		selected_route_id = ""
		active_route = {}
		claimed_route_nodes.clear()
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
	combat_runtime = CombatRuntime.new(registry, event_bus, run_context)
	tick_loop = FixedTickLoop.new(event_bus)
	tick_loop.add_system(combat_runtime)
	_show_starter_screen()


func _update_combat_hud() -> void:
	if combat_player_hp_bar != null:
		combat_player_hp_bar.max_value = player_max_hp
		combat_player_hp_bar.value = max(0.0, player_hp)
	if combat_mana_bar != null:
		combat_mana_bar.max_value = max(1.0, player_max_mana)
		combat_mana_bar.value = clamp(player_mana, 0.0, player_max_mana)
	if combat_boss_hp_bar != null:
		combat_boss_hp_bar.visible = boss_spawned and not boss_enemy.is_empty()
		if combat_boss_hp_bar.visible:
			combat_boss_hp_bar.max_value = float(boss_enemy.get("max_hp", 1.0))
			combat_boss_hp_bar.value = max(0.0, float(boss_enemy.get("hp", 0.0)))
	if combat_hud_label != null:
		var phase = "Boss" if boss_spawned else "Mobs"
		combat_hud_label.text = "%s  Floor %d  HP %d/%d  Mana %d/%d  Weapons %d/4" % [
			phase,
			run_context.floor,
			int(max(0.0, player_hp)),
			int(player_max_hp),
			int(player_mana),
			int(player_max_mana),
			_equipped_weapon_count(),
		]
	for i in range(magic_slot_nodes.size()):
		var slot: Label = magic_slot_nodes[i]
		var content = run_context.equipped_magics[i] if i < run_context.equipped_magics.size() else null
		var cd = magic_cooldowns[i] if i < magic_cooldowns.size() else 0.0
		var key = ["Q", "E", "R", "F"][i]
		if content == null:
			slot.text = "%s\n-" % key
			slot.modulate = Color(0.65, 0.65, 0.65, 0.72)
		elif cd > 0.0:
			slot.text = "%s\n%.0f" % [key, cd]
			slot.modulate = Color(0.65, 0.65, 0.9, 0.78)
		else:
			slot.text = "%s\nReady" % key
			slot.modulate = Color.WHITE


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
	toast_label.modulate = Color(1, 1, 1, 1)
	tween.tween_interval(1.2)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	return PlayableUiFactory.make_label(text, font_size, color, alignment)


func _make_pixel_button(text: String, pos: Vector2, size: Vector2) -> Button:
	return PlayableUiFactory.make_pixel_button(text, pos, size)


func _make_bar(position: Vector2, size: Vector2, fill_color: Color) -> ProgressBar:
	return PlayableUiFactory.make_bar(position, size, fill_color)


func _make_sprite(texture_path: String, sprite_size: Vector2) -> TextureRect:
	return PlayableUiFactory.make_sprite(texture_path, sprite_size)


func _update_sprite_position(sprite: Control, world_pos: Vector2) -> void:
	PlayableUiFactory.update_sprite_position(sprite, world_pos)


func _style_box(fill: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	return PlayableUiFactory.style_box(fill, border, border_width, corner_radius)


func _random_edge_position() -> Vector2:
	var side = randi_range(0, 3)
	var rect = COMBAT_ARENA_RECT
	match side:
		0:
			return Vector2(randf_range(rect.position.x, rect.position.x + rect.size.x), rect.position.y)
		1:
			return Vector2(randf_range(rect.position.x, rect.position.x + rect.size.x), rect.position.y + rect.size.y)
		2:
			return Vector2(rect.position.x, randf_range(rect.position.y, rect.position.y + rect.size.y))
		_:
			return Vector2(rect.position.x + rect.size.x, randf_range(rect.position.y, rect.position.y + rect.size.y))


func _flash_attack(target_pos: Vector2, attack_vector: Vector2) -> void:
	if combat_fx_layer == null:
		return
	var fx = _make_sprite("res://assets/art/source/fries_slash/fries_slash-1.png", Vector2(132, 132))
	fx.position = target_pos - fx.size * 0.5
	if attack_vector.length() > 0.01:
		fx.rotation = attack_vector.angle() + PI
	combat_fx_layer.add_child(fx)
	var tween = create_tween()
	tween.tween_property(fx, "modulate:a", 0.0, 0.22)
	tween.finished.connect(func(): fx.queue_free())


func _flash_magic(target_pos: Vector2) -> void:
	if combat_fx_layer == null:
		return
	var fx = _make_sprite("res://assets/art/source/magic_vfx/magic_vfx-1.png", Vector2(96, 96))
	fx.position = target_pos - fx.size * 0.5
	combat_fx_layer.add_child(fx)
	var tween = create_tween()
	tween.tween_property(fx, "scale", Vector2(1.45, 1.45), 0.22)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, 0.22)
	tween.finished.connect(func(): fx.queue_free())


func _float_text(text: String, pos: Vector2, color: Color) -> void:
	if ui_root == null:
		return
	var label = _make_label(text, 22, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = pos - Vector2(70, 20)
	label.size = Vector2(140, 36)
	ui_root.add_child(label)
	floating_texts.append({"node": label, "life": 0.8, "velocity": Vector2(0, -42)})


func _update_floating_texts(delta: float) -> void:
	for item in floating_texts.duplicate():
		if not item.has("node") or not is_instance_valid(item["node"]):
			floating_texts.erase(item)
			continue
		item["life"] = float(item["life"]) - delta
		item["node"].position += item["velocity"] * delta
		item["node"].modulate.a = clamp(float(item["life"]) / 0.8, 0.0, 1.0)
		if float(item["life"]) <= 0.0:
			item["node"].queue_free()
			floating_texts.erase(item)


func _fill_offer_choices(entries: Array, count: int, content_type: String) -> Array:
	var result = entries.duplicate()
	if result.is_empty():
		result = item_pool.build_candidates(run_context, content_type, {})
	if result.is_empty():
		return []
	var i = 0
	while result.size() < count:
		result.append(result[i % result.size()])
		i += 1
	return result.slice(0, count)


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


func _content_sprite_path(entry: Dictionary) -> String:
	return PlayableContentPresenter.content_sprite_path(asset_catalog, entry)


func _enemy_frame_paths(content_id: String) -> Array:
	return PlayableContentPresenter.enemy_frame_paths(content_id)


func _rarity_color(entry: Dictionary) -> Color:
	return PlayableContentPresenter.rarity_color(entry)


func _load_texture(path: String) -> Texture2D:
	return PlayableUiFactory.load_texture(path)


func _ensure_input_actions() -> void:
	PlayableInputActions.ensure_defaults()


func _ensure_action(action_name: String, keycodes: Array) -> void:
	PlayableInputActions.ensure_action(action_name, keycodes)
