class_name PlayableCombatScene
extends Control

signal combat_finished(result: Dictionary)

const PlayableUiFactory = preload("res://src/app/playable/playable_ui_factory.gd")
const PlayableContentPresenter = preload("res://src/app/playable/playable_content_presenter.gd")

const COMBAT_ARENA_RECT = Rect2(Vector2(48, 118), Vector2(1184, 560))
const PLAYER_SPEED = 220.0
const PLAYER_TOUCH_RADIUS = 24.0
const ENEMY_TOUCH_RADIUS = 28.0
const MOB_PHASE_SECONDS = 22.0
const MOB_SPAWN_SECONDS = 1.7
const WEAPON_ATTACK_SECONDS = 0.42
const WEAPON_RANGE = 188.0

var registry
var run_context
var asset_catalog

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
var combat_session_id = 0
var magic_cooldowns: Array = []
var floating_texts: Array = []
var toast_label: Label
var is_finished = false


func setup(p_registry, p_run_context, p_asset_catalog) -> void:
	registry = p_registry
	run_context = p_run_context
	asset_catalog = p_asset_catalog
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
	magic_slot_nodes.clear()


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
	_add_background_path("res://assets/art/map/backgrounds/chapter_1_route_background.png")
	_add_overlay(Color(0.06, 0.05, 0.035, 0.18))

	combat_layer = Control.new()
	combat_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(combat_layer)

	combat_fx_layer = Control.new()
	combat_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(combat_fx_layer)

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


func _clear_local_state() -> void:
	for child in get_children():
		remove_child(child)
		_queue_free_if_valid(child)
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


func _is_combat_ready() -> bool:
	return not is_finished and combat_layer != null and is_instance_valid(combat_layer)


func _is_current_combat_session(session_id: int) -> bool:
	return session_id == combat_session_id and _is_combat_ready()


func _is_combat_fx_ready() -> bool:
	return _is_combat_ready() and combat_fx_layer != null and is_instance_valid(combat_fx_layer)


func _queue_free_if_valid(node) -> void:
	if node != null and is_instance_valid(node):
		node.queue_free()


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
	combat_hud_label = _make_label("", 20, Color(1.0, 0.92, 0.68), HORIZONTAL_ALIGNMENT_LEFT)
	combat_hud_label.position = Vector2(32, 26)
	combat_hud_label.size = Vector2(720, 34)
	add_child(combat_hud_label)

	combat_hint_label = _make_label("Move: WASD / Arrows    Magic: Q E R F", 18, Color(1.0, 0.92, 0.68), HORIZONTAL_ALIGNMENT_RIGHT)
	combat_hint_label.position = Vector2(720, 28)
	combat_hint_label.size = Vector2(520, 30)
	add_child(combat_hint_label)

	combat_player_hp_bar = _make_bar(Vector2(32, 68), Vector2(350, 22), Color(0.58, 0.88, 0.28))
	add_child(combat_player_hp_bar)
	combat_mana_bar = _make_bar(Vector2(32, 96), Vector2(350, 16), Color(0.35, 0.55, 1.0))
	add_child(combat_mana_bar)
	combat_boss_hp_bar = _make_bar(Vector2(430, 68), Vector2(420, 18), Color(0.92, 0.24, 0.28))
	combat_boss_hp_bar.visible = false
	add_child(combat_boss_hp_bar)

	var keys = ["Q", "E", "R", "F"]
	for i in range(4):
		var slot = _make_label(keys[i], 18, Color(0.95, 0.88, 0.68), HORIZONTAL_ALIGNMENT_CENTER)
		slot.position = Vector2(930 + i * 72, 76)
		slot.size = Vector2(58, 58)
		slot.add_theme_stylebox_override("normal", _style_box(Color(0.08, 0.06, 0.045, 0.86), Color(0.38, 0.54, 1.0, 0.8), 2, 6))
		add_child(slot)
		magic_slot_nodes.append(slot)

	_add_toast_anchor()


func _update_combat(delta: float) -> void:
	if not _is_combat_ready():
		return
	combat_elapsed += delta
	idle_time += delta
	player_mana = min(player_max_mana, player_mana + player_mana_regen * delta)
	_update_player_movement(delta)
	_update_player_attack(delta)
	if is_finished:
		return
	_update_magic_input()
	_update_magic_cooldowns(delta)
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
	_update_combat_hud()
	if player_hp <= 0.0:
		_end_combat(false)


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
	if combat_layer == null or not is_instance_valid(combat_layer):
		return
	for weapon in combat_weapon_sprites:
		_queue_free_if_valid(weapon)
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
	if not _is_combat_ready():
		return
	if not boss_spawned and combat_elapsed >= MOB_PHASE_SECONDS:
		_spawn_boss()
	mob_spawn_timer -= delta
	if mob_spawn_timer <= 0.0 and enemies.size() < 14:
		mob_spawn_timer = MOB_SPAWN_SECONDS
		_spawn_mob()


