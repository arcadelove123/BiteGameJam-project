extends Node2D

@export var bird_scene: PackedScene = preload("res://Bird/Bird.tscn")

@export_group("Shooting Points")
@export var start_node: Marker2D
@export var target_node: Marker2D
@export var fallback_target_offset: Vector2 = Vector2(500, 0)

@export var cooldown: float = 2.0
var can_shoot: bool = true

func _ready():
	if has_node("DetectionArea"):
		$DetectionArea.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and can_shoot:
		shoot()
		start_cooldown()

func start_cooldown():
	can_shoot = false
	get_tree().create_timer(cooldown).timeout.connect(func(): can_shoot = true)

func shoot():
	var from = global_position
	if start_node:
		from = start_node.global_position
		
	var to = from + fallback_target_offset
	if target_node:
		to = target_node.global_position
		
	_perform_shoot(from, to)

func _perform_shoot(from: Vector2, to: Vector2):
	if not bird_scene:
		push_error("Bird scene not assigned to BirdSpawner!")
		return
		
	var bird = bird_scene.instantiate()
	get_tree().current_scene.add_child(bird)
	bird.setup(from, to)
