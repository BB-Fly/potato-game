class_name WeaponRuntime
extends RefCounted

var definition: Dictionary
var cooldown_frames = 0


func initialize(p_definition: Dictionary) -> void:
	definition = p_definition
	cooldown_frames = 0


func tick() -> bool:
	if cooldown_frames > 0:
		cooldown_frames -= 1
		return false
	cooldown_frames = int(definition.get("attack_interval_frames", 60))
	return true


