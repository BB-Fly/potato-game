class_name RewardService
extends RefCounted

var registry
var item_pool


func _init(p_registry, p_item_pool) -> void:
	registry = p_registry
	item_pool = p_item_pool


func build_reward(run_context, reward_table_id: String) -> Dictionary:
	var reward_table = registry.get_entry("reward_table", reward_table_id)
	if reward_table.is_empty():
		return {}

	var reward = {
		"id": reward_table_id,
		"gold": _resolve_gold(run_context, reward_table),
		"offers": [],
	}

	for offer_config in reward_table.get("offers", []):
		var content_type = String(offer_config.get("content_type", "item"))
		reward["offers"].append({
			"content_type": content_type,
			"choices": item_pool.roll_offer(run_context, content_type, offer_config),
		})

	return reward


func apply_reward(run_context, reward: Dictionary, selected_choice_ids: Array = []) -> void:
	run_context.grant_gold(int(reward.get("gold", 0)))
	for choice_id in selected_choice_ids:
		_grant_content(run_context, String(choice_id))
	run_context.reward_history.append(reward)


func _resolve_gold(run_context, reward_table: Dictionary) -> int:
	if reward_table.has("gold_by_floor"):
		var key = str(run_context.floor)
		if reward_table["gold_by_floor"].has(key):
			return int(reward_table["gold_by_floor"][key])
	var base = int(reward_table.get("gold_base", 0))
	var per_floor = int(reward_table.get("gold_per_floor", 0))
	return base + max(0, run_context.floor - 1) * per_floor


func _grant_content(run_context, content_id: String) -> void:
	if content_id.begins_with("weapon."):
		run_context.add_weapon(content_id)
	elif content_id.begins_with("magic."):
		run_context.add_magic(content_id)
	elif content_id.begins_with("item."):
		run_context.add_item(content_id)

