class_name ChainLightningAbility
extends TowerAbility

## Tesla Tower — Path A Tier 3: "Arc Storm"
## On shot, lightning jumps to up to 3 nearby enemies dealing 40% of original damage.

@export var jump_count: int = 3
@export var jump_range: float = 6.0
@export var damage_falloff: float = 0.4   ## Each jump does this fraction of the previous


func on_shot(target: Node3D, damage: float) -> void:
	var hit: Array[Node3D] = [target]
	var current_damage := damage * damage_falloff
	var current_pos := target.global_position

	for _i in range(jump_count):
		var next := _find_nearest_unhit(current_pos, hit)
		if next == null:
			break
		if next.has_method("take_damage"):
			next.take_damage(current_damage)
		hit.append(next)
		current_pos = next.global_position
		current_damage *= damage_falloff
		ability_triggered.emit(next)


func _find_nearest_unhit(from: Vector3, already_hit: Array[Node3D]) -> Node3D:
	var nearest: Node3D = null
	var nearest_dist := jump_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy in already_hit:
			continue
		var d := from.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	return nearest
