class_name BuffInstance
extends RefCounted

var definition: Dictionary
var source_id = ""
var stacks = 1
var remaining_frames = 0
var per_stack_remaining_frames: Array = []
var tick_accumulator = 0


func initialize(p_definition: Dictionary, p_source_id: String, p_stacks: int = 1) -> void:
	definition = p_definition
	source_id = p_source_id
	stacks = p_stacks
	remaining_frames = int(definition.get("duration_frames", 0))
	if String(definition.get("stack_mode", "")) == "independent_timers":
		for _i in range(stacks):
			per_stack_remaining_frames.append(remaining_frames)


func is_expired() -> bool:
	if remaining_frames < 0:
		return false
	if not per_stack_remaining_frames.is_empty():
		return per_stack_remaining_frames.is_empty()
	return remaining_frames == 0


