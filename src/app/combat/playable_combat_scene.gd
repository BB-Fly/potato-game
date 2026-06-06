class_name PlayableCombatScene
extends Control

signal combat_finished(result: Dictionary)

const PlayableUiFactory = preload("res://src/app/playable/playable_ui_factory.gd")
const PlayableContentPresenter = preload("res://src/app/playable/playable_content_presenter.gd")
const CombatActor = preload("res://src/domain/combat/combat_actor.gd")
const CombatFormula = preload("res://src/domain/combat/combat_formula.gd")
const EffectRunner = preload("res://src/domain/effect/effect_runner.gd")

const PLAYER_IDLE_SHEET_COLUMNS = 2
const PLAYER_IDLE_SHEET_ROWS = 2
const PLAYER_WALK_SHEET_COLUMNS = 4
const PLAYER_WALK_SHEET_ROWS = 4
const PLAYER_WALK_RIGHT_START_FRAME = 8
const VFX_SHEET_COLUMNS = 2
const VFX_SHEET_ROWS = 2

var registry
var run_context
var asset_catalog
var effect_runner
var balance: Dictionary = {}
var arena_rect = Rect2(Vector2(48, 118), Vector2(1184, 560))
var player_speed = 220.0
var player_touch_radius = 24.0
var enemy_touch_radius = 28.0
var mob_phase_seconds = 22.0
var mob_spawn_seconds = 1.7
var max_mobs = 14
var current_weapon_entry: Dictionary = {}
var equipped_weapon_entries: Array = []
var weapon_attack_timers: Array = []
var boss_entry: Dictionary = {}
var boss_ability: Dictionary = {}

var combat_layer: Control
var combat_fx_layer: Control
var combat_hud_layer: Control
var combat_player_sprite: TextureRect
var combat_boss_sprite: TextureRect
var combat_weapon_sprites: Array = []

var player_pos = Vector2.ZERO
var player_actor
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
var combat_session_id = 0
var magic_cooldowns: Array = []
var magic_total_cooldowns: Array = []
var magic_auto_cast_timers: Array = []
var floating_texts: Array = []
var is_finished = false


func setup(p_registry, p_run_context, p_asset_catalog, p_effect_runner = null) -> void:
	registry = p_registry
	run_context = p_run_context
	asset_catalog = p_asset_catalog
	effect_runner = p_effect_runner if p_effect_runner != null else EffectRunner.new(registry)
	balance = registry.get_entry("balance", "balance.playable_combat")
	name = "PlayableCombatScene"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_process(true)
	_start_combat()


func cleanup() -> void:
	is_finished = true
	combat_session_id += 1
	set_process(false)
	enemies.clear()
	boss_projectiles.clear()
	floating_texts.clear()
	combat_weapon_sprites.clear()
	if combat_hud_layer != null and is_instance_valid(combat_hud_layer) and combat_hud_layer.has_method("reset"):
		combat_hud_layer.reset()


func _exit_tree() -> void:
	cleanup()


func _process(delta: float) -> void:
	if not _is_combat_ready():
		return
	_update_combat(delta)
	_update_floating_texts(delta)


func _start_combat() -> void:
	combat_session_id += 1
	is_finished = false
	_clear_local_state()
	_load_runtime_balance()
	_add_background_path(_string_from(_section("scene"), "background_path", "res://assets/art/map/backgrounds/chapter_1_route_background.png"))
	_add_overlay(_color_from(_section("scene"), "overlay_color", Color(0.06, 0.05, 0.035, 0.18)))

	combat_layer = Control.new()
	combat_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(combat_layer)

	combat_fx_layer = Control.new()
	combat_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(combat_fx_layer)

	var character = registry.get_entry("character", run_context.character_id)
	var player_cfg = _section("player")
	player_actor = _make_actor("player", run_context.character_id, character, character.get("base_stats", {}))
	_apply_run_loadout_effects(player_actor)
	_sync_player_resources_from_actor()
	player_mana_regen = player_actor.get_stat("mana_regen")
	player_speed = player_actor.get_stat("move_speed")
	player_pos = _vector_from(player_cfg, "start_position", Vector2(640, 410))
	player_attack_timer = _float_from(player_cfg, "initial_attack_delay_seconds", 0.35)
	_reset_weapon_attack_timers(player_attack_timer)
	mob_spawn_timer = _float_from(_section("spawning"), "initial_mob_spawn_seconds", 0.1)
	combat_elapsed = 0.0
	boss_spawned = false
	boss_enemy = {}
	boss_ability_timer = _float_from(boss_ability, "cooldown_seconds", 8.0)
	boss_cast_timer = 0.0
	magic_cooldowns.clear()
	magic_cooldowns.resize(_int_from(_section("magic"), "slot_count", 4))
	magic_cooldowns.fill(0.0)
	magic_total_cooldowns.clear()
	magic_total_cooldowns.resize(_int_from(_section("magic"), "slot_count", 4))
	magic_total_cooldowns.fill(0.0)
	magic_auto_cast_timers.clear()
	magic_auto_cast_timers.resize(_int_from(_section("magic"), "slot_count", 4))
	magic_auto_cast_timers.fill(0.0)
	_reset_magic_auto_cast_timers()

	combat_player_sprite = _make_frame_sprite(_player_frame_ref(false, 0), Vector2(86, 86))
	combat_layer.add_child(combat_player_sprite)
	_update_sprite_position(combat_player_sprite, player_pos)
	_build_weapon_sprites()
	_add_combat_hud()


func _clear_local_state() -> void:
	for child in get_children():
		if child.name == "CombatHud":
			combat_hud_layer = child
			continue
		remove_child(child)
		_queue_free_if_valid(child)
	enemies.clear()
	boss_projectiles.clear()
	floating_texts.clear()
	combat_weapon_sprites.clear()
	equipped_weapon_entries.clear()
	weapon_attack_timers.clear()
	player_actor = null
	combat_layer = null
	combat_fx_layer = null
	combat_player_sprite = null
	combat_boss_sprite = null
	if combat_hud_layer != null and is_instance_valid(combat_hud_layer) and combat_hud_layer.has_method("reset"):
		combat_hud_layer.reset()


