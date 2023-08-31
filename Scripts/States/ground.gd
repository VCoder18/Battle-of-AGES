extends BaseState
class_name GroundState

@onready var IDLE: BaseState = $"../../Movement/Idle"

func enter() -> void:
	super.enter()

func exit() -> void:
	super.exit()

func input() -> BaseState:
	super.input()
	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func physics_process(delta: float) -> BaseState:
	return null

func traction(multiplier: float = 1, custom_traction: float = player.STATS.TRACTION) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0, custom_traction * multiplier)
	player.velocity.z = move_toward(player.velocity.z, 0, custom_traction * multiplier)
