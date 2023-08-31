extends Node
class_name StateMachine

@export var init_state: BaseState

var current_state: BaseState
var new_state: BaseState

var states: Array[BaseState]

func change_state(next_state: BaseState) -> void:
	if current_state:
		current_state.exit()
	current_state = next_state
	states.push_front(current_state)
	if len(states) > 3:
		states.pop_back()
	current_state.enter()

func init(player: Character) -> void:
	for child in get_children():
		for sub_child in child.get_children():
			sub_child.player = player
	change_state(init_state)

func _physics_process(delta: float) -> void:
	new_state = current_state.physics_process(delta)
	if new_state:
		change_state(new_state)

func input():
	new_state = current_state.input()
	if new_state:
		change_state(new_state)
