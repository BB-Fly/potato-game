class_name AudioDirector
extends RefCounted

var registry
var event_bus
var current_music_state_id = ""
var current_track_ref = ""


func _init(p_registry, p_event_bus) -> void:
	registry = p_registry
	event_bus = p_event_bus
	event_bus.subscribe("boss_spawned", Callable(self, "_on_boss_spawned"))
	event_bus.subscribe("combat_won", Callable(self, "_on_combat_finished"))
	event_bus.subscribe("combat_lost", Callable(self, "_on_combat_finished"))


func request_music(music_state_id: String) -> void:
	var state = registry.get_entry("audio", music_state_id)
	if state.is_empty():
		push_warning("Music state not found: %s" % music_state_id)
		return
	current_music_state_id = music_state_id
	current_track_ref = String(state.get("track_ref", ""))
	event_bus.emit_event("music_requested", {
		"music_state_id": current_music_state_id,
		"track_ref": current_track_ref,
		"fade_in_ms": int(state.get("fade_in_ms", 0)),
		"fade_out_ms": int(state.get("fade_out_ms", 0)),
	})


func _on_boss_spawned(_payload: Dictionary) -> void:
	request_music("music_state.combat.boss")


func _on_combat_finished(payload: Dictionary) -> void:
	if payload.has("victory_music_state"):
		request_music(String(payload["victory_music_state"]))

