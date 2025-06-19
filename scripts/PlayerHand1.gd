extends Node2D

const HAND_COUNT = 8
const CARD_SCENE_PATH = "res://scenes/card.tscn"
const CARD_WIDTH = 50
const HAND_Y_POSITION = 750
const CARD_SPEED = 0.2 # 抽牌动画的速度

var player_cards = []
var center_screen_x

func add_card_to_hand(card):
	if card not in player_cards:
		player_cards.insert(0,card)
		update_hand_positions()
	else:
		animate_card_to_position(card, card.card_position)
	
func update_hand_positions():
	for i in range(player_cards.size()):
		var new_position = Vector2(calculate_card_position(i),HAND_Y_POSITION)
		var card = player_cards[i]
		card.card_position = new_position
		animate_card_to_position(card,new_position)

func calculate_card_position(index: int):
	var total_width = (player_cards.size() -1)*CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width/2
	return x_offset

func animate_card_to_position(card,new_position):
	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", new_position, CARD_SPEED)
	
func remove_from_player_hand(card):
	if card in player_cards:
		player_cards.erase(card)
		card.visible = false # 打出之后让那张牌变为不可见
		update_hand_positions()

func _ready() -> void:
	center_screen_x = get_viewport().size.x/2
	var card_scene = preload(CARD_SCENE_PATH)
	for i in range(HAND_COUNT):
		var new_card = card_scene.instantiate()
		$"../CardManager".add_child(new_card)
		add_card_to_hand(new_card)
