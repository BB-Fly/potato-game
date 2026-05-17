class_name PlayableRewardController
extends RefCounted


func build_starter_offer(item_pool, run_context) -> Array:
	return _filled_offer(
		item_pool,
		run_context,
		"weapon",
		{
			"count": 3,
			"duplicate_policy": "avoid_same_offer",
			"guarantees": [{"slot": 0, "school": "character_primary"}],
		},
		3
	)


func build_reward_offer(item_pool, run_context, reward_id: String) -> Array:
	var content_type = content_type_for_reward(reward_id)
	return _filled_offer(
		item_pool,
		run_context,
		content_type,
		{
			"count": 3,
			"duplicate_policy": "avoid_same_offer",
			"guarantees": [{"slot": 0, "school": "character_primary"}],
		},
		3
	)


func build_shop_offer(item_pool, run_context, node_type: String, count: int = 3) -> Array:
	var content_type = content_type_for_node(node_type)
	return _filled_offer(
		item_pool,
		run_context,
		content_type,
		{
			"count": count,
			"duplicate_policy": "avoid_same_offer",
			"guarantees": [{"slot": 0, "school": "character_primary"}],
		},
		count
	)


func content_type_for_reward(reward_id: String) -> String:
	if reward_id.contains("weapon"):
		return "weapon"
	return "item"


func content_type_for_node(node_type: String) -> String:
	if node_type.contains("weapon"):
		return "weapon"
	if node_type.contains("magic"):
		return "magic"
	return "item"


func grant_content(run_context, content_id: String) -> void:
	if content_id.begins_with("weapon."):
		run_context.add_weapon(content_id)
	elif content_id.begins_with("magic."):
		run_context.add_magic(content_id)
	elif content_id.begins_with("item."):
		run_context.add_item(content_id)


func buy_content(run_context, content_id: String, price: int = -1, shop_id: String = "") -> Dictionary:
	if price < 0:
		price = shop_price(run_context)
	if not run_context.spend_gold(price):
		return {
			"success": false,
			"message": "Gold is not enough",
			"price": price,
		}
	grant_content(run_context, content_id)
	run_context.record_shop_purchase(shop_id)
	return {
		"success": true,
		"message": "Purchased for %d gold" % price,
		"price": price,
	}


func shop_price(run_context) -> int:
	return 120 + run_context.floor * 35


func fill_offer_choices(item_pool, run_context, entries: Array, count: int, content_type: String) -> Array:
	var result = entries.duplicate()
	if result.is_empty():
		result = item_pool.build_candidates(run_context, content_type, {})
	if result.is_empty():
		return []
	var i = 0
	while result.size() < count:
		result.append(result[i % result.size()])
		i += 1
	return result.slice(0, count)


func _filled_offer(item_pool, run_context, content_type: String, offer_config: Dictionary, count: int) -> Array:
	return fill_offer_choices(
		item_pool,
		run_context,
		item_pool.roll_offer(run_context, content_type, offer_config),
		count,
		content_type
	)
