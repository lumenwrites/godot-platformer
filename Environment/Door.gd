extends Area2D

const OPEN_TEXTURE = preload("res://art/door_open.png")

var is_open = false

func open(body):
	print("open")
	is_open = true
	$Sprite.texture = OPEN_TEXTURE

func _on_Door_body_entered(body):
	if body is Player and is_open:
		print("Victory!")
