class_name SchoolState
extends RefCounted

const METAMORPH_SCHOOL_ID = "school.metamorph"

var primary_school_id = ""
var non_metamorph_school_limit = 3
var active_school_ids: Array = []


func initialize(p_primary_school_id: String) -> void:
	primary_school_id = p_primary_school_id
	_add_school(primary_school_id)


func learn_from_entry(entry: Dictionary) -> void:
	for school_id in entry.get("school_ids", []):
		_add_school(String(school_id))


func can_entry_appear(entry: Dictionary) -> bool:
	var school_ids: Array = entry.get("school_ids", [])
	if school_ids.is_empty():
		return true

	var unknown_non_metamorph = []
	for school_id in school_ids:
		var normalized = String(school_id)
		if normalized == METAMORPH_SCHOOL_ID:
			continue
		if not active_school_ids.has(normalized):
			unknown_non_metamorph.append(normalized)

	if unknown_non_metamorph.is_empty():
		return true

	return _current_non_metamorph_count() + unknown_non_metamorph.size() <= non_metamorph_school_limit


func _add_school(school_id: String) -> void:
	if school_id.is_empty() or active_school_ids.has(school_id):
		return
	active_school_ids.append(school_id)


func _current_non_metamorph_count() -> int:
	var count = 0
	for school_id in active_school_ids:
		if school_id != METAMORPH_SCHOOL_ID:
			count += 1
	return count


