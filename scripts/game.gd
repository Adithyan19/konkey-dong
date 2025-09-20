extends Node2D

# Game settings
@export var plane_scene: PackedScene  # DRAG YOUR PLANE.TSCN HERE
@export var spawn_interval: float = 3.0
@export var plane_speed: float = 120.0

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
	
	print("✅ Game started using YOUR plane asset!")

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
	
	if plane_scene == null:
		print("ERROR: Please drag your plane.tscn into the Plane Scene field in the inspector!")
		return
		
	print("Spawning YOUR plane...")
	
	# Create YOUR plane instance
	var plane_instance = plane_scene.instantiate()
	add_child(plane_instance)
	
	# Setup plane properties
	var spawn_left = randf() > 0.5
	
	# Adjust based on game state
	match current_game_state:
		GameState.LEFT_ONLY:
			spawn_left = false  # Attack remaining left tower from right
		GameState.RIGHT_ONLY:
			spawn_left = true   # Attack remaining right tower from left
	
	# Set position and velocity
	if spawn_left:
		plane_instance.position = Vector2(-250, randf_range(-50, 50))
		plane_instance.velocity = Vector2(plane_speed, 0)
		plane_instance.scale.x = 1
		plane_instance.target_tower = "right"
	else:
		plane_instance.position = Vector2(250, randf_range(-50, 50))
		plane_instance.velocity = Vector2(-plane_speed, 0)
		plane_instance.scale.x = -1  # Flip plane to face left
		plane_instance.target_tower = "left"
	
	# Connect YOUR plane's signals
	if plane_instance.has_signal("plane_reached_tower"):
		plane_instance.plane_reached_tower.connect(_on_plane_reached_tower)

func _on_plane_reached_tower(tower_side: String):
	print("💥 Plane reached ", tower_side, " tower!")
	if tower_side == "left" and left_tower and not left_tower.is_destroyed:
		left_tower.destroy_tower()
	elif tower_side == "right" and right_tower and not right_tower.is_destroyed:
		right_tower.destroy_tower()

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
