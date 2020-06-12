extends Area2D

var parent # set by spawner
var speed = 10
var vel = Vector2()

func _ready():
	vel = parent.global_transform.x * speed
	rotation = vel.angle()
	
func _physics_process(delta):
	position += vel

func _on_FireMissile_body_entered(body):
	if body.has_method('take_damage'):
		body.take_damage()
	queue_free()
