class_name FixedTickLoop
extends RefCounted

const TICKS_PER_SECOND = 60
const FIXED_DELTA_SECONDS = 1.0 / float(TICKS_PER_SECOND)

var tick_index = 0
var event_bus: RefCounted
var systems: Array = []


func _init(p_event_bus: RefCounted) -> void:
	event_bus = p_event_bus


func add_system(system: Object) -> void:
	if system == null:
		return
	if not systems.has(system):
		systems.append(system)


func remove_system(system: Object) -> void:
	systems.erase(system)


func step(tick_count: int = 1) -> void:
	for _i in range(tick_count):
		tick_index += 1
		if event_bus != null:
			event_bus.emit_event("tick_started", {
				"tick": tick_index,
				"fixed_delta_seconds": FIXED_DELTA_SECONDS,
			})

		for system in systems:
			if system != null and system.has_method("tick"):
				system.tick(tick_index)

		if event_bus != null:
			event_bus.emit_event("tick_finished", {
				"tick": tick_index,
				"fixed_delta_seconds": FIXED_DELTA_SECONDS,
			})


func seconds_to_frames(seconds: float) -> int:
	return int(round(seconds * TICKS_PER_SECOND))


func frames_to_seconds(frames: int) -> float:
	return float(frames) / float(TICKS_PER_SECOND)


