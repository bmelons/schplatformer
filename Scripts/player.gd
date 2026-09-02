extends CharacterBody3D
class_name Player
@export var SPEED : float = 5 ## movement speed
@export var JUMP_FORCE : float = 3 ## jump force
@export var GRAVITY_FORCE : float = 10 ## ok i dont need to label these first four really
@export var PUSH_FORCE : float = 1
@export var RIGHT_STICK_SENSITIVITY : float = 15 ## camera speed on stick controls
@export var INPUT_BUFFER_TIME : float = 0.1 ## how much time the jump button stays active after pressing (i.e tapping jump right before hitting the ground and it works)
@export var JUMP_MAX_RISE_TIME : float = 0.2 ## how long you can hold jump to retain jump force
@export var ACCEL_FACTOR : float = 40.0
@export var AIR_ACCELERATE : float = .1 ## air acceleration percentage

@onready var camArm : SpringArm3D = $camArm
@onready var camera : Camera3D = $camArm/MainCamera
@onready var collider : CollisionShape3D = $Collider
@onready var sounds : Dictionary = {
	"Jump": $JumpSound,
	"ZoomIn": $ZoomIn,
	"ZoomOut": $ZoomOut,
	
}
# Called when the node enters the scene tree for the first time.
var camInput = Vector2.ZERO
var lastActiveInput = Vector2.UP
var gravity : float = 0 # current vertical velocity
var lastJump : float = 0
var lastJumpInput : float = 0
var grabbableProp : Prop = null
var holding : Prop = null


func _ready() -> void:
	Main.current_player = self
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # lock mouse in window
	camArm.add_excluded_object(self) #keep spring arm from colloding with yourself

func _unhandled_input(event: InputEvent) -> void: 
	if event is InputEventMouseMotion:
		camInput += event.relative/180 # add mouse movement to camera movement, the movement is processed on a frame by frame basis but the input is handled event by event
	
func PlaySoundRandPitch(sound):
	sound = sounds[sound]
	sound.pitch_scale = .9 + (randf()*.2)
	sound.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func grab():
	if grabbableProp == null:
		return
	holding = grabbableProp
	grabbableProp = null
func throw():
	if holding == null:
		return
	holding.linear_velocity = Vector3(0,0,0)
func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_close_dialog"): get_tree().quit()
	var rightStick = Input.get_vector("cam_pan_left","cam_pan_right","cam_pan_up","cam_pan_down")*delta*RIGHT_STICK_SENSITIVITY
	camInput += rightStick
	camArm.rotation.x += -camInput.y
	camArm.rotation.y += -camInput.x
	camArm.rotation.x = clampf(camArm.rotation.x,deg_to_rad(-80),deg_to_rad(70))
	#var inputAngle = 
	camInput = Vector2.ZERO
	
	var input_2d = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_2d.length() > .1:
		lastActiveInput = input_2d
	if not is_on_floor():
		input_2d = input_2d # for later when im implementing persistent aerial velocity
	
	var move_dir = Vector3(input_2d.x, 0, input_2d.y).rotated(Vector3.UP, camArm.rotation.y)
	
	
	if is_on_floor():
		gravity = 0
	else:
		gravity -= GRAVITY_FORCE * delta
		
	if Input.is_action_just_pressed("jump"):
		# set the jump to buffer
		
		lastJumpInput = Main.tick()
	if Main.tick()-lastJumpInput <= INPUT_BUFFER_TIME and is_on_floor():
		# if the player pressed jump within the last INPUT_BUFFER_TIME seconds and theyre on the floor
		gravity = JUMP_FORCE
		lastJump = Main.tick()
		PlaySoundRandPitch("Jump")
	elif Input.is_action_pressed("jump") and Main.tick()-lastJump < JUMP_MAX_RISE_TIME:
		# if theyre holding jump during the rise period
		#the funky math is the 0.0->1.0 percent of how much rise time the player has left
		gravity += GRAVITY_FORCE*((Main.tick()-lastJumpInput)/JUMP_MAX_RISE_TIME)*delta
		

	
	
	var current_h_vel = Vector3(velocity.x, 0.0, velocity.z)
	var target_h_vel = move_dir * SPEED
	var current_accel = ACCEL_FACTOR 
	if not is_on_floor():
		current_accel *= AIR_ACCELERATE
	var new_h_vel = current_h_vel.move_toward(target_h_vel, current_accel * delta)

	velocity.x = new_h_vel.x
	velocity.z = new_h_vel.z
	velocity.y = gravity
	move_and_slide()
	
	#push objects
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider_obj = collision.get_collider()
		
		if collider_obj is RigidBody3D:
			var normal = collision.get_normal()
			if normal.y > 0.5:
				continue
			var push_dir = -Vector3(normal.x, 0, normal.z).normalized()
			var a = clampf(target_h_vel.length(),0,1)
			collider_obj.apply_impulse(push_dir * PUSH_FORCE * a, collision.get_position() - collider_obj.global_position)
