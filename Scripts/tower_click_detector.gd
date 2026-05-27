extends Node

## Attach to any Node in Level1.tscn.
## Detects mouse clicks on placed towers and opens the UpgradePanel.
##
## Uses TWO detection methods in order:
##   1. Physics raycast (works if tower has StaticBody3D + CollisionShape3D)
##   2. Screen-space distance fallback (works regardless of colliders)

var _upgrade_panel: Control = null
var _camera: Camera3D = null

## How close the click needs to be to a tower center on screen (pixels)
const SCREEN_PICK_RADIUS: float = 40.0


func _ready() -> void:
	await get_tree().process_frame
	_camera = get_viewport().get_camera_3d()
	_upgrade_panel = get_tree().current_scene.find_child("UpgradePanel", true, false)
	if _upgrade_panel == null:
		push_warning("TowerClickDetector: UpgradePanel not found. Add it to your HUD scene.")


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not (event as InputEventMouseButton).pressed:
		return
	if (event as InputEventMouseButton).button_index != MOUSE_BUTTON_LEFT:
		return

	## Don't steal clicks when the upgrade panel is open
	if _upgrade_panel != null and _upgrade_panel.visible:
		return

	## Don't steal clicks when a tower is being placed (TowerPlacer is active)
	var placer := get_tree().current_scene.find_child("TowerPlacer", true, false)
	if placer != null and placer.get("_placing") == true:
		return

	var click_pos: Vector2 = (event as InputEventMouseButton).position
	var tower := _find_tower_at(click_pos)
	if tower != null:
		_open_panel(tower)
		get_viewport().set_input_as_handled()


func _find_tower_at(screen_pos: Vector2) -> Node3D:
	if _camera == null:
		return null

	## Method 1: physics raycast
	var hit := _raycast(screen_pos)
	if hit != null:
		return hit

	## Method 2: screen-space proximity fallback
	return _screen_space_pick(screen_pos)


func _raycast(screen_pos: Vector2) -> Node3D:
	var space := get_viewport().get_world_3d().direct_space_state
	var origin := _camera.project_ray_origin(screen_pos)
	var direction := _camera.project_ray_normal(screen_pos)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * 1000.0)
	query.collision_mask = 0xFFFFFFFF
	var result := space.intersect_ray(query)
	if result.is_empty():
		return null

	## Walk up parents to find a node in the towers group
	var node: Node = result.get("collider") as Node
	while node != null:
		if node.is_in_group("towers") and node is Node3D:
			return node as Node3D
		node = node.get_parent()
	return null


func _screen_space_pick(screen_pos: Vector2) -> Node3D:
	## Project every tower's 3D position to screen and find the nearest within radius
	var best: Node3D = null
	var best_dist := SCREEN_PICK_RADIUS

	for tower in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(tower) or not tower is Node3D:
			continue
		var tower3d := tower as Node3D
		if not _camera.is_position_in_frustum(tower3d.global_position):
			continue
		var screen := _camera.unproject_position(tower3d.global_position)
		var dist := screen.distance_to(screen_pos)
		if dist < best_dist:
			best_dist = dist
			best = tower3d
	return best


func _open_panel(tower: Node3D) -> void:
	if _upgrade_panel != null and _upgrade_panel.has_method("open_for"):
		_upgrade_panel.open_for(tower)