func _is_combat_ready() -> bool:
	return not is_finished and combat_layer != null and is_instance_valid(combat_layer)


func _is_current_combat_session(session_id: int) -> bool:
	return session_id == combat_session_id and _is_combat_ready()


func _is_combat_fx_ready() -> bool:
	return _is_combat_ready() and combat_fx_layer != null and is_instance_valid(combat_fx_layer)


func _queue_free_if_valid(node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()


func _load_runtime_balance() -> void:
	var arena = _section("arena")
	arena_rect = Rect2(
		Vector2(_float_from(arena, "x", 48.0), _float_from(arena, "y", 118.0)),
		Vector2(_float_from(arena, "width", 1184.0), _float_from(arena, "height", 560.0))
	)
	player_touch_radius = _float_from(_section("player"), "touch_radius", 24.0)
	enemy_touch_radius = _float_from(_section("enemies"), "touch_radius", 28.0)
	var spawning = _section("spawning")
	mob_phase_seconds = _float_from(spawning, "mob_phase_seconds", 22.0)
	var count_multiplier = _floor_count_multiplier()
	mob_spawn_seconds = max(0.1, _float_from(spawning, "mob_spawn_seconds", 1.7) / count_multiplier)
	max_mobs = max(1, int(round(float(_int_from(spawning, "max_mobs", 14)) * count_multiplier)))
	equipped_weapon_entries = _equipped_entries("weapon")
	current_weapon_entry = equipped_weapon_entries[0] if not equipped_weapon_entries.is_empty() else {}
	boss_entry = registry.get_entry("boss", _string_from(_section("boss"), "id", "boss.demo_pollution_source"))
	boss_ability = _first_entry(boss_entry.get("abilities", []), "radial_projectiles")


func _section(key: String) -> Dictionary:
	var value = balance.get(key, {})
	return value if typeof(value) == TYPE_DICTIONARY else {}


func _float_from(source: Dictionary, key: String, default_value: float) -> float:
	return float(source.get(key, default_value))


func _int_from(source: Dictionary, key: String, default_value: int) -> int:
	return int(source.get(key, default_value))


func _string_from(source: Dictionary, key: String, default_value: String) -> String:
	return String(source.get(key, default_value))


func _vector_from(source: Dictionary, key: String, default_value: Vector2) -> Vector2:
	var value = source.get(key, {})
	if typeof(value) != TYPE_DICTIONARY:
		return default_value
	return Vector2(float(value.get("x", default_value.x)), float(value.get("y", default_value.y)))


func _color_from(source: Dictionary, key: String, default_value: Color) -> Color:
	var value = source.get(key, [])
	if typeof(value) != TYPE_ARRAY or value.size() < 4:
		return default_value
	return Color(float(value[0]), float(value[1]), float(value[2]), float(value[3]))


func _floor_count_multiplier() -> float:
	var floor_rules = _section("scaling").get("floor_multipliers", {})
	if typeof(floor_rules) != TYPE_DICTIONARY:
		return 1.0
	var rule = floor_rules.get(str(run_context.floor), {})
	if typeof(rule) != TYPE_DICTIONARY:
		return 1.0
	return max(0.1, float(rule.get("count", 1.0)))


func _first_entry(entries: Array, id: String) -> Dictionary:
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY and String(entry.get("id", "")) == id:
			return entry
	return entries[0] if not entries.is_empty() and typeof(entries[0]) == TYPE_DICTIONARY else {}


func _first_equipped_entry(content_type: String) -> Dictionary:
	var entries = _equipped_entries(content_type)
	return entries[0] if not entries.is_empty() else {}


func _equipped_entries(content_type: String) -> Array:
	var slots: Array = []
	if content_type == "weapon":
		slots = run_context.equipped_weapons
	elif content_type == "magic":
		slots = run_context.equipped_magics
	var entries: Array = []
	for content_id in slots:
		if content_id == null:
			continue
		var entry = registry.get_entry(content_type, String(content_id))
		if not entry.is_empty():
			entries.append(entry)
	return entries


func _runtime_rules() -> Dictionary:
	return {
		"stat_rules": _section("stat_rules"),
		"operation_aliases": _section("operation_aliases"),
		"formulas": _section("formulas"),
	}


func _make_actor(actor_type: String, content_id: String, definition: Dictionary, base_stats: Dictionary):
	var actor = CombatActor.new()
	actor.initialize(registry, actor_type, content_id, definition, base_stats, _runtime_rules())
	return actor


func _apply_run_loadout_effects(actor) -> void:
	if actor == null:
		return
	for item_id in run_context.inventory["items"]:
		var item = registry.get_entry("item", String(item_id))
		_run_configured_effects(item.get("effects", []), actor, actor, String(item_id), {})


func _sync_player_resources_from_actor() -> void:
	if player_actor == null:
		return
	player_hp = player_actor.current_health
	player_max_hp = player_actor.max_health
	player_mana = player_actor.current_mana
	player_max_mana = player_actor.max_mana
	player_mana_regen = player_actor.get_stat("mana_regen")
	player_speed = player_actor.get_stat("move_speed")


func _sync_enemy_resource_cache(enemy: Dictionary) -> void:
	var actor = enemy.get("actor", null)
	if actor == null:
		return
	enemy["hp"] = actor.current_health
	enemy["max_hp"] = actor.max_health
	enemy["attack"] = actor.get_stat("attack")
	enemy["speed"] = actor.get_stat("move_speed")


func _damage_player(raw_damage: float, source_actor, damage_type: String) -> Dictionary:
	if player_actor == null:
		player_hp = max(0.0, player_hp - raw_damage)
		return {"amount": int(ceil(raw_damage)), "hp": player_hp}
	var result = player_actor.take_damage(raw_damage, source_actor, {"damage_type": damage_type})
	_sync_player_resources_from_actor()
	return result


func _run_configured_effects(effects: Array, source_actor, target_actor, source_id: String, extra_context: Dictionary = {}) -> void:
	if effect_runner == null:
		return
	var context = {
		"self": source_actor,
		"source": source_actor,
		"target": target_actor,
		"hit_target": target_actor,
		"run_context": run_context,
		"source_id": source_id,
	}
	for key in extra_context.keys():
		context[key] = extra_context[key]
	effect_runner.run_effects(effects, context)


func _run_triggered_effects(effect_groups: Array, trigger: String, source_actor, target_actor, source_id: String, extra_context: Dictionary = {}) -> void:
	for effect_group in effect_groups:
		if typeof(effect_group) != TYPE_DICTIONARY:
			continue
		if String(effect_group.get("trigger", "")) != trigger:
			continue
		_run_configured_effects(effect_group.get("actions", []), source_actor, target_actor, source_id, extra_context)


func _end_combat(victory: bool) -> void:
	if is_finished:
		return
	is_finished = true
	combat_session_id += 1
	set_process(false)
	combat_finished.emit({
		"victory": victory,
		"elapsed": combat_elapsed,
		"player_hp": max(0.0, player_hp),
	})


func _add_combat_hud() -> void:
	if combat_hud_layer == null or not is_instance_valid(combat_hud_layer):
		combat_hud_layer = get_node_or_null("CombatHud") as Control
	if combat_hud_layer == null:
		push_error("Combat HUD scene is missing from combat_scene.tscn.")
		return
	combat_hud_layer.visible = true
	combat_hud_layer.z_index = 3000
	if combat_hud_layer.has_method("setup"):
		combat_hud_layer.setup(
			registry,
			run_context,
			asset_catalog,
			balance,
			player_max_hp,
			player_max_mana,
			_int_from(_section("magic"), "slot_count", 4)
		)


func _update_combat(delta: float) -> void:
	if not _is_combat_ready():
		return
	combat_elapsed += delta
	idle_time += delta
	if player_actor != null:
		player_actor.tick(delta, effect_runner, {
			"self": player_actor,
			"source": player_actor,
			"target": player_actor,
			"run_context": run_context,
			"source_id": player_actor.content_id,
		})
		_sync_player_resources_from_actor()
	_update_player_movement(delta)
	_update_player_attack(delta)
	if is_finished:
		return
	_update_magic_input()
	_update_magic_cooldowns(delta)
	_update_magic_auto_cast(delta)
	_update_spawning(delta)
	_update_enemies(delta)
	if is_finished:
		return
	_update_boss_ability(delta)
	_update_boss_projectiles(delta)
	if is_finished:
		return
	_update_player_visual()
	_update_weapon_visuals()
	_sync_player_resources_from_actor()
	_update_combat_hud(delta)
	if player_actor != null and player_actor.is_dead():
		_end_combat(false)


func _update_player_movement(delta: float) -> void:
	if player_actor != null:
		player_speed = player_actor.get_stat("move_speed")
		if player_actor.has_behavior_lock("movement"):
			is_player_moving = false
			return
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	is_player_moving = input_vector.length() > 0.01
	if is_player_moving:
		input_vector = input_vector.normalized()
		if abs(input_vector.x) > 0.05:
			facing_direction = -1 if input_vector.x > 0.0 else 1
		player_pos += input_vector * player_speed * delta
		player_pos.x = clamp(player_pos.x, arena_rect.position.x, arena_rect.position.x + arena_rect.size.x)
		player_pos.y = clamp(player_pos.y, arena_rect.position.y, arena_rect.position.y + arena_rect.size.y)


func _update_player_visual() -> void:
	if combat_player_sprite == null:
		return
	var frame = int(floor(idle_time * (9.0 if is_player_moving else 5.0))) % 4
	combat_player_sprite.texture = _frame_texture(_player_frame_ref(is_player_moving, frame))
	combat_player_sprite.flip_h = facing_direction > 0
	var pulse = sin(idle_time * (11.0 if is_player_moving else 5.0))
	combat_player_sprite.scale = Vector2(1.0 + pulse * 0.035, 1.0 - pulse * 0.03)
	combat_player_sprite.rotation_degrees = 0.0
	_update_sprite_position(combat_player_sprite, player_pos)


func _build_weapon_sprites() -> void:
	if combat_layer == null or not is_instance_valid(combat_layer):
		return
	for weapon in combat_weapon_sprites:
		_queue_free_if_valid(weapon)
	combat_weapon_sprites.clear()
	var count = _equipped_weapon_count()
	var weapon_cfg = _section("weapon")
	var sprite_size = _vector_from(weapon_cfg, "sprite_size", Vector2(92, 92))
	for i in range(count):
		var weapon_entry = equipped_weapon_entries[i] if i < equipped_weapon_entries.size() else {}
		var weapon = _make_sprite(_content_sprite_path(weapon_entry) if not weapon_entry.is_empty() else "res://assets/art/sprites/weapons/fries.png", sprite_size)
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
		if combat_player_sprite != null and is_instance_valid(combat_player_sprite):
			weapon.z_index = combat_player_sprite.z_index + 2


func _weapon_layout_offsets(count: int) -> Array:
	var base: Array = []
	for item in _section("weapon").get("layout_offsets", []):
		if typeof(item) == TYPE_DICTIONARY:
			base.append(Vector2(float(item.get("x", 0.0)), float(item.get("y", 0.0))))
	if base.is_empty():
		base = [Vector2(72, 2), Vector2(-72, 2), Vector2(48, -48), Vector2(-48, -48)]
	return base.slice(0, clamp(count, 0, base.size()))


func _update_player_attack(delta: float) -> void:
	if player_actor != null and player_actor.has_behavior_lock("attack"):
		return
	if equipped_weapon_entries.is_empty():
		return
	while weapon_attack_timers.size() < equipped_weapon_entries.size():
		weapon_attack_timers.append(_float_from(_section("player"), "initial_attack_delay_seconds", 0.35))
	for i in range(equipped_weapon_entries.size()):
		weapon_attack_timers[i] = float(weapon_attack_timers[i]) - delta
		if float(weapon_attack_timers[i]) <= 0.0:
			var weapon_entry: Dictionary = equipped_weapon_entries[i]
			weapon_attack_timers[i] = _weapon_attack_seconds(weapon_entry)
			_perform_weapon_attack(weapon_entry)


func _perform_weapon_attack(weapon_entry: Dictionary) -> void:
	var target = _nearest_enemy()
	if target.is_empty():
		return
	var attack_vector: Vector2 = target["pos"] - player_pos
	if attack_vector.length() > _weapon_range(weapon_entry):
		return
	var target_actor = target.get("actor", null)
	if target_actor == null:
		return
	var damage_result = _weapon_damage(target_actor, weapon_entry)
	var applied_damage = target_actor.take_damage(float(damage_result.get("amount", 0.0)), player_actor, {"damage_type": "weapon"})
	_sync_enemy_resource_cache(target)
	_float_damage_text(int(applied_damage.get("amount", 0)), target["pos"] + Vector2(0, -34))
	_flash_attack(target["pos"], attack_vector)
	_run_triggered_effects(
		weapon_entry.get("passive_effects", []),
		"on_hit",
		player_actor,
		target_actor,
		String(weapon_entry.get("id", "")),
		{"damage_result": damage_result}
	)
	_sync_enemy_resource_cache(target)
	if target_actor.is_dead():
		_kill_enemy(target)


func _reset_weapon_attack_timers(initial_delay: float) -> void:
	weapon_attack_timers.clear()
	for _entry in equipped_weapon_entries:
		weapon_attack_timers.append(initial_delay)


func _weapon_attack_seconds(weapon_entry: Dictionary) -> float:
	return CombatFormula.attack_interval_seconds(player_actor, weapon_entry, _section("formulas"))


func _weapon_range(weapon_entry: Dictionary) -> float:
	return float(weapon_entry.get("range", _float_from(_section("weapon"), "default_range", 188.0)))


func _weapon_damage(target_actor, weapon_entry: Dictionary) -> Dictionary:
	return CombatFormula.weapon_damage(player_actor, target_actor, weapon_entry, run_context.rng, _section("formulas"))


func _update_magic_input() -> void:
	for i in range(4):
		if Input.is_action_just_pressed("cast_magic_%d" % i):
			_try_cast_magic(i)


func _try_cast_magic(slot_index: int, options: Dictionary = {}) -> bool:
	if slot_index < 0 or slot_index >= run_context.equipped_magics.size():
		return false
	if slot_index >= magic_cooldowns.size():
		return false
	var is_auto = bool(options.get("auto", false))
	var is_free = bool(options.get("free", false))
	if run_context.equipped_magics[slot_index] == null:
		if not is_auto:
			_spell_popup(slot_index, false)
			_show_toast("No magic in slot %d" % (slot_index + 1))
		return false
	if player_actor == null or player_actor.has_behavior_lock("cast"):
		if not is_auto:
			_spell_popup(slot_index, false)
		return false
	if magic_cooldowns[slot_index] > 0.0:
		if not is_auto:
			_spell_popup(slot_index, false)
		return false
	var magic_entry = registry.get_entry("magic", String(run_context.equipped_magics[slot_index]))
	var effect: Dictionary = magic_entry.get("combat_effect", {})
	var magic_cfg = _section("magic")
	var cost = float(magic_entry.get("mana_cost", _float_from(magic_cfg, "default_mana_cost", 28.0)))
	var energy_cost = float(magic_entry.get("energy_cost", 0.0))
	if not is_free and (player_actor.current_mana < cost or player_actor.current_energy < energy_cost):
		if not is_auto:
			_spell_popup(slot_index, false)
			_show_toast("Not enough mana")
		return false
	if not is_free:
		player_actor.spend_mana(cost)
		player_actor.current_energy = max(0.0, player_actor.current_energy - energy_cost)
	_sync_player_resources_from_actor()
	var cooldown = max(0.1, CombatFormula.cooldown_seconds(player_actor, magic_entry, _section("formulas")))
	magic_cooldowns[slot_index] = cooldown
	magic_total_cooldowns[slot_index] = cooldown
	_spell_popup(slot_index, true)
	_run_configured_effects(magic_entry.get("effects", []), player_actor, player_actor, String(magic_entry.get("id", "")), {})
	var range = _float_from(effect, "range", _float_from(magic_cfg, "default_range", 240.0))
	for enemy in enemies.duplicate():
		var target_actor = enemy.get("actor", null)
		if target_actor == null:
			continue
		if player_pos.distance_to(enemy["pos"]) <= range:
			var damage_result = CombatFormula.magic_damage(player_actor, target_actor, magic_entry, _section("formulas"))
			var applied_damage = target_actor.take_damage(float(damage_result.get("amount", 0.0)), player_actor, {"damage_type": "spell"})
			_sync_enemy_resource_cache(enemy)
			_float_damage_text(int(applied_damage.get("amount", 0)), enemy["pos"] + Vector2(0, -34))
			_flash_magic(enemy["pos"])
			if target_actor.is_dead():
				_kill_enemy(enemy)
	return true


func _update_magic_cooldowns(delta: float) -> void:
	for i in range(magic_cooldowns.size()):
		magic_cooldowns[i] = max(0.0, magic_cooldowns[i] - delta)


func _reset_magic_auto_cast_timers() -> void:
	for i in range(magic_auto_cast_timers.size()):
		magic_auto_cast_timers[i] = _magic_auto_cast_interval_seconds(i)


func _update_magic_auto_cast(delta: float) -> void:
	for i in range(magic_auto_cast_timers.size()):
		var interval = _magic_auto_cast_interval_seconds(i)
		if interval <= 0.0:
			continue
		magic_auto_cast_timers[i] = max(0.0, float(magic_auto_cast_timers[i]) - delta)
		if float(magic_auto_cast_timers[i]) <= 0.0:
			magic_auto_cast_timers[i] = interval
			var magic_entry = registry.get_entry("magic", String(run_context.equipped_magics[i]))
			_try_cast_magic(i, {
				"auto": true,
				"free": bool(magic_entry.get("auto_cast_is_free", false)),
			})


func _magic_auto_cast_interval_seconds(slot_index: int) -> float:
	if slot_index < 0 or slot_index >= run_context.equipped_magics.size():
		return 0.0
	if run_context.equipped_magics[slot_index] == null:
		return 0.0
	var magic_entry = registry.get_entry("magic", String(run_context.equipped_magics[slot_index]))
	var frames = int(magic_entry.get("auto_cast_interval_frames", 0))
	return max(0.0, float(frames) / 60.0)


func _update_spawning(delta: float) -> void:
	if not _is_combat_ready():
		return
	if not boss_spawned and combat_elapsed >= mob_phase_seconds:
		_spawn_boss()
	mob_spawn_timer -= delta
	if mob_spawn_timer <= 0.0 and enemies.size() < max_mobs:
		mob_spawn_timer = mob_spawn_seconds
		_spawn_mob()


func _spawn_mob() -> void:
	if not _is_combat_ready():
		return
	var ids: Array = _section("spawning").get("fallback_mob_ids", [])
	if ids.is_empty():
		ids = ["monster.metamorph.sprouting_potato", "monster.metamorph.mushroom_spore", "monster.metamorph.bomb_fruitling"]
	var id = _pick_mob_id(ids)
	var entry = registry.get_entry("monster", id)
	var default_stats: Dictionary = _section("enemies").get("default_stats", {})
	var stats: Dictionary = CombatFormula.scaled_stats(entry if not entry.is_empty() else {"stats": default_stats}, run_context.floor, _section("scaling"), "monster")
	var actor = _make_actor("monster", id, entry, stats)
	var node = _make_frame_sprite(_first_frame_ref(entry), Vector2(58, 58))
	combat_layer.add_child(node)
	var pos = _random_edge_position()
	var enemy = {
		"id": id,
		"actor": actor,
		"node": node,
		"pos": pos,
		"hp": actor.current_health,
		"max_hp": actor.max_health,
		"attack": actor.get_stat("attack"),
		"speed": actor.get_stat("move_speed"),
		"touch_timer": 0.0,
		"frames": _content_frame_refs(entry),
		"frame_index": 0,
		"frame_timer": 0.0,
		"anim_time": 0.0,
		"is_boss": false,
		"session_id": combat_session_id,
	}
	enemies.append(enemy)
	_update_sprite_position(node, pos)


func _pick_mob_id(ids: Array) -> String:
	var candidates: Array = []
	for raw_id in ids:
		var id = String(raw_id)
		var entry = registry.get_entry("monster", id)
		if entry.is_empty():
			continue
		var spawn = entry.get("spawn", {})
		if typeof(spawn) != TYPE_DICTIONARY:
			spawn = {}
		if run_context.floor < int(spawn.get("first_floor", 1)):
			continue
		var max_simultaneous = int(spawn.get("max_simultaneous", 0))
		if max_simultaneous > 0 and _active_enemy_count(id) >= max_simultaneous:
			continue
		var candidate = entry.duplicate(true)
		candidate["weight"] = float(spawn.get("weight", 1.0))
		candidates.append(candidate)
	if candidates.is_empty():
		return String(ids[0]) if not ids.is_empty() else ""
	var picked = run_context.rng.weighted_pick(candidates)
	if picked == null:
		return String(ids[0])
	return String(picked.get("id", ids[0]))


func _active_enemy_count(content_id: String) -> int:
	var count = 0
	for enemy in enemies:
		if String(enemy.get("id", "")) == content_id:
			count += 1
	return count


func _spawn_boss() -> void:
	if not _is_combat_ready():
		return
	var entry = boss_entry if not boss_entry.is_empty() else registry.get_entry("boss", "boss.demo_pollution_source")
	var stats: Dictionary = CombatFormula.scaled_stats(entry, run_context.floor, _section("scaling"), "boss")
	var actor = _make_actor("boss", String(entry.get("id", "boss.demo_pollution_source")), entry, stats)
	var node = _make_frame_sprite(_first_frame_ref(entry), Vector2(132, 132))
	combat_layer.add_child(node)
	boss_spawned = true
	boss_enemy = {
		"id": String(entry.get("id", "boss.demo_pollution_source")),
		"actor": actor,
		"node": node,
		"pos": _vector_from(_section("boss"), "spawn_position", Vector2(640, 176)),
		"hp": actor.current_health,
		"max_hp": actor.max_health,
		"attack": actor.get_stat("attack"),
		"speed": actor.get_stat("move_speed"),
		"touch_timer": 0.0,
		"frames": _content_frame_refs(entry),
		"frame_index": 0,
		"frame_timer": 0.0,
		"anim_time": 0.0,
		"is_boss": true,
		"session_id": combat_session_id,
	}
	enemies.append(boss_enemy)
	combat_boss_sprite = node
	_update_sprite_position(node, boss_enemy["pos"])


func _update_enemies(delta: float) -> void:
	for enemy in enemies.duplicate():
		if int(enemy.get("session_id", -1)) != combat_session_id:
			_queue_free_if_valid(enemy.get("node", null))
			enemies.erase(enemy)
			continue
		if not enemy.has("node") or not is_instance_valid(enemy["node"]):
			enemies.erase(enemy)
			continue
		var actor = enemy.get("actor", null)
		if actor != null:
			actor.tick(delta, effect_runner, {
				"self": actor,
				"source": actor,
				"target": actor,
				"run_context": run_context,
				"source_id": String(enemy.get("id", "")),
			})
			_sync_enemy_resource_cache(enemy)
			if actor.is_dead():
				_kill_enemy(enemy)
				continue
		var pos: Vector2 = enemy["pos"]
		var direction = player_pos - pos
		var distance = direction.length()
		if distance > 8.0 and (actor == null or not actor.has_behavior_lock("movement")):
			pos += direction.normalized() * float(enemy.get("speed", 60.0)) * delta
		enemy["move_x"] = direction.x
		enemy["pos"] = pos
		_update_sprite_position(enemy["node"], pos)
		_update_enemy_animation(enemy, delta)
		enemy["touch_timer"] = max(0.0, float(enemy.get("touch_timer", 0.0)) - delta)
		if distance <= enemy_touch_radius and float(enemy["touch_timer"]) <= 0.0 and (actor == null or not actor.has_behavior_lock("attack")):
			var damage = float(enemy.get("attack", 3.0))
			var applied_damage = _damage_player(damage, actor, "contact")
			enemy["touch_timer"] = _float_from(_section("enemies"), "touch_cooldown_seconds", 0.85)
			_float_text("-%d" % int(applied_damage.get("amount", 0)), player_pos + Vector2(0, -52), Color(1.0, 0.36, 0.28))


func _update_enemy_animation(enemy: Dictionary, delta: float) -> void:
	var node: TextureRect = enemy.get("node", null)
	if node == null or not is_instance_valid(node):
		return
	var move_x = float(enemy.get("move_x", 0.0))
	if abs(move_x) > 0.05:
		node.flip_h = move_x > 0.0
	enemy["anim_time"] = float(enemy.get("anim_time", 0.0)) + delta
	if bool(enemy.get("is_boss", false)) and boss_cast_timer > 0.0:
		var cast_frames: Array = _boss_cast_frames(enemy)
		if not cast_frames.is_empty():
			node.texture = _frame_texture(cast_frames[int(floor(float(enemy["anim_time"]) * 12.0)) % cast_frames.size()])
			var cast_pulse = sin(float(enemy["anim_time"]) * 18.0)
			node.scale = Vector2(1.18 + cast_pulse * 0.08, 1.12 - cast_pulse * 0.04)
			node.rotation_degrees = 0.0
			return
	var frames: Array = enemy.get("frames", [])
	if not frames.is_empty():
		enemy["frame_timer"] = float(enemy.get("frame_timer", 0.0)) - delta
		if float(enemy["frame_timer"]) <= 0.0:
			var enemies_cfg = _section("enemies")
			enemy["frame_timer"] = _float_from(enemies_cfg, "mob_frame_seconds", 0.16) if not bool(enemy.get("is_boss", false)) else _float_from(enemies_cfg, "boss_frame_seconds", 0.11)
			enemy["frame_index"] = (int(enemy.get("frame_index", 0)) + 1) % frames.size()
			node.texture = _frame_texture(frames[int(enemy["frame_index"])])
	var pulse = sin(float(enemy["anim_time"]) * (5.0 if not bool(enemy.get("is_boss", false)) else 3.0))
	node.scale = Vector2(1.0 + pulse * 0.035, 1.0 - pulse * 0.025)
	node.rotation_degrees = 0.0


func _update_boss_ability(delta: float) -> void:
	if not _is_combat_ready() or not boss_spawned or boss_enemy.is_empty():
		return
	var boss_actor = boss_enemy.get("actor", null)
	if boss_actor != null and boss_actor.has_behavior_lock("attack"):
		return
	boss_ability_timer -= delta
	boss_cast_timer = max(0.0, boss_cast_timer - delta)
	if boss_ability_timer <= 0.0:
		boss_ability_timer = _float_from(boss_ability, "cooldown_seconds", 8.0)
		boss_cast_timer = _float_from(boss_ability, "cast_duration_seconds", 0.65)
		_play_boss_cast_motion()
		get_tree().create_timer(_float_from(boss_ability, "spawn_delay_seconds", 0.32)).timeout.connect(_spawn_boss_radial_projectiles.bind(combat_session_id))


func _play_boss_cast_motion() -> void:
	if combat_boss_sprite == null or not is_instance_valid(combat_boss_sprite) or not _is_combat_fx_ready():
		return
	var cast_frames: Array = _boss_cast_frames(boss_enemy)
	if not cast_frames.is_empty():
		combat_boss_sprite.texture = _frame_texture(cast_frames[0])
	var vfx_cfg = _section("vfx")
	var warning = _make_sprite(_resolve_asset_id("boss.demo_pollution_source.warning_icon", "res://assets/art/icons/boss_pollution_source_warning.png"), _vector_from(vfx_cfg, "boss_warning_size", Vector2(96, 96)))
	_update_sprite_position(warning, boss_enemy.get("pos", Vector2.ZERO) + _vector_from(vfx_cfg, "boss_warning_offset", Vector2(0, -88)))
	combat_fx_layer.add_child(warning)
	var tween = create_tween()
	tween.bind_node(warning)
	tween.tween_property(combat_boss_sprite, "scale", Vector2(1.32, 1.18), 0.18)
	tween.tween_property(combat_boss_sprite, "scale", Vector2(1.0, 1.0), 0.28)
	tween.parallel().tween_property(warning, "modulate:a", 0.0, 0.5)
	tween.finished.connect(_queue_free_if_valid.bind(warning))


func _spawn_boss_radial_projectiles(session_id: int) -> void:
	if not _is_current_combat_session(session_id) or not boss_spawned or boss_enemy.is_empty():
		return
	var center: Vector2 = boss_enemy.get("pos", Vector2.ZERO)
	var damage = float(boss_enemy.get("attack", 10.0))
	var projectile_count = max(1, _int_from(boss_ability, "projectile_count", 16))
	var projectile_speed = _float_from(boss_ability, "projectile_speed", 225.0)
	var projectile_radius = _float_from(boss_ability, "projectile_radius", 18.0)
	var projectile_life = _float_from(boss_ability, "projectile_life_seconds", 5.0)
	var projectile_offset = _float_from(boss_ability, "projectile_spawn_offset", 72.0)
	var vfx_cfg = _section("vfx")
	for i in range(projectile_count):
		var angle = TAU * float(i) / float(projectile_count)
		var direction = Vector2(cos(angle), sin(angle))
		var node = _make_frame_sprite(_magic_frame_ref(1), _vector_from(vfx_cfg, "boss_projectile_size", Vector2(34, 34)))
		node.modulate = _color_from(vfx_cfg, "boss_projectile_color", Color(0.85, 0.58, 1.0, 0.95))
		_update_sprite_position(node, center + direction * projectile_offset)
		combat_layer.add_child(node)
		boss_projectiles.append({
			"node": node,
			"pos": center + direction * projectile_offset,
			"velocity": direction * projectile_speed,
			"damage": damage,
			"radius": projectile_radius,
			"life": projectile_life,
			"anim_time": 0.0,
			"session_id": session_id,
		})


func _update_boss_projectiles(delta: float) -> void:
	for projectile in boss_projectiles.duplicate():
		if int(projectile.get("session_id", -1)) != combat_session_id:
			_queue_free_if_valid(projectile.get("node", null))
			boss_projectiles.erase(projectile)
			continue
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
		var expired = float(projectile["life"]) <= 0.0 or not arena_rect.grow(96.0).has_point(projectile["pos"])
		if not expired and player_pos.distance_to(projectile["pos"]) <= float(projectile["radius"]) + player_touch_radius:
			var applied_damage = _damage_player(float(projectile["damage"]), boss_enemy.get("actor", null), "projectile")
			_float_text("-%d" % int(applied_damage.get("amount", 0)), player_pos + Vector2(0, -52), Color(1.0, 0.36, 0.28))
			expired = true
		if expired:
			_queue_free_if_valid(node)
			boss_projectiles.erase(projectile)


func _nearest_enemy() -> Dictionary:
	var best: Dictionary = {}
	var best_distance = INF
	for enemy in enemies:
		var actor = enemy.get("actor", null)
		if actor != null and actor.is_dead():
			continue
		var distance = player_pos.distance_to(enemy["pos"])
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _kill_enemy(enemy: Dictionary) -> void:
	if enemy.has("node") and is_instance_valid(enemy["node"]):
		_queue_free_if_valid(enemy["node"])
	enemies.erase(enemy)
	if bool(enemy.get("is_boss", false)):
		boss_enemy = {}
		boss_spawned = false
		_end_combat(true)


func _update_combat_hud(delta: float) -> void:
	if combat_hud_layer == null or not is_instance_valid(combat_hud_layer) or not combat_hud_layer.has_method("update_state"):
		return
	_sync_player_resources_from_actor()
	if not boss_enemy.is_empty():
		_sync_enemy_resource_cache(boss_enemy)
	combat_hud_layer.update_state(delta, {
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"player_mana": player_mana,
		"player_max_mana": player_max_mana,
		"boss_spawned": boss_spawned and not boss_enemy.is_empty(),
		"boss_hp": float(boss_enemy.get("hp", 0.0)),
		"boss_max_hp": float(boss_enemy.get("max_hp", 1.0)),
		"phase": "Boss" if boss_spawned else "Mobs",
		"floor": run_context.floor,
		"weapon_count": _equipped_weapon_count(),
		"equipped_magics": run_context.equipped_magics,
		"cooldowns": magic_cooldowns,
		"total_cooldowns": magic_total_cooldowns,
	})


func _equipped_weapon_count() -> int:
	var count = 0
	for weapon_id in run_context.equipped_weapons:
		if weapon_id != null:
			count += 1
	return min(4, count)


func _add_background_path(path: String) -> void:
	var bg = TextureRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture = _load_texture(path)
	add_child(bg)


func _add_overlay(color: Color) -> void:
	var overlay = ColorRect.new()
	overlay.color = color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)


