extends Area2D

signal pickup_key

const DISABLED_TEXTURE = preload("res://art/toggle_disabled.png")

func _ready():
	connect("body_entered",$"../Door","open")

func _on_Key_body_entered(body):
	if body is Player:
		$Sprite.texture = DISABLED_TEXTURE
