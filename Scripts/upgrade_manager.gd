extends Node

## Autoload singleton — add as "UpgradeManager" in Project Settings > Autoload.
##
## Responsibilities:
##   - Track purchased upgrades per tower instance
##   - Validate purchases (gold, prerequisites, path-lock rules)
##   - Apply stat modifiers and attach ability nodes
##   - Clean up on tower sell

signal upgrade_purchased(tower: Node3D, upgrade: UpgradeNode)
signal upgrade_failed(tower: Node3D, reason: String)

## tower instance id (get_instance_id()) → Array[String] of purchased upgrade IDs
var _purchased: Dictionary = {}

## Max tier on one path if you've bought tier 2+ on the other.
const PATH_LOCK_THRESHOLD: int = 2
const PATH_LOCK_MAX_TIER: int = 2


# ─── Public API ───────────────────────────────────────────────────────────────

func can_purchase(tower: Node3D, upgrade: UpgradeNode) -> bool:
	var tid: int = tower.get_instance_id()
	var owned: Array[String] = _get_owned(tid)

	## Already purchased
	if upgrade.id in owned:
		return false

	## Prerequisites not met
	for prereq_id: String in upgrade.prerequisites:
		if prereq_id not in owned:
			return false

	## Path-lock rule: if other path has tier PATH_LOCK_THRESHOLD+,
	## this path is capped at PATH_LOCK_MAX_TIER
	var other_path: int = 1 - upgrade.path
	var other_max_tier: int = _max_tier_on_path(tid, other_path, tower)
	if other_max_tier >= PATH_LOCK_THRESHOLD and upgrade.tier > PATH_LOCK_MAX_TIER:
		return false

	## Gold check
	if not GameManager.can_afford(upgrade.cost):
		return false

	return true


func purchase(tower: Node3D, upgrade: UpgradeNode) -> bool:
	if not can_purchase(tower, upgrade):
		upgrade_failed.emit(tower, "Cannot purchase: %s" % upgrade.id)
		return false

	if not GameManager.spend_gold(upgrade.cost):
		upgrade_failed.emit(tower, "Not enough gold for: %s" % upgrade.id)
		return false

	var tid: int = tower.get_instance_id()
	_get_owned(tid).append(upgrade.id)

	## Apply stat modifiers
	for mod: StatModifier in upgrade.to_stat_modifiers():
		tower.add_modifier(mod)

	## Attach ability if specified
	if upgrade.ability_script_path != "":
		_attach_ability(tower, upgrade)

	upgrade_purchased.emit(tower, upgrade)
	print("[UpgradeManager] Purchased '%s' for tower %d" % [upgrade.display_name, tid])
	return true


func sell_tower(tower: Node3D) -> void:
	## Remove all upgrade state, remove ability nodes, refund half the upgrade costs.
	var tid: int = tower.get_instance_id()
	var owned: Array[String] = _get_owned(tid)
	var refund: int = 0

	if tower.has_method("clear_modifiers"):
		tower.clear_modifiers()

	## Remove ability child nodes
	for child in tower.get_children():
		if child is TowerAbility:
			child.on_removed()
			child.queue_free()

	## Refund upgrades at 50%
	if tower.tower_data != null:
		for upgrade_id: String in owned:
			var node: UpgradeNode = tower.tower_data.get_upgrade(upgrade_id)
			if node != null:
				refund += int(node.cost * 0.5)

	## Refund base tower cost at 70%
	if tower.tower_data != null:
		refund += int(tower.tower_data.base_cost * 0.7)

	GameManager.add_gold(refund)
	_purchased.erase(tid)
	tower.queue_free()
	print("[UpgradeManager] Sold tower %d, refunded %d gold" % [tid, refund])


func get_purchased_upgrades(tower: Node3D) -> Array[String]:
	return _get_owned(tower.get_instance_id()).duplicate()


func is_purchased(tower: Node3D, upgrade_id: String) -> bool:
	return upgrade_id in _get_owned(tower.get_instance_id())


## Returns all UpgradeNodes for a tower with their purchasability state.
## Used by UpgradeUI to render the tree without needing upgrade logic.
func get_upgrade_states(tower: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not tower.get("tower_data") or tower.get("tower_data") == null:
		return result
	for upgrade: UpgradeNode in tower.tower_data.get_all_upgrades():
		result.append({
			"upgrade": upgrade,
			"purchased": is_purchased(tower, upgrade.id),
			"can_buy": can_purchase(tower, upgrade),
			"locked": not _prerequisites_met(tower, upgrade),
		})
	return result


# ─── Internal ─────────────────────────────────────────────────────────────────

func _get_owned(tower_id: int) -> Array[String]:
	if not _purchased.has(tower_id):
		_purchased[tower_id] = [] as Array[String]
	return _purchased[tower_id]


func _prerequisites_met(tower: Node3D, upgrade: UpgradeNode) -> bool:
	var owned: Array[String] = _get_owned(tower.get_instance_id())
	for prereq_id: String in upgrade.prerequisites:
		if prereq_id not in owned:
			return false
	return true


func _max_tier_on_path(tower_id: int, path_index: int, tower: Node3D) -> int:
	if not tower.get("tower_data") or tower.get("tower_data") == null:
		return 0
	var owned: Array[String] = _get_owned(tower_id)
	var max_tier: int = 0
	if path_index >= tower.tower_data.upgrade_paths.size():
		return 0
	for node: UpgradeNode in tower.tower_data.upgrade_paths[path_index]:
		if node.id in owned and node.tier > max_tier:
			max_tier = node.tier
	return max_tier


func _attach_ability(tower: Node3D, upgrade: UpgradeNode) -> void:
	## Remove any existing ability from the same upgrade slot
	## (in case of upgrade replacement in future)
	var script: Script = load(upgrade.ability_script_path)
	if script == null:
		push_error("[UpgradeManager] Could not load ability script: %s" % upgrade.ability_script_path)
		return
	var ability: TowerAbility = script.new()
	ability.name = "Ability_" + upgrade.id
	tower.add_child(ability)
