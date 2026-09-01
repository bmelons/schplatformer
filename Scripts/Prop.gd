extends RigidBody3D
class_name Prop

@export var Grabbable : bool = false

@onready var prompt : PackedScene = load("res://Prefabs/BillboardButtonPrompt.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var pd = global_position.distance_to(Main.current_player.global_position)
