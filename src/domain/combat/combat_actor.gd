class_name CombatActor
extends RefCounted

const StatBlock = preload("res://src/domain/stats/stat_block.gd")
const BuffContainer = preload("res://src/domain/buff/buff_container.gd")
const CombatFormula = preload("res://src/domain/combat/combat_formula.gd")

var registry
var actor_id = ""
var actor_type = ""
var content_id = ""
var definition: Dictionary = {}
var stat_block
var buff_container
var formula_rules: Dictionary = {}
var current_health = 0.0
var max_health = 0.0
var current_mana = 0.0
var max_mana = 0.0
var current_energy = 0.0
var max_energy = 0.0
var shield_value = 0.0


func initialize(p_registry, p_actor_type: String, p_content_id: String, p_definition: Dictionary, base_stats: Dictionary, runtime_rules: Dictionary = {}) -> void:
	registry = p_registry
	actor_type = p_actor_type
	content_id = p_content_id
	definition = p_definition.duplicate(true)
	actor_id = "%s:%s:%d" % [actor_type, content_id, get_instance_id()]
	formula_rules = runtime_rules.get("formulas", {}).duplicate(true)

	stat_block = StatBlock.new()
	stat_block.configure(
		runtime_rules.get("stat_rules", {}),
		runtime_rules.get("operation_aliases", {})
	)
	stat_block.apply_base_stats(base_stats)

	buff_container = BuffContainer.new(registry, actor_id)
	buff_container.bind_stat_block(stat_block)
	_initialize_resources()


func get_stat(stat_id: String) -> float:
	if stat_block == null:
		return 0.0
	return stat_block.get_final(stat_id)


func apply_buff(buff_id: String, source_id: String = "", stacks: int = 1, overrides: Dictionary = {}) -> void:
	var before = _resource_snapshot()
	buff_container.apply_buff(buff_id, source_id, stacks, overrides)
	_refresh_resource_limits(before)


func tick(delta_seconds: float, effect_runner = null, context: Dictionary = {}) -> void:
	var before = _resource_snapshot()
	var tick_context = context.duplicate()
	tick_context["self"] = self
	if not tick_context.has("target"):
		tick_context["target"] = self
	buff_container.tick_seconds(delta_seconds, effect_runner, tick_context)
	_refresh_resource_limits(before)
	_apply_regen(delta_seconds)


func take_damage(raw_damage: float, source_actor = null, options: Dictionary = {}) -> Dictionary:
	if raw_damage <= 0.0 or is_dead():
		return {"raw": raw_damage, "amount": 0, "absorbed": 0.0, "hp": current_health}
	var incoming = int(ceil(max(1.0, raw_damage)))
	if not bool(options.get("ignore_defense", false)):
		incoming = CombatFormula.incoming_damage(raw_damage, self, formula_rules)

	var absorbed = min(shield_value, float(incoming))
	shield_value -= absorbed
	var health_damage = max(0.0, float(incoming) - absorbed)
	current_health = max(0.0, current_health - health_damage)
	return {
		"raw": raw_damage,
		"amount": int(ceil(health_damage)),
		"absorbed": absorbed,
		"hp": current_health,
		"source": source_actor,
	}


func heal(amount: float) -> float:
	if amount <= 0.0 or is_dead():
		return 0.0
	var before = current_health
	current_health = min(max_health, current_health + amount)
	return current_health - before


func restore_mana(amount: float) -> float:
	if amount <= 0.0:
		return 0.0
	var before = current_mana
	current_mana = min(max_mana, current_mana + amount)
	return current_mana - before


func spend_mana(amount: float) -> bool:
	if amount < 0.0 or current_mana < amount:
		return false
	current_mana -= amount
	return true


func is_dead() -> bool:
	return current_health <= 0.0


func has_behavior_lock(lock_id: String) -> bool:
	return buff_container != null and buff_container.has_behavior_lock(lock_id)


func _initialize_resources() -> void:
	max_health = max(1.0, get_stat("max_health"))
	current_health = max_health
	max_mana = max(0.0, get_stat("max_mana"))
	current_mana = max_mana
	max_energy = max(0.0, get_stat("max_energy"))
	current_energy = max_energy


func _refresh_resource_limits(before: Dictionary) -> void:
	var previous_max_health = float(before.get("max_health", max_health))
	var previous_max_mana = float(before.get("max_mana", max_mana))
	var previous_max_energy = float(before.get("max_energy", max_energy))

	max_health = max(1.0, get_stat("max_health"))
	max_mana = max(0.0, get_stat("max_mana"))
	max_energy = max(0.0, get_stat("max_energy"))

	if max_health > previous_max_health:
		current_health += max_health - previous_max_health
	if max_mana > previous_max_mana:
		current_mana += max_mana - previous_max_mana
	if max_energy > previous_max_energy:
		current_energy += max_energy - previous_max_energy

	current_health = clamp(current_health, 0.0, max_health)
	current_mana = clamp(current_mana, 0.0, max_mana)
	current_energy = clamp(current_energy, 0.0, max_energy)


func _resource_snapshot() -> Dictionary:
	return {
		"max_health": max_health,
		"max_mana": max_mana,
		"max_energy": max_energy,
	}


func _apply_regen(delta_seconds: float) -> void:
	if is_dead():
		return
	heal(max(0.0, get_stat("health_regen")) * delta_seconds)
	restore_mana(max(0.0, get_stat("mana_regen")) * delta_seconds)
