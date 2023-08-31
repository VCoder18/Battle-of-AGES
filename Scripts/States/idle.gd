extends GroundState

func input() -> BaseState:
	# Handle horizontal movement states : WALK, RUN
	var new_state: BaseState = super.input()
	if new_state:
		return new_state
	return null

func physics_process(delta: float) -> BaseState:
	var new_state: BaseState = super.physics_process(delta)
	if new_state:
		return new_state
	# Handle Traction
	traction()
	return null
