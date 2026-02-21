extends Path2D

@export var speed: float = 600.0
@export var retreat_speed: float = 400.0
@export var warning_duration: float = 1.0
@export var lifetime: float = 5.0

var is_active: bool = false
var is_retreating: bool = false
var start_global_pos: Vector2
var retreat_direction: Vector2 = Vector2.ZERO

@onready var path_follow: PathFollow2D = $PathFollow2D
@onready var bird_area: Area2D = $PathFollow2D/BirdArea
@onready var warning_sprite: Sprite2D = $PathFollow2D/BirdArea/WarningSprite
@onready var bird_sprite: AnimatedSprite2D = $PathFollow2D/BirdArea/BirdSprite
@onready var collision_shape: CollisionShape2D = $PathFollow2D/BirdArea/CollisionShape2D

func _ready():
	bird_sprite.hide()
	warning_sprite.hide()
	collision_shape.set_deferred("disabled", true)
	
	bird_area.body_entered.connect(_on_body_entered)
	
	path_follow.progress = 0.0
	path_follow.rotates = true

func setup_with_curve(path_curve: Curve2D):
	curve = path_curve
	
	if not is_inside_tree():
		await ready
	
	var end_point = curve.get_baked_points()[-1]
	start_warning(to_global(end_point))

func start_warning(warning_pos: Vector2):
	warning_sprite.top_level = true
	warning_sprite.global_position = warning_pos
	warning_sprite.show()
	
	var tween = create_tween().set_loops()
	tween.tween_property(warning_sprite, "modulate:a", 0.1, 0.2)
	tween.tween_property(warning_sprite, "modulate:a", 1.0, 0.2)
	
	await get_tree().create_timer(warning_duration).timeout
	
	if not is_inside_tree(): return
		
	tween.kill()
	warning_sprite.hide()
	bird_sprite.show()
	bird_sprite.play("Fly")
	collision_shape.set_deferred("disabled", false)
	start_global_pos = path_follow.global_position
	is_active = true
	
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta):
	if is_retreating:
		var bird_global = bird_area.global_position
		var dist = bird_global.distance_to(start_global_pos)
		var step = retreat_speed * delta
		
		if dist <= step:
			queue_free()
		else:
			var dir = (start_global_pos - bird_global).normalized()
			# Detach from path: move Area2D directly
			path_follow.global_position += dir * step
			
			# Rotate bird toward start
			bird_area.look_at(start_global_pos)
			if abs(bird_area.rotation) > PI / 2:
				bird_sprite.flip_v = true
			else:
				bird_sprite.flip_v = false
		return
	
	if is_active and curve:
		path_follow.progress += speed * delta
		
		if abs(path_follow.rotation) > PI / 2:
			bird_sprite.flip_v = true
		else:
			bird_sprite.flip_v = false
		
		if path_follow.progress_ratio >= 1.0:
			pop()

func start_retreat():
	is_active = false
	is_retreating = true
	collision_shape.set_deferred("disabled", true)
	path_follow.rotates = false

func pop():
	if not is_active: return
	is_active = false
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.is_damage_ignored():
			# Player is dashing — bird gets knocked back
			if body.has_method("on_damage_ignored"):
				body.on_damage_ignored(0)
			start_retreat()
		else:
			if body.get("hpSystem"):
				body.hpSystem.take_damage(body.hpSystem.health)
			pop()
	elif body is TileMap:
		pop()
