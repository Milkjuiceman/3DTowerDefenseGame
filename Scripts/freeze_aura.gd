class_name FreezeAuraAbility
extends TowerAbility

## Frost Tower — Path B Tier 3: "Permafrost"
## Passively slows all enemies within range. On kill, briefly freezes all nearby enemies.

@export var slow_factor: float = 0.5       ## Enemies move at 50% speed
@export var freeze_duration: float = 1.5   ## Full freeze on kill
@export var aura_range: float = 8.0

var _slowed_enemies: Dictionary = {}   ## enemy → original_speed


func _on_init() -> void:
	## Connect to tower's died signal to trigger freeze-on-kill
	if tower.has_signal("enemy_killed"):
		tower.enemy_killed.connect(_on_enemy_killed)


func on_process(_delta: float) -> void:
	_update_slow_aura()


func _update_slow_aura() -> void:
	var current_in_range: Array[Node3D] = []

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var d := tower.global_position.distance_to(enemy.global_position)
		if d <= aura_range:
			current_in_range.append(enemy)
			if not _slowed_enemies.has(enemy):
				## Apply slow
				_slowed_enemies[enemy] = enemy.speed
				enemy.speed *= slow_factor

	## Remove slow from enemies that left range
	for enemy in _slowed_enemies.keys():
		if not is_instance_valid(enemy) or enemy not in current_in_range:
			if is_instance_valid(enemy):
				enemy.speed = _slowed_enemies[enemy]
			_slowed_enemies.erase(enemy)


func _on_enemy_killed(_enemy: Node3D) -> void:
	## Freeze all currently slowed enemies briefly
	for enemy in _slowed_enemies.keys():
		if is_instance_valid(enemy):
			var saved_speed: float = _slowed_enemies[enemy]
			enemy.speed = 0.0
			get_tree().create_timer(freeze_duration).timeout.connect(
				func() -> void:
					if is_instance_valid(enemy):
						enemy.speed = saved_speed * slow_factor
			)
	ability_triggered.emit(tower)


func on_removed() -> void:
	## Restore all slowed enemies to normal speed
	for enemy in _slowed_enemies.keys():
		if is_instance_valid(enemy):
			enemy.speed = _slowed_enemies[enemy]
	_slowed_enemies.clear()
