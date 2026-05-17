class_name RunContext
extends RefCounted

const DeterministicRng = preload("res://src/core/deterministic_rng.gd")

var run_id = ""
var character_id = ""
var difficulty_id = ""
var mode_id = ""
var seed = 1
var rng

var current_map_id = ""
var current_chapter_id = ""
var current_area_index = 0
var floor = 1
var gold = 0

var school_state: RefCounted
var inventory = {
	"weapons": [],
	"magics": [],
	"items": [],
}
var equipped_weapons: Array = []
var equipped_magics: Array = []
var acquire_counts: Dictionary = {}
var route_history: Array = []
var reward_history: Array = []
var shop_purchase_counts: Dictionary = {}


func initialize(p_character_id: String, p_difficulty_id: String, p_mode_id: String, p_seed: int) -> void:
	character_id = p_character_id
	difficulty_id = p_difficulty_id
	mode_id = p_mode_id
	seed = p_seed
	rng = DeterministicRng.new(seed)
	run_id = "%s:%s:%s" % [character_id, mode_id, seed]
	equipped_weapons.resize(4)
	equipped_magics.resize(4)


func grant_gold(amount: int) -> void:
	gold += max(0, amount)


func can_spend_gold(amount: int) -> bool:
	return gold >= amount


func spend_gold(amount: int) -> bool:
	if amount < 0 or gold < amount:
		return false
	gold -= amount
	return true


func record_shop_purchase(shop_id: String) -> void:
	if shop_id.is_empty():
		return
	shop_purchase_counts[shop_id] = int(shop_purchase_counts.get(shop_id, 0)) + 1


func record_acquired(content_id: String) -> void:
	acquire_counts[content_id] = get_acquire_count(content_id) + 1


func get_acquire_count(content_id: String) -> int:
	return int(acquire_counts.get(content_id, 0))


func add_weapon(weapon_id: String) -> void:
	inventory["weapons"].append(weapon_id)
	record_acquired(weapon_id)
	_auto_equip(equipped_weapons, weapon_id)


func add_magic(magic_id: String) -> void:
	inventory["magics"].append(magic_id)
	record_acquired(magic_id)
	_auto_equip(equipped_magics, magic_id)


func add_item(item_id: String) -> void:
	inventory["items"].append(item_id)
	record_acquired(item_id)


func _auto_equip(slots: Array, content_id: String) -> void:
	for i in range(slots.size()):
		if slots[i] == null:
			slots[i] = content_id
			return

