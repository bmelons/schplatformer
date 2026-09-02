# not finished at ALL i realized i didnt need to implement this at all right now
extends RigidBody3D
class_name Bouncer
func _ready():
	# Or connect via the Node dock in the editor
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D):
	print("Collided with: ", body.name)
	if body.name == Main.current_player.name:
		print("Hit the floor!")
