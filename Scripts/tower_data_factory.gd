@tool
extends Node

## HOW TO USE:
## 1. Attach this script to any Node in your scene
## 2. Select that node in the editor
## 3. Click "Generate Tower Data" in the Inspector
## 4. Check res://Data/Towers/ for the .tres files
## 5. Delete this node from the scene when done

func _generate() -> void:
	if not Engine.is_editor_hint():
		return
	DirAccess.make_dir_recursive_absolute("res://Data/Towers")
	_save(build_archer(), "res://Data/Towers/ArcherData.tres")
	_save(build_cannon(), "res://Data/Towers/CannonData.tres")
	_save(build_tesla(),  "res://Data/Towers/TeslaData.tres")
	_save(build_frost(),  "res://Data/Towers/FrostData.tres")
	print("[TowerDataFactory] Done — check res://Data/Towers/")

## Inspector button — works in Godot 4.3+
@export_tool_button("Generate Tower Data", "Add") var _btn_generate := _generate


# --- ARCHER -------------------------------------------------------------------

func build_archer() -> TowerData:
	var d := TowerData.new()
	d.id = "archer"
	d.display_name = "Archer"
	d.description = "Fast attack, single target. Upgrades into multishot or critical strikes."
	d.base_cost = 75
	d.base_stats = {"damage": 15.0, "fire_rate": 2.0, "detection_range": 10.0, "bullet_speed": 25.0}

	var a1 := _node("archer_a1", "Sharp Arrows",    75,  0, 1, [],            [_m("damage", 8.0, "ADD")],                                          "",                                       Vector2(0.15, 0.20))
	var a2 := _node("archer_a2", "Volley",          112, 0, 2, ["archer_a1"], [_m("damage", 1.2, "MULTIPLY")],                                     "res://Scripts/Abilities/multishot.gd",   Vector2(0.15, 0.40))
	var a3 := _node("archer_a3", "Broadhead",       225, 0, 3, ["archer_a2"], [_m("damage", 1.5, "MULTIPLY")],                                     "",                                       Vector2(0.15, 0.60))
	var a4 := _node("archer_a4", "Storm of Arrows", 525, 0, 4, ["archer_a3"], [_m("fire_rate", 2.0, "MULTIPLY"), _m("damage", 1.3, "MULTIPLY")],    "",                                       Vector2(0.15, 0.82))
	a1.description = "+8 damage per arrow."
	a2.description = "Fires 2 extra arrows at nearby targets for 60% damage."
	a3.description = "Damage x1.5. Arrows pierce through 1 enemy."
	a4.description = "Fire rate doubled. +30% damage."

	var b1 := _node("archer_b1", "Eagle Eye",      75,  1, 1, [],             [_m("detection_range", 4.0, "ADD")],                                 "",  Vector2(0.85, 0.20))
	var b2 := _node("archer_b2", "Crippling Shot", 112, 1, 2, ["archer_b1"], [_m("detection_range", 1.3, "MULTIPLY")],                             "",  Vector2(0.85, 0.40))
	var b3 := _node("archer_b3", "Predator Mark",  225, 1, 3, ["archer_b2"], [_m("damage", 0.25, "ADD")],                                          "",  Vector2(0.85, 0.60))
	var b4 := _node("archer_b4", "Death Mark",     525, 1, 4, ["archer_b3"], [_m("detection_range", 1.5, "MULTIPLY"), _m("fire_rate", 1.3, "MULTIPLY")], "", Vector2(0.85, 0.82))
	b1.description = "+4 detection range."
	b2.description = "Range x1.3. Shots slow enemies by 20% for 1s."
	b3.description = "Every 5th shot crits for x3 damage."
	b4.description = "Crits one-shot enemies below 20% HP. Range x1.5, fire rate x1.3."

	d.upgrade_paths = [[a1, a2, a3, a4], [b1, b2, b3, b4]]
	return d


# --- CANNON -------------------------------------------------------------------

