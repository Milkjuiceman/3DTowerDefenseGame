class_name ExplosionAbility
extends TowerAbility

## Cannon Tower — Path A Tier 2: "Shrapnel"
## Bullets explode on impact, dealing splash damage to nearby enemies.

@export var explosion_radius: float = 3.0
@export var splash_damage_percent: float = 0.5   ## 50% of bullet damage to splash targets


func on_shot(target: Node3D, damage: float) -> void:
	## Called after the primary hit. Apply splash to nearby enemies.
	if not is_instance_valid(target):
		return

	var splash_damage := damage * splash_damage_percent
	var origin := target.global_position

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if enemy == target:
			continue
		if origin.distance_to(enemy.global_position) <= explosion_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(splash_damage)
	ability_triggered.emit(target)
