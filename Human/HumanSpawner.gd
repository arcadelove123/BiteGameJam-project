extends Node2D

@export var human_scene: PackedScene = preload("res://Human/Human.tscn")

@export var flight_path: Path2D

@export var cooldown: float = 2.0
var can_shoot: bool = true

func _ready():
	if has_node("DetectionArea"):
		$DetectionArea.body_entered.connect(_on_body_entered)

	if not flight_path:
		for child in get_children():
			if child is Path2D:
				flight_path = child
				break

func _on_body_entered(body):
	if body.is_in_group("player") and can_shoot:
		shoot()
		start_cooldown()

func start_cooldown():
	can_shoot = false
	get_tree().create_timer(cooldown).timeout.connect(func(): can_shoot = true)

func shoot():
	if not flight_path or not flight_path.curve or flight_path.curve.point_count < 2:
		push_error("HumanSpawner: No valid flight path! Add a Path2D child with at least 2 curve points.")
		return
	_perform_shoot(flight_path.curve)

func _perform_shoot(path_curve: Curve2D) -> void:
	if not human_scene:
		push_error("Human scene not assigned to HumanSpawner!")
		return

	var human = human_scene.instantiate()
	get_tree().current_scene.add_child(human)
	human.global_position = flight_path.global_position if flight_path else global_position
	human.global_rotation = flight_path.global_rotation if flight_path else global_rotation
	human.setup_with_curve(path_curve)
