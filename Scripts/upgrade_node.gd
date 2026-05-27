class_name UpgradeNode
extends Resource

## One purchasable node in a tower's upgrade tree.
## Define these in the Godot Inspector and save as .tres files.
## No code changes needed to add new upgrades — pure data.

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
@export var cost: int = 100
@export var path: int = 0          ## 0 = Path A (Power), 1 = Path B (Utility)
@export var tier: int = 1          ## 1–4

## IDs of upgrades that must be purchased before this one unlocks.
## Leave empty for Tier 1 nodes (always available).
@export var prerequisites: Array[String] = []

## Stat changes applied when this upgrade is purchased.
## Each entry: { "key": "damage", "value": 1.5, "mode": "MULTIPLY" }
## mode values: "ADD", "MULTIPLY", "OVERRIDE"
@export var stat_modifiers: Array[Dictionary] = []

## Optional: path to a GDScript that implements a special ability.
## The script will be instantiated as a child Node of the tower.
## Must extend TowerAbility (res://Scripts/Abilities/tower_ability.gd).
@export var ability_script_path: String = ""

## UI position in the upgrade panel graph (normalized 0–1 space).
## The UpgradePanel reads these to place hexagon nodes on the canvas.
@export var ui_position: Vector2 = Vector2(0.5, 0.5)


func to_stat_modifiers() -> Array[StatModifier]:
	var result: Array[StatModifier] = []
	for entry in stat_modifiers:
		var mode := StatModifier.Mode.ADD
		match entry.get("mode", "ADD"):
			"MULTIPLY": mode = StatModifier.Mode.MULTIPLY
			"OVERRIDE": mode = StatModifier.Mode.OVERRIDE
		result.append(StatModifier.make(
			entry.get("key", ""),
			float(entry.get("value", 0.0)),
			mode,
			id
		))
	return result
