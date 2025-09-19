# plane.gd - Reference script (planes are created programmatically in game.gd)
extends RigidBody2D

var target_tower: String = ""
var destroyed_by_player: bool = false

func _ready():
	# Basic setup
	gravity_scale = 0
	add_to_group("planes")
	
	# Auto-remove when off screen
	var timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()

func _on_body_entered(body):
	if destroyed_by_player:
		return
		
	# Check if we hit our target tower
	if body.has_method("destroy_tower"):
		if (target_tower == "left" and body.tower_side == "left") or \
		   (target_tower == "right" and body.tower_side == "right"):
			print("Plane hit target tower!")
			body.destroy_tower()
			queue_free()

func destroy_by_player():
	if not destroyed_by_player:
		destroyed_by_player = true
		print("Plane destroyed by player!")
		queue_free()
