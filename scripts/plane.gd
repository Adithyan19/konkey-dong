# plane.gd
extends RigidBody2D

var velocity: Vector2 = Vector2.ZERO
var has_been_destroyed: bool = false
var target_tower: String = ""  # "left" or "right"
var has_reached_tower: bool = false

signal plane_reached_tower(tower_side: String)

@onready var anim_sprite = $AnimatedSprite2D

func _ready():
	# Set up the RigidBody2D
	gravity_scale = 0
	linear_damp = 0
	
	# Add plane to group for easy management
	add_to_group("planes")
	
	# Connect collision signal for tower detection
	body_entered.connect(_on_body_entered)
	
	# Start flying animation
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("fly"):
		anim_sprite.play("fly")

func _physics_process(delta: float) -> void:
	if not has_been_destroyed and not has_reached_tower:
		# Apply velocity
		linear_velocity = velocity*0.2
		
		# Auto-remove when far off screen
		var screen_size = get_viewport_rect().size
		if position.x < -300 or position.x > screen_size.x + 300:
			queue_free()

func _on_body_entered(body):
	if has_been_destroyed or has_reached_tower:
		return  # Already processed
	
	# Check if we hit the target tower
	var hit_correct_tower = false
	
	if body.name == "tower1" or (body.get_parent() and body.get_parent().name == "tower1"):
		if target_tower == "left":
			hit_correct_tower = true
	elif body.name == "tower2" or (body.get_parent() and body.get_parent().name == "tower2"):
		if target_tower == "right":
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
	linear_velocity = Vector2.ZERO
	
	# Play explosion animation if available
	if anim_sprite and anim_sprite.sprite_frames and anim_sprite.sprite_frames.has_animation("explosion"):
		anim_sprite.play("explosion")
		await anim_sprite.animation_finished
	else:
		# Simple explosion effect if no animation
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.RED, 0.1)
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.1)
		tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
		await tween.finished
	
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
