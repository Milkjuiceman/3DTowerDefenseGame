extends Node3D

## Attach to a simple scene: Node3D (root) > MeshInstance3D (small sphere) + Area3D > CollisionShape3D
## The tower spawns this and calls setup() on it.

@export var speed: float = 20.0
@export var damage: float = 25.0

var _target: Node3D = null
var _direction: Vector3 = Vector3.ZERO


func setup(target: Node3D, damage_amount: float) -> void:
	_target = target
	damage = damage_amount


func _process(delta: float) -> void:
	# If target is gone, fly straight ahead and self-destruct shortly
	if not is_instance_valid(_target):
		_direction = _direction if _direction != Vector3.ZERO else -global_transform.basis.z
		global_position += _direction * speed * delta
		await get_tree().create_timer(1.0).timeout
		queue_free()
		return

	# Home toward target
	_direction = (_target.global_position - global_position).normalized()
	global_position += _direction * speed * delta

	# Check if we've hit the target (within 0.6 units)
	if global_position.distance_to(_target.global_position) < 0.6:
		_hit_target()


func _hit_target() -> void:
	if is_instance_valid(_target) and _target.has_method("take_damage"):
		_target.take_damage(damage)
	queue_free()
