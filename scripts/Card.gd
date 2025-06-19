extends Node2D

signal hovered
signal hovered_off
var card_position

func _ready() -> void:
	# 这样操作会让Card在创建时让它的父节点（CardManager）调用connect_card_signals方法
	get_parent().connect_card_signals(self)
	var random_number = str(RandomNumberGenerator.new().randi_range(1,9))
	var new_texture = load("res://assets/萝卜牌/bk_card"+random_number+".png")
	$CardImage.texture = new_texture
	
func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
