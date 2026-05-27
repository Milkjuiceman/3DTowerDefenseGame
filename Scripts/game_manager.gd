extends Node

## Autoload singleton — add this in Project > Project Settings > Autoload
## Name it "GameManager" so all scripts can access it globally.

signal gold_changed(new_amount: int)
signal lives_changed(new_amount: int)
signal wave_changed(new_wave: int)
signal game_over()
signal game_won()

const STARTING_GOLD: int = 150
const STARTING_LIVES: int = 20

var gold: int = STARTING_GOLD
var lives: int = STARTING_LIVES
var current_wave: int = 0
var total_waves: int = 0  # Set by EnemySpawner on ready


func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true


func can_afford(amount: int) -> bool:
	return gold >= amount


func lose_life(amount: int = 1) -> void:
	lives -= amount
	lives_changed.emit(lives)
	if lives <= 0:
		lives = 0
		game_over.emit()


func set_wave(wave: int) -> void:
	current_wave = wave
	wave_changed.emit(wave)


func reset() -> void:
	gold = STARTING_GOLD
	lives = STARTING_LIVES
	current_wave = 0
	gold_changed.emit(gold)
	lives_changed.emit(lives)
	wave_changed.emit(current_wave)
