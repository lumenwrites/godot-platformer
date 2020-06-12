extends Area2D

export (NodePath) var PortalB
var exit 

func _ready():
	exit = $Exit
	
func _on_PortalA_body_entered(body):
	if body is Player:
		body.global_position = get_node(PortalB).exit.global_position
		body.vel = -get_node(PortalB).exit.global_transform.y * body.vel.length() * 1.5
