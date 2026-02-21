extends Path2D

@export var speed: float = 600.0
@export var retreat_speed: float = 400.0
@export var warning_duration: float = 1.0
@export var lifetime: float = 5.0

enum BirdState {
	IDLE,
	WARNING,
	FLYING,
	RETREATING
}

var state: BirdState = BirdState.IDLE
var last_global_x: float = 0.0

@onready var path_follow: PathFollow2D = $PathFollow2D
@onready var human_area: Area2D = $PathFollow2D/HumanArea
@onready var warning_sprite: Sprite2D = $PathFollow2D/HumanArea/WarningSprite
@onready var human_sprite: AnimatedSprite2D = $PathFollow2D/HumanArea/HumanSprite
@onready var collision_shape: CollisionShape2D = $PathFollow2D/HumanArea/CollisionShape2D

func _ready() -> void:
	human_sprite.hide()
	warning_sprite.hide()
	collision_shape.set_deferred("disabled", true)

	human_area.body_entered.connect(_on_body_entered)

	path_follow.progress = 0.0
	path_follow.rotates = false
	last_global_x = path_follow.global_position.x

func setup_with_curve(path_curve: Curve2D) -> void:
	if path_curve == null or path_curve.point_count < 2:
		push_error("Human: Invalid path curve.")
		queue_free()
		return

	curve = path_curve.duplicate(true)

	if not is_inside_tree():
		await ready

	path_follow.progress_ratio = 1.0
	var warning_point := path_follow.global_position
	path_follow.progress = 0.0
	last_global_x = path_follow.global_position.x
	await start_warning(warning_point)

func start_warning(warning_pos: Vector2) -> void:
	state = BirdState.WARNING
	warning_sprite.top_level = true
	warning_sprite.z_as_relative = false
	warning_sprite.z_index = 100
	warning_sprite.global_position = warning_pos
	warning_sprite.show()

	var tween := create_tween().set_loops()
	tween.tween_property(warning_sprite, "modulate:a", 0.1, 0.2)
	tween.tween_property(warning_sprite, "modulate:a", 1.0, 0.2)

	await get_tree().create_timer(warning_duration).timeout

	if not is_inside_tree():
		return

	tween.kill()
	warning_sprite.hide()
	warning_sprite.top_level = false
	human_sprite.show()
	_play_move_animation()
	collision_shape.set_deferred("disabled", false)
	state = BirdState.FLYING

	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)

func _physics_process(delta: float) -> void:
	if state == BirdState.RETREATING:
		path_follow.progress = max(0.0, path_follow.progress - retreat_speed * delta)
		_update_sprite_facing()
		if path_follow.progress <= 0.0:
			queue_free()
		return

	if state == BirdState.FLYING and curve:
		path_follow.progress += speed * delta
		_update_sprite_facing()
		if path_follow.progress_ratio >= 1.0:
			pop()

func start_retreat() -> void:
	if state != BirdState.FLYING:
		return

	state = BirdState.RETREATING
	collision_shape.set_deferred("disabled", true)
	path_follow.rotates = false
	_play_move_animation()

func pop() -> void:
	if state != BirdState.FLYING:
		return
	state = BirdState.IDLE
	queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.is_damage_ignored():
			if body.has_method("on_damage_ignored"):
				body.on_damage_ignored(0)
			start_retreat()
		else:
			if body.get("hpSystem"):
				body.hpSystem.take_damage(body.hpSystem.health)
			pop()
	elif body is TileMap:
		pop()

func _on_lifetime_timeout() -> void:
	if not is_inside_tree():
		return
	if state == BirdState.FLYING:
		pop()

func _update_sprite_facing() -> void:
	var current_x := path_follow.global_position.x
	var delta_x := current_x - last_global_x

	if abs(delta_x) > 0.001:
		human_sprite.flip_h = delta_x < 0.0

	last_global_x = current_x

func _play_move_animation() -> void:
	human_sprite.play("Run")
