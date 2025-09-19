# player.gd - FIXED VERSION
extends CharacterBody2D

# Movement
const SPEED = 200.0
const LEFT_X = -100.0
const RIGHT_X = 100.0
const TOP_Y = -80.0
const BOTTOM_Y = 80.0

# State
var current_tower = "left"
var can_switch = true
var is_attacking = false

# Attack areas (will be created automatically)
var left_attack_area: Area2D
var right_attack_area: Area2D

func _ready():
	# Start at left tower
	position = Vector2(LEFT_X, 0)
	
	# Create attack areas programmatically
	create_attack_areas()
	
	print("Player ready at left tower")

func create_attack_areas():
	# Create LEFT attack area
	left_attack_area = Area2D.new()
	left_attack_area.name = "LeftAttackArea"
	left_attack_area.monitoring = false
	
	var left_collision = CollisionShape2D.new()
	var left_shape = RectangleShape2D.new()
	left_shape.size = Vector2(60, 40)
	left_collision.shape = left_shape
	left_attack_area.add_child(left_collision)
	
	# Create RIGHT attack area
	right_attack_area = Area2D.new()
	right_attack_area.name = "RightAttackArea"  
	right_attack_area.monitoring = false
	
	var right_collision = CollisionShape2D.new()
	var right_shape = RectangleShape2D.new()
	right_shape.size = Vector2(60, 40)
	right_collision.shape = right_shape
	right_attack_area.add_child(right_collision)
	
	# Add to player
	add_child(left_attack_area)
	add_child(right_attack_area)
	
	# Connect signals
	left_attack_area.body_entered.connect(_on_left_attack_hit)
	right_attack_area.body_entered.connect(_on_right_attack_hit)
	
	print("Attack areas created successfully!")

func _physics_process(_delta):
	# Movement
	var input_dir = Vector2()
	
	if Input.is_action_pressed("ui_up") and position.y > TOP_Y:
		input_dir.y = -1
	if Input.is_action_pressed("ui_down") and position.y < BOTTOM_Y:
		input_dir.y = 1
	
	velocity = input_dir * SPEED
	move_and_slide()

func _input(event):
	# Switch towers with SPACE
	if event.is_action_pressed("ui_accept") and can_switch and not is_attacking:
		switch_tower()
	
	# Attack with LEFT CLICK
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_attacking:
				attack()

func switch_tower():
	if current_tower == "left":
		current_tower = "right"
		position.x = RIGHT_X
		print("Switched to RIGHT tower")
	else:
		current_tower = "left"
		position.x = LEFT_X
		print("Switched to LEFT tower")

func attack():
	if is_attacking:
		return
		
	is_attacking = true
	print("🥊 ATTACK! Tower: ", current_tower)
	
	# Enable correct attack area for 1 SECOND
	if current_tower == "left":
		left_attack_area.monitoring = true
		print("LEFT attack area ENABLED")
	else:
		right_attack_area.monitoring = true
		print("RIGHT attack area ENABLED")
	
	# Wait 1 second then disable
	await get_tree().create_timer(1.0).timeout
	
	# Disable all attack areas
	left_attack_area.monitoring = false
	right_attack_area.monitoring = false
	
	is_attacking = false
	print("Attack ended - areas disabled")

func _on_left_attack_hit(body):
	if body.is_in_group("planes") and current_tower == "left" and is_attacking:
		print("✨ LEFT ATTACK HIT PLANE! ✨")
		body.queue_free()

func _on_right_attack_hit(body):
	if body.is_in_group("planes") and current_tower == "right" and is_attacking:
		print("✨ RIGHT ATTACK HIT PLANE! ✨")
		body.queue_free()

func lock_to_tower(tower_name: String):
	current_tower = tower_name
	can_switch = false
	
	if tower_name == "left":
		position.x = LEFT_X
	else:
		position.x = RIGHT_X
	
	print("🚫 LOCKED to ", tower_name, " tower - cannot switch!")

func reset():
	current_tower = "left"
	can_switch = true
	is_attacking = false
	position = Vector2(LEFT_X, 0)
	
	if left_attack_area:
		left_attack_area.monitoring = false
	if right_attack_area:
		right_attack_area.monitoring = false
	
	print("Player reset")
