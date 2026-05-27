extends Node3D

## Attach to Tower1/2/3.tscn root nodes.
## Each tower has different stats set via @export in the Inspector or scene defaults.

@export var detection_range: float = 10.0
@export var fire_rate: float = 1.0
@export var damage: float = 25.0
@export var cost: int = 50              # Gold cost — checked by TowerPlacer before placing
@export var bullet_scene: PackedScene

var _target: Node3D = null
var _fire_cooldown: float = 0.0
var _bullet_spawner: Node3D


func _ready() -> void:
	_bullet_spawner = get_node_or_null("Bullet_Spawner")
	if _bullet_spawner == null:
		_bullet_spawner = get_node_or_null("Node3D")


func _process(delta: float) -> void:
	_fire_cooldown -= delta

	if not is_instance_valid(_target):
		_target = _find_nearest_enemy()

	if _target == null:
		return

	if global_position.distance_to(_target.global_position) > detection_range:
		_target = null
		return

	var look_pos := Vector3(_target.global_position.x, global_position.y, _target.global_position.z)
	if look_pos.distance_to(global_position) > 0.01:
		look_at(look_pos, Vector3.UP)

	if _fire_cooldown <= 0.0:
		_shoot()
		_fire_cooldown = 1.0 / fire_rate


func _find_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := detection_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	return nearest


func _shoot() -> void:
	if bullet_scene == null or _target == null or not is_instance_valid(_target):
		return
	var bullet: Node3D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	var spawn_pos := _bullet_spawner.global_position if _bullet_spawner else global_position
	bullet.global_position = spawn_pos
	bullet.setup(_target, damage)
