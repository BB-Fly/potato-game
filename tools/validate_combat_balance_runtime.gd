extends SceneTree

const ContentRegistry = preload("res://src/core/registry.gd")
const ContentConfigLoader = preload("res://src/config/content_config_loader.gd")
const RunContext = preload("res://src/domain/run/run_context.gd")
const SchoolState = preload("res://src/domain/school/school_state.gd")
const AssetCatalog = preload("res://src/config/asset_catalog.gd")
const EffectRunner = preload("res://src/domain/effect/effect_runner.gd")
const PlayableInputActions = preload("res://src/app/playable/playable_input_actions.gd")
const CombatScenePacked = preload("res://scenes/combat_scene.tscn")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	PlayableInputActions.ensure_defaults()

	var registry = ContentRegistry.new()
	var loader = ContentConfigLoader.new()
	var warnings = loader.load_all(registry)
	if not warnings.is_empty():
		_fail("Content warnings: %s" % [warnings])
		return

	var character = registry.get_entry("character", "character.potato_hero")
	var run_context = RunContext.new()
	run_context.initialize("character.potato_hero", "difficulty.normal", "mode.demo", 1)
	run_context.school_state = SchoolState.new()
	run_context.school_state.initialize(character.get("primary_school_id", "school.metamorph"))
	run_context.add_weapon("weapon.metamorph.fries")
	run_context.add_magic("magic.metamorph.comprehensive_development")
	run_context.add_item("item.metamorph.potato_enhancement")

	var combat_scene = CombatScenePacked.instantiate()
	get_root().add_child(combat_scene)
	combat_scene.setup(registry, run_context, AssetCatalog.new(registry), EffectRunner.new(registry))

	if combat_scene.player_actor == null:
		_fail("Combat scene did not create player actor")
		return
	if combat_scene.player_actor.get_stat("max_health") < 120.0:
		_fail("Potato Enhancement item buff did not raise max_health")
		return
	if combat_scene.player_actor.get_stat("spell_power") < 1.0:
		_fail("Potato Enhancement item buff did not add spell_power")
		return

	if not combat_scene._try_cast_magic(0, {"free": true}):
		_fail("Configured magic could not cast")
		return
	if combat_scene.player_actor.get_stat("melee_attack") < 5.0:
		_fail("Comprehensive Development buff did not modify player stats")
		return

	combat_scene._spawn_mob()
	if combat_scene.enemies.is_empty():
		_fail("Combat scene did not spawn a configured mob")
		return
	var enemy: Dictionary = combat_scene.enemies[0]
	enemy["pos"] = combat_scene.player_pos + Vector2(40, 0)
	combat_scene._perform_weapon_attack(registry.get_entry("weapon", "weapon.metamorph.fries"))
	var enemy_actor = enemy.get("actor", null)
	if enemy_actor == null:
		_fail("Spawned mob did not create combat actor")
		return
	if not enemy_actor.buff_container.has_buff("buff.bruise"):
		_fail("Weapon on-hit passive did not apply bruise")
		return

	print("Combat balance runtime validation passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