func _show_toast(text: String) -> void:
	if combat_hud_layer == null or not is_instance_valid(combat_hud_layer) or not combat_hud_layer.has_method("show_toast"):
		return
	combat_hud_layer.show_toast(text)


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	return PlayableUiFactory.make_label(text, font_size, color, alignment)


func _make_sprite(texture_path: String, sprite_size: Vector2) -> TextureRect:
	return PlayableUiFactory.make_sprite(texture_path, sprite_size)


func _make_frame_sprite(frame_ref, sprite_size: Vector2) -> TextureRect:
	return PlayableUiFactory.make_sprite_from_texture(_frame_texture(frame_ref), sprite_size)


func _frame_texture(frame_ref) -> Texture2D:
	return PlayableUiFactory.load_frame_texture(frame_ref)


func _update_sprite_position(sprite: Control, world_pos: Vector2) -> void:
	PlayableUiFactory.update_sprite_position(sprite, world_pos)
	if sprite != null and is_instance_valid(sprite):
		sprite.z_index = int(round(world_pos.y + sprite.size.y * 0.5))


func _style_box(fill: Color, border: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	return PlayableUiFactory.style_box(fill, border, border_width, corner_radius)


func _random_edge_position() -> Vector2:
	var rng = run_context.rng if run_context != null and run_context.rng != null else null
	var side = rng.randi_range(0, 3) if rng != null else randi_range(0, 3)
	var rect = arena_rect
	match side:
		0:
			return Vector2(_rng_float(rng, rect.position.x, rect.position.x + rect.size.x), rect.position.y)
		1:
			return Vector2(_rng_float(rng, rect.position.x, rect.position.x + rect.size.x), rect.position.y + rect.size.y)
		2:
			return Vector2(rect.position.x, _rng_float(rng, rect.position.y, rect.position.y + rect.size.y))
		_:
			return Vector2(rect.position.x + rect.size.x, _rng_float(rng, rect.position.y, rect.position.y + rect.size.y))


func _rng_float(rng, min_value: float, max_value: float) -> float:
	if rng != null and rng.has_method("randf_range"):
		return rng.randf_range(min_value, max_value)
	return randf_range(min_value, max_value)


func _flash_attack(target_pos: Vector2, attack_vector: Vector2) -> void:
	if not _is_combat_fx_ready():
		return
	var vfx_cfg = _section("vfx")
	var fx = _make_frame_sprite(_weapon_slash_frame_ref(0), _vector_from(vfx_cfg, "slash_size", Vector2(132, 132)))
	fx.position = target_pos - fx.size * 0.5
	if attack_vector.length() > 0.01:
		fx.rotation = attack_vector.angle() + PI
	combat_fx_layer.add_child(fx)
	var tween = create_tween()
	tween.bind_node(fx)
	tween.tween_property(fx, "modulate:a", 0.0, _float_from(vfx_cfg, "attack_fade_seconds", 0.22))
	tween.finished.connect(_queue_free_if_valid.bind(fx))


func _flash_magic(target_pos: Vector2) -> void:
	if not _is_combat_fx_ready():
		return
	var vfx_cfg = _section("vfx")
	var fade_seconds = _float_from(vfx_cfg, "magic_fade_seconds", 0.22)
	var fx = _make_frame_sprite(_magic_frame_ref(0), _vector_from(vfx_cfg, "magic_size", Vector2(96, 96)))
	fx.position = target_pos - fx.size * 0.5
	combat_fx_layer.add_child(fx)
	var tween = create_tween()
	tween.bind_node(fx)
	tween.tween_property(fx, "scale", Vector2(1.45, 1.45), fade_seconds)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, fade_seconds)
	tween.finished.connect(_queue_free_if_valid.bind(fx))


