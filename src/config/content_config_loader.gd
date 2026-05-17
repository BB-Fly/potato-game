class_name ContentConfigLoader
extends RefCounted

const BASE_PATH = "res://content/base"

const CONTENT_DIRS = {
	"schools": "school",
	"characters": "character",
	"weapons": "weapon",
	"magics": "magic",
	"items": "item",
	"buffs": "buff",
	"monsters": "monster",
	"bosses": "boss",
	"maps": "map",
	"rewards": "reward_table",
	"shops": "shop",
	"audio": "audio",
	"assets": "asset",
	"balance": "balance",
}


func load_all(registry) -> Array:
	var warnings: Array = []
	for dir_name in CONTENT_DIRS.keys():
		var content_type = String(CONTENT_DIRS[dir_name])
		var path = "%s/%s" % [BASE_PATH, dir_name]
		warnings.append_array(_load_directory(registry, content_type, path))
	return warnings


func _load_directory(registry, content_type: String, path: String) -> Array:
	var warnings: Array = []
	var dir = DirAccess.open(path)
	if dir == null:
		warnings.append("Content directory missing: %s" % path)
		return warnings

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var file_path = "%s/%s" % [path, file_name]
			var loaded = _load_json_file(file_path)
			if loaded.is_empty():
				warnings.append("Content file is empty or invalid: %s" % file_path)
			else:
				var entries = _extract_entries(loaded)
				for entry in entries:
					if typeof(entry) != TYPE_DICTIONARY:
						warnings.append("Skipping non-dictionary entry in %s" % file_path)
						continue
					var normalized = entry.duplicate(true)
					_normalize_entry(normalized)
					if not registry.register_entry(content_type, normalized):
						warnings.append("Failed to register %s entry in %s" % [content_type, file_path])
		file_name = dir.get_next()
	dir.list_dir_end()
	return warnings


func _load_json_file(path: String):
	var text = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if parsed == null:
		push_error("Invalid JSON: %s" % path)
		return {}
	return parsed


func _extract_entries(parsed) -> Array:
	if typeof(parsed) == TYPE_ARRAY:
		return parsed
	if typeof(parsed) == TYPE_DICTIONARY:
		if parsed.has("entries") and typeof(parsed["entries"]) == TYPE_ARRAY:
			return parsed["entries"]
		return [parsed]
	return []


func _normalize_entry(entry: Dictionary) -> void:
	if entry.has("duration_seconds") and not entry.has("duration_frames"):
		entry["duration_frames"] = int(round(float(entry["duration_seconds"]) * 60.0))
	if entry.has("cooldown_seconds") and not entry.has("cooldown_frames"):
		entry["cooldown_frames"] = int(round(float(entry["cooldown_seconds"]) * 60.0))
	if entry.has("attack_interval_seconds") and not entry.has("attack_interval_frames"):
		entry["attack_interval_frames"] = int(round(float(entry["attack_interval_seconds"]) * 60.0))

