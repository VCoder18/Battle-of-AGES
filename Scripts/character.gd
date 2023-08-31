extends CharacterBody3D
class_name Character

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20

const FPS: int = 10

@export var PLAYER: bool = true
@export var CHARACTER: String = "Emerl" # Character name
@export var NAME: String = "Aimed B690"
@export var CAMERA: Camera3D
@onready var STATS: Dictionary = load("res://Characters/" + CHARACTER + "/Data/stats.json").data # Character stats
@onready var ANIMATIONS: Dictionary = load("res://Characters/" + CHARACTER + "/Data/animations.json").data # Character animation data

@onready var Sprite: AnimatedSprite3D = $Sprite
@onready var Animator: AnimationPlayer = $Animator
@onready var StateManager: StateMachine = $StateMachine

var direction: Vector2
var move_direction: Vector3

var anim_frame: int
var current_anim: String
var frame: int

func _ready() -> void:
	setup_anim(CHARACTER) # Setup the character animations
	StateManager.init(self)

func handle_input():
	direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	move_direction = (CAMERA.transform.basis * Vector3(direction.x, 0, direction.y)).normalized()
	StateManager.input() # Execute input callback of the state machine


func _physics_process(delta):
	# Add the gravity.
	anim_frame = Sprite.frame
	handle_input() # Handle input
	StateManager._physics_process(delta) # State machine's physics process
	frame += 1 # Update frame counter
	if frame == 1800:
		frame = 0 # Reset frame counter if we remained for the same state for 1800 frames which is equivalent to 5 min
	
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = STATS.JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	if direction:
		velocity.x = move_direction.x * STATS.WALK_SPEED 
		velocity.z = move_direction.z * STATS.WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, STATS.WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, STATS.WALK_SPEED)

	move_and_slide()

func play_animation(anim_name: String, speed_scale: float = 1, seek: int = 0, blend: float = -1, restart: bool = false) -> void:
	# Plays an animation at a custom speed scale with backward play support
	if anim_name != current_anim or restart:
		if restart:
			Animator.stop()
		Animator.play(anim_name, blend, ANIMATIONS[anim_name]["speed"] * speed_scale, speed_scale < 0)
		if seek >= 0:
			Animator.seek(seek / FPS)
		current_anim = anim_name
		anim_frame = 0

func setup_anim(name: String) -> void:
	
	### Sprites Setup ###
	for d in ["Movement", "Attacks"]:
		var dir: DirAccess = DirAccess.open("res://Characters/" + name + "/Animations/" + d) # Opens the character's directory
		if dir and PLAYER: # We load everything if the directory exists and only once per character
			dir.list_dir_begin() # We begin the iteration of the character folder's content
			var anim_name = dir.get_next() # We start the 1st step of the iteration and get the name of its element
			while anim_name != "": # While there's still a folder to check we restart the procedure
				if dir.current_is_dir(): # If the we are actually in a folder...
					var subdir: DirAccess = DirAccess.open("res://Characters/" + name + "/Animations/" + d + "/" + anim_name) # We open the animation folder
					
					if subdir: # If that folder exists...
						Sprite.get_sprite_frames().add_animation(anim_name) # We create an animation named after its folder in Sprite
						Sprite.get_sprite_frames().set_animation_loop(anim_name, false) # We disable loop mode
						subdir.list_dir_begin() # We begin the iteration of the animation folder
						var sprite_name = subdir.get_next() # We start the 1st step of the iteration and get the name of its element
						
						while sprite_name != "": # While there's still content in that folder, in our case, sprites
							if sprite_name[-1] != 't': # If the selected file isn't a .import from the engine...
								Sprite.get_sprite_frames().add_frame(anim_name, ResourceLoader.load("res://Characters/" + name + "/Animations/" + d + "/" + anim_name + "/" + sprite_name)) # We add the sprite to the animation
								
							sprite_name = subdir.get_next() # We go to next sprite
						
						subdir.list_dir_end() # We close the animation's sprites folder
						
						### Animations Setup ###
						var animation: Animation = Animation.new() # We create an Animation for Animator
						var animation_track = animation.add_track(Animation.TYPE_VALUE) # We add to it a track to switch the animations in Sprite
						var frame_track = animation.add_track(Animation.TYPE_VALUE) # We add to it a track to move the frames of Sprite
						animation.track_set_path(animation_track, "Sprite:animation") # We setup the Sprite animation track
						animation.track_set_path(frame_track, "Sprite:frame") # We stup the Sprite frame track
						animation.track_insert_key(animation_track, 0.0, anim_name) # We add a keyframe to switch an animation at its beginning
						for i in range(len(subdir.get_files()) / 2): # We loop through the number of sprites in that animation folder
							animation.track_insert_key(frame_track, 1.0 / FPS * i, i) # We insert a keyframe for each sprite
						animation.value_track_set_update_mode(animation_track, animation.UPDATE_DISCRETE) # We set the animation track into discrete mode
						animation.value_track_set_update_mode(frame_track, animation.UPDATE_DISCRETE) # We set the frame track into discrete mode
						animation.length = len(subdir.get_files()) / 2 * 1.0 / FPS # We set the length of the animation in Animator
						animation.loop_mode = Animation.LOOP_LINEAR if ANIMATIONS[anim_name]["loop"] else Animation.LOOP_NONE # We set the loop mode of the animation according to the character's Animations data
						
						Animator.get_animation_library("").add_animation(anim_name, animation) # We add the animation to the Animator's library
				
				anim_name = dir.get_next() # We go to the next animation folder and loop again
			
			dir.list_dir_end() # We close the character folder

func _on_sprite_frame_changed():
	var texture: Texture2D = Sprite.sprite_frames.get_frame_texture(Sprite.animation, Sprite.frame) # Get the sprite of the current animation at the current frame
	var size: Vector2 = texture.get_size() # Get the dimensions of that sprite
	Sprite.offset.y = -17 + size.y / 2 # Make the sprite's position fixed to its bottom
