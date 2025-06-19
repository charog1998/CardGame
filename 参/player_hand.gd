extends HBoxContainer

#class_name PlayerHand

signal card_selected(card)

func update_hand(cards: Array):
	# 清除现有卡片
	for child in get_children():
		child.queue_free()
	
	# 添加新卡片
	for card in cards:
		var button = Button.new()
		button.text = card.name
		button.custom_minimum_size = Vector2(80, 120)
		button.pressed.connect(_on_card_pressed.bind(card))
		add_child(button)

func _on_card_pressed(card: Card):
	emit_signal("card_selected", card)
