extends Node2D

const COLLISION_MASK_CARD = 1
const HIGHLIGHT_RATE = 1.2 # 卡片的悬停效果的缩放倍率

var card_being_dragged # 正在被拖动的卡牌
var screen_size
var is_hovering_card

func _ready() -> void:
	screen_size = get_viewport_rect().size
	
	
func _process(delta: float) -> void:
	if card_being_dragged:
		var mouse_pos = get_global_mouse_position()
		card_being_dragged.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var card = raycast_check_for_card()
			if card:
				start_drag(card)
		else:
			finish_drag()

func raycast_check_for_card():
	# 返回与当前鼠标位置发生碰撞的卡片
	var space_state = get_world_2d().direct_space_state # 一种保存了所有 2D 世界组件的资源，例如画布和物理运算空间。
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_card_with_highest_z_index(result)
	else:
		return null

func connect_card_signals(card):
	card.connect("hovered", on_hovered_over_card)
	card.connect("hovered_off", on_hovered_off_card)
	
func on_hovered_over_card(card):
	# emit_signal时传送了self也就是Card自身过来，所以也要接受这个参数
	if !is_hovering_card:
		is_hovering_card = true
		highlight_card(card, true)

func on_hovered_off_card(card):
	if !card_being_dragged: # 在拖动卡片时，不要切换new_card_hovered，换句话说就是拖住卡牌时经过其他卡牌不会发生悬停效果
		highlight_card(card, false)
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered:
			highlight_card(new_card_hovered, true)
		else:
			is_hovering_card = false
	
func highlight_card(card, hovered):
	if hovered:
		card.scale = Vector2(HIGHLIGHT_RATE, HIGHLIGHT_RATE)
		card.z_index = 2
	else:
		card.scale = Vector2(1, 1)
		card.z_index = 1
		
func get_card_with_highest_z_index(cards):
	# 传入多张卡片，返回其中z坐标最高的那一个
	# 我们会在highlight函数中修改卡片的z坐标
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	# 循环求最大值
	for i in range(1,cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_index = current_card.z_index
			highest_z_card = current_card
			
	return highest_z_card

# 开始拖动让卡牌变小
func start_drag(card):
	card_being_dragged = card
	card_being_dragged.scale = Vector2(1, 1)
	
func finish_drag():
	card_being_dragged.scale = Vector2(HIGHLIGHT_RATE, HIGHLIGHT_RATE)
	card_being_dragged = null
