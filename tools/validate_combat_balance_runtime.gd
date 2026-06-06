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

	combat_scene.balance["spawning"]["fallback_mob_ids"] = ["monster.metamorph.sprouting_potato"]
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

	run_context.floor = 1
	var bomb_entry = registry.get_entry("monster", "monster.metamorph.bomb_fruitling")
	var bomb_spawn = bomb_entry.get("spawn", {})
	if int(bomb_spawn.get("first_floor", 99)) > 1:
		_fail("Bomb Fruitling is not eligible for first-floor spawning")
		return
	combat_scene.balance["spawning"]["fallback_mob_ids"] = ["monster.metamorph.bomb_fruitling"]
	combat_scene._spawn_mob()
	var bomb: Dictionary = combat_scene.enemies[combat_scene.enemies.size() - 1]
	if String(bomb.get("fuse_state", "")) != "asleep":
		_fail("Bomb Fruitling did not spawn asleep")
		return
	bomb["pos"] = combat_scene.player_pos + Vector2(260, 0)
	combat_scene._update_enemies(0.016)
	var bomb_actor = bomb.get("actor", null)
	if bomb_actor == null or not bomb_actor.buff_container.has_buff("buff.fuse_lit"):
		_fail("Bomb Fruitling did not wake and receive fuse buff near the player")
		return
	if float(bomb.get("speed", 0.0)) < 64.0:
		_fail("Bomb Fruitling fuse buff did not increase speed")
		return
	var hp_after_wake = float(bomb_actor.current_health)
	combat_scene._update_enemies(1.05)
	if float(bomb_actor.current_health) >= hp_after_wake:
		_fail("Bomb Fruitling fuse buff did not deal periodic self-damage")
		return
	if float(bomb.get("speed", 0.0)) < 68.0:
		_fail("Bomb Fruitling fuse buff did not stack speed over time")
		return
	var player_hp_before_bomb = combat_scene.player_hp
	bomb["pos"] = combat_scene.player_pos + Vector2(4, 0)
	combat_scene._update_enemies(0.016)
	if combat_scene.enemies.has(bomb):
		_fail("Bomb Fruitling did not explode on contact")
		return
	if combat_scene.player_hp > player_hp_before_bomb - 20.0:
		_fail("Bomb Fruitling explosion did not deal configured damage to player")
		return

	print("Combat balance runtime validation passed.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
