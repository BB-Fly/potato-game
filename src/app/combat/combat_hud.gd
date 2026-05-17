class_name CombatHud
extends Control

const PlayableUiFactory = preload("res://src/app/playable/playable_ui_factory.gd")
const PlayableContentPresenter = preload("res://src/app/playable/playable_content_presenter.gd")

const LOGICAL_VIEWPORT_WIDTH = 1280.0
const MAGIC_KEYS = ["Q", "E", "R", "F"]

var registry
var run_context
var asset_catalog
var balance: Dictionary = {}
var player_hp_bar_ui: Dictionary = {}
var player_mana_bar_ui: Dictionary = {}
var boss_hp_bar_ui: Dictionary = {}
var magic_slot_nodes: Array = []
var toast_label: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 3000
	_apply_scene_defaults()


func setup(p_registry, p_run_context, p_asset_catalog, p_balance: Dictionary, player_max_hp: float, player_max_mana: float, slot_count: int) -> void:
	registry = p_registry
	run_context = p_run_context
	asset_catalog = p_asset_catalog
	balance = p_balance
	_apply_scene_defaults()
	player_hp_bar_ui = _bind_combat_stat_bar(
		_get_control("PlayerHud/PlayerHpBar"),
		player_max_hp,
		Color(0.48, 0.92, 0.28),
		Color(0.78, 1.0, 0.54),
		Color(1.0, 0.2, 0.18),
		"res://assets/art/ui/combat_hp_frame_slim.png",
		"HP",
		false
	)
	player_mana_bar_ui = _bind_combat_stat_bar(
		_get_control("PlayerHud/PlayerManaBar"),
		player_max_mana,
		Color(0.28, 0.54, 1.0),
		Color(0.62, 0.88, 1.0),
		Color(0.62, 0.88, 1.0),
		"res://assets/art/ui/combat_mana_frame.png",
		"MP",
		false
	)
	boss_hp_bar_ui = _bind_combat_stat_bar(
		_get_control("TopHud/BossHpBar"),
		300.0,
		Color(0.86, 0.12, 0.16),
		Color(1.0, 0.84, 0.22),
		Color(1.0, 0.84, 0.22),
		"res://assets/art/ui/combat_boss_hp_frame.png",
		"BOSS",
		true
	)
	var boss_root: Control = boss_hp_bar_ui.get("root", null)
	if boss_root != null:
		boss_root.visible = false
	_bind_magic_slots(slot_count)
	toast_label = get_node_or_null("ToastLabel") as Label
	if toast_label != null:
		toast_label.text = ""
		toast_label.modulate.a = 0.0


func reset() -> void:
	player_hp_bar_ui.clear()
	player_mana_bar_ui.clear()
	boss_hp_bar_ui.clear()
	magic_slot_nodes.clear()
	if toast_label != null and is_instance_valid(toast_label):
		toast_label.text = ""
		toast_label.modulate.a = 0.0


func update_state(delta: float, state: Dictionary) -> void:
	_sync_combat_stat_bar(player_hp_bar_ui, max(0.0, float(state.get("player_hp", 0.0))), float(state.get("player_max_hp", 1.0)), delta)
	_sync_combat_stat_bar(player_mana_bar_ui, clamp(float(state.get("player_mana", 0.0)), 0.0, float(state.get("player_max_mana", 1.0))), max(1.0, float(state.get("player_max_mana", 1.0))), delta)

	var boss_spawned = bool(state.get("boss_spawned", false))
	if not boss_hp_bar_ui.is_empty():
		var boss_root: Control = boss_hp_bar_ui.get("root", null)
		if boss_root != null and is_instance_valid(boss_root):
			boss_root.visible = boss_spawned
		if boss_root != null and is_instance_valid(boss_root) and boss_root.visible:
			_sync_combat_stat_bar(boss_hp_bar_ui, max(0.0, float(state.get("boss_hp", 0.0))), float(state.get("boss_max_hp", 1.0)), delta)

	var status_label = get_node_or_null("TopHud/TopStatusLabel") as Label
	if status_label != null:
		status_label.text = "%s  Floor %d  Weapons %d/4" % [
			String(state.get("phase", "Mobs")),
			int(state.get("floor", 1)),
			int(state.get("weapon_count", 0)),
		]

	var equipped_magics: Array = state.get("equipped_magics", [])
	var cooldowns: Array = state.get("cooldowns", [])
	var total_cooldowns: Array = state.get("total_cooldowns", [])
	var player_mana = float(state.get("player_mana", 0.0))
	for i in range(magic_slot_nodes.size()):
		_update_magic_slot(i, equipped_magics, cooldowns, total_cooldowns, player_mana)


