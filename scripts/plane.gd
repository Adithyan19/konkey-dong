extends Area2D

var velocity: Vector2 = Vector2.ZERO
var has_been_destroyed: bool = false
var target_tower: String = ""  # "left" or "right"
var has_reached_tower: bool = false

signal plane_reached_tower(tower_side: String)

@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	# Set up Area2D
	# Remove gravity and damping since Area2D is not physics-based
	# Add plane to group for easy management
	add_to_group("planes")
	
	# Connect collision signal for tower detection
	body_entered.connect(_on_area_entered)
	
	# Start flying animation
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("fly"):
		anim_sprite.play("fly")

func _process(delta: float) -> void:
	if not has_been_destroyed and not has_reached_tower:
		# Apply velocity manually
		position += velocity*0.5 * delta
		
		# Auto-remove when far off screen
		var screen_size = get_viewport_rect().size
		if position.x < -300 or position.x > screen_size.x + 300:
			queue_free()

func _on_area_entered(area):
	if has_been_destroyed or has_reached_tower:
		return  # Already processed
	
	# Check if we hit the target tower
	var hit_correct_tower = false
	
	if area.name == "tower1" or (area.get_parent() and area.get_parent().name == "tower1"):
		if target_tower == "right":
			hit_correct_tower = true
	elif area.name == "tower2" or (area.get_parent() and area.get_parent().name == "tower2"):
		if target_tower == "left":
			hit_correct_tower = true
	
	if hit_correct_tower:
		has_reached_tower = true
		print("💥 PLANE HIT TOWER: ", target_tower, " - TOWER DESTROYED!")
		plane_reached_tower.emit(target_tower)
		destroy_plane_with_explosion()

func destroy_plane_with_explosion():
	"""Destroy plane with explosion effect when it hits tower"""
	# Stop the plane
	velocity = Vector2.ZERO
	
	# Play explosion animation if available
	anim_sprite.play("explosion")
	await anim_sprite.animation_finished
	
	# Remove the plane
	queue_free()

# Called by Kong when plane is destroyed by Kong's attack
func destroy_by_player():
	"""INSTANT DESTRUCTION when hit by Kong's collision during attack"""
	if has_been_destroyed or has_reached_tower:
		return false  # Already processed
	
	has_been_destroyed = true
	print("✨ PLANE INSTANTLY DESTROYED BY KONG! ✨")
	
	# INSTANT DESTRUCTION - NO ANIMATIONS, JUST DISAPPEAR IMMEDIATELY
	queue_free()
	return true

func get_target_tower():
	return target_tower

func is_destroyed():
	return has_been_destroyed or has_reached_tower
