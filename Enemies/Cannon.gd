extends Node2D

const MISSILE = preload("res://Enemies/FireMissile.tscn")
var reload_rate = 2.0
var can_fire = true

func spawn(node, position):
	var instance = node.instance()
	var scene_root = get_tree().root.get_children()[0]
	instance.global_position = position
	instance.parent = $Weapon
	scene_root.add_child(instance)
	
func _physics_process(delta):
	$Weapon.look_at($"../Player".global_position)
	if $Weapon/RayCast2D.is_colliding():
		if $Weapon/RayCast2D.get_collider() is Player:
			fire()
	
func fire():
	if can_fire:
		spawn(MISSILE, $Weapon/Position2D.global_position)
		can_fire = false
		yield(get_tree().create_timer(reload_rate), "timeout")
		can_fire = true