func show_toast(text: String) -> void:
	if toast_label == null or not is_instance_valid(toast_label):
		return
	toast_label.text = text
	var tween = create_tween()
	tween.bind_node(toast_label)
	toast_label.modulate = Color(1, 1, 1, 1)
	tween.tween_interval(1.2)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.35)


func _apply_scene_defaults() -> void:
	var status_label = get_node_or_null("TopHud/TopStatusLabel") as Label
	if status_label != null:
		_style_label(status_label, 20, Color(1.0, 0.92, 0.68), HORIZONTAL_ALIGNMENT_LEFT)
	var hint_label = get_node_or_null("TopHud/HintLabel") as Label
	if hint_label != null:
		_style_label(hint_label, 18, Color(1.0, 0.92, 0.68), HORIZONTAL_ALIGNMENT_RIGHT)
	var panel_texture = get_node_or_null("PlayerHud/PlayerPanel/Texture") as TextureRect
	if panel_texture != null:
		panel_texture.texture = _load_texture("res://assets/art/ui/panel_wood_wide.png")
		panel_texture.modulate = Color(1, 1, 1, 0.52)
	for i in range(MAGIC_KEYS.size()):
		var slot = get_node_or_null("PlayerHud/MagicSlots/Slot%d" % i) as Control
		if slot == null:
			continue
		var frame = slot.get_node_or_null("Frame") as TextureRect
		if frame != null:
			frame.texture = _load_texture("res://assets/art/ui/combat_magic_slot_disabled.png")
		var key_label = slot.get_node_or_null("KeyLabel") as Label
		if key_label != null:
			key_label.text = MAGIC_KEYS[i]
			_style_label(key_label, 15, Color(1.0, 0.92, 0.62), HORIZONTAL_ALIGNMENT_CENTER)
		var cooldown_label = slot.get_node_or_null("CooldownLabel") as Label
		if cooldown_label != null:
			_style_label(cooldown_label, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
	var toast = get_node_or_null("ToastLabel") as Label
	if toast != null:
		_style_label(toast, 20, Color(1.0, 0.92, 0.62), HORIZONTAL_ALIGNMENT_CENTER)


func _bind_combat_stat_bar(root: Control, max_value: float, fill_color: Color, lag_color: Color, heat_color: Color, frame_path: String, label_prefix: String, is_boss_bar: bool) -> Dictionary:
	if root == null:
		return {}
	var frame_texture = _load_texture(frame_path)
	var split = _bar_frame_split(frame_texture, is_boss_bar)
	var left_cap = int(split["left"])
	var right_cap = int(split["right"])

	var backing = root.get_node_or_null("Backing") as ColorRect
	if backing != null:
		backing.color = Color(0.04, 0.024, 0.02, 0.72) if is_boss_bar else Color(0.035, 0.026, 0.02, 0.62)

	var fill_inset = _bar_fill_inset(is_boss_bar)
	var bg = root.get_node_or_null("BarBackground") as ColorRect
	if bg != null:
		bg.color = Color(0.05, 0.035, 0.025, 0.92)

	var lag = root.get_node_or_null("LagFill") as ColorRect
	if lag != null:
		lag.color = lag_color

	var fill = root.get_node_or_null("Fill") as ColorRect
	if fill != null:
		fill.color = fill_color

	var frame_parts = _get_sliced_bar_frame_parts(root)
	_ensure_sliced_bar_frame_textures(frame_parts, frame_texture, left_cap, right_cap)
	var label = root.get_node_or_null("ValueLabel") as Label
	if label != null:
		_style_label(label, 16, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)

	return {
		"root": root,
		"bg": bg,
		"lag": lag,
		"fill": fill,
		"backing": backing,
		"frame_texture": frame_texture,
		"frame_parts": frame_parts,
		"left_cap": left_cap,
		"right_cap": right_cap,
		"frame_y": 0.0,
		"fill_inset": fill_inset,
		"label": label,
		"prefix": label_prefix,
		"value": max_value,
		"lag_value": max_value,
		"max_value": max_value,
		"fill_color": fill_color,
		"lag_color": lag_color,
		"heat_color": heat_color,
		"heat": 0.0,
		"heat_timer": 0.0,
		"lag_timer": 0.0,
		"is_boss": is_boss_bar,
	}


func _bind_magic_slots(slot_count: int) -> void:
	magic_slot_nodes.clear()
	for i in range(MAGIC_KEYS.size()):
		var root = get_node_or_null("PlayerHud/MagicSlots/Slot%d" % i) as Control
		if root == null:
			continue
		root.visible = i < slot_count
		var frame = root.get_node_or_null("Frame") as TextureRect
		var icon = root.get_node_or_null("Icon") as TextureRect
		var mask = root.get_node_or_null("Mask") as ColorRect
		var cooldown = root.get_node_or_null("CooldownLabel") as Label
		if i < slot_count:
			magic_slot_nodes.append({
				"root": root,
				"frame": frame,
				"icon": icon,
				"mask": mask,
				"cooldown": cooldown,
			})


func _update_magic_slot(slot_index: int, equipped_magics: Array, cooldowns: Array, total_cooldowns: Array, player_mana: float) -> void:
	if slot_index < 0 or slot_index >= magic_slot_nodes.size():
		return
	var slot: Dictionary = magic_slot_nodes[slot_index]
	var frame: TextureRect = slot.get("frame", null)
	var icon: TextureRect = slot.get("icon", null)
	var mask: ColorRect = slot.get("mask", null)
	var cooldown_label: Label = slot.get("cooldown", null)
	if frame == null or icon == null or mask == null or cooldown_label == null:
		return
	var magic_id = equipped_magics[slot_index] if slot_index < equipped_magics.size() else null
	var cd = float(cooldowns[slot_index]) if slot_index < cooldowns.size() else 0.0
	if magic_id == null:
		frame.texture = _load_texture("res://assets/art/ui/combat_magic_slot_disabled.png")
		icon.texture = null
		mask.visible = true
		mask.position = Vector2(19, 21)
		mask.size = Vector2(48, 48)
		mask.color = Color(0, 0, 0, 0.42)
		cooldown_label.text = "-"
		return

	var magic_entry = registry.get_entry("magic", String(magic_id)) if registry != null else {}
	frame.texture = _load_texture("res://assets/art/ui/combat_magic_slot_disabled.png")
	icon.texture = _load_texture(_content_icon_path(magic_entry))
	if cd > 0.0:
		var total = max(0.1, float(total_cooldowns[slot_index]) if slot_index < total_cooldowns.size() else cd)
		var remaining_ratio = clamp(cd / total, 0.0, 1.0)
		mask.visible = true
		mask.color = Color(0, 0, 0, 0.62)
		mask.position = Vector2(19, 21 + 48.0 * (1.0 - remaining_ratio))
		mask.size = Vector2(48, 48.0 * remaining_ratio)
		cooldown_label.text = "%.1f" % cd if cd < 10.0 else "%.0f" % cd
		return
	var mana_cost = float(magic_entry.get("mana_cost", _float_from(_section("magic"), "default_mana_cost", 28.0)))
	if player_mana < mana_cost:
		mask.visible = true
		mask.position = Vector2(19, 21)
		mask.size = Vector2(48, 48)
		mask.color = Color(0.1, 0.42, 1.0, 0.46)
		cooldown_label.text = ""
	else:
		mask.visible = false
		cooldown_label.text = ""


func _sync_combat_stat_bar(bar: Dictionary, value: float, max_value: float, delta: float) -> void:
	if bar.is_empty():
		return
	var root: Control = bar.get("root", null)
	var bg: ColorRect = bar.get("bg", null)
	var fill: ColorRect = bar.get("fill", null)
	var lag: ColorRect = bar.get("lag", null)
	var backing: ColorRect = bar.get("backing", null)
	var label: Label = bar.get("label", null)
	if root == null or bg == null or fill == null or lag == null or label == null:
		return
	if not is_instance_valid(root):
		return

	max_value = max(1.0, max_value)
	value = clamp(value, 0.0, max_value)
	var previous = float(bar.get("value", value))
	if abs(max_value - float(bar.get("max_value", max_value))) > 0.01:
		bar["max_value"] = max_value

	if value < previous:
		bar["lag_value"] = max(float(bar.get("lag_value", previous)), previous)
		bar["lag_timer"] = _float_from(_section("hud"), "bar_loss_delay_seconds", 0.32)
		bar["heat"] = clamp(float(bar.get("heat", 0.0)) + (previous - value) / max_value * 1.9, 0.0, 1.0)
		bar["heat_timer"] = _float_from(_section("hud"), "damage_heat_window_seconds", 0.85)
	elif value > previous and value > float(bar.get("lag_value", value)):
		bar["lag_value"] = value

	bar["lag_timer"] = max(0.0, float(bar["lag_timer"]) - delta)
	if float(bar["lag_timer"]) <= 0.0:
		var catchup = _float_from(_section("hud"), "bar_loss_catchup_speed", 3.0)
		bar["lag_value"] = lerp(float(bar.get("lag_value", value)), value, clamp(delta * catchup, 0.0, 1.0))
	bar["heat_timer"] = max(0.0, float(bar["heat_timer"]) - delta)
	if float(bar["heat_timer"]) <= 0.0:
		var decay = _float_from(_section("hud"), "damage_heat_decay_speed", 1.35)
		bar["heat"] = max(0.0, float(bar.get("heat", 0.0)) - delta * decay)

	var ratio = value / max_value
	var lag_ratio = clamp(float(bar.get("lag_value", value)) / max_value, ratio, 1.0)
	fill.size.x = bg.size.x * ratio
	lag.size.x = bg.size.x * lag_ratio
	var lag_color: Color = bar.get("lag_color", Color.WHITE)
	var heat_color: Color = bar.get("heat_color", lag_color)
	lag.color = lag_color.lerp(heat_color, float(bar.get("heat", 0.0)))
	label.text = "%s %d/%d" % [String(bar.get("prefix", "")), int(round(value)), int(round(max_value))]
	bar["value"] = value


func _hud_bar_width(max_value: float, is_boss_bar: bool) -> float:
	if is_boss_bar:
		return clamp(600.0 + max(0.0, max_value - 250.0) * 0.12, 600.0, 760.0)
	return clamp(235.0 + max(0.0, max_value - 80.0) * 0.62, 235.0, 360.0)


func _bar_fill_inset(is_boss_bar: bool) -> Rect2:
	if is_boss_bar:
		return Rect2(Vector2(-8, 6), Vector2(10, 18))
	return Rect2(Vector2(-6, 12), Vector2(10, 22))


func _bar_frame_split(texture: Texture2D, is_boss_bar: bool) -> Dictionary:
	if texture == null:
		return {"left": 34, "right": 20, "height": 45}
	var texture_size = texture.get_size()
	var left_cap = 72 if is_boss_bar else 32
	var right_cap = 32 if is_boss_bar else 18
	left_cap = min(left_cap, int(texture_size.x * 0.46))
	right_cap = min(right_cap, int(texture_size.x * 0.32))
	if is_boss_bar:
		left_cap = min(72, int(texture_size.x * 0.64))
		right_cap = min(32, int(texture_size.x * 0.28))
	return {"left": left_cap, "right": right_cap, "height": texture_size.y}


func _get_sliced_bar_frame_parts(root: Control) -> Array:
	var parts: Array = []
	var left = root.get_node_or_null("FrameLeft") as TextureRect
	var middle = root.get_node_or_null("FrameMiddle") as TextureRect
	var right = root.get_node_or_null("FrameRight") as TextureRect
	if left == null or middle == null or right == null:
		return parts
	parts.append(left)
	parts.append(middle)
	parts.append(right)
	return parts


func _ensure_sliced_bar_frame_textures(parts: Array, texture: Texture2D, left_cap: int, right_cap: int) -> void:
	if parts.size() < 3 or texture == null:
		return
	var texture_size = texture.get_size()
	var source_middle_width = max(1.0, texture_size.x - left_cap - right_cap)
	_set_frame_slice_texture(parts[0], texture, Rect2(0, 0, left_cap, texture_size.y))
	_set_frame_slice_texture(parts[1], texture, Rect2(left_cap, 0, source_middle_width, texture_size.y))
	_set_frame_slice_texture(parts[2], texture, Rect2(texture_size.x - right_cap, 0, right_cap, texture_size.y))


func _set_frame_slice_texture(slice: TextureRect, texture: Texture2D, region: Rect2) -> void:
	if slice == null or not is_instance_valid(slice):
		return
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	slice.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slice.stretch_mode = TextureRect.STRETCH_SCALE
	slice.texture = atlas


func _configure_sliced_bar_frame(root: Control, texture: Texture2D, left_cap: int, right_cap: int, middle_width: float, y: float) -> Array:
	var parts: Array = []
	var left = root.get_node_or_null("FrameLeft") as TextureRect
	var middle = root.get_node_or_null("FrameMiddle") as TextureRect
	var right = root.get_node_or_null("FrameRight") as TextureRect
	if left == null or middle == null or right == null:
		return parts
	parts.append(left)
	parts.append(middle)
	parts.append(right)
	if texture == null:
		return parts
	var texture_size = texture.get_size()
	var source_middle_width = max(1.0, texture_size.x - left_cap - right_cap)
	_set_frame_slice(left, texture, Rect2(0, 0, left_cap, texture_size.y), Vector2(0, y), Vector2(left_cap, texture_size.y))
	_set_frame_slice(middle, texture, Rect2(left_cap, 0, source_middle_width, texture_size.y), Vector2(left_cap, y), Vector2(middle_width, texture_size.y))
	_set_frame_slice(right, texture, Rect2(texture_size.x - right_cap, 0, right_cap, texture_size.y), Vector2(left_cap + middle_width, y), Vector2(right_cap, texture_size.y))
	return parts


func _set_frame_slice(slice: TextureRect, texture: Texture2D, region: Rect2, slice_position: Vector2, slice_size: Vector2) -> void:
	var atlas = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	slice.position = slice_position
	slice.size = slice_size
	slice.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	slice.stretch_mode = TextureRect.STRETCH_SCALE
	slice.texture = atlas


func _layout_sliced_bar_frame(bar: Dictionary, bar_width: float) -> void:
	var parts: Array = bar.get("frame_parts", [])
	if parts.size() < 3:
		return
	var left_cap = int(bar.get("left_cap", 34))
	var right_cap = int(bar.get("right_cap", 20))
	var y = float(bar.get("frame_y", 0.0))
	var texture: Texture2D = bar.get("frame_texture", null)
	var height = texture.get_size().y if texture != null else 45.0
	var left: TextureRect = parts[0]
	var middle: TextureRect = parts[1]
	var right: TextureRect = parts[2]
	if left != null and is_instance_valid(left):
		left.position = Vector2(0, y)
		left.size = Vector2(left_cap, height)
	if middle != null and is_instance_valid(middle):
		middle.position = Vector2(left_cap, y)
		middle.size = Vector2(bar_width, height)
	if right != null and is_instance_valid(right):
		right.position = Vector2(left_cap + bar_width, y)
		right.size = Vector2(right_cap, height)


func _style_label(label: Label, font_size: int, color: Color, alignment: HorizontalAlignment) -> void:
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)


func _get_control(path: String) -> Control:
	return get_node_or_null(path) as Control


func _section(key: String) -> Dictionary:
	var value = balance.get(key, {})
	return value if typeof(value) == TYPE_DICTIONARY else {}


func _float_from(source: Dictionary, key: String, default_value: float) -> float:
	return float(source.get(key, default_value))


func _content_icon_path(entry: Dictionary) -> String:
	return PlayableContentPresenter.content_icon_path(asset_catalog, entry)


func _load_texture(path: String) -> Texture2D:
	return PlayableUiFactory.load_texture(path)