func build_cannon() -> TowerData:
	var d := TowerData.new()
	d.id = "cannon"
	d.display_name = "Cannon"
	d.description = "Slow but devastating AoE. Upgrades into siege weapon or incendiary platform."
	d.base_cost = 150
	d.base_stats = {"damage": 60.0, "fire_rate": 0.5, "detection_range": 10.0, "bullet_speed": 15.0}

	var a1 := _node("cannon_a1", "Heavy Shells", 120,  0, 1, [],             [_m("damage", 30.0, "ADD")],                                          "",                                       Vector2(0.15, 0.20))
	var a2 := _node("cannon_a2", "Shrapnel",     225,  0, 2, ["cannon_a1"], [_m("damage", 1.25, "MULTIPLY")],                                      "res://Scripts/Abilities/explosion.gd",   Vector2(0.15, 0.40))
	var a3 := _node("cannon_a3", "Siege Cannon", 450,  0, 3, ["cannon_a2"], [_m("damage", 2.0, "MULTIPLY"), _m("detection_range", 4.0, "ADD")],     "",                                       Vector2(0.15, 0.60))
	var a4 := _node("cannon_a4", "MOAB Buster",  1050, 0, 4, ["cannon_a3"], [_m("damage", 3.0, "MULTIPLY"), _m("fire_rate", 1.5, "MULTIPLY")],      "",                                       Vector2(0.15, 0.82))
	a1.description = "+30 damage per shot."
	a2.description = "Shells explode on impact dealing 50% splash damage."
	a3.description = "Damage x2. +4 range. Explosion radius increased."
	a4.description = "x3 damage, x1.5 fire rate. Devastating vs large enemies."

	var b1 := _node("cannon_b1", "Incendiary", 120,  1, 1, [],             [_m("fire_rate", 0.15, "ADD")],                                         "",  Vector2(0.85, 0.20))
	var b2 := _node("cannon_b2", "Napalm",     225,  1, 2, ["cannon_b1"], [_m("damage", 1.2, "MULTIPLY")],                                         "",  Vector2(0.85, 0.40))
	var b3 := _node("cannon_b3", "Inferno",    450,  1, 3, ["cannon_b2"], [_m("fire_rate", 1.3, "MULTIPLY")],                                      "",  Vector2(0.85, 0.60))
	var b4 := _node("cannon_b4", "Hellfire",   1050, 1, 4, ["cannon_b3"], [_m("damage", 2.0, "MULTIPLY"), _m("detection_range", 1.4, "MULTIPLY")], "",  Vector2(0.85, 0.82))
	b1.description = "Shells ignite enemies for 20 DPS over 2s. +0.15 fire rate."
	b2.description = "Fire DoT 40 DPS. Spreads to 1 nearby enemy. +20% damage."
	b3.description = "Burning enemies deal no lives damage on death. Fire rate x1.3."
	b4.description = "Ground in range permanently ignites. x2 damage, x1.4 range."

	d.upgrade_paths = [[a1, a2, a3, a4], [b1, b2, b3, b4]]
	return d


# --- TESLA --------------------------------------------------------------------

func build_tesla() -> TowerData:
	var d := TowerData.new()
	d.id = "tesla"
	d.display_name = "Tesla"
	d.description = "Lightning that chains between enemies. Crowd control or raw power."
	d.base_cost = 200
	d.base_stats = {"damage": 25.0, "fire_rate": 1.5, "detection_range": 9.0, "bullet_speed": 30.0}

	var a1 := _node("tesla_a1", "Charged Coil",  160,  0, 1, [],            [_m("damage", 10.0, "ADD")],                                           "",                                           Vector2(0.15, 0.20))
	var a2 := _node("tesla_a2", "Arc Conductor", 240,  0, 2, ["tesla_a1"], [_m("damage", 1.3, "MULTIPLY")],                                        "",                                           Vector2(0.15, 0.40))
	var a3 := _node("tesla_a3", "Arc Storm",     480,  0, 3, ["tesla_a2"], [_m("damage", 1.4, "MULTIPLY")],                                        "res://Scripts/Abilities/chain_lightning.gd", Vector2(0.15, 0.60))
	var a4 := _node("tesla_a4", "Thundergod",    1120, 0, 4, ["tesla_a3"], [_m("damage", 3.0, "MULTIPLY"), _m("fire_rate", 1.5, "MULTIPLY")],       "",                                           Vector2(0.15, 0.82))
	a1.description = "+10 lightning damage."
	a2.description = "Chains to 1 extra enemy. x1.3 damage."
	a3.description = "Chains to 3 targets at 40% damage per jump."
	a4.description = "x3 damage, x1.5 fire rate. Jumps deal 70% instead of 40%."

	var b1 := _node("tesla_b1", "Grounding Wire", 160,  1, 1, [],            [_m("detection_range", 2.0, "ADD")],                                  "",  Vector2(0.85, 0.20))
	var b2 := _node("tesla_b2", "EMP Pulse",      240,  1, 2, ["tesla_b1"], [_m("fire_rate", 0.2, "ADD")],                                         "",  Vector2(0.85, 0.40))
	var b3 := _node("tesla_b3", "Static Field",   480,  1, 3, ["tesla_b2"], [_m("detection_range", 1.3, "MULTIPLY")],                              "",  Vector2(0.85, 0.60))
	var b4 := _node("tesla_b4", "Overload",       1120, 1, 4, ["tesla_b3"], [_m("damage", 2.0, "MULTIPLY"), _m("detection_range", 1.5, "MULTIPLY")],"",  Vector2(0.85, 0.82))
	b1.description = "+2 range. Lightning slows hit enemies."
	b2.description = "Every 4th shot stuns all enemies in range for 0.5s."
	b3.description = "Passive field: enemies take 5 DPS and move 15% slower."
	b4.description = "Field triples. EMP stun 2s. x2 damage, x1.5 range."

	d.upgrade_paths = [[a1, a2, a3, a4], [b1, b2, b3, b4]]
	return d


