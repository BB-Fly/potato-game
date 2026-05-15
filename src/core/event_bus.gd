class_name GameplayEventBus
extends RefCounted

var _listeners: Dictionary = {}
var _event_log: Array = []
var keep_event_log = true
var max_event_log_size = 512


func subscribe(event_name: String, listener: Callable) -> void:
	if event_name.is_empty() or not listener.is_valid():
		return
	if not _listeners.has(event_name):
		_listeners[event_name] = []
	_listeners[event_name].append(listener)


func unsubscribe(event_name: String, listener: Callable) -> void:
	if not _listeners.has(event_name):
		return
	_listeners[event_name].erase(listener)


func emit_event(event_name: String, payload: Dictionary = {}) -> void:
	if keep_event_log:
		_event_log.append({
			"name": event_name,
			"payload": payload,
		})
		if _event_log.size() > max_event_log_size:
			_event_log.pop_front()

	if not _listeners.has(event_name):
		return

	for listener in _listeners[event_name].duplicate():
		if listener.is_valid():
			listener.call(payload)


func get_event_log() -> Array:
	return _event_log.duplicate(true)


func clear_event_log() -> void:
	_event_log.clear()


