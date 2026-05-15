class_name EconomyService
extends RefCounted

var registry


func _init(p_registry) -> void:
	registry = p_registry


func price_for_entry(run_context, shop_id: String, entry: Dictionary) -> int:
	var shop = registry.get_entry("shop", shop_id)
	if shop.is_empty():
		return 0

	var rarity = String(entry.get("rarity", "common"))
	var ranges = shop.get("price_by_rarity", {})
	var price_range: Array = ranges.get(rarity, [0, 0])
	var base_price = int(round((float(price_range[0]) + float(price_range[1])) / 2.0))
	var floor_increase = int(shop.get("floor_price_increase", 0)) * max(0, run_context.floor - 1)
	var price = base_price + floor_increase

	if _is_first_shop_purchase(run_context, shop_id) and _has_first_purchase_discount(run_context):
		price = int(ceil(float(price) * 0.5))

	return max(0, price)


func service_price(run_context, shop_id: String, service_id: String) -> int:
	var shop = registry.get_entry("shop", shop_id)
	var service_prices = shop.get("service_prices", {})
	var base_price = int(service_prices.get(service_id, shop.get("service_price", 0)))
	var floor_increase = int(shop.get("service_floor_price_increase", shop.get("floor_price_increase", 0)))
	return base_price + floor_increase * max(0, run_context.floor - 1)


func _is_first_shop_purchase(run_context, shop_id: String) -> bool:
	return int(run_context.shop_purchase_counts.get(shop_id, 0)) == 0


func _has_first_purchase_discount(run_context) -> bool:
	return run_context.character_id == "character.potato_hero"