# --- FROST --------------------------------------------------------------------

func build_frost() -> TowerData:
	var d := TowerData.new()
	d.id = "frost"
	d.display_name = "Frost"
	d.description = "Slows and freezes enemies. Low damage, high utility."
	d.base_cost = 125
	d.base_stats = {"damage": 8.0, "fire_rate": 1.2, "detection_range": 11.0, "bullet_speed": 18.0}

	var a1 := _node("frost_a1", "Deep Freeze",   100, 0, 1, [],            [_m("damage", 5.0, "ADD")],                                             "",                                       Vector2(0.15, 0.20))
	var a2 := _node("frost_a2", "Brittle",       187, 0, 2, ["frost_a1"], [_m("damage", 1.5, "MULTIPLY")],                                         "",                                       Vector2(0.15, 0.40))
	var a3 := _node("frost_a3", "Shatter",       375, 0, 3, ["frost_a2"], [_m("damage", 1.5, "MULTIPLY"), _m("fire_rate", 1.2, "MULTIPLY")],        "",                                       Vector2(0.15, 0.60))
	var a4 := _node("frost_a4", "Absolute Zero", 875, 0, 4, ["frost_a3"], [_m("damage", 2.5, "MULTIPLY"), _m("detection_range", 1.3, "MULTIPLY")],  "",                                       Vector2(0.15, 0.82))
	a1.description = "+5 damage. Slow duration 2s."
	a2.description = "Frozen enemies take x1.5 damage from all sources."
	a3.description = "Killing a frozen enemy deals 80 splash damage nearby."
	a4.description = "Enemies freeze permanently in range. Shatter radius doubled. x2.5 damage."

	var b1 := _node("frost_b1", "Cold Snap",  100, 1, 1, [],            [_m("detection_range", 2.0, "ADD")],                                       "",                                           Vector2(0.85, 0.20))
	var b2 := _node("frost_b2", "Ice Rink",   187, 1, 2, ["frost_b1"], [_m("detection_range", 1.2, "MULTIPLY")],                                   "",                                           Vector2(0.85, 0.40))
	var b3 := _node("frost_b3", "Permafrost", 375, 1, 3, ["frost_b2"], [_m("fire_rate", 1.3, "MULTIPLY")],                                         "res://Scripts/Abilities/freeze_aura.gd",     Vector2(0.85, 0.60))
	var b4 := _node("frost_b4", "Glacier",    875, 1, 4, ["frost_b3"], [_m("detection_range", 1.6, "MULTIPLY"), _m("damage", 2.0, "MULTIPLY")],     "",                                           Vector2(0.85, 0.82))
	b1.description = "+2 range. Cold aura passively slows nearby enemies."
	b2.description = "Aura covers full detection range at 40% slow. x1.2 range."
	b3.description = "On kill: all slowed enemies freeze for 1.5s. Fire rate x1.3."
	b4.description = "Freeze 4s. Frozen take x3 damage. x1.6 range, x2 damage."

	d.upgrade_paths = [[a1, a2, a3, a4], [b1, b2, b3, b4]]
	return d


# --- Helpers ------------------------------------------------------------------

func _node(
		id: String, display_name: String, cost: int,
		path_index: int, tier: int,
		prereqs: Array,
		modifiers: Array[Dictionary],
		ability_path: String,
		ui_pos: Vector2) -> UpgradeNode:
	var n := UpgradeNode.new()
	n.id = id
	n.display_name = display_name
	n.cost = cost
	n.path = path_index
	n.tier = tier
	for p: String in prereqs:
		n.prerequisites.append(p)
	for mod: Dictionary in modifiers:
		n.stat_modifiers.append(mod)
	n.ability_script_path = ability_path
	n.ui_position = ui_pos
	return n


func _m(key: String, value: float, mode: String) -> Dictionary:
	return {"key": key, "value": value, "mode": mode}


func _save(resource: Resource, path: String) -> void:
	var err := ResourceSaver.save(resource, path)
	if err != OK:
		push_error("[TowerDataFactory] Failed to save %s -- error %d" % [path, err])
	else:
		print("[TowerDataFactory] Saved: %s" % path)
