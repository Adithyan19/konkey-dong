# game.gd - FIXED VERSION  
extends Node2D

# Game settings
@export var spawn_interval: float = 3.0
@export var plane_speed: float = 100.0

# Game state
enum GameState { BOTH_TOWERS, LEFT_ONLY, RIGHT_ONLY, GAME_OVER }
var current_game_state: GameState = GameState.BOTH_TOWERS

# Node references
@onready var left_tower = $tower1
@onready var right_tower = $tower2
@onready var player = $Player
@onready var spawn_timer = $SpawnTimer

# UI
var game_over_label: Label
var replay_button: Button

func _ready():
	# Setup timer
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(spawn_plane)
	spawn_timer.start()
	
	# Setup towers
	left_tower.tower_destroyed.connect(_on_tower_destroyed)
	right_tower.tower_destroyed.connect(_on_tower_destroyed)
	
	# Setup UI
	create_ui()
	
	print("✅ Game started!")

func create_ui():
	# Game Over label
	game_over_label = Label.new()
	game_over_label.text = "GAME OVER"
	game_over_label.add_theme_font_size_override("font_size", 48)
	game_over_label.modulate = Color.RED
	game_over_label.position = Vector2(-100, -50)
	game_over_label.visible = false
	add_child(game_over_label)
	
	# Replay button
	replay_button = Button.new()
	replay_button.text = "RESTART"
	replay_button.size = Vector2(100, 40)
	replay_button.position = Vector2(-50, 20)
	replay_button.visible = false
	replay_button.pressed.connect(restart_game)
	add_child(replay_button)

func spawn_plane():
	if current_game_state == GameState.GAME_OVER:
		return
		
	print("Spawning plane...")
	
	# Create plane
	var plane = RigidBody2D.new()
	plane.gravity_scale = 0
	
	# Add collision
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(30, 15)
	collision.shape = shape
	plane.add_child(collision)
	
	# Add visual
	var visual = ColorRect.new()
	visual.size = Vector2(30, 15)
	visual.color = Color.YELLOW
	visual.position = Vector2(-15, -7.5)
	plane.add_child(visual)
	
	# Add to group
	plane.add_to_group("planes")
	add_child(plane)
	
	# Setup plane properties
	var spawn_left = randf() > 0.5
	
	# Adjust based on game state
	match current_game_state:
		GameState.LEFT_ONLY:
			spawn_left = false  # Attack remaining left tower from right
		GameState.RIGHT_ONLY:
			spawn_left = true   # Attack remaining right tower from left
	
	if spawn_left:
		plane.position = Vector2(-300, randf_range(-50, 50))
		plane.linear_velocity = Vector2(plane_speed, 0)
		plane.set_meta("target", "right")
	else:
		plane.position = Vector2(300, randf_range(-50, 50))
		plane.linear_velocity = Vector2(-plane_speed, 0)
		plane.set_meta("target", "left")
		visual.rotation = PI  # Flip plane
	
	# Connect collision
	plane.body_entered.connect(_on_plane_hit_something.bind(plane))
	
	# Auto-remove after 10 seconds if still exists
	get_tree().create_timer(10.0).timeout.connect(plane.queue_free)

func _on_plane_hit_something(plane: RigidBody2D, body):
	if not is_instance_valid(plane):
		return
		
	var target = plane.get_meta("target", "")
	
	# Check if hit correct tower
	if body == left_tower and target == "left":
		print("💥 Plane hit LEFT tower!")
		left_tower.destroy_tower()
		plane.queue_free()
	elif body == right_tower and target == "right":
		print("💥 Plane hit RIGHT tower!")  
		right_tower.destroy_tower()
		plane.queue_free()

func _on_tower_destroyed(side: String):
	print("🚨 Tower destroyed: ", side)
	
	if side == "left":
		if right_tower.is_destroyed:
			game_over()
		else:
			current_game_state = GameState.RIGHT_ONLY
			player.lock_to_tower("right")
	else:  # right tower
		if left_tower.is_destroyed:
			game_over()
		else:
			current_game_state = GameState.LEFT_ONLY
			player.lock_to_tower("left")

func game_over():
	current_game_state = GameState.GAME_OVER
	spawn_timer.stop()
	game_over_label.visible = true
	replay_button.visible = true
	print("💀 GAME OVER!")

func restart_game():
	current_game_state = GameState.BOTH_TOWERS
	
	# Clear planes
	get_tree().call_group("planes", "queue_free")
	
	# Reset towers
	left_tower.reset()
	right_tower.reset()
	
	# Reset player
	player.reset()
	
	# Hide UI
	game_over_label.visible = false
	replay_button.visible = false
	
	# Restart spawning
	spawn_timer.start()
	print("🔄 Game restarted!")
