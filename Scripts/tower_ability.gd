class_name TowerAbility
extends Node

var tower: Node3D = null

func _ready() -> void:
	tower = get_parent()
	_on_init()

func _on_init() -> void:
	pass

func on_shot(_target: Node3D, _damage: float) -> void:
	pass

func on_process(_delta: float) -> void:
	pass

func on_removed() -> void:
	pass
