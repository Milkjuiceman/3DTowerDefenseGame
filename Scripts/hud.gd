extends CanvasLayer

## Attach to a CanvasLayer node called "HUD" in Level1.tscn.
## Scene structure:
##   HUD (CanvasLayer)
##   └── Control
##       ├── TopBar (HBoxContainer) — anchor: top full
##       │   ├── GoldLabel (Label)
##       │   ├── LivesLabel (Label)
##       │   └── WaveLabel (Label)
##       ├── TowerInfo (Label) — anchor: bottom left, shows selected tower cost
##       ├── GameOverScreen (ColorRect, hidden) — full screen
##       │   └── VBoxContainer
##       │       ├── GameOverLabel (Label) — "GAME OVER"
##       │       └── RestartButton (Button)
##       └── WaveAnnouncement (Label) — center screen, fades in/out

@onready var gold_label: Label = $Control/TopBar/GoldLabel
@onready var lives_label: Label = $Control/TopBar/LivesLabel
@onready var wave_label: Label = $Control/TopBar/WaveLabel
@onready var tower_info: Label = $Control/TowerInfo
@onready var game_over_screen: ColorRect = $Control/GameOverScreen
@onready var wave_announcement: Label = $Control/WaveAnnouncement
@onready var restart_button: Button = $Control/GameOverScreen/VBoxContainer/RestartButton

const TOWER_NAMES := ["Tower 1 — Rapid (50g)", "Tower 2 — Heavy (100g)", "Tower 3 — Sniper (150g)"]


func _ready() -> void:
	game_over_screen.hide()
	wave_announcement.hide()

	# Connect GameManager signals
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.game_over.connect(_on_game_over)
	GameManager.game_won.connect(_on_game_won)

	# Initialize display
	_on_gold_changed(GameManager.gold)
	_on_lives_changed(GameManager.lives)
	_on_wave_changed(GameManager.current_wave)

	restart_button.pressed.connect(_on_restart)


func _on_gold_changed(amount: int) -> void:
	gold_label.text = "Gold: %d" % amount


func _on_lives_changed(amount: int) -> void:
	lives_label.text = "Lives: %d" % amount


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Wave: %d / %d" % [wave, GameManager.total_waves]
	if wave > 0:
		_show_wave_announcement("Wave %d" % wave)


func show_tower_info(index: int) -> void:
	## Called by TowerPlacer when a tower type is selected
	if index < TOWER_NAMES.size():
		tower_info.text = TOWER_NAMES[index]
		tower_info.show()


func hide_tower_info() -> void:
	tower_info.hide()


func _show_wave_announcement(text: String) -> void:
	wave_announcement.text = text
	wave_announcement.show()
	wave_announcement.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(wave_announcement, "modulate:a", 0.0, 0.8)
	tween.tween_callback(wave_announcement.hide)


func _on_game_over() -> void:
	game_over_screen.show()
	var label := $Control/GameOverScreen/VBoxContainer/GameOverLabel as Label
	label.text = "GAME OVER"


func _on_game_won() -> void:
	game_over_screen.show()
	var label := $Control/GameOverScreen/VBoxContainer/GameOverLabel as Label
	label.text = "YOU WIN!"


func _on_restart() -> void:
	GameManager.reset()
	get_tree().reload_current_scene()
