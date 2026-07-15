extends Node3D
class_name InvasionSpawner

@export_category("Spawning Configuration")
@export var ladder_slime_scene: PackedScene
@export var basic_slime_scene: PackedScene
@export var spawn_radius: float = 50.0

@export_category("Limits & Timing")
@export var max_ladder_slimes: int = 4
@export var max_basic_slimes: int = 12
@export var ladder_spawn_interval: float = 8.0
@export var basic_spawn_interval: float = 3.0

@export_category("Dependencies")
@export var invasion_manager: InvasionManager

var current_ladder_slimes: int = 0
var current_basic_slimes: int = 0

var ladder_timer: Timer
var basic_timer: Timer

func _ready() -> void:
	if not invasion_manager:
		invasion_manager = get_parent() as InvasionManager
		if not invasion_manager:
			push_error("InvasionSpawner: Missing InvasionManager reference! Cannot spawn.")
			return

	setup_timers()

func setup_timers() -> void:
	ladder_timer = Timer.new()
	ladder_timer.wait_time = ladder_spawn_interval
	ladder_timer.timeout.connect(attempt_spawn_ladder)
	add_child(ladder_timer)
	ladder_timer.start()

	basic_timer = Timer.new()
	basic_timer.wait_time = basic_spawn_interval
	basic_timer.timeout.connect(attempt_spawn_basic)
	add_child(basic_timer)
	basic_timer.start()

func get_random_edge_position() -> Vector3:
	var angle = randf() * TAU

	var x = cos(angle) * spawn_radius
	var z = sin(angle) * spawn_radius

	return global_position + Vector3(x, 1.0, z)

func attempt_spawn_ladder() -> void:
	if current_ladder_slimes >= max_ladder_slimes:
		return

	if not invasion_manager.has_available_ladder_spots():
		return

	spawn_slime(ladder_slime_scene, true)

func attempt_spawn_basic() -> void:
	if current_basic_slimes >= max_basic_slimes:
		return

	spawn_slime(basic_slime_scene, false)

func spawn_slime(scene: PackedScene, is_ladder: bool) -> void:
	if not scene:
		push_warning("InvasionSpawner: Scene not assigned!")
		return
	
	var slime = scene.instantiate()

	var headwear_nodes = get_tree().get_nodes_in_group("headwear")
	if headwear_nodes.size() > 0:
		slime.target = headwear_nodes[1]
	else:
		push_warning("InvasionSpawner: No nodes in 'headwear' group found!")

	slime.invasion_manager = invasion_manager

	get_tree().current_scene.add_child(slime)
	slime.global_position = get_random_edge_position()

	if is_ladder:
		current_ladder_slimes += 1
		slime.tree_exiting.connect(_on_ladder_slime_died)
	else:
		current_basic_slimes += 1
		slime.tree_exiting.connect(_on_basic_slime_died)

func _on_ladder_slime_died() -> void:
	current_ladder_slimes = max(0, current_ladder_slimes - 1)

func _on_basic_slime_died() -> void:
	current_basic_slimes = max(0, current_basic_slimes - 1)
