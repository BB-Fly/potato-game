class_name CombatFormula
extends RefCounted

const TICKS_PER_SECOND = 60.0


static func scaled_stats(entry: Dictionary, floor: int, scaling_rules: Dictionary = {}, actor_type: String = "monster") -> Dictionary:
	var stats = entry.get("stats", {}).duplicate(true)
	if actor_type == "boss":
		_apply_boss_scaling(stats, floor, scaling_rules)
	else:
		_apply_floor_scaling(stats, floor, scaling_rules)
	return stats


static func weapon_damage(attacker, target, weapon_entry: Dictionary, rng = null, formula_rules: Dictionary = {}) -> Dictionary:
	var damage_cfg = weapon_entry.get("damage", {})
	var amount = _scaled_value(damage_cfg, attacker, float(formula_rules.get("default_weapon_damage", 1.0)))
	amount = max(float(formula_rules.get("minimum_damage_before_modifiers", 1.0)), amount)
	amount *= 1.0 + _actor_stat(attacker, "global_damage_percent")
	if target != null and String(target.actor_type) == "boss":
		amount *= 1.0 + _actor_stat(attacker, "boss_damage_percent")

	var crit_chance = float(weapon_entry.get("crit_chance", 0.0)) + _actor_stat(attacker, "crit_chance")
	var crit_cap = float(formula_rules.get("crit_cap", 0.75))
	crit_chance = clamp(crit_chance, 0.0, crit_cap)
	var crit_multiplier = max(
		float(formula_rules.get("minimum_crit_multiplier", 1.5)),
		float(weapon_entry.get("crit_multiplier", formula_rules.get("default_crit_multiplier", 2.0))) + _actor_stat(attacker, "crit_multiplier_bonus")
	)
	var is_crit = _roll_chance(rng, crit_chance)
	if is_crit:
		amount *= crit_multiplier

	if target != null:
		amount += _actor_stat(target, "weapon_damage_taken_flat")

	amount = ceil(max(float(formula_rules.get("minimum_final_damage", 1.0)), amount))
	return {
		"amount": amount,
		"is_crit": is_crit,
		"crit_chance": crit_chance,
		"crit_multiplier": crit_multiplier,
	}


static func magic_damage(caster, target, magic_entry: Dictionary, formula_rules: Dictionary = {}) -> Dictionary:
	var effect = magic_entry.get("combat_effect", {})
	var damage_cfg = effect.get("damage", effect)
	var amount = _scaled_value(damage_cfg, caster, float(formula_rules.get("default_magic_damage", 0.0)))
	amount *= 1.0 + _actor_stat(caster, "spell_effect_percent")
	if target != null and String(target.actor_type) == "boss":
		amount *= 1.0 + _actor_stat(caster, "boss_damage_percent")
	amount = ceil(max(float(formula_rules.get("minimum_final_damage", 1.0)), amount))
	return {
		"amount": amount,
		"is_crit": false,
	}


static func effect_value(effect: Dictionary, source_actor = null, default_value: float = 0.0) -> float:
	return _scaled_value(effect, source_actor, default_value)


static func attack_interval_seconds(attacker, weapon_entry: Dictionary, formula_rules: Dictionary = {}) -> float:
	var base_frames = max(1.0, float(weapon_entry.get("attack_interval_frames", formula_rules.get("default_attack_interval_frames", 60))))
	var base_seconds = base_frames / TICKS_PER_SECOND
	var speed_multiplier = clamp(
		1.0 + _actor_stat(attacker, "attack_speed"),
		float(formula_rules.get("attack_speed_multiplier_min", 0.35)),
		float(formula_rules.get("attack_speed_multiplier_max", 3.0))
	)
	var min_interval = float(weapon_entry.get("min_attack_interval_seconds", formula_rules.get("weapon_min_interval_seconds", 0.25)))
	return max(min_interval, base_seconds / speed_multiplier)


