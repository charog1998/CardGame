class_name Card

# 卡牌类型枚举
enum CardType {
	SKIP,       # 跳过
	REVERSE,    # 转向
	SHUFFLE,    # 洗牌
	SEE_THRU,   # 看穿
	DIVINE,     # 占卜
	COMMAND,    # 指使
	DEMAND,     # 索要
	EXCHANGE,   # 交换
	VETO,       # 否决
	POOP,       # 粑粑
	CLEAN       # 扫除
}

var type: CardType
var name: String
var description: String

func _init(type: CardType):
	self.type = type
	match type:
		CardType.SKIP:
			name = "跳过"
			description = "跳过下一名玩家的回合"
		CardType.REVERSE:
			name = "转向"
			description = "反转游戏方向"
		CardType.SHUFFLE:
			name = "洗牌"
			description = "重新洗牌"
		CardType.SEE_THRU:
			name = "看穿"
			description = "查看牌堆前三张牌"
		CardType.DIVINE:
			name = "占卜"
			description = "显示最近粑粑牌位置"
		CardType.COMMAND:
			name = "指使"
			description = "指定玩家额外行动2次"
		CardType.DEMAND:
			name = "索要"
			description = "从其他玩家获取一张牌"
		CardType.EXCHANGE:
			name = "交换"
			description = "与其他玩家交换手牌"
		CardType.VETO:
			name = "否决"
			description = "拒绝索要、指使或交换"
		CardType.POOP:
			name = "粑粑"
			description = "摸到后需使用扫除牌"
		CardType.CLEAN:
			name = "扫除"
			description = "清除粑粑牌"

func get_texture() -> Texture2D:
	var card_textures = [
		preload("res://assets/cards/card_0.png"),  # 跳过
		preload("res://assets/cards/card_1.png"),  # 转向
		preload("res://assets/cards/card_2.png"),  # 洗牌
		preload("res://assets/cards/card_3.png"),  # 看穿
		preload("res://assets/cards/card_4.png"),  # 占卜
		preload("res://assets/cards/card_5.png"),  # 指使
		preload("res://assets/cards/card_6.png"),  # 索要
		preload("res://assets/cards/card_7.png"),  # 交换
		preload("res://assets/cards/card_8.png"),  # 否决
		preload("res://assets/cards/card_9.png"),  # 粑粑
		preload("res://assets/cards/card_10.png") # 扫除
	]
	return card_textures[type]
