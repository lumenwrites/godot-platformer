extends Area2D

func _ready():
	pass


func _on_Trampoline_body_entered(body):
	if body is Player:
		print("jump")
		body.vel.y = -1200
		body.jumps_left = 1
		body.can_dash = true
