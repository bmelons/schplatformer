extends Node3D
class_name BillboardButtonPrompt
var button = "x"
var opacity :float = 0.0 : set = _set_opacity
@export var offset : Vector3
func _set_opacity(new:float):
	opacity = new
	$prompt.get_surface_override_material(0)["shader_parameter/albedo"] = Color(1,1,1,opacity)


func _ready() -> void:
	opacity= opacity

func _process(delta: float) -> void:
	$prompt.global_position = global_position +offset
