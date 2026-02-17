extends Area2D

@export var speed: float = 800.0
@export var warning_duration: float = 1.0
@export var lifetime: float = 5.0
@export var ground_web_scene: PackedScene = preload("res://Web/web_on_ground.tscn")

var target_position: Vector2
var is_active: bool = false
var move_direction: Vector2 = Vector2.ZERO

@onready var warning_sprite = $WarningSprite
@onready var web_sprite = $WebSprite
@onready var collision_shape = $CollisionShape2D

func _ready():
	web_sprite.hide()
	warning_sprite.hide()
	collision_shape.set_deferred("disabled", true)

func setup(start_pos: Vector2, target_pos: Vector2):
	global_position = start_pos
	target_position = target_pos
	
	var diff = target_pos - start_pos
	if diff.length() > 0:
		move_direction = diff.normalized()
	else:
		move_direction = Vector2.RIGHT
		
	look_at(target_pos)
	
	if not is_inside_tree():
		await ready
	
	start_warning()

func start_warning():
	warning_sprite.top_level = true
	warning_sprite.global_position = target_position
	warning_sprite.show()
	
	var tween = create_tween().set_loops()
	tween.tween_property(warning_sprite, "modulate:a", 0.1, 0.2)
	tween.tween_property(warning_sprite, "modulate:a", 1.0, 0.2)
	
	await get_tree().create_timer(warning_duration).timeout
	
	if not is_inside_tree(): return
		
	tween.kill()
	warning_sprite.hide()
	web_sprite.show()
	collision_shape.set_deferred("disabled", false)
	is_active = true
	

	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta):
	if is_active:
		var distance_to_target = global_position.distance_to(target_position)
		var move_step = speed * delta
		
		if distance_to_target <= move_step:
			global_position = target_position
			pop()
		else:
			global_position += move_direction * move_step

func pop():
	if not is_active: return
	is_active = false
	
	if ground_web_scene:
		var ground_web = ground_web_scene.instantiate()
		get_tree().current_scene.add_child(ground_web)
		ground_web.global_position = global_position
	
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(10)
		pop()
	elif body is TileMap:
		pop()
