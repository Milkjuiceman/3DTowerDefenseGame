extends Node3D

## Attach to a "TowerPlacer" Node3D in Level1.tscn.

@export var tower_scenes: Array[PackedScene] = []
@export var bullet_scene: PackedScene
@export var tower_costs: Array[int] = [50, 100, 150]  # Must match tower_scenes order
@export var placement_layer: int = 1

var _selected_index: int = 0
var _ghost: Node3D = null
var _placing: bool = false
var _placed_towers: Array[Node3D] = []
var _camera: Camera3D
var _can_place: bool = false   # Tracks if current ghost position is affordable


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _enter_placement_mode(0)
			KEY_2: _enter_placement_mode(1)
			KEY_3: _enter_placement_mode(2)
			KEY_ESCAPE: _cancel_placement()

	if not _placing:
		return

	if event is InputEventMouseMotion:
		var hit: Variant = _raycast_ground(event.position)
		if hit != null and _ghost:
			_ghost.global_position = hit
			_update_ghost_affordability()

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit: Variant = _raycast_ground(event.position)
		if hit != null:
			_place_tower(hit)


func _enter_placement_mode(index: int) -> void:
	if index >= tower_scenes.size():
		return

	var cost := tower_costs[index] if index < tower_costs.size() else 50
	if not GameManager.can_afford(cost):
		print("Not enough gold! Need %d, have %d" % [cost, GameManager.gold])
		return

	_cancel_placement()
	_selected_index = index
	_placing = true

	_ghost = tower_scenes[index].instantiate()
	add_child(_ghost)
	_ghost.set_process(false)
	_ghost.set_physics_process(false)
	_set_ghost_transparency(_ghost, 0.45)


func _place_tower(position: Vector3) -> void:
	var cost := tower_costs[_selected_index] if _selected_index < tower_costs.size() else 50
	if not GameManager.spend_gold(cost):
		print("Not enough gold!")
		_cancel_placement()
		return

	var tower: Node3D = tower_scenes[_selected_index].instantiate()
	get_tree().current_scene.add_child(tower)
	tower.global_position = position
	tower.add_to_group("towers")

	if bullet_scene != null:
		tower.set("bullet_scene", bullet_scene)

	# Apply per-tower stats based on type
	_apply_tower_stats(tower, _selected_index)
	_placed_towers.append(tower)


func _apply_tower_stats(tower: Node3D, index: int) -> void:
	## Tower1: Fast, cheap, low damage — good for early waves
	## Tower2: Slow, mid cost, high damage — good all-rounder
	## Tower3: Long range, expensive, medium damage — covers large areas
	match index:
		0:  # Tower1 — Rapid fire
			tower.set("fire_rate", 2.5)
			tower.set("damage", 12.0)
			tower.set("detection_range", 8.0)
		1:  # Tower2 — Heavy hitter
			tower.set("fire_rate", 0.6)
			tower.set("damage", 60.0)
			tower.set("detection_range", 10.0)
		2:  # Tower3 — Sniper
			tower.set("fire_rate", 1.0)
			tower.set("damage", 35.0)
			tower.set("detection_range", 18.0)


func _update_ghost_affordability() -> void:
	var cost := tower_costs[_selected_index] if _selected_index < tower_costs.size() else 50
	_can_place = GameManager.can_afford(cost)
	# Tint green if affordable, red if not
	var tint := Color(0.4, 1.0, 0.4, 0.45) if _can_place else Color(1.0, 0.3, 0.3, 0.45)
	_set_ghost_color(_ghost, tint)


func _cancel_placement() -> void:
	_placing = false
	if _ghost:
		_ghost.queue_free()
		_ghost = null


func _raycast_ground(screen_pos: Vector2) -> Variant:
	if _camera == null:
		return null
	var space := get_world_3d().direct_space_state
	var ray_origin := _camera.project_ray_origin(screen_pos)
	var ray_end := ray_origin + _camera.project_ray_normal(screen_pos) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.collision_mask = placement_layer
	var result := space.intersect_ray(query)
	if result.is_empty():
		return null
	var hit_pos: Vector3 = result["position"]
	hit_pos.y += 0.01
	return hit_pos


func _set_ghost_transparency(node: Node3D, alpha: float) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		var surface_count: int = mesh_inst.mesh.get_surface_count() if mesh_inst.mesh else 0
		for i in surface_count:
			var mat := mesh_inst.get_active_material(i)
			var dup: StandardMaterial3D
			if mat is StandardMaterial3D:
				dup = mat.duplicate() as StandardMaterial3D
			else:
				dup = StandardMaterial3D.new()
			dup.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			dup.albedo_color.a = alpha
			mesh_inst.set_surface_override_material(i, dup)
	for child in node.get_children():
		if child is Node3D:
			_set_ghost_transparency(child as Node3D, alpha)


func _set_ghost_color(node: Node3D, color: Color) -> void:
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		for i in mesh_inst.get_surface_override_material_count():
			var mat := mesh_inst.get_surface_override_material(i) as StandardMaterial3D
			if mat:
				mat.albedo_color = color
	for child in node.get_children():
		if child is Node3D:
			_set_ghost_color(child as Node3D, color)
