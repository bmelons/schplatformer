extends RigidBody3D
class_name Prop

@export var InteractDistance : float = 1.0
@export var Grabbable : bool = false

@onready var prompt_scene : PackedScene = load("res://Prefabs/BillboardButtonPrompt.tscn")
var prompt : BillboardButtonPrompt
var active = false : set = _set_active
var activated_time :float = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prompt = prompt_scene.instantiate()
	add_child(prompt)
	prompt.position = Vector3.ZERO
	
	pass

func time_active():
	return Main.tick()-activated_time

func _set_active(new):
	active = new
	if new == true:
		Main.current_player.grabbableProp = self
	if new == false and Main.current_player.grabbableProp == self:
		Main.current_player.grabbableProp = null
	activated_time = Main.tick()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player_distance = global_position.distance_to(Main.current_player.global_position)
	if active:
		# this math makes it flash, then its clamped down to the valid range of opacity
		#heres the graph for the function
		#https://www.desmos.com/calculator/d90wnd35fh
		var op = -cos(time_active()*PI*3) + 1
		prompt.opacity = clampf(op,0,1)
	else:
		prompt.opacity = lerpf(prompt.opacity,0,.2)
	
	if player_distance <= InteractDistance and active == false:
		active = true
	elif player_distance > InteractDistance and active:
		active = false
	
	
