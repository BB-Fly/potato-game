class_name CombatRuntime
extends RefCounted

enum CombatState {
	IDLE,
	MOB_PHASE,
	BOSS_INTRO,
	BOSS_PHASE,
	VICTORY,
	DEFEAT,
}

var registry
var event_bus
var run_context
var state = CombatState.IDLE
var combat_tick = 0
var mob_phase_end_tick = 0
var boss_id = ""


func _init(p_registry, p_event_bus, p_run_context) -> void:
	registry = p_registry
	event_bus = p_event_bus
	run_context = p_run_context


func start_combat(combat_config: Dictionary = {}) -> void:
	combat_tick = 0
	state = CombatState.MOB_PHASE
	mob_phase_end_tick = int(combat_config.get("mob_phase_frames", _default_mob_phase_frames()))
	boss_id = String(combat_config.get("boss_id", "boss.demo_pollution_source"))
	event_bus.emit_event("combat_started", {
		"floor": run_context.floor,
		"mob_phase_frames": mob_phase_end_tick,
		"boss_id": boss_id,
	})


func tick(_global_tick: int) -> void:
	if state == CombatState.IDLE or state == CombatState.VICTORY or state == CombatState.DEFEAT:
		return

	combat_tick += 1
	if state == CombatState.MOB_PHASE and combat_tick >= mob_phase_end_tick:
		_enter_boss_phase()


func mark_boss_defeated() -> void:
	if state != CombatState.BOSS_PHASE:
		return
	state = CombatState.VICTORY
	event_bus.emit_event("combat_won", {
		"floor": run_context.floor,
		"combat_tick": combat_tick,
		"boss_id": boss_id,
	})


func mark_player_defeated() -> void:
	state = CombatState.DEFEAT
	event_bus.emit_event("combat_lost", {
		"floor": run_context.floor,
		"combat_tick": combat_tick,
	})


func _enter_boss_phase() -> void:
	state = CombatState.BOSS_INTRO
	event_bus.emit_event("boss_intro_started", {
		"boss_id": boss_id,
		"combat_tick": combat_tick,
	})
	state = CombatState.BOSS_PHASE
	event_bus.emit_event("boss_spawned", {
		"boss_id": boss_id,
		"combat_tick": combat_tick,
	})


func _default_mob_phase_frames() -> int:
	var seconds_by_floor = {
		1: 45,
		2: 50,
		3: 60,
		4: 70,
		5: 80,
		6: 90,
	}
	return int(seconds_by_floor.get(run_context.floor, 90)) * 60

