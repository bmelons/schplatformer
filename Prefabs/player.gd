extends CharacterBody3D

@export var speed : float = 5

@onready var camArm : SpringArm3D = $camArm
@onready var camera : Camera3D = $camArm/MainCamera
@onready var collider : CollisionShape3D = $Collider
# Called when the node enters the scene tree for the first time.
var camInput = Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camArm.add_excluded_object(self)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		camInput += event.relative/180
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"): get_tree().quit()
	camArm.rotation.x += camInput.y
	camArm.rotation.y += -camInput.x
	camInput = Vector2.ZERO
	
	var input_2d = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir = Vector3(input_2d.x, 0, input_2d.y).rotated(Vector3.UP, cam_arm.rotation.y)
	
	velocity = move_dir * speed
	move_and_slide()
