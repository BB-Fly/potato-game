class_name MagicRuntime
extends RefCounted

var definition: Dictionary
var cooldown_frames = 0
var auto_cast_interval_frames = 0
var auto_cast_counter = 0


func initialize(p_definition: Dictionary) -> void:
	definition = p_definition
	cooldown_frames = 0
	auto_cast_interval_frames = int(definition.get("auto_cast_interval_frames", 0))
	auto_cast_counter = auto_cast_interval_frames


func can_cast(current_mana: int, current_energy: int) -> bool:
	return cooldown_frames <= 0 \
		and current_mana >= int(definition.get("mana_cost", 0)) \
		and current_energy >= int(definition.get("energy_cost", 0))


func mark_cast() -> void:
	cooldown_frames = int(definition.get("cooldown_frames", 0))


func tick() -> bool:
	if cooldown_frames > 0:
		cooldown_frames -= 1
	if auto_cast_interval_frames <= 0:
		return false
	auto_cast_counter -= 1
	if auto_cast_counter <= 0:
		auto_cast_counter = auto_cast_interval_frames
		return true
	return false


