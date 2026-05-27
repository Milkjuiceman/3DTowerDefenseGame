class_name TowerData
extends Resource

## Defines a tower type: base stats, cost, and all upgrade paths.
## One .tres file per tower type. Zero code changes to add a new tower.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var scene_path: String = ""   ## e.g. "res://Scenes/Towers/Archer.tscn"
@export var base_cost: int = 50

## Base stats. All towers share these keys; towers can have extras.
## Keys: damage, fire_rate, detection_range, bullet_speed, lives_damage, gold_reward_multiplier
@export var base_stats: Dictionary = {
	"damage": 20.0,
	"fire_rate": 1.0,
	"detection_range": 10.0,
	"bullet_speed": 20.0,
}

## Two upgrade paths. Index 0 = Path A (Power), Index 1 = Path B (Utility).
## Each path is an Array[UpgradeNode] ordered by tier.
@export var upgrade_paths: Array[Array] = [[], []]


func get_upgrade(upgrade_id: String) -> UpgradeNode:
	for path in upgrade_paths:
		for node: UpgradeNode in path:
			if node.id == upgrade_id:
				return node
	return null


func get_all_upgrades() -> Array[UpgradeNode]:
	var all: Array[UpgradeNode] = []
	for path in upgrade_paths:
		for node: UpgradeNode in path:
			all.append(node)
	return all
