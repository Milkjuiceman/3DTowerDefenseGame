class_name TowerInstance
extends Node3D

## Replaces tower.gd. Attach to all tower scene root nodes.
## Stats are never mutated directly — use add_modifier() and get_stat().

signal enemy_killed(enemy: Node3D)

@export var tower_data: TowerData = null
@export var bullet_scene: PackedScene

var _stat_cache: Dictionary = {}
var _cache_dirty: bool = true
var _modifiers: Array[StatModifier] = []

var _target: Node3D = null
var _fire_cooldown: float = 0.0
var _bullet_spawner: Node3D


func _ready() -> void:
	_bullet_spawner = get_node_or_null("Bullet_Spawner")
	if _bullet_spawner == null:
		_bullet_spawner = get_node_or_null("Node3D")
	add_to_group("towers")


func _process(delta: float) -> void:
	_fire_cooldown -= delta

	if not is_instance_valid(_target):
		_target = _find_nearest_enemy()

	if _target == null:
		return

	if global_position.distance_to(_target.global_position) > get_stat("detection_range"):
		_target = null
		return

	var look_pos := Vector3(_target.global_position.x, global_position.y, _target.global_position.z)
	if look_pos.distance_to(global_position) > 0.01:
		look_at(look_pos, Vector3.UP)

	if _fire_cooldown <= 0.0:
		_shoot()
		_fire_cooldown = 1.0 / get_stat("fire_rate")


# --- Stat System --------------------------------------------------------------

func get_stat(key: String) -> float:
	if _cache_dirty:
		_recompute_cache()
	return _stat_cache.get(key, 0.0)


func add_modifier(mod: StatModifier) -> void:
	_modifiers.append(mod)
	_cache_dirty = true


func remove_modifiers_from(upgrade_id: String) -> void:
	_modifiers = _modifiers.filter(
		func(m: StatModifier) -> bool: return m.source_upgrade_id != upgrade_id
	)
	_cache_dirty = true


func clear_modifiers() -> void:
	_modifiers.clear()
	_cache_dirty = true


func _recompute_cache() -> void:
	_stat_cache.clear()

	if tower_data != null:
		for key: String in tower_data.base_stats:
			_stat_cache[key] = float(tower_data.base_stats[key])

	# ADD first, then MULTIPLY, then OVERRIDE — order-independent stacking
	for mod: StatModifier in _modifiers:
		if mod.mode == StatModifier.Mode.ADD:
			_stat_cache[mod.key] = _stat_cache.get(mod.key, 0.0) + mod.value

	for mod: StatModifier in _modifiers:
		if mod.mode == StatModifier.Mode.MULTIPLY:
			_stat_cache[mod.key] = _stat_cache.get(mod.key, 0.0) * mod.value

	for mod: StatModifier in _modifiers:
		if mod.mode == StatModifier.Mode.OVERRIDE:
			_stat_cache[mod.key] = mod.value

	_cache_dirty = false


# --- Combat -------------------------------------------------------------------

func _find_nearest_enemy() -> Node3D:
	var nearest: Node3D = null
	var nearest_dist: float = get_stat("detection_range")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var d: float = global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	return nearest


func _shoot() -> void:
	if bullet_scene == null or _target == null or not is_instance_valid(_target):
		return

	var bullet: Node3D = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	var spawn_pos: Vector3 = _bullet_spawner.global_position if _bullet_spawner else global_position
	bullet.global_position = spawn_pos

	var dmg: float = get_stat("damage")
	bullet.setup(_target, dmg)

	for child in get_children():
		if child is TowerAbility:
			child.on_shot(_target, dmg)


func notify_kill(enemy: Node3D) -> void:
	enemy_killed.emit(enemy)


# --- Compatibility shim -------------------------------------------------------
# _set() is the correct virtual override for intercepting property writes.
# This lets tower_placer.gd continue calling tower.set("damage", x) unchanged.

func _set(property: StringName, value: Variant) -> bool:
	match str(property):
		"fire_rate", "damage", "detection_range", "bullet_speed":
			if tower_data != null:
				tower_data.base_stats[str(property)] = float(value)
				_cache_dirty = true
				return true
	return false
