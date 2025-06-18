extends Node2D

signal hovered
signal hovered_off

func _ready() -> void:
	# 这样操作会让Card在创建时让它的父节点（CardManager）调用connect_card_signals方法
	get_parent().connect_card_signals(self)

func _on_area_2d_mouse_entered() -> void:
	print("in")
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
