class_name StatBlock
extends RefCounted

var base_values: Dictionary = {}
var flat_modifiers: Dictionary = {}
var additive_percent_modifiers: Dictionary = {}
var multiplicative_modifiers: Dictionary = {}
var final_add_modifiers: Dictionary = {}


func set_base(stat_id: String, value: float) -> void:
	base_values[stat_id] = value


func get_base(stat_id: String) -> float:
	return float(base_values.get(stat_id, 0.0))


func add_modifier(stat_id: String, operation: String, value: float, source_id: String = "") -> void:
	var bucket = _bucket_for_operation(operation)
	if not bucket.has(stat_id):
		bucket[stat_id] = []
	bucket[stat_id].append({
		"value": value,
		"source_id": source_id,
	})


func remove_modifiers_from_source(source_id: String) -> void:
	for bucket in [flat_modifiers, additive_percent_modifiers, multiplicative_modifiers, final_add_modifiers]:
		for stat_id in bucket.keys():
			bucket[stat_id] = bucket[stat_id].filter(func(modifier): return modifier.get("source_id", "") != source_id)


func get_final(stat_id: String) -> float:
	var base = get_base(stat_id)
	var flat = _sum_bucket(flat_modifiers, stat_id)
	var additive_percent = _sum_bucket(additive_percent_modifiers, stat_id)
	var multiplicative = _product_bucket(multiplicative_modifiers, stat_id)
	var final_add = _sum_bucket(final_add_modifiers, stat_id)
	return ((base + flat) * (1.0 + additive_percent)) * multiplicative + final_add


func apply_base_stats(stats: Dictionary) -> void:
	for stat_id in stats.keys():
		set_base(String(stat_id), float(stats[stat_id]))


func _bucket_for_operation(operation: String) -> Dictionary:
	match operation:
		"add":
			return flat_modifiers
		"add_percent":
			return additive_percent_modifiers
		"multiply":
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

