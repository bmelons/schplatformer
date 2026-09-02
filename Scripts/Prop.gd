extends RigidBody3D
class_name Prop

@export var InteractDistance : float = 1.0
@export var Grabbable : bool = false

@onready var prompt_scene : PackedScene = load("res://Prefabs/BillboardButtonPrompt.tscn")
@onready var collider : CollisionShape3D = $CollisionShape3D
@onready var IntendedMass : float = self.mass
@onready var IntendedCollLayer : int = self.collision_layer
@onready var IntendedCollMask : int = self.collision_mask
var prompt : BillboardButtonPrompt
var active = false : set = _set_active
var activated_time :float = 0.0
var lastDropped: float = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prompt = prompt_scene.instantiate()
	add_child(prompt)
	prompt.position = Vector3.ZERO
	Main.current_player.camArm.add_excluded_object(self)
	print(collision_layer,collision_mask)
	
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

func wizard_math():
	# this math makes it flash, then its clamped down to the valid range of opacity
		#heres the graph for the function
		#https://www.desmos.com/calculator/d90wnd35fh
	var base_math = -cos(time_active()*PI*3) + 1
	var clamped_to_range =clampf(base_math,0,1)
	return clamped_to_range

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var player_distance = global_position.distance_to(Main.current_player.global_position)
	if Grabbable: 
		if Main.current_player.holding == self or Main.time_since(lastDropped) < .5:
			active = false
		elif player_distance <= InteractDistance and active == false:
			active = true
		elif player_distance > InteractDistance and active:
			active = false
	if active:
		prompt.opacity = wizard_math()
	else:
		prompt.opacity = lerpf(prompt.opacity,0,.2)
	
