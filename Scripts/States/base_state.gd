extends Node
class_name BaseState

@export var anim_name: String # The animation to play once the state started
@export var anim_speed: float = 1
@export var anim_seek: int = 0
@export var anim_blend: float = -1

var player: Character # A reference to the controlled Character

### Enter Callback ###
func enter() -> void:
	player.frame = 0 # Reset state duration in frame
	play_animation(anim_name, anim_speed, false, anim_seek, anim_blend) # Plays the state's animation

### Exit Callback ###
func exit() -> void:
	pass

### Input Callback ###
func input() -> BaseState:
	return null

### Physics Process ###
func physics_process(delta: float) -> BaseState:
	return null

func get_face() -> int:
	return 1 if player.face else -1

func play_animation(n: String = anim_name, s: float = anim_speed, r: bool = false, k: float = anim_seek, b: float = anim_blend) -> void:
	player.play_animation(n, s, k, b, r)
