extends Node2D

class_name MainScene

# 玩家类
class Player:
	var id: int
	var name: String
	var is_human: bool
	var hand: Array = []
	var command_count: int = 0
	var has_poop: bool = false
	
	func _init(id: int, name: String, is_human: bool):
		self.id = id
		self.name = name
		self.is_human = is_human
		self.command_count = 0
		self.has_poop = false

# 游戏状态
enum GameState {
	PLAYER_TURN,
	AI_TURN,
	CARD_EFFECT,
	GAME_OVER
}

# 游戏变量
var players: Array = []
var current_player_index: int = 0
var draw_pile: Array = []
var discard_pile: Array = []
var game_state: GameState = GameState.PLAYER_TURN
var game_direction: int = 1  # 1: 顺时针, -1: 逆时针
var last_poop_index: int = -1
var top_three_cards: Array = []
var selected_card: Card = null
var selected_target: int = -1
var command_stack: Array = []

# 节点引用
@onready var player_hand = $UI/PlayerHand
@onready var game_board = $GameBoard
@onready var player_info = $UI/PlayerInfo
@onready var message_label = $UI/MessageLabel
@onready var card_preview = $UI/CardPreview
@onready var action_buttons = $UI/ActionButtons
@onready var effect_buttons = $UI/EffectButtons
@onready var target_buttons = $UI/TargetButtons
@onready var poop_position_label = $UI/PoopPositionLabel

func _ready():
	# 初始化玩家
	players.append(Player.new(0, "你", true))
	players.append(Player.new(1, "AI-1", false))
	players.append(Player.new(2, "AI-2", false))
	players.append(Player.new(3, "AI-3", false))
	
	# 初始化牌堆
	initialize_deck()
	
	# 开始游戏
	start_game()

# 初始化牌堆
func initialize_deck():
	draw_pile = []
	
	# 添加各种卡牌
	for i in range(5): draw_pile.append(Card.new(Card.CardType.SKIP))
	for i in range(3): draw_pile.append(Card.new(Card.CardType.REVERSE))
	for i in range(3): draw_pile.append(Card.new(Card.CardType.SHUFFLE))
	for i in range(4): draw_pile.append(Card.new(Card.CardType.SEE_THRU))
	for i in range(4): draw_pile.append(Card.new(Card.CardType.DIVINE))
	for i in range(4): draw_pile.append(Card.new(Card.CardType.COMMAND))
	for i in range(3): draw_pile.append(Card.new(Card.CardType.DEMAND))
	for i in range(3): draw_pile.append(Card.new(Card.CardType.EXCHANGE))
	for i in range(3): draw_pile.append(Card.new(Card.CardType.VETO))
	for i in range(3): draw_pile.append(Card.new(Card.CardType.POOP))
	for i in range(5): draw_pile.append(Card.new(Card.CardType.CLEAN))
	
	shuffle_deck()

# 洗牌
func shuffle_deck():
	# 主洗牌逻辑
	draw_pile.shuffle()
	update_last_poop_position()

# 更新最近粑粑牌位置
func update_last_poop_position():
	last_poop_index = -1
	for i in range(draw_pile.size()):
		if draw_pile[i].type == Card.CardType.POOP:
			last_poop_index = i
			break

# 开始游戏
func start_game():
	# 每位玩家发5张牌
	for player in players:
		for i in range(5):
			draw_card(player)
	
	# 随机选择起始玩家
	current_player_index = randi() % players.size()
	update_ui()
	start_turn()

# 开始回合
func start_turn():
	var player = players[current_player_index]
	
	# 检查玩家是否出局
	if player.has_poop and not has_clean_card(player):
		player_out(player)
		return
	
	# 显示消息
	show_message("%s的回合" % player.name)
	
	if player.is_human:
		game_state = GameState.PLAYER_TURN
		action_buttons.visible = true
	else:
		game_state = GameState.AI_TURN
		# AI思考后行动
		await get_tree().create_timer(1.0).timeout
		ai_turn()

