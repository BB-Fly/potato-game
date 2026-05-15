class_name ContentRegistry
extends RefCounted

var _entries_by_type: Dictionary = {}


func register_entry(content_type: String, entry: Dictionary) -> bool:
	if content_type.is_empty():
		push_error("Content type is empty.")
		return false
	if not entry.has("id") or String(entry["id"]).is_empty():
		push_error("Content entry for type '%s' has no id." % content_type)
		return false

	var id = String(entry["id"])
	if not _entries_by_type.has(content_type):
		_entries_by_type[content_type] = {}
	if _entries_by_type[content_type].has(id):
		push_error("Duplicate content id '%s' for type '%s'." % [id, content_type])
		return false

	_entries_by_type[content_type][id] = entry
	return true


func has_entry(content_type: String, id: String) -> bool:
	return _entries_by_type.has(content_type) and _entries_by_type[content_type].has(id)


func get_entry(content_type: String, id: String, default_value: Dictionary = {}) -> Dictionary:
	if not has_entry(content_type, id):
		return default_value
	return _entries_by_type[content_type][id]


func get_entries(content_type: String) -> Array:
	if not _entries_by_type.has(content_type):
		return []
	return _entries_by_type[content_type].values()


func get_registered_types() -> Array:
	return _entries_by_type.keys()


func count(content_type: String = "") -> int:
	if content_type.is_empty():
		var total = 0
		for type_name in _entries_by_type.keys():
			total += _entries_by_type[type_name].size()
		return total
	if not _entries_by_type.has(content_type):
		return 0
	return _entries_by_type[content_type].size()


