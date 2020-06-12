extends KinematicBody2D

class_name Player

const IDLE_TEXTURE = preload("res://art/player_idle.png")
const RUN_TEXTURE = preload("res://art/player_run.png")
const WALL_SLIDE_TEXTURE = preload("res://art/player_wall_left.png")

var speed = 250
var jump_power = 2000
var dash_power = 10000
var charge_power = 10000
var stopping_friction = 0.6
var running_friction = 0.9
var air_friction = 0.93
var gravity = 120

var vel = Vector2()

# Facing right or left, 1 or -1
var direction = 1

var jumps_left = 2
var dash_direction = Vector2(1,0)
var can_dash = false
var dashing = false

var hook_pos = Vector2()
var hooked = false
var rope_length = 500
var current_rope_length

var time_scale = 1.0
var slowing = false
var speeding = false


func _ready():
	# Input.set_mouse_mode(Input.MOUSE_MODE_CONFINED)
	Input.set_custom_mouse_cursor(
		load("res://art/cursor.png"),
		Input.CURSOR_ARROW, Vector2(16,16)
	)

	current_rope_length = rope_length
	#hook_pos = $"../HookPoint".global_position

func _draw():
	var pos = global_position
	#$HookPoint.hide()	
	if hooked:
		draw_line(Vector2(0,-16), to_local(hook_pos), Color(0.203922, 0.458824, 0.972549), 3, true)
	else:
		return
		# Draw rope preview
		var colliding = $RopeRaycast.is_colliding()
		var col_point = $RopeRaycast.get_collision_point()
		if colliding and pos.distance_to(col_point) < rope_length:
			draw_line(Vector2(0,-16), to_local(col_point), Color(0.109804, 0.435294, 0.933333, 0.25), 0.5, true)
			#$HookPoint.show()
			
func _input(event):
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
		#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Input.is_action_just_pressed("right_click"):
		slowing = true
		Engine.set_time_scale(0.2)
	if Input.is_action_just_released("right_click"):
		speeding = true
		slowing = false
		Engine.set_time_scale(1)

func bullet_time():
	if slowing:
		time_scale = lerp(time_scale,0.2,0.05)
		if time_scale <= 0.22:
			slowing = false
			#yield(get_tree().create_timer(0.2), "timeout")
			
			#speeding = true
	if speeding:
		time_scale = lerp(time_scale,1,0.05)
		if time_scale == 1:
			slowing = false
	
	Engine.set_time_scale(time_scale)
	
func _physics_process(delta):
	#bullet_time()
	hook()
	update() # update drawn rope
	if hooked:
		#run(delta)
		gravity()
		swing(delta)
		vel *= 0.998
		vel = move_and_slide(vel, Vector2.UP)
		return
	

	run(delta)
	jump()
	dash()
	gravity()
	
	time_control()
	charge(delta)
	if charging:
		bounce(delta)
		vel *= 0.99
		return

	friction()
	handle_textures()
	vel = move_and_slide(vel, Vector2.UP)

var player_positions = []
var player_velocities = []
var player_directions = []

func time_control():
	if Input.is_action_pressed("rewind"):
		if player_positions.back(): # if theres some time stored left
			global_position = player_positions.pop_back()
			vel = player_velocities.pop_back()
			direction = player_directions.pop_back()
	else:
		player_positions.append(global_position)
		player_velocities.append(vel)
		player_directions.append(direction)
		if player_positions.size() > 500:
			player_positions.pop_front()
		if player_velocities.size() > 500:
			player_velocities.pop_front()
		if player_directions.size() > 500:
			player_directions.pop_front()
var gaining_charge = false
var charging = false
var can_charge = false
var charge_strength = 0.0

func charge(delta):
	if not charging and is_on_floor():
		can_charge = true

	if Input.is_action_pressed("charge") and can_charge:
		charge_strength += 10000 * delta
		charge_strength = clamp(charge_strength, 0, 2000)
	

	if Input.is_action_just_released("charge") and not charging and can_charge:
		print("charge")
		can_charge = false
		charging = true
		vel = Vector2(charge_strength*direction,-charge_strength)
		yield(get_tree().create_timer(charge_strength/200), "timeout")
		charging = false
		vel = Vector2()
		charge_strength = 0
	if charging and Input.is_action_just_pressed("charge"):
		charging = false
		vel = Vector2()
		
func bounce(delta):
	var collision = move_and_collide(vel * delta)
	if collision:
		vel = vel.bounce(collision.normal) * 0.99
	
	
