class_name ItemPoolService
extends RefCounted

var registry


func _init(p_registry) -> void:
	registry = p_registry


func build_candidates(run_context, content_type: String, options: Dictionary = {}) -> Array:
	var entries = registry.get_entries(content_type)
	var candidates: Array = []

	for entry in entries:
		if not bool(entry.get("enabled", true)):
			continue
		if not _matches_rarity(entry, options):
			continue
		if not _matches_school(run_context, entry):
			continue
		if not _matches_acquire_limit(run_context, entry):
			continue
		if not _matches_tags(entry, options):
			continue
		candidates.append(entry)

	return candidates


func roll_offer(run_context, content_type: String, offer_config: Dictionary) -> Array:
	var count = int(offer_config.get("count", 3))
	var duplicate_policy = String(offer_config.get("duplicate_policy", "avoid_same_offer"))
	var result: Array = []
	var used_ids = {}

	for guarantee in offer_config.get("guarantees", []):
		if typeof(guarantee) != TYPE_DICTIONARY:
			continue
		var guaranteed = _roll_guaranteed(run_context, content_type, guarantee, used_ids)
		if not guaranteed.is_empty():
			result.append(guaranteed)
			used_ids[guaranteed["id"]] = true

	while result.size() < count:
		var candidates = build_candidates(run_context, content_type, offer_config)
		if duplicate_policy == "avoid_same_offer":
			candidates = candidates.filter(func(entry): return not used_ids.has(entry.get("id", "")))
		if candidates.is_empty():
			break
		var picked = run_context.rng.weighted_pick(candidates)
		if picked == null:
			break
		result.append(picked)
		used_ids[picked["id"]] = true

	return result


func _roll_guaranteed(run_context, content_type: String, guarantee: Dictionary, used_ids: Dictionary) -> Dictionary:
	var options = guarantee.duplicate(true)
	if String(options.get("school", "")) == "character_primary":
		options["required_school_id"] = run_context.school_state.primary_school_id

	var candidates = build_candidates(run_context, content_type, options)
	candidates = candidates.filter(func(entry): return not used_ids.has(entry.get("id", "")))
	var picked = run_context.rng.weighted_pick(candidates)
	if picked == null:
		return {}
	return picked


func _matches_rarity(entry: Dictionary, options: Dictionary) -> bool:
	if not options.has("rarity"):
		return true
	return String(entry.get("rarity", "")) == String(options["rarity"])


func _matches_school(run_context, entry: Dictionary) -> bool:
	if run_context.school_state == null:
		return true
	return run_context.school_state.can_entry_appear(entry)


func _matches_acquire_limit(run_context, entry: Dictionary) -> bool:
	var acquire_limit = int(entry.get("acquire_limit", 0))
	if acquire_limit <= 0:
		return true
	return run_context.get_acquire_count(String(entry.get("id", ""))) < acquire_limit


func _matches_tags(entry: Dictionary, options: Dictionary) -> bool:
	if not options.has("required_school_id"):
		return true
	var required_school_id = String(options["required_school_id"])
	return entry.get("school_ids", []).has(required_school_id)