func _spell_popup(slot_index: int, success: bool) -> void:
	if not _is_combat_fx_ready():
		return
	var texture_path = "res://assets/art/ui/combat_cast_forbidden.png"
	if success and slot_index >= 0 and slot_index < run_context.equipped_magics.size() and run_context.equipped_magics[slot_index] != null:
		var magic_entry = registry.get_entry("magic", String(run_context.equipped_magics[slot_index]))
		texture_path = _content_icon_path(magic_entry)
	var popup = _make_sprite(texture_path, Vector2(46, 46))
	popup.position = player_pos + Vector2(-23, -88)
	combat_fx_layer.add_child(popup)
	var tween = create_tween()
	tween.bind_node(popup)
	tween.tween_property(popup, "position", popup.position + Vector2(0, -28), 0.42)
	tween.parallel().tween_property(popup, "modulate:a", 0.0, 0.42)
	tween.finished.connect(_queue_free_if_valid.bind(popup))


func _float_damage_text(amount: int, pos: Vector2) -> void:
	if not is_inside_tree():
		return
	var root = Control.new()
	root.position = pos - Vector2(54, 28)
	root.size = Vector2(108, 52)
	add_child(root)

	var burst = TextureRect.new()
	burst.position = Vector2(20, 0)
	burst.size = Vector2(68, 52)
	burst.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	burst.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	burst.texture = _load_texture("res://assets/art/ui/combat_damage_burst.png")
	burst.modulate = Color(1, 1, 1, 0.78)
	root.add_child(burst)

	var label = _make_label(str(amount), 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2.ZERO
	label.size = root.size
	root.add_child(label)

	var vfx_cfg = _section("vfx")
	floating_texts.append({
		"node": root,
		"life": _float_from(vfx_cfg, "floating_text_life_seconds", 0.8),
		"max_life": _float_from(vfx_cfg, "floating_text_life_seconds", 0.8),
		"velocity": _vector_from(vfx_cfg, "floating_text_velocity", Vector2(0, -42)),
		"session_id": combat_session_id,
	})


func _float_text(text: String, pos: Vector2, color: Color) -> void:
	if not is_inside_tree():
		return
	var label = _make_label(text, 22, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = pos - Vector2(70, 20)
	label.size = Vector2(140, 36)
	add_child(label)
	var vfx_cfg = _section("vfx")
	floating_texts.append({
		"node": label,
		"life": _float_from(vfx_cfg, "floating_text_life_seconds", 0.8),
		"max_life": _float_from(vfx_cfg, "floating_text_life_seconds", 0.8),
		"velocity": _vector_from(vfx_cfg, "floating_text_velocity", Vector2(0, -42)),
		"session_id": combat_session_id,
	})


func _update_floating_texts(delta: float) -> void:
	for item in floating_texts.duplicate():
		if int(item.get("session_id", -1)) != combat_session_id:
			_queue_free_if_valid(item.get("node", null))
			floating_texts.erase(item)
			continue
		if not item.has("node") or not is_instance_valid(item["node"]):
			floating_texts.erase(item)
			continue
		item["life"] = float(item["life"]) - delta
		item["node"].position += item["velocity"] * delta
		item["node"].modulate.a = clamp(float(item["life"]) / max(0.01, float(item.get("max_life", 0.8))), 0.0, 1.0)
		if float(item["life"]) <= 0.0:
			_queue_free_if_valid(item["node"])
			floating_texts.erase(item)


func _content_sprite_path(entry: Dictionary) -> String:
	return PlayableContentPresenter.content_sprite_path(asset_catalog, entry)


func _content_frame_refs(entry: Dictionary) -> Array:
	return PlayableContentPresenter.content_frame_refs(asset_catalog, entry)


func _content_icon_path(entry: Dictionary) -> String:
	return PlayableContentPresenter.content_icon_path(asset_catalog, entry)


func _first_frame_ref(entry: Dictionary):
	var frames = _content_frame_refs(entry)
	if frames.is_empty():
		return _content_sprite_path(entry)
	return frames[0]


func _boss_cast_frames(enemy: Dictionary) -> Array:
	var frames: Array = enemy.get("frames", [])
	if frames.size() < 9:
		return frames
	return frames.slice(6, 9)


func _player_frame_ref(is_moving: bool, frame_index: int) -> Dictionary:
	var character = registry.get_entry("character", run_context.character_id)
	var refs = character.get("asset_refs", {})
	var asset_id = ""
	var fallback = "res://assets/art/sprites/characters/potato_hero.png"
	var columns = PLAYER_IDLE_SHEET_COLUMNS
	var rows = PLAYER_IDLE_SHEET_ROWS
	var index = frame_index
	if is_moving:
		asset_id = String(refs.get("walk_sprite", ""))
		fallback = "res://assets/art/sprites/characters/potato_hero_walk.png"
		columns = PLAYER_WALK_SHEET_COLUMNS
		rows = PLAYER_WALK_SHEET_ROWS
		index = PLAYER_WALK_RIGHT_START_FRAME + frame_index
	else:
		asset_id = String(refs.get("sprite", ""))
	var path = _resolve_asset_id(asset_id, fallback)
	return PlayableContentPresenter.sheet_frame_ref(path, columns, rows, index)


func _weapon_slash_frame_ref(frame_index: int) -> Dictionary:
	var refs = current_weapon_entry.get("asset_refs", {})
	var asset_id = String(refs.get("slash_vfx", "weapon.fries.slash_vfx")) if typeof(refs) == TYPE_DICTIONARY else "weapon.fries.slash_vfx"
	var path = _resolve_asset_id(asset_id, "res://assets/art/vfx/weapon_fries_slash.png")
	return PlayableContentPresenter.sheet_frame_ref(path, VFX_SHEET_COLUMNS, VFX_SHEET_ROWS, frame_index)


func _magic_frame_ref(frame_index: int) -> Dictionary:
	var path = _resolve_asset_id("magic.comprehensive_development.vfx", "res://assets/art/vfx/comprehensive_development.png")
	return PlayableContentPresenter.sheet_frame_ref(path, VFX_SHEET_COLUMNS, VFX_SHEET_ROWS, frame_index)


func _resolve_asset_id(asset_id: String, default_path: String) -> String:
	if asset_catalog == null or asset_id.is_empty():
		return default_path
	return asset_catalog.resolve_asset_path(asset_id, default_path)


func _load_texture(path: String) -> Texture2D:
	return PlayableUiFactory.load_texture(path)
