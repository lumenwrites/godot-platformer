extends Area2D

var is_active = true
var reactivate_time = 3.0

func activate():
	$Sprite.show()
	is_active = true
	
func deactivate():
	$Sprite.hide()
	is_active = false
	
func _on_Powerup_body_entered(body):
	if body is Player and is_active:
		body.jumps_left += 1
		body.can_dash = true
		deactivate()
		yield(get_tree().create_timer(reactivate_time), "timeout")
		activate()
