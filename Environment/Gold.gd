extends Area2D

func _ready():
	pass


func _on_Gold_body_entered(body):
	if body is Player:
		queue_free()
		$"../HUD".increment_score()
