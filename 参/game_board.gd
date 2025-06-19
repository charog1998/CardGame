extends Control

class_name GameBoard

@onready var draw_pile_label = $DrawPileLabel
@onready var discard_pile_label = $DiscardPileLabel
@onready var player_positions = $PlayerPositions

func update_piles(draw_count: int, discard_count: int):
	draw_pile_label.text = "牌堆: %d" % draw_count
	discard_pile_label.text = "弃牌堆: %d" % discard_count

func update_player_positions(players: Array, current_player_index: int):
	for i in range(player_positions.get_child_count()):
		var position = player_positions.get_child(i)
		if i < players.size():
			position.visible = true
			position.get_node("Name").text = players[i].name
			position.get_node("Cards").text = "手牌: %d" % players[i].hand.size()
			
			if players[i].has_poop:
				position.get_node("Status").text = "状态: 有粑粑牌"
				position.get_node("Status").modulate = Color.RED
			elif players[i].command_count > 0:
				position.get_node("Status").text = "状态: 被指使(%d)" % players[i].command_count
				position.get_node("Status").modulate = Color.YELLOW
			else:
				position.get_node("Status").text = "状态: 正常"
				position.get_node("Status").modulate = Color.GREEN
			
			if i == current_player_index:
				position.modulate = Color(1, 1, 0.5)  # 高亮当前玩家
			else:
				position.modulate = Color.WHITE
		else:
			position.visible = false