# 玩家出局处理
func player_out(player: Player):
	show_message("%s 摸到粑粑牌且无扫除牌，出局！" % player.name)
	players.erase(player)
	
	# 检查游戏是否结束
	if players.size() == 1:
		end_game(players[0])
		return
	
	# 继续游戏
	if current_player_index >= players.size():
		current_player_index = 0
	start_turn()

# 结束游戏
func end_game(winner: Player):
	game_state = GameState.GAME_OVER
	show_message("游戏结束！%s 获胜！" % winner.name)
	action_buttons.visible = false

# 玩家摸牌
func draw_card(player: Player):
	if draw_pile.is_empty():
		reshuffle_discard_pile()
	
	if not draw_pile.is_empty():
		var card = draw_pile.pop_front()
		player.hand.append(card)
		
		# 如果摸到粑粑牌
		if card.type == Card.CardType.POOP:
			player.has_poop = true
			show_message("%s 摸到了粑粑牌！" % player.name)
			
			# 检查是否有扫除牌
			if not has_clean_card(player):
				# 没有扫除牌，玩家出局
				player_out(player)
				return false
		
		return true
	return false

# 检查玩家是否有扫除牌
func has_clean_card(player: Player) -> bool:
	for card in player.hand:
		if card.type == Card.CardType.CLEAN:
			return true
	return false

# 重新洗入弃牌堆
func reshuffle_discard_pile():
	if discard_pile.is_empty():
		return
	
	# 保留最后一张牌
	var last_card = discard_pile.pop_back() if not discard_pile.is_empty() else null
	
	# 洗牌
	discard_pile.shuffle()
	draw_pile = discard_pile.duplicate()
	
	# 如果有最后一张牌，放回弃牌堆
	if last_card:
		discard_pile = [last_card]
	else:
		discard_pile = []
	
	update_last_poop_position()

# 玩家行动 - 摸牌
func _on_draw_button_pressed():
	var player = players[current_player_index]
	
	if draw_card(player):
		end_turn()
	else:
		show_message("牌堆已空！")

# 玩家行动 - 出牌
func _on_play_button_pressed():
	player_hand.visible = true
	effect_buttons.visible = false
	target_buttons.visible = false

# 卡牌被选择
func _on_card_selected(card: Card):
	selected_card = card
	
	# 如果玩家有粑粑牌且选择的不是扫除牌
	var player = players[current_player_index]
	if player.has_poop and card.type != Card.CardType.CLEAN:
		show_message("你只能使用扫除牌！")
		return
	
	# 根据卡牌类型显示额外选项
	match card.type:
		Card.CardType.DEMAND, Card.CardType.EXCHANGE, Card.CardType.COMMAND:
			# 需要选择目标
			show_target_buttons()
		Card.CardType.CLEAN:
			# 扫除牌需要选择放置位置
			show_effect_buttons(["放回顶部", "放回中间", "放回底部"])
		_:
			# 直接使用卡牌
			play_card(card, -1)

# 显示目标选择按钮
func show_target_buttons():
	target_buttons.visible = true
	for i in range(target_buttons.get_child_count()):
		var btn = target_buttons.get_child(i)
		if i < players.size() and players[i].id != current_player_index:
			btn.text = players[i].name
			btn.visible = true
		else:
			btn.visible = false

# 显示效果选择按钮
func show_effect_buttons(options: Array):
	effect_buttons.visible = true
	for i in range(effect_buttons.get_child_count()):
		var btn = effect_buttons.get_child(i)
		if i < options.size():
			btn.text = options[i]
			btn.visible = true
		else:
			btn.visible = false

# 目标被选择
func _on_target_selected(index: int):
	selected_target = index
	play_card(selected_card, selected_target)

# 效果被选择
func _on_effect_selected(index: int):
	play_card(selected_card, index)

