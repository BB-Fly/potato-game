class_name BuffContainer
extends RefCounted

const BuffInstance = preload("res://src/domain/buff/buff_instance.gd")

var registry
var owner_id = ""
var buffs: Dictionary = {}


func _init(p_registry, p_owner_id: String = "") -> void:
	registry = p_registry
	owner_id = p_owner_id


func apply_buff(buff_id: String, source_id: String = "", stacks: int = 1) -> void:
	var definition = registry.get_entry("buff", buff_id)
	if definition.is_empty():
		push_warning("Buff not found: %s" % buff_id)
		return

	if not buffs.has(buff_id):
		var instance = BuffInstance.new()
		instance.initialize(definition, source_id, stacks)
		buffs[buff_id] = instance
		return

	_merge_buff(buffs[buff_id], definition, stacks)


func tick(_tick_index: int) -> void:
	var expired: Array = []
	for buff_id in buffs.keys():
		var instance = buffs[buff_id]
		_tick_instance(instance)
		if instance.is_expired():
			expired.append(buff_id)
	for buff_id in expired:
		buffs.erase(buff_id)


func _merge_buff(instance, definition: Dictionary, stacks: int) -> void:
	var mode = String(definition.get("stacking_mode", "refresh_duration"))
	var max_stacks = int(definition.get("max_stacks", 1))
	if mode == "refresh_duration":
		instance.remaining_frames = int(definition.get("duration_frames", 0))
	elif mode == "stack_refresh_duration":
		instance.stacks = min(max_stacks, instance.stacks + stacks)
		instance.remaining_frames = int(definition.get("duration_frames", 0))
	elif mode == "independent_timers":
		for _i in range(stacks):
			if instance.per_stack_remaining_frames.size() < max_stacks:
				instance.per_stack_remaining_frames.append(int(definition.get("duration_frames", 0)))
		instance.stacks = instance.per_stack_remaining_frames.size()


func _tick_instance(instance) -> void:
	if not instance.per_stack_remaining_frames.is_empty():
		for i in range(instance.per_stack_remaining_frames.size() - 1, -1, -1):
			instance.per_stack_remaining_frames[i] -= 1
			if instance.per_stack_remaining_frames[i] <= 0:
				instance.per_stack_remaining_frames.remove_at(i)
		instance.stacks = instance.per_stack_remaining_frames.size()
		return

	if instance.remaining_frames > 0:
		instance.remaining_frames -= 1

