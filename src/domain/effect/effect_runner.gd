class_name EffectRunner
extends RefCounted

const CombatFormula = preload("res://src/domain/combat/combat_formula.gd")

var registry
var event_bus


func _init(p_registry, p_event_bus = null) -> void:
	registry = p_registry
	event_bus = p_event_bus


func run_effects(effects: Array, context: Dictionary) -> void:
	for effect in effects:
		if typeof(effect) == TYPE_DICTIONARY:
			run_effect(effect, context)


func run_effect(effect: Dictionary, context: Dictionary) -> void:
	var effect_type = String(effect.get("type", ""))
	match effect_type:
		"apply_buff":
			_apply_buff(effect, context)
		"deal_damage":
			_deal_damage(effect, context)
		"heal":
			_heal(effect, context)
		"restore_mana":
			_restore_mana(effect, context)
		"grant_gold":
			_grant_gold(effect, context)
		"grant_item":
			_grant_item(effect, context)
		"modify_stat":
			_modify_stat(effect, context)
		"emit_event":
			_emit_effect_event(effect, context)
		_:
			push_warning("Unsupported effect type: %s" % effect_type)


func _apply_buff(effect: Dictionary, context: Dictionary) -> void:
	var buff_id = String(effect.get("buff_id", ""))
	var target = _resolve_target(effect.get("target", "self"), context)
	if target != null and target.has_method("apply_buff"):
		var overrides: Dictionary = {}
		for key in ["duration_frames", "duration_seconds", "tick_interval_frames", "tick_seconds"]:
			if effect.has(key):
				overrides[key] = effect[key]
		if overrides.has("duration_seconds") and not overrides.has("duration_frames"):
			overrides["duration_frames"] = int(round(float(overrides["duration_seconds"]) * 60.0))
		if overrides.has("tick_seconds") and not overrides.has("tick_interval_frames"):
			overrides["tick_interval_frames"] = int(round(float(overrides["tick_seconds"]) * 60.0))
		target.apply_buff(buff_id, String(context.get("source_id", "")), int(effect.get("stacks", 1)), overrides)
	if event_bus != null:
		event_bus.emit_event("buff_apply_requested", {
			"buff_id": buff_id,
			"source_id": String(context.get("source_id", "")),
			"target_key": String(effect.get("target", "self")),
		})


func _deal_damage(effect: Dictionary, context: Dictionary) -> void:
	var target = _resolve_target(effect.get("target", "target"), context)
	if target == null or not target.has_method("take_damage"):
		return
	var source = _resolve_target(effect.get("source", "source"), context)
	var amount = CombatFormula.effect_value(effect, source, float(effect.get("amount", effect.get("base", 0.0))))
	if bool(effect.get("per_stack", false)):
		amount *= max(1, int(context.get("stacks", 1)))
	var result = target.take_damage(amount, source, {
		"damage_type": String(effect.get("damage_type", "generic")),
		"ignore_defense": bool(effect.get("ignore_defense", false)),
	})
	if event_bus != null:
		event_bus.emit_event("damage_dealt", {
			"effect": effect,
			"context": context,
			"result": result,
		})


func _heal(effect: Dictionary, context: Dictionary) -> void:
	var target = _resolve_target(effect.get("target", "self"), context)
	if target == null or not target.has_method("heal"):
		return
	var source = _resolve_target(effect.get("source", "source"), context)
	var amount = CombatFormula.effect_value(effect, source, float(effect.get("amount", effect.get("base", 0.0))))
	if bool(effect.get("per_stack", false)):
		amount *= max(1, int(context.get("stacks", 1)))
	target.heal(amount)


func _restore_mana(effect: Dictionary, context: Dictionary) -> void:
	var target = _resolve_target(effect.get("target", "self"), context)
	if target == null or not target.has_method("restore_mana"):
		return
	var source = _resolve_target(effect.get("source", "source"), context)
	var amount = CombatFormula.effect_value(effect, source, float(effect.get("amount", effect.get("base", 0.0))))
	if bool(effect.get("per_stack", false)):
		amount *= max(1, int(context.get("stacks", 1)))
	target.restore_mana(amount)


func _grant_gold(effect: Dictionary, context: Dictionary) -> void:
	var run_context = context.get("run_context")
	if run_context != null and run_context.has_method("grant_gold"):
		run_context.grant_gold(int(effect.get("amount", 0)))


func _grant_item(effect: Dictionary, context: Dictionary) -> void:
	var run_context = context.get("run_context")
	var content_id = String(effect.get("content_id", ""))
	if run_context == null:
		return
	if content_id.begins_with("weapon."):
		run_context.add_weapon(content_id)
	elif content_id.begins_with("magic."):
		run_context.add_magic(content_id)
	elif content_id.begins_with("item."):
		run_context.add_item(content_id)


func _modify_stat(effect: Dictionary, context: Dictionary) -> void:
	var target = _resolve_target(effect.get("target", "self"), context)
	if target == null or not target.has_method("add_modifier"):
		return
	target.add_modifier(
		String(effect.get("stat", "")),
		String(effect.get("operation", "add")),
		float(effect.get("value", 0.0)),
		String(context.get("source_id", ""))
	)


func _emit_effect_event(effect: Dictionary, context: Dictionary) -> void:
	if event_bus == null:
		return
	event_bus.emit_event(String(effect.get("event_name", "effect_event")), {
		"effect": effect,
		"context": context,
	})


func _resolve_target(target_key, context: Dictionary):
	if typeof(target_key) != TYPE_STRING:
		return null
	return context.get(String(target_key))

