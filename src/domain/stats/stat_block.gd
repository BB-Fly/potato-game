class_name StatBlock
extends RefCounted

var base_values: Dictionary = {}
var stat_rules: Dictionary = {}
var operation_aliases: Dictionary = {}
var flat_modifiers: Dictionary = {}
var additive_percent_modifiers: Dictionary = {}
var multiplicative_modifiers: Dictionary = {}
var final_add_modifiers: Dictionary = {}


func configure(p_stat_rules: Dictionary = {}, p_operation_aliases: Dictionary = {}) -> void:
	stat_rules = p_stat_rules.duplicate(true)
	operation_aliases = p_operation_aliases.duplicate(true)


func set_base(stat_id: String, value: float) -> void:
	base_values[stat_id] = value


func get_base(stat_id: String) -> float:
	return float(base_values.get(stat_id, _default_for_stat(stat_id)))


func add_modifier(stat_id: String, operation: String, value: float, source_id: String = "") -> void:
	var bucket = _bucket_for_operation(operation)
	if not bucket.has(stat_id):
		bucket[stat_id] = []
	bucket[stat_id].append({
		"value": value,
		"source_id": source_id,
	})


func apply_modifiers(modifiers: Array, source_id: String = "", stacks: int = 1) -> void:
	for modifier in modifiers:
		if typeof(modifier) != TYPE_DICTIONARY:
			continue
		var stat_id = String(modifier.get("stat", ""))
		if stat_id.is_empty():
			continue
		var value = float(modifier.get("value", 0.0))
		value += float(modifier.get("value_per_stack", 0.0)) * float(max(1, stacks))
		add_modifier(stat_id, String(modifier.get("operation", "add")), value, source_id)


func remove_modifiers_from_source(source_id: String) -> void:
	for bucket in [flat_modifiers, additive_percent_modifiers, multiplicative_modifiers, final_add_modifiers]:
		for stat_id in bucket.keys():
			bucket[stat_id] = bucket[stat_id].filter(func(modifier): return modifier.get("source_id", "") != source_id)
			if bucket[stat_id].is_empty():
				bucket.erase(stat_id)


func clear_modifiers() -> void:
	flat_modifiers.clear()
	additive_percent_modifiers.clear()
	multiplicative_modifiers.clear()
	final_add_modifiers.clear()


func get_final(stat_id: String) -> float:
	var base = get_base(stat_id)
	var flat = _sum_bucket(flat_modifiers, stat_id)
	var additive_percent = _sum_bucket(additive_percent_modifiers, stat_id)
	var multiplicative = _product_bucket(multiplicative_modifiers, stat_id)
	var final_add = _sum_bucket(final_add_modifiers, stat_id)
	return _apply_limits(stat_id, ((base + flat) * (1.0 + additive_percent)) * multiplicative + final_add)


func get_modifier_total(stat_id: String, operation: String) -> float:
	var bucket = _bucket_for_operation(operation)
	if bucket == multiplicative_modifiers:
		return _product_bucket(bucket, stat_id)
	return _sum_bucket(bucket, stat_id)


func get_known_stat_ids() -> Array:
	var ids: Array = []
	for source in [stat_rules, base_values, flat_modifiers, additive_percent_modifiers, multiplicative_modifiers, final_add_modifiers]:
		for stat_id in source.keys():
			if not ids.has(stat_id):
				ids.append(stat_id)
	return ids


func get_snapshot() -> Dictionary:
	var snapshot: Dictionary = {}
	for stat_id in get_known_stat_ids():
		snapshot[String(stat_id)] = get_final(String(stat_id))
	return snapshot


func apply_base_stats(stats: Dictionary) -> void:
	for stat_id in stats.keys():
		set_base(String(stat_id), float(stats[stat_id]))


func _bucket_for_operation(operation: String) -> Dictionary:
	var normalized = String(operation_aliases.get(operation, operation))
	match normalized:
		"add":
			return flat_modifiers
		"flat_add":
			return flat_modifiers
		"add_percent":
			return additive_percent_modifiers
		"additive_percent":
			return additive_percent_modifiers
		"multiply":
			return multiplicative_modifiers
		"mult":
			return multiplicative_modifiers
		"final_add":
			return final_add_modifiers
		_:
			return flat_modifiers


func _sum_bucket(bucket: Dictionary, stat_id: String) -> float:
	var total = 0.0
	for modifier in bucket.get(stat_id, []):
		total += float(modifier.get("value", 0.0))
	return total


func _product_bucket(bucket: Dictionary, stat_id: String) -> float:
	var total = 1.0
	for modifier in bucket.get(stat_id, []):
		total *= float(modifier.get("value", 1.0))
	return total


func _default_for_stat(stat_id: String) -> float:
	var rule = stat_rules.get(stat_id, {})
	if typeof(rule) == TYPE_DICTIONARY and rule.has("default"):
		return float(rule["default"])
	return 0.0


func _apply_limits(stat_id: String, value: float) -> float:
	var rule = stat_rules.get(stat_id, {})
	if typeof(rule) != TYPE_DICTIONARY:
		return value
	if rule.has("min"):
		value = max(value, float(rule["min"]))
	if rule.has("max"):
		value = min(value, float(rule["max"]))
	return value
