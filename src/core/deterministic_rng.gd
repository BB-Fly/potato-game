class_name DeterministicRng
extends RefCounted

var rng = RandomNumberGenerator.new()


func _init(seed_value: int = 1) -> void:
	rng.seed = seed_value


func randi_range(min_value: int, max_value: int) -> int:
	return rng.randi_range(min_value, max_value)


func randf_range(min_value: float, max_value: float) -> float:
	return rng.randf_range(min_value, max_value)


func pick(array: Array, default_value = null):
	if array.is_empty():
		return default_value
	return array[rng.randi_range(0, array.size() - 1)]


func weighted_pick(entries: Array, weight_key: String = "weight", default_weight: float = 1.0):
	if entries.is_empty():
		return null

	var total_weight = 0.0
	for entry in entries:
		if typeof(entry) == TYPE_DICTIONARY:
			total_weight += max(0.0, float(entry.get(weight_key, default_weight)))
		else:
			total_weight += max(0.0, default_weight)

	if total_weight <= 0.0:
		return pick(entries)

	var roll = rng.randf_range(0.0, total_weight)
	var cursor = 0.0
	for entry in entries:
		var weight = default_weight
		if typeof(entry) == TYPE_DICTIONARY:
			weight = float(entry.get(weight_key, default_weight))
		cursor += max(0.0, weight)
		if roll <= cursor:
			return entry

	return entries.back()


