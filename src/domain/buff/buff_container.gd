class_name BuffContainer
extends RefCounted

const BuffInstance = preload("res://src/domain/buff/buff_instance.gd")

var registry
var owner_id = ""
var buffs: Dictionary = {}
var bound_stat_block = null
var active_modifier_sources: Array = []


func _init(p_registry, p_owner_id: String = "") -> void:
	registry = p_registry
	owner_id = p_owner_id


func bind_stat_block(stat_block) -> void:
	bound_stat_block = stat_block
	_rebuild_bound_stat_modifiers()


func apply_buff(buff_id: String, source_id: String = "", stacks: int = 1, overrides: Dictionary = {}) -> BuffInstance:
	var definition = registry.get_entry("buff", buff_id)
	if definition.is_empty():
		push_warning("Buff not found: %s" % buff_id)
		return null

	var instance_key = _instance_key(definition, buff_id, source_id)
	if not buffs.has(instance_key):
		var instance = BuffInstance.new()
		instance.initialize(definition, source_id, stacks, overrides)
		buffs[instance_key] = instance
		_rebuild_bound_stat_modifiers()
		return instance

	_merge_buff(buffs[instance_key], definition, stacks, overrides)
	_rebuild_bound_stat_modifiers()
	return buffs[instance_key]


func tick(_tick_index: int) -> void:
	tick_frames(1.0)


func tick_seconds(delta_seconds: float, effect_runner = null, context: Dictionary = {}) -> void:
	tick_frames(delta_seconds * 60.0, effect_runner, context)


func tick_frames(frames: float, effect_runner = null, context: Dictionary = {}) -> void:
	if frames <= 0.0:
		return
	var expired: Array = []
	var changed_stacks = false
	for instance_key in buffs.keys():
		var instance = buffs[instance_key]
		if _tick_instance(instance, frames, effect_runner, context):
			changed_stacks = true
		if instance.is_expired():
			expired.append(instance_key)
	for instance_key in expired:
		buffs.erase(instance_key)
	if changed_stacks or not expired.is_empty():
		_rebuild_bound_stat_modifiers()


func get_instances() -> Array:
	return buffs.values()


func has_buff(buff_id: String) -> bool:
	for instance in buffs.values():
		if instance.get_buff_id() == buff_id:
			return true
	return false


func get_total_stacks(buff_id: String) -> int:
	var total = 0
	for instance in buffs.values():
		if instance.get_buff_id() == buff_id:
			total += int(instance.stacks)
	return total


func has_behavior_lock(lock_id: String) -> bool:
	for instance in buffs.values():
		if instance.get_behavior_locks().has(lock_id):
			return true
	return false


func rebuild_stat_modifiers(stat_block) -> void:
	bound_stat_block = stat_block
	_rebuild_bound_stat_modifiers()


func _merge_buff(instance, definition: Dictionary, stacks: int, overrides: Dictionary = {}) -> void:
	for key in overrides.keys():
		instance.definition[key] = overrides[key]
	var mode = String(definition.get("stacking_mode", "refresh_duration"))
	var max_stacks = int(definition.get("max_stacks", 1))
	var duration_frames = int(instance.definition.get("duration_frames", definition.get("duration_frames", 0)))
	if mode == "refresh_duration":
		instance.stacks = min(max_stacks, max(instance.stacks, stacks))
		instance.remaining_frames = duration_frames
	elif mode == "stack_refresh_duration":
		instance.stacks = min(max_stacks, instance.stacks + stacks)
		instance.remaining_frames = duration_frames
	elif mode == "independent_timers":
		if duration_frames < 0:
			instance.stacks = min(max_stacks, instance.stacks + stacks)
			instance.remaining_frames = -1
		else:
			for _i in range(stacks):
				if instance.per_stack_remaining_frames.size() < max_stacks:
					instance.per_stack_remaining_frames.append(duration_frames)
			instance.stacks = instance.per_stack_remaining_frames.size()
	elif mode == "permanent_stack":
		instance.stacks = min(max_stacks, instance.stacks + stacks)
		instance.remaining_frames = -1
	elif mode == "replace_if_stronger":
		if _instance_strength(instance) <= _definition_strength(instance.definition):
			instance.stacks = min(max_stacks, stacks)
			instance.remaining_frames = duration_frames


func _tick_instance(instance, frames: float, effect_runner = null, context: Dictionary = {}) -> bool:
	var stack_count_before = int(instance.stacks)
	if not instance.per_stack_remaining_frames.is_empty():
		for i in range(instance.per_stack_remaining_frames.size() - 1, -1, -1):
			instance.per_stack_remaining_frames[i] -= frames
			if instance.per_stack_remaining_frames[i] <= 0:
				instance.per_stack_remaining_frames.remove_at(i)
		instance.stacks = instance.per_stack_remaining_frames.size()
	else:
		if instance.remaining_frames > 0:
			instance.remaining_frames = max(0, instance.remaining_frames - frames)

	_tick_periodic_effects(instance, frames, effect_runner, context)
	return stack_count_before != int(instance.stacks)


func _tick_periodic_effects(instance, frames: float, effect_runner, context: Dictionary) -> void:
	if effect_runner == null:
		return
	var tick_interval = instance.get_tick_interval_frames()
	if tick_interval <= 0:
		return
	var effects = instance.get_periodic_effects()
	if effects.is_empty():
		return
	instance.tick_accumulator += frames
	while instance.tick_accumulator >= tick_interval:
		instance.tick_accumulator -= tick_interval
		var tick_context = context.duplicate()
		tick_context["source_id"] = instance.source_id if not String(instance.source_id).is_empty() else instance.get_buff_id()
		tick_context["source_buff_id"] = instance.get_buff_id()
		tick_context["stacks"] = instance.stacks
		tick_context["buff_instance"] = instance
		effect_runner.run_effects(effects, tick_context)


func _instance_key(definition: Dictionary, buff_id: String, source_id: String) -> String:
	var mode = String(definition.get("stacking_mode", "refresh_duration"))
	if mode == "unique_by_source":
		return "%s@%s" % [buff_id, source_id]
	var unique_group = String(definition.get("unique_group", ""))
	if not unique_group.is_empty():
		return "group:%s" % unique_group
	return buff_id


func _rebuild_bound_stat_modifiers() -> void:
	if bound_stat_block == null:
		return
	for source_id in active_modifier_sources:
		bound_stat_block.remove_modifiers_from_source(source_id)
	active_modifier_sources.clear()
	for instance_key in buffs.keys():
		var instance = buffs[instance_key]
		var modifiers = instance.definition.get("modifiers", [])
		if typeof(modifiers) != TYPE_ARRAY or modifiers.is_empty():
			continue
		var source_id = _modifier_source_id(instance_key)
		bound_stat_block.apply_modifiers(modifiers, source_id, int(instance.stacks))
		active_modifier_sources.append(source_id)


func _modifier_source_id(instance_key: String) -> String:
	return "buff:%s:%s" % [owner_id, instance_key]


func _instance_strength(instance) -> float:
	return _definition_strength(instance.definition) * max(1, int(instance.stacks))


func _definition_strength(definition: Dictionary) -> float:
	var shield = definition.get("shield", {})
	if typeof(shield) == TYPE_DICTIONARY:
		return float(shield.get("base", 0.0))
	var total = 0.0
	for modifier in definition.get("modifiers", []):
		if typeof(modifier) == TYPE_DICTIONARY:
			total += abs(float(modifier.get("value", 0.0)) + float(modifier.get("value_per_stack", 0.0)))
	return total