static func cooldown_seconds(caster, entry: Dictionary, formula_rules: Dictionary = {}) -> float:
	var base_frames = max(0.0, float(entry.get("cooldown_frames", formula_rules.get("default_cooldown_frames", 0))))
	var reduction_cap = float(formula_rules.get("cooldown_reduction_cap", 0.5))
	var reduction = clamp(_actor_stat(caster, "cooldown_reduction"), 0.0, reduction_cap)
	return base_frames / TICKS_PER_SECOND * (1.0 - reduction)


static func incoming_damage(raw_damage: float, target, formula_rules: Dictionary = {}) -> int:
	if bool(formula_rules.get("ignore_defense", false)):
		return int(ceil(max(1.0, raw_damage)))
	var defense = _actor_stat(target, "defense")
	var multiplier = defense_damage_multiplier(defense, formula_rules)
	multiplier *= max(0.0, 1.0 + _actor_stat(target, "damage_taken_percent"))
	var flat = _actor_stat(target, "damage_taken_flat")
	return int(ceil(max(1.0, raw_damage * multiplier + flat)))


static func defense_damage_multiplier(defense: float, formula_rules: Dictionary = {}) -> float:
	if defense >= 0.0:
		var defense_scale = float(formula_rules.get("defense_scale", 6.0))
		return 100.0 / (100.0 + defense * defense_scale)
	return 1.0 + abs(defense) * float(formula_rules.get("negative_defense_damage_per_point", 0.04))


static func _scaled_value(config, actor, default_value: float = 0.0) -> float:
	if typeof(config) != TYPE_DICTIONARY:
		return float(config) if typeof(config) in [TYPE_INT, TYPE_FLOAT] else default_value
	var value = float(config.get("base", config.get("amount", default_value)))
	var scales = config.get("scales", [])
	if typeof(scales) == TYPE_ARRAY:
		for scale in scales:
			if typeof(scale) != TYPE_DICTIONARY:
				continue
			value += _actor_stat(actor, String(scale.get("stat", ""))) * float(scale.get("ratio", 0.0))
	if config.has("stat"):
		value += _actor_stat(actor, String(config.get("stat", ""))) * float(config.get("ratio", 0.0))
	return value


static func _actor_stat(actor, stat_id: String) -> float:
	if actor == null or stat_id.is_empty():
		return 0.0
	if actor.has_method("get_stat"):
		return float(actor.get_stat(stat_id))
	return 0.0


static func _roll_chance(rng, chance: float) -> bool:
	if chance <= 0.0:
		return false
	if chance >= 1.0:
		return true
	if rng != null and rng.has_method("randf_range"):
		return rng.randf_range(0.0, 1.0) <= chance
	return randf() <= chance


static func _apply_floor_scaling(stats: Dictionary, floor: int, scaling_rules: Dictionary) -> void:
	var floor_rule = _floor_rule(floor, scaling_rules.get("floor_multipliers", {}))
	_multiply_stat(stats, "max_health", float(floor_rule.get("health", 1.0)))
	_multiply_stat(stats, "attack", float(floor_rule.get("attack", 1.0)))
	_multiply_stat(stats, "move_speed", float(floor_rule.get("speed", 1.0)))


static func _apply_boss_scaling(stats: Dictionary, floor: int, scaling_rules: Dictionary) -> void:
	var boss_rules = scaling_rules.get("boss", {})
	var health_multiplier = 1.0 + float(boss_rules.get("health_per_floor", 0.55)) * float(max(0, floor - 1))
	_multiply_stat(stats, "max_health", health_multiplier)
	var floor_rule = _floor_rule(floor, scaling_rules.get("floor_multipliers", {}))
	_multiply_stat(stats, "attack", float(floor_rule.get("attack", 1.0)))
	_multiply_stat(stats, "move_speed", float(floor_rule.get("speed", 1.0)))


static func _floor_rule(floor: int, floor_multipliers) -> Dictionary:
	if typeof(floor_multipliers) != TYPE_DICTIONARY:
		return {}
	var key = str(max(1, floor))
	if floor_multipliers.has(key) and typeof(floor_multipliers[key]) == TYPE_DICTIONARY:
		return floor_multipliers[key]
	return {}


static func _multiply_stat(stats: Dictionary, stat_id: String, multiplier: float) -> void:
	if stats.has(stat_id):
		stats[stat_id] = float(stats[stat_id]) * multiplier
