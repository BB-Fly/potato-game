class_name AssetCatalog
extends RefCounted

const CONTENT_TYPE = "asset"

var registry


func _init(p_registry) -> void:
	registry = p_registry


func has_asset(asset_id: String) -> bool:
	return registry != null and registry.has_entry(CONTENT_TYPE, asset_id)


func get_asset_entry(asset_id: String, default_value: Dictionary = {}) -> Dictionary:
	if registry == null:
		return default_value
	return registry.get_entry(CONTENT_TYPE, asset_id, default_value)


func resolve_asset_path(asset_id: String, default_path: String = "") -> String:
	if asset_id.is_empty():
		return default_path
	var entry = get_asset_entry(asset_id)
	if entry.is_empty():
		return default_path
	return String(entry.get("path", default_path))


func resolve_asset_ref(asset_refs: Dictionary, ref_key: String, default_path: String = "") -> String:
	var asset_id = String(asset_refs.get(ref_key, ""))
	return resolve_asset_path(asset_id, default_path)


func resolve_audio_path(audio_id: String, default_path: String = "") -> String:
	return resolve_asset_path(audio_id, default_path)


func resolve_audio_ref(audio_refs: Dictionary, ref_key: String, default_path: String = "") -> String:
	var audio_id = String(audio_refs.get(ref_key, ""))
	return resolve_audio_path(audio_id, default_path)


func resolve_content_asset_path(content_entry: Dictionary, ref_key: String, default_path: String = "") -> String:
	var refs = content_entry.get("asset_refs", {})
	if typeof(refs) != TYPE_DICTIONARY:
		return default_path
	return resolve_asset_ref(refs, ref_key, default_path)


func resolve_content_audio_path(content_entry: Dictionary, ref_key: String, default_path: String = "") -> String:
	var refs = content_entry.get("audio_refs", {})
	if typeof(refs) != TYPE_DICTIONARY:
		return default_path
	return resolve_audio_ref(refs, ref_key, default_path)
