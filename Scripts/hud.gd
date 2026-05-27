extends CanvasLayer

## Attach to a CanvasLayer node called "HUD" in Level1.tscn.
## Scene structure:
##   HUD (CanvasLayer)
##   └── Control
##       ├── TopBar (HBoxContainer) — anchor: top full
##       │   ├── GoldLabel (Label)
##       │   ├── LivesLabel (Label)
##       │   └── WaveLabel (Label)
##       ├── TowerInfo (Label) — anchor: bottom left
##       ├── WaveAnnouncement (Label) — center screen
##       ├── GameOverScreen (ColorRect, hidden) — full screen
##       │   └── VBoxContainer
##       │       ├── GameOverLabel (Label)
##       │       └── RestartButton (Button)
##       └── TowerPanel (PanelContainer) — right side, collapsible
##           └── HBoxContainer
##               ├── ToggleButton (Button) — "<" / ">" arrow
##               └── TowerVBox (VBoxContainer)
##                   ├── PanelTitle (Label)
##                   ├── Tower1Btn (Button)
##                   ├── Tower2Btn (Button)
##                   └── Tower3Btn (Button)

@onready var gold_label: Label = $Control/TopBar/GoldLabel
@onready var lives_label: Label = $Control/TopBar/LivesLabel
@onready var wave_label: Label = $Control/TopBar/WaveLabel
@onready var tower_info: Label = $Control/TowerInfo
@onready var game_over_screen: ColorRect = $Control/GameOverScreen
@onready var wave_announcement: Label = $Control/WaveAnnouncement
@onready var restart_button: Button = $Control/GameOverScreen/VBoxContainer/RestartButton

@onready var tower_panel: PanelContainer = $Control/TowerPanel
@onready var tower_vbox: VBoxContainer = $Control/TowerPanel/HBoxContainer/TowerVBox
@onready var toggle_button: Button = $Control/TowerPanel/HBoxContainer/ToggleButton
@onready var tower1_btn: Button = $Control/TowerPanel/HBoxContainer/TowerVBox/Tower1Btn
@onready var tower2_btn: Button = $Control/TowerPanel/HBoxContainer/TowerVBox/Tower2Btn
@onready var tower3_btn: Button = $Control/TowerPanel/HBoxContainer/TowerVBox/Tower3Btn

var _panel_expanded: bool = true
var _tower_buttons: Array[Button] = []
var _tower_placer: Node = null

const TOWER_COSTS := [50, 100, 150]
const TOWER_COLORS := [
	Color(0.2, 0.2, 0.2, 1),   # Tower1 dark grey
	Color(0.46, 0.18, 0.43, 1), # Tower2 purple
	Color(0.65, 0.65, 0.65, 1), # Tower3 light grey
]


func _ready() -> void:
	game_over_screen.hide()
	wave_announcement.hide()
	tower_info.hide()

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

	# Tower panel setup
	_tower_buttons = [tower1_btn, tower2_btn, tower3_btn]
	tower1_btn.pressed.connect(func(): _on_tower_btn_pressed(0))
	tower2_btn.pressed.connect(func(): _on_tower_btn_pressed(1))
	tower3_btn.pressed.connect(func(): _on_tower_btn_pressed(2))
	toggle_button.pressed.connect(_toggle_panel)

	# Style the tower buttons
	_style_tower_buttons()

	# Find TowerPlacer in scene
	await get_tree().process_frame
	_tower_placer = get_tree().current_scene.find_child("TowerPlacer", true, false)

	# Update button affordability each frame
	GameManager.gold_changed.connect(_update_button_affordability)
	_update_button_affordability(GameManager.gold)


func _style_tower_buttons() -> void:
	var tower_data: Array[Dictionary] = [
		{"name": "Tower 1", "sub": "Rapid Fire", "cost": 50, "key": "[1]"},
		{"name": "Tower 2", "sub": "Heavy Hitter", "cost": 100, "key": "[2]"},
		{"name": "Tower 3", "sub": "Sniper", "cost": 150, "key": "[3]"},
	]
	for i in range(_tower_buttons.size()):
		var btn := _tower_buttons[i]
		var d: Dictionary = tower_data[i]
		btn.text = "%s\n%s\n%d Gold  %s" % [d["name"], d["sub"], d["cost"], d["key"]]
		btn.custom_minimum_size = Vector2(0, 75)
		# We'll tint the button via modulate to show tower color
		btn.modulate = TOWER_COLORS[i].lerp(Color.WHITE, 0.5)


func _on_tower_btn_pressed(index: int) -> void:
	if _tower_placer and _tower_placer.has_method("_enter_placement_mode"):
		_tower_placer._enter_placement_mode(index)
	_highlight_selected_button(index)


func _highlight_selected_button(selected: int) -> void:
	for i in range(_tower_buttons.size()):
		var btn := _tower_buttons[i]
		if i == selected:
			btn.modulate = Color(1.0, 1.0, 0.3, 1.0)  # Yellow highlight when selected
		else:
			btn.modulate = TOWER_COLORS[i].lerp(Color.WHITE, 0.5)


func clear_tower_selection() -> void:
	## Called by TowerPlacer when placement is cancelled
	for i in range(_tower_buttons.size()):
		_tower_buttons[i].modulate = TOWER_COLORS[i].lerp(Color.WHITE, 0.5)


func _update_button_affordability(gold: int) -> void:
	for i in range(_tower_buttons.size()):
		var btn := _tower_buttons[i]
		var can_afford: bool = gold >= TOWER_COSTS[i]
		btn.disabled = not can_afford
		if not can_afford:
			btn.modulate = Color(0.5, 0.5, 0.5, 0.6)
		else:
			btn.modulate = TOWER_COLORS[i].lerp(Color.WHITE, 0.5)


func _toggle_panel() -> void:
	_panel_expanded = not _panel_expanded
	tower_vbox.visible = _panel_expanded
	toggle_button.text = "◀" if _panel_expanded else "▶"

	# Animate the panel sliding
	var target_offset: float = -220.0 if _panel_expanded else -28.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(tower_panel, "offset_left", target_offset, 0.2)


func _on_gold_changed(amount: int) -> void:
	gold_label.text = "💰 Gold: %d" % amount


func _on_lives_changed(amount: int) -> void:
	lives_label.text = "❤️ Lives: %d" % amount


func _on_wave_changed(wave: int) -> void:
	wave_label.text = "🌊 Wave: %d / %d" % [wave, GameManager.total_waves]
	if wave > 0:
		_show_wave_announcement("Wave %d" % wave)


func show_tower_info(index: int) -> void:
	## Called by TowerPlacer when a tower type is selected
	var names := ["Tower 1 — Rapid (50g)", "Tower 2 — Heavy (100g)", "Tower 3 — Sniper (150g)"]
	if index < names.size():
		tower_info.text = names[index]
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
	label.text = "YOU WIN! 🎉"


func _on_restart() -> void:
	GameManager.reset()
	get_tree().reload_current_scene()
