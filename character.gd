extends CharacterBody3D
class_name Character

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = 20

const FPS: int = 10

@export var PLAYER: bool = true
@export var CHARACTER: String = "Emerl" # Character name
@export var NAME: String = "Aimed B690"
@onready var STATS: Dictionary = load("res://Characters/" + CHARACTER + "/Data/stats.json").data # Character stats
@onready var ANIMATIONS: Dictionary = load("res://Characters/" + CHARACTER + "/Data/animations.json").data # Character animation data

@onready var Sprite: AnimatedSprite3D = $Sprite
@onready var Animator: AnimationPlayer = $Animator
@onready var StateManager: StateMachine = $StateMachine

var FORWARD: Vector3 = Vector3.FORWARD

func _ready() -> void:
	setup_anim(CHARACTER) # Setup the character animations

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = STATS.JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (CAMERA.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * STATS.WALK_SPEED 
		velocity.z = direction.z * STATS.WALK_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, STATS.WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, STATS.WALK_SPEED)

	move_and_slide()

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
