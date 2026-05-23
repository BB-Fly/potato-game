class_name PlayableInputActions
extends RefCounted


static func ensure_defaults() -> void:
	ensure_action("move_left", [KEY_A, KEY_LEFT])
	ensure_action("move_right", [KEY_D, KEY_RIGHT])
	ensure_action("move_up", [KEY_W, KEY_UP])
	ensure_action("move_down", [KEY_S, KEY_DOWN])
	var magic_keys = [KEY_Q, KEY_E, KEY_R, KEY_F]
	for i in range(magic_keys.size()):
		ensure_action("cast_magic_%d" % i, [magic_keys[i]])
	ensure_action("map_snap_up", [KEY_PAGEUP])
	ensure_action("map_snap_down", [KEY_PAGEDOWN])


static func ensure_action(action_name: String, keycodes: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for keycode in keycodes:
		var exists = false
		for event in InputMap.action_get_events(action_name):
			if event is InputEventKey and event.keycode == keycode:
				exists = true
				break
		if not exists:
			var key_event = InputEventKey.new()
			key_event.keycode = keycode
			InputMap.action_add_event(action_name, key_event)
