extends Area2D

@export var speed: float = 300.0
@export var warning_duration: float = 1.0
@export var lifetime: float = 5.0

var target_position: Vector2
var is_active: bool = false
var move_direction: Vector2 = Vector2.ZERO

@onready var warning_sprite = $WarningSprite
@onready var bird_sprite = $BirdSprite
@onready var collision_shape = $CollisionShape2D

func _ready():
	bird_sprite.hide()
	warning_sprite.hide()
	collision_shape.set_deferred("disabled", true)
	
	body_entered.connect(_on_body_entered)

func setup(start_pos: Vector2, target_pos: Vector2):
	$BirdSprite.play("Fly")
	global_position = start_pos
	target_position = target_pos
	
	var diff = target_pos - start_pos
	if diff.length() > 0:
		move_direction = diff.normalized()
	else:
		move_direction = Vector2.RIGHT
		
	look_at(target_pos)
	
	if abs(rotation) > PI / 2:
		bird_sprite.flip_v = true
	else:
		bird_sprite.flip_v = false
	
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
	bird_sprite.show()
	bird_sprite.play("Fly")
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
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.get("hpSystem"):
			body.hpSystem.health = 0
			body.hpSystem.update_heart_display()
		pop()
	elif body is TileMap:
		pop()
