extends Node3D

## Attach to root Node3D of Enemy1/2/3.tscn

@export var speed: float = 5.0
@export var max_health: float = 100.0
@export var gold_reward: int = 10       # Gold dropped on death
@export var lives_damage: int = 1       # Lives lost when reaching the end

var health: float
var _path_follow: PathFollow3D

signal reached_end(enemy)
signal died(enemy)


func _ready() -> void:
	health = max_health
	add_to_group("enemies")


func setup(path_follow: PathFollow3D) -> void:
	_path_follow = path_follow


func _process(delta: float) -> void:
	if _path_follow == null:
		return

	_path_follow.progress_ratio += speed * delta / _get_path_length()
	global_position = _path_follow.global_position

	var forward := _path_follow.global_transform.basis.z
	if forward.length_squared() > 0.001:
		look_at(global_position - forward, Vector3.UP)

	if _path_follow.progress_ratio >= 1.0:
		reached_end.emit(self)
		GameManager.lose_life(lives_damage)
		_cleanup()


func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		GameManager.add_gold(gold_reward)
		died.emit(self)
		_cleanup()


func apply_wave_scaling(wave: int) -> void:
	## Called by EnemySpawner to scale stats per wave
	var scale_factor := 1.0 + (wave - 1) * 0.2   # +20% per wave
	max_health *= scale_factor
	health = max_health
	speed *= 1.0 + (wave - 1) * 0.1               # +10% speed per wave
	gold_reward = int(gold_reward * (1.0 + (wave - 1) * 0.15))  # more gold for harder enemies


func _get_path_length() -> float:
	var path: Path3D = _path_follow.get_parent() as Path3D
	if path and path.curve:
		return path.curve.get_baked_length()
	return 1.0


func _cleanup() -> void:
	remove_from_group("enemies")
	if _path_follow:
		_path_follow.queue_free()
	queue_free()