func _spawn_mob() -> void:
	if not _is_combat_ready():
		return
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
		"session_id": combat_session_id,
	}
	enemies.append(enemy)
	_update_sprite_position(node, pos)


func _spawn_boss() -> void:
	if not _is_combat_ready():
		return
	var entry = registry.get_entry("boss", "boss.demo_pollution_source")
	var stats: Dictionary = entry.get("stats", {})
	var node = _make_sprite("res://assets/art/source/boss_pollution_source/boss_pollution_source-1.png", Vector2(132, 132))
	combat_layer.add_child(node)
	boss_spawned = true
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
	if not _is_combat_ready() or not boss_spawned or boss_enemy.is_empty():
		return
	boss_ability_timer -= delta
	boss_cast_timer = max(0.0, boss_cast_timer - delta)
	if boss_ability_timer <= 0.0:
		boss_ability_timer = 8.0
		boss_cast_timer = 0.65
		_play_boss_cast_motion()
		get_tree().create_timer(0.32).timeout.connect(_spawn_boss_radial_projectiles.bind(combat_session_id))


func _play_boss_cast_motion() -> void:
	if combat_boss_sprite == null or not is_instance_valid(combat_boss_sprite) or not _is_combat_fx_ready():
		return
	combat_boss_sprite.texture = _load_texture("res://assets/art/source/boss_pollution_source/boss_pollution_source-7.png")
	var warning = _make_sprite("res://assets/art/source/enemy_pack_01/boss_pollution_source_warning/boss_pollution_source_warning-1.png", Vector2(96, 96))
	_update_sprite_position(warning, boss_enemy.get("pos", Vector2.ZERO) + Vector2(0, -88))
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
		var expired = float(projectile["life"]) <= 0.0 or not COMBAT_ARENA_RECT.grow(96.0).has_point(projectile["pos"])
		if not expired and player_pos.distance_to(projectile["pos"]) <= float(projectile["radius"]) + PLAYER_TOUCH_RADIUS:
			player_hp -= float(projectile["damage"])
			_float_text("-%d" % int(projectile["damage"]), player_pos + Vector2(0, -52), Color(1.0, 0.36, 0.28))
			expired = true
		if expired:
			_queue_free_if_valid(node)
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
		_queue_free_if_valid(enemy["node"])
	enemies.erase(enemy)
	if bool(enemy.get("is_boss", false)):
		boss_enemy = {}
		boss_spawned = false
		_end_combat(true)


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


func _add_toast_anchor() -> void:
	toast_label = _make_label("", 20, Color(1.0, 0.92, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
	toast_label.position = Vector2(220, 120)
	toast_label.size = Vector2(840, 34)
	add_child(toast_label)


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
	if not _is_combat_fx_ready():
		return
	var fx = _make_sprite("res://assets/art/source/fries_slash/fries_slash-1.png", Vector2(132, 132))
	fx.position = target_pos - fx.size * 0.5
	if attack_vector.length() > 0.01:
		fx.rotation = attack_vector.angle() + PI
	combat_fx_layer.add_child(fx)
	var tween = create_tween()
	tween.bind_node(fx)
	tween.tween_property(fx, "modulate:a", 0.0, 0.22)
	tween.finished.connect(_queue_free_if_valid.bind(fx))


func _flash_magic(target_pos: Vector2) -> void:
	if not _is_combat_fx_ready():
		return
	var fx = _make_sprite("res://assets/art/source/magic_vfx/magic_vfx-1.png", Vector2(96, 96))
	fx.position = target_pos - fx.size * 0.5
	combat_fx_layer.add_child(fx)
	var tween = create_tween()
	tween.bind_node(fx)
	tween.tween_property(fx, "scale", Vector2(1.45, 1.45), 0.22)
	tween.parallel().tween_property(fx, "modulate:a", 0.0, 0.22)
	tween.finished.connect(_queue_free_if_valid.bind(fx))


func _float_text(text: String, pos: Vector2, color: Color) -> void:
	if not is_inside_tree():
		return
	var label = _make_label(text, 22, color, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = pos - Vector2(70, 20)
	label.size = Vector2(140, 36)
	add_child(label)
	floating_texts.append({"node": label, "life": 0.8, "velocity": Vector2(0, -42), "session_id": combat_session_id})


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
		item["node"].modulate.a = clamp(float(item["life"]) / 0.8, 0.0, 1.0)
		if float(item["life"]) <= 0.0:
			_queue_free_if_valid(item["node"])
			floating_texts.erase(item)


func _content_sprite_path(entry: Dictionary) -> String:
	return PlayableContentPresenter.content_sprite_path(asset_catalog, entry)


func _enemy_frame_paths(content_id: String) -> Array:
	return PlayableContentPresenter.enemy_frame_paths(content_id)


func _load_texture(path: String) -> Texture2D:
	return PlayableUiFactory.load_texture(path)
