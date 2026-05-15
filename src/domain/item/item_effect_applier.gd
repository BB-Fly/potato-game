class_name ItemEffectApplier
extends RefCounted

var registry


func _init(p_registry) -> void:
	registry = p_registry


func apply_item(run_context, item_id: String) -> void:
	var item = registry.get_entry("item", item_id)
	if item.is_empty():
		push_warning("Item not found: %s" % item_id)
		return
	run_context.add_item(item_id)
	if run_context.school_state != null:
		run_context.school_state.learn_from_entry(item)

