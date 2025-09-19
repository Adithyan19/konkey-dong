# tower.gd - FINAL PERFECT VERSION
extends StaticBody2D

@export var tower_side: String = "left"  # Set this in inspector
var is_destroyed: bool = false

signal tower_destroyed(side: String)

@onready var sprite = $Sprite2D

func _ready():
	print("🏗️ Tower ", tower_side, " ready at ORIGINAL position")

func destroy_tower():
	if is_destroyed:
		return
		
	is_destroyed = true
	print("💥 TOWER ", tower_side.to_upper(), " DESTROYED!")
	
	# Visual effect
	if sprite:
		sprite.modulate = Color.RED
		sprite.scale = Vector2(0.8, 0.8)
		
		# Shake effect
		var tween = create_tween()
		tween.set_loops(5)
		tween.tween_property(sprite, "position", Vector2(5, 0), 0.05)
		tween.tween_property(sprite, "position", Vector2(-5, 0), 0.05)
		tween.tween_property(sprite, "position", Vector2(0, 0), 0.05)
	else:
		# If using ColorRect instead of Sprite2D
		var color_rect = get_node_or_null("ColorRect")
		if color_rect:
			color_rect.modulate = Color.RED
			color_rect.scale = Vector2(0.8, 0.8)
	
	# Emit signal
	tower_destroyed.emit(tower_side)

func reset():
	is_destroyed = false
	
	if sprite:
		sprite.modulate = Color.WHITE
		sprite.scale = Vector2(1.0, 1.0)
		sprite.position = Vector2(0, 0)
	else:
		# If using ColorRect
		var color_rect = get_node_or_null("ColorRect")
		if color_rect:
			color_rect.modulate = Color.WHITE
			color_rect.scale = Vector2(1.0, 1.0)
	
	print("🔄 Tower ", tower_side, " reset")

func get_destroyed() -> bool:
	return is_destroyed
