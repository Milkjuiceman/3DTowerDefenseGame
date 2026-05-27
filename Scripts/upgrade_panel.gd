extends Control

signal closed

const HEX_RADIUS: float = 38.0
const LINE_COLOR_LOCKED    := Color(0.3, 0.3, 0.3, 0.6)
const LINE_COLOR_PURCHASED := Color(0.2, 0.7, 1.0, 1.0)

var _tower: Node3D = null
var _states: Array[Dictionary] = []
var _buttons: Array[Dictionary] = []

## These match the node names exactly as they appear in UpgradePanel.tscn
@onready var title_label: Label       = $VBoxContainer/TopRow/TitleLabel
@onready var close_button: Button     = $VBoxContainer/TopRow/CloseButton
@onready var stats_label: Label       = $VBoxContainer/StatsLabel
@onready var graph_area: Control      = $VBoxContainer/GraphArea
@onready var sell_button: Button      = $VBoxContainer/SellButton


func _ready() -> void:
	hide()
	close_button.pressed.connect(_on_close)
	sell_button.pressed.connect(_on_sell)
	graph_area.draw.connect(_on_graph_draw)
	graph_area.gui_input.connect(_on_graph_gui_input)
	if UpgradeManager:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)


func open_for(tower: Node3D) -> void:
	_tower = tower
	_refresh()
	show()


func _refresh() -> void:
	if _tower == null or not is_instance_valid(_tower):
		_on_close()
		return

	## Guard: tower must use tower_instance.gd (has tower_data property)
	if not _tower.get("tower_data") != null and not _tower.has_method("get_stat"):
		title_label.text = "No upgrade data"
		stats_label.text = "Assign tower_instance.gd and a TowerData resource."
		sell_button.text = "Sell"
		graph_area.queue_redraw()
		return

	_states = UpgradeManager.get_upgrade_states(_tower)
	_buttons.clear()
	var td: TowerData = _tower.get("tower_data")
	title_label.text = td.display_name if td else "Tower"
	sell_button.text = "Sell (~%dg)" % _estimate_sell_value()
	_refresh_stats()
	graph_area.queue_redraw()


func _refresh_stats() -> void:
	if _tower == null or not is_instance_valid(_tower):
		return
	stats_label.text = "DMG: %.0f  |  Rate: %.1f/s  |  Range: %.1f" % [
		_tower.get_stat("damage"),
		_tower.get_stat("fire_rate"),
		_tower.get_stat("detection_range"),
	]


func _estimate_sell_value() -> int:
	if _tower == null or _tower.tower_data == null:
		return 0
	var total: int = int(_tower.tower_data.base_cost * 0.7)
	for state: Dictionary in _states:
		if state["purchased"]:
			var upg: UpgradeNode = state["upgrade"]
			total += int(upg.cost * 0.5)
	return total


# --- Drawing ------------------------------------------------------------------

func _on_graph_draw() -> void:
	_buttons.clear()
	var area_size: Vector2 = graph_area.size

	## Lines behind nodes
	for state: Dictionary in _states:
		var upg: UpgradeNode = state["upgrade"]
		for prereq_id: String in upg.prerequisites:
			var prereq_state: Dictionary = _find_state(prereq_id)
			if prereq_state.is_empty():
				continue
			var from_pos: Vector2 = upg.ui_position * area_size
			var to_pos: Vector2 = (prereq_state["upgrade"] as UpgradeNode).ui_position * area_size
			var line_color: Color = LINE_COLOR_PURCHASED if prereq_state["purchased"] else LINE_COLOR_LOCKED
			graph_area.draw_line(from_pos, to_pos, line_color, 2.0)

	## Nodes
	for state: Dictionary in _states:
		var upg: UpgradeNode = state["upgrade"]
		var center: Vector2 = upg.ui_position * area_size
		_draw_hex_node(center, upg, state)
		_buttons.append({
			"rect": Rect2(center - Vector2(HEX_RADIUS, HEX_RADIUS), Vector2(HEX_RADIUS * 2.0, HEX_RADIUS * 2.0)),
			"upgrade": upg,
			"state": state,
		})


func _draw_hex_node(center: Vector2, upg: UpgradeNode, state: Dictionary) -> void:
	var purchased: bool = state["purchased"]
	var can_buy: bool   = state["can_buy"]
	var locked: bool    = state["locked"]

	var bg_color: Color
	var border_color: Color
	if purchased:
		bg_color = Color(0.15, 0.55, 0.9, 1.0);  border_color = Color(0.4, 0.8, 1.0, 1.0)
	elif can_buy:
		bg_color = Color(0.15, 0.6, 0.2, 1.0);   border_color = Color(0.4, 1.0, 0.4, 1.0)
	elif locked:
		bg_color = Color(0.18, 0.18, 0.18, 0.9); border_color = Color(0.35, 0.35, 0.35, 1.0)
	else:
		bg_color = Color(0.5, 0.35, 0.1, 0.9);   border_color = Color(0.9, 0.65, 0.1, 1.0)

	var pts := PackedVector2Array()
	for i in range(6):
		var angle: float = deg_to_rad(60.0 * i - 30.0)
		pts.append(center + Vector2(cos(angle), sin(angle)) * HEX_RADIUS)
	graph_area.draw_colored_polygon(pts, bg_color)
	for i in range(6):
		graph_area.draw_line(pts[i], pts[(i + 1) % 6], border_color, 2.5)

	var font: Font = ThemeDB.fallback_font
	var text_color: Color = Color.WHITE if not locked else Color(0.5, 0.5, 0.5)
	graph_area.draw_string(font, center + Vector2(-HEX_RADIUS * 0.8, -10.0),
		upg.display_name, HORIZONTAL_ALIGNMENT_LEFT, HEX_RADIUS * 1.6, 11, text_color)
	var cost_str: String = "%dg" % upg.cost if not purchased else "OK"
	var cost_color: Color = Color(1.0, 0.9, 0.3) if not purchased else Color(0.4, 1.0, 0.4)
	graph_area.draw_string(font, center + Vector2(-12.0, 14.0),
		cost_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, cost_color)
	var path_label: String = "A" if upg.path == 0 else "B"
	graph_area.draw_string(font, center + Vector2(-4.0, -HEX_RADIUS + 12.0),
		path_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.8, 0.8, 0.8, 0.7))


func _find_state(upgrade_id: String) -> Dictionary:
	for state: Dictionary in _states:
		if (state["upgrade"] as UpgradeNode).id == upgrade_id:
			return state
	return {}


# --- Input --------------------------------------------------------------------

func _on_graph_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for btn: Dictionary in _buttons:
			if (btn["rect"] as Rect2).has_point(event.position):
				_try_purchase(btn["upgrade"] as UpgradeNode)
				return


func _try_purchase(upgrade: UpgradeNode) -> void:
	if _tower == null or not is_instance_valid(_tower):
		return
	if not UpgradeManager.purchase(_tower, upgrade):
		_show_flash("Cannot purchase: %s" % upgrade.display_name)


func _show_flash(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.position = Vector2(10.0, graph_area.size.y - 30.0)
	graph_area.add_child(lbl)
	get_tree().create_timer(1.5).timeout.connect(lbl.queue_free)


# --- Signals ------------------------------------------------------------------

func _on_upgrade_purchased(tower: Node3D, _upgrade: UpgradeNode) -> void:
	if tower == _tower:
		_refresh()


func _on_sell() -> void:
	if _tower != null and is_instance_valid(_tower):
		UpgradeManager.sell_tower(_tower)
	_tower = null
	hide()
	closed.emit()


func _on_close() -> void:
	_tower = null
	hide()
	closed.emit()
