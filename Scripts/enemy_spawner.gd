extends Node3D

@export var path: Path3D
@export var enemy_scenes: Array[PackedScene] = []
@export var total_waves: int = 5
@export var base_enemies_per_wave: int = 5
@export var base_spawn_interval: float = 2.0
@export var wave_start_delay: float = 3.0

signal wave_started(wave: int)
signal wave_completed(wave: int)
signal all_waves_completed

var _current_wave: int = 0
var _enemies_spawned: int = 0
var _active_enemies: int = 0
var _spawn_timer: float = 0.0
var _spawning: bool = false


func _ready() -> void:
	GameManager.total_waves = total_waves
	await get_tree().create_timer(1.0).timeout
	_start_next_wave()


func _process(delta: float) -> void:
	if not _spawning:
		return
	_spawn_timer -= delta
	var enemies_this_wave := _enemies_this_wave()
	if _spawn_timer <= 0.0 and _enemies_spawned < enemies_this_wave:
		_spawn_enemy()
		_spawn_timer = _spawn_interval_this_wave()


func _start_next_wave() -> void:
	if _current_wave >= total_waves:
		all_waves_completed.emit()
		GameManager.game_won.emit()
		return
	_current_wave += 1
	_enemies_spawned = 0
	_active_enemies = 0
	_spawning = true
	_spawn_timer = 0.0
	GameManager.set_wave(_current_wave)
	wave_started.emit(_current_wave)
	print("Wave %d started!" % _current_wave)


func _enemies_this_wave() -> int:
	return base_enemies_per_wave + (_current_wave - 1) * 2


func _spawn_interval_this_wave() -> float:
	return max(0.6, base_spawn_interval - (_current_wave - 1) * 0.2)


func _spawn_enemy() -> void:
	if path == null or enemy_scenes.is_empty():
		push_error("EnemySpawner: assign Path3D and enemy scenes.")
		return
	var scene: PackedScene = _pick_enemy_scene()
	var enemy: Node3D = scene.instantiate()
	var follower := PathFollow3D.new()
	follower.loop = false
	follower.rotation_mode = PathFollow3D.ROTATION_ORIENTED
	path.add_child(follower)
	follower.progress_ratio = 0.0
	get_tree().current_scene.add_child(enemy)
	enemy.setup(follower)
	enemy.apply_wave_scaling(_current_wave)
	enemy.reached_end.connect(_on_enemy_reached_end)
	enemy.died.connect(_on_enemy_died)
	_enemies_spawned += 1
	_active_enemies += 1


func _pick_enemy_scene() -> PackedScene:
	var max_type: int = min(_current_wave, enemy_scenes.size()) - 1
	var weights: Array[float] = []
	for i in range(max_type + 1):
		weights.append(pow(0.5, float(max_type - i)))
	var total: float = weights.reduce(func(a: float, b: float) -> float: return a + b)
	var roll: float = randf() * total
	var cumulative := 0.0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return enemy_scenes[i]
	return enemy_scenes[max_type]


func _on_enemy_reached_end(_enemy: Node3D) -> void:
	_active_enemies -= 1
	_check_wave_complete()


func _on_enemy_died(_enemy: Node3D) -> void:
	_active_enemies -= 1
	_check_wave_complete()


func _check_wave_complete() -> void:
	var enemies_this_wave := _enemies_this_wave()
	if _enemies_spawned >= enemies_this_wave and _active_enemies <= 0:
		_spawning = false
		wave_completed.emit(_current_wave)
		print("Wave %d complete!" % _current_wave)
		await get_tree().create_timer(wave_start_delay).timeout
		_start_next_wave()