# 出牌
func play_card(card: Card, extra_info: int = -1):
	var player = players[current_player_index]
	
	# 从手牌中移除
	if player.hand.has(card):
		player.hand.erase(card)
	
	# 执行卡牌效果
	execute_card_effect(card, player, extra_info)
	
	# 添加到弃牌堆（除非是粑粑牌）
	if card.type != Card.CardType.POOP:
		discard_card(card)
	
	# 重置选择
	selected_card = null
	selected_target = -1
	
	# 隐藏UI
	player_hand.visible = false
	effect_buttons.visible = false
	target_buttons.visible = false
	
	# 结束回合（除非有指令叠加）
	if player.command_count <= 0:
		end_turn()

# 执行卡牌效果
func execute_card_effect(card: Card, player: Player, extra_info: int):
	match card.type:
		Card.CardType.SKIP:
			skip_next_player()
		Card.CardType.REVERSE:
			reverse_direction()
		Card.CardType.SHUFFLE:
			shuffle_deck()
		Card.CardType.SEE_THRU:
			see_through()
		Card.CardType.DIVINE:
			divine_poop()
		Card.CardType.COMMAND:
			command_player(extra_info)
		Card.CardType.DEMAND:
			demand_card(extra_info)
		Card.CardType.EXCHANGE:
			exchange_cards(extra_info)
		Card.CardType.VETO:
			# 否决牌在响应时使用，这里不会主动打出
			pass
		Card.CardType.CLEAN:
			clean_poop(extra_info)
		_:
			pass

# 卡牌效果实现
func skip_next_player():
	show_message("跳过了下一名玩家的回合")
	advance_to_next_player()

func reverse_direction():
	game_direction *= -1
	show_message("游戏方向已反转！")

func reshuffle_from_discard_pile():
	if discard_pile.is_empty():
		return
	
	var last_card = discard_pile.pop_back() if not discard_pile.is_empty() else null
	discard_pile.shuffle()
	draw_pile = discard_pile.duplicate()
	
	if last_card:
		discard_pile = [last_card]
	else:
		discard_pile = []
	update_last_poop_position()

func see_through():
	top_three_cards = []
	for i in range(min(3, draw_pile.size())):
		top_three_cards.append(draw_pile[i])
	
	show_message("牌堆前三张: %s, %s, %s" % [
		top_three_cards[0].name if top_three_cards.size() > 0 else "无",
		top_three_cards[1].name if top_three_cards.size() > 1 else "无",
		top_three_cards[2].name if top_three_cards.size() > 2 else "无"
	])

func divine_poop():
	if last_poop_index >= 0:
		show_message("最近粑粑牌在牌堆第 %d 张" % (last_poop_index + 1))
	else:
		show_message("牌堆中没有粑粑牌")

func command_player(target_index: int):
	var target = players[target_index]
	target.command_count += 2
	show_message("%s 被指使，需额外行动 %d 次！" % [target.name, target.command_count])
	
	# 如果目标是当前玩家，需要立即执行
	if target_index == current_player_index:
		command_stack.append(target.command_count)

func demand_card(target_index: int):
	var target = players[target_index]
	
	# 检查目标是否有否决牌
	var veto_index = -1
	for i in range(target.hand.size()):
		if target.hand[i].type == Card.CardType.VETO:
			veto_index = i
			break
	
	if veto_index != -1:
		# 使用否决牌
		var veto_card = target.hand[veto_index]
		target.hand.remove_at(veto_index)
		discard_pile.append(veto_card)
		show_message("%s 使用了否决牌，拒绝了索要！" % target.name)
	else:
		# 随机给一张牌
		if not target.hand.is_empty():
			var given_card = target.hand.pick_random()
			target.hand.erase(given_card)
			players[current_player_index].hand.append(given_card)
			show_message("%s 给了 %s 一张 %s" % [
				target.name, players[current_player_index].name, given_card.name
			])

