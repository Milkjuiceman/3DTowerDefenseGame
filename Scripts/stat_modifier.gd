class_name StatModifier
extends Resource

## A single stat modification applied to a tower.
## Stack multiple modifiers and recompute — never mutate base stats directly.

enum Mode {
	ADD,       ## Flat addition: base + value
	MULTIPLY,  ## Multiplicative: result *= value
	OVERRIDE,  ## Replaces base entirely (use sparingly)
}

@export var key: String = ""         ## Stat name: "damage", "fire_rate", "detection_range", etc.
@export var value: float = 0.0
@export var mode: Mode = Mode.ADD
@export var source_upgrade_id: String = ""  ## Which upgrade applied this (for removal on sell)


static func make(stat_key: String, val: float, mod_mode: Mode, upgrade_id: String) -> StatModifier:
	var m := StatModifier.new()
	m.key = stat_key
	m.value = val
	m.mode = mod_mode
	m.source_upgrade_id = upgrade_id
	return m
