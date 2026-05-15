extends Node

const FixedTickLoop = preload("res://src/core/fixed_tick_loop.gd")
const GameplayEventBus = preload("res://src/core/event_bus.gd")
const ContentRegistry = preload("res://src/core/registry.gd")
const ContentConfigLoader = preload("res://src/config/content_config_loader.gd")
const RunContext = preload("res://src/domain/run/run_context.gd")
const SchoolState = preload("res://src/domain/school/school_state.gd")
const ItemPoolService = preload("res://src/domain/reward/item_pool_service.gd")
const MapFlow = preload("res://src/domain/map/map_flow.gd")
const RewardService = preload("res://src/domain/reward/reward_service.gd")
const EconomyService = preload("res://src/domain/economy/economy_service.gd")
const CombatRuntime = preload("res://src/domain/combat/combat_runtime.gd")
const AudioDirector = preload("res://src/domain/audio/audio_director.gd")
const EffectRunner = preload("res://src/domain/effect/effect_runner.gd")

var event_bus
var registry
var tick_loop
var run_context
var item_pool
var map_flow
var reward_service
var economy_service
var combat_runtime
var audio_director
var effect_runner


func _ready() -> void:
	Engine.physics_ticks_per_second = FixedTickLoop.TICKS_PER_SECOND

	event_bus = GameplayEventBus.new()
	registry = ContentRegistry.new()

	var loader = ContentConfigLoader.new()
	var load_report = loader.load_all(registry)
	if not load_report.is_empty():
		for message in load_report:
			push_warning(message)

	var character = registry.get_entry("character", "character.potato_hero")
	run_context = RunContext.new()
	run_context.initialize("character.potato_hero", "difficulty.normal", "mode.demo", 1)
	run_context.school_state = SchoolState.new()
	run_context.school_state.initialize(character.get("primary_school_id", "school.metamorph"))

	item_pool = ItemPoolService.new(registry)
	map_flow = MapFlow.new(registry, run_context)
	reward_service = RewardService.new(registry, item_pool)
	economy_service = EconomyService.new(registry)
	combat_runtime = CombatRuntime.new(registry, event_bus, run_context)
	audio_director = AudioDirector.new(registry, event_bus)
	effect_runner = EffectRunner.new(registry, event_bus)

	tick_loop = FixedTickLoop.new(event_bus)
	tick_loop.add_system(combat_runtime)

	map_flow.start_map("map.demo")
	audio_director.request_music("music_state.map.chapter_1")

	event_bus.emit_event("run_started", {
		"character_id": run_context.character_id,
		"seed": run_context.seed,
	})

	print("Puritato architecture bootstrap complete. Registered types: %s" % [registry.get_registered_types()])


func _physics_process(_delta: float) -> void:
	tick_loop.step()
