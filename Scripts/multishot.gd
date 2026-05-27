class_name MultishotAbility
extends TowerAbility

## Archer Tower — Path A Tier 2: "Volley"
## Each shot fires additional arrows at nearby secondary targets.

@export var extra_targets: int = 2
@export var damage_multiplier: float = 0.6   ## Extra arrows deal 60% damage


func on_shot(primary_target: Node3D, damage: float) -> void:
	var secondary_damage := damage * damage_multiplier
	var found: int = 0
	var skip: Array[Node3D] = [primary_target]

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if found >= extra_targets:
			break
		if not is_instance_valid(enemy) or enemy in skip:
			continue
		var d := tower.global_position.distance_to(enemy.global_position)
		if d <= tower.get_stat("detection_range"):
			if enemy.has_method("take_damage"):
				enemy.take_damage(secondary_damage)
			skip.append(enemy)
			found += 1
			ability_triggered.emit(enemy)