func swing(delta):
	var radius = global_position - hook_pos # points away from center
	if vel.length() < 0.01 or radius.length() < 10: return
	var angle = acos(radius.dot(vel) / (radius.length() * vel.length()))
	var rad_vel = cos(angle) * vel.length()
	vel += radius.normalized() * -rad_vel
	# Hacky way to fix gradual lengthening
	if global_position.distance_to(hook_pos) > current_rope_length:
		global_position = hook_pos + radius.normalized() * current_rope_length
	
	#if Input.is_action_pressed("right_click"):
	#	current_rope_length = global_position.distance_to(hook_pos) # gradual lengthening related
	vel += (hook_pos - global_position).normalized() * 15000 * delta
	
func get_hook_pos():
	# Loop through all raycasts starting from center
	# Return the first one that collides
	for raycast in $RopeRaycasts.get_children():
		if raycast.is_colliding():
			return raycast.get_collision_point()
			
func hook():
	$RopeRaycasts.look_at(get_global_mouse_position())
	# $HookPoint.global_position = $RopeRaycast.get_collision_point()
	if Input.is_action_just_pressed("left_click"):
		hook_pos = get_hook_pos()
		if hook_pos:
			hooked = true
			current_rope_length = global_position.distance_to(hook_pos)

	if Input.is_action_just_released("left_click") and hooked:
		hooked = false
		jumps_left = 1
		can_dash = true
		

		
func run(delta):
	if dashing: return
	if Input.is_action_pressed("right"):
		vel.x += speed
		$RopeRaycasts.rotation_degrees = -45
		direction = 1
	if Input.is_action_pressed("left"):
		vel.x -= speed
		$RopeRaycasts.rotation_degrees = -135
		direction = -1

func jump():
	# I can jump when I'm on floor or next to the wall
	if is_on_floor() or next_to_wall():
		jumps_left = 2 # Recharge double-jump. 
	
	if Input.is_action_just_pressed("jump") and jumps_left > 0:
		if vel.y > 0: vel.y = 0 # if I'm falling - ignore fall velocity
		vel.y -= jump_power
		jumps_left -= 1
		# Jump away from the wall
		if not is_on_floor() and next_to_left_wall():
			vel.x += jump_power
		if not is_on_floor() and next_to_right_wall():
			vel.x -= jump_power
	
	# If I'm still going up and have released the jump button - cut off the jump and start falling down
	if Input.is_action_just_released("jump") and vel.y < 0:
		vel.y = 0


func friction():
	# When I hold the key
	var running = Input.is_action_pressed("left") or Input.is_action_pressed("right")
	#if not is_on_floor():
	#	return
	if is_on_floor():
		if running:
			vel.x *= running_friction
		else:
			vel.x *= stopping_friction
	else:
		vel.x *= air_friction

func gravity():
	if not dashing: # or dash_direction.y < 0
		vel.y += gravity
	if vel.y > 2000: 
		vel.y = 2000 # clamp falling speed
		
	var right_sliding = next_to_right_wall() and Input.is_action_pressed("right")
	var left_sliding = next_to_left_wall() and Input.is_action_pressed("left")
	var wall_sliding = right_sliding or left_sliding
	if wall_sliding and vel.y > 100: 
		vel.y = 100 # wall slide


func dash():
	if is_on_floor():
		can_dash = true # recharges when player touches the floor
		
	#dash_direction.x = 0
	if Input.is_action_pressed("right"):
		dash_direction.x = 1
	if Input.is_action_pressed("left"):
		dash_direction.x = -1
	#dash_direction.y = 0
	#if Input.is_action_pressed("jump"):
	#	dash_direction.y = -1
	#dash_direction = global_position.direction_to(get_global_mouse_position())
	if Input.is_action_just_pressed("dash") and can_dash:
		vel = dash_direction.normalized() * dash_power
		can_dash = false
		dashing = true # turn off gravity while dashing
		yield(get_tree().create_timer(0.125), "timeout")
		vel = Vector2()
		yield(get_tree().create_timer(0.1), "timeout")#hang in the air
		dashing = false


func next_to_wall():
	return next_to_left_wall() or next_to_right_wall()
	
func next_to_left_wall():
	return $LeftWallRaycast1.is_colliding() or $LeftWallRaycast2.is_colliding()

func next_to_right_wall():
	return $RightWallRaycast1.is_colliding() or $RightWallRaycast2.is_colliding()


func take_damage():
	get_tree().change_scene("res://Levels/Level03.tscn")
	Engine.set_time_scale(1)

func handle_textures():
	if direction == 1:
		$Sprite.flip_h = false
	else:
		$Sprite.flip_h = true
	$Sprite.texture = IDLE_TEXTURE
	if not is_on_floor() and next_to_left_wall():
		$Sprite.texture = WALL_SLIDE_TEXTURE
		$Sprite.flip_h = false
	if not is_on_floor() and next_to_right_wall():
		$Sprite.texture = WALL_SLIDE_TEXTURE
		$Sprite.flip_h = true
	var running = Input.is_action_pressed("left") or Input.is_action_pressed("right")
	if running and is_on_floor():
		$Sprite.texture = RUN_TEXTURE