func exchange_cards(target_index: int):
	var target = players[target_index]
	
	# 检查目标是否有否决牌
	var veto_index = -1
	for i in range(target.hand.size()):
		if target.hand[i].type == Card.CardType.VETO:
			veto_index = i
			break
	
	if veto_index != -1:
		# 使用否决牌
		var veto_card = target.hand[veto_index]
		target.hand.remove_at(veto_index)
		discard_pile.append(veto_card)
		show_message("%s 使用了否决牌，拒绝了交换！" % target.name)
	else:
		# 交换手牌
		var temp_hand = players[current_player_index].hand.duplicate()
		players[current_player_index].hand = target.hand.duplicate()
		target.hand = temp_hand
		show_message("%s 和 %s 交换了手牌！" % [
			players[current_player_index].name, target.name
		])

func clean_poop(position: int):
	var player = players[current_player_index]
	
	# 找到粑粑牌
	var poop_index = -1
	for i in range(player.hand.size()):
		if player.hand[i].type == Card.CardType.POOP:
			poop_index = i
			break
	
	if poop_index != -1:
		var poop_card = player.hand[poop_index]
		player.hand.remove_at(poop_index)
		player.has_poop = false
		
		# 将粑粑牌放回牌堆
		var insert_index = 0
		match position:
			0: insert_index = 0  # 顶部
			1: insert_index = draw_pile.size() / 2  # 中间
			2: insert_index = draw_pile.size()  # 底部
		
		draw_pile.insert(insert_index, poop_card)
		update_last_poop_position()
		
		show_message("粑粑牌被清除并放回牌堆第 %d 位" % (insert_index + 1))

# 结束回合
func end_turn():
	# 如果有指令叠加
	if not command_stack.is_empty():
		var count = command_stack.pop_back()
		if count > 1:
			command_stack.append(count - 1)
			show_message("继续执行指使 (%d次剩余)" % (count - 1))
			start_turn()
			return
	
	# 前进到下一个玩家
	advance_to_next_player()
	start_turn()

# 前进到下一个玩家
func advance_to_next_player():
	current_player_index = (current_player_index + game_direction) % players.size()
	if current_player_index < 0:
		current_player_index = players.size() - 1

# AI回合
func ai_turn():
	var player = players[current_player_index]
	
	# 如果玩家有粑粑牌，只能使用扫除牌
	if player.has_poop:
		# 查找扫除牌
		for card in player.hand:
			if card.type == Card.CardType.CLEAN:
				# 使用扫除牌，随机选择放置位置
				play_card(card, randi() % 3)
				return
		# 没有扫除牌，玩家出局
		player_out(player)
		return
	
	# 随机决定行动：70%出牌，30%摸牌
	if player.hand.size() > 0 and randf() < 0.7:
		# 选择一张牌
		var card = player.hand.pick_random()
		
		# 特殊卡牌处理
		match card.type:
			Card.CardType.DEMAND, Card.CardType.EXCHANGE, Card.CardType.COMMAND:
				# 选择目标（不能是自己）
				var target_index = current_player_index
				while target_index == current_player_index:
					target_index = randi() % players.size()
				play_card(card, target_index)
			Card.CardType.CLEAN:
				# 扫除牌在无粑粑时无法使用
				# 尝试其他牌
				for other_card in player.hand:
					if other_card.type != Card.CardType.CLEAN:
						card = other_card
						break
				play_card(card, -1)
			_:
				play_card(card, -1)
	else:
		# 摸牌
		draw_card(player)
		end_turn()

# 添加到弃牌堆
func discard_card(card: Card):
	discard_pile.append(card)

# 显示消息
func show_message(text: String):
	message_label.text = text
	message_label.visible = true
	await get_tree().create_timer(2.0).timeout
	message_label.visible = false

# 更新UI
func update_ui():
	# 更新玩家信息
	player_info.update_players(players, current_player_index)
	
	# 更新玩家手牌
	if players[current_player_index].is_human:
		player_hand.update_hand(players[current_player_index].hand)
	
	# 更新粑粑牌位置
	if last_poop_index >= 0:
		poop_position_label.text = "最近粑粑牌位置: %d" % (last_poop_index + 1)
	else:
		poop_position_label.text = "最近粑粑牌位置: 无"
	
	# 更新牌堆和弃牌堆显示
	game_board.update_piles(draw_pile.size(), discard_pile.size())
