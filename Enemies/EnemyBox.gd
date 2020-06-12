extends Area2D

var vel = Vector2(250,0)


func _physics_process(delta):
	position += vel * delta
	
func _on_EnemyBox_body_entered(body):
	if body.has_method('take_damage'):
		body.take_damage()
	vel *= -1
	$Sprite.flip_h = not $Sprite.flip_h
