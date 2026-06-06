class_name BuffInstance
extends RefCounted

var definition: Dictionary
var source_id = ""
var stacks = 1
var remaining_frames = 0
var per_stack_remaining_frames: Array = []
var tick_accumulator = 0


func initialize(p_definition: Dictionary, p_source_id: String, p_stacks: int = 1, overrides: Dictionary = {}) -> void:
	definition = p_definition.duplicate(true)
	for key in overrides.keys():
		definition[key] = overrides[key]
	source_id = p_source_id
	stacks = max(1, p_stacks)
	remaining_frames = int(definition.get("duration_frames", 0))
	tick_accumulator = 0
	per_stack_remaining_frames.clear()
	if String(definition.get("stacking_mode", "")) == "independent_timers" and remaining_frames >= 0:
		for _i in range(stacks):
			per_stack_remaining_frames.append(remaining_frames)


func is_expired() -> bool:
	if remaining_frames < 0:
		return false
	if not per_stack_remaining_frames.is_empty():
		return per_stack_remaining_frames.is_empty()
	return remaining_frames == 0


func get_buff_id() -> String:
	return String(definition.get("id", ""))


func get_tick_interval_frames() -> int:
	return int(definition.get("tick_interval_frames", 0))


func get_periodic_effects() -> Array:
	var effects = definition.get("periodic_effects", [])
	return effects if typeof(effects) == TYPE_ARRAY else []


func get_behavior_locks() -> Array:
	var locks = definition.get("behavior_locks", [])
	return locks if typeof(locks) == TYPE_ARRAY else []


