extends GPUParticles2D

@export_group("Warning Blink")
@export var warning_blink_count: int = 3
@export var warning_min_alpha: float = 0.15
@export var warning_start_peak_alpha: float = 0.6
@export var warning_peak_step_alpha: float = 0.4
@export var warning_up_duration: float = 0.5
@export var warning_down_duration: float = 0.5
@export var warning_end_fade_duration: float = 1

@onready var player = null
@onready var warning: TextureRect = $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	warning.modulate.a = 0.0
	self.visibility_rect = Rect2(Vector2(-2000, -2000), Vector2(4000, 12000))
	self.process_material.color.a = 0.0

func fade(target_alpha: float, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(warning, "modulate:a", target_alpha, duration)
	return tween

func _on_area_2d_body_exited(body: Node2D) -> void:
	$Timer2.stop()
	$Timer3.stop()
	self.process_material.color.a = 0.0
	warning.modulate.a = 0.0
	player = null
	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player = body
		$Timer2.start()

func _on_timer_2_timeout() -> void:
	if player == null:
		return

	var blink_count = max(warning_blink_count, 0)
	var min_alpha = clamp(warning_min_alpha, 0.0, 1.0)
	var start_peak_alpha = clamp(warning_start_peak_alpha, 0.0, 1.0)
	var peak_step_alpha = max(warning_peak_step_alpha, 0.0)
	var up_duration = max(warning_up_duration, 0.01)
	var down_duration = max(warning_down_duration, 0.01)

	for i in range(blink_count):
		var peak_alpha = clamp(start_peak_alpha + (i * peak_step_alpha), 0.0, 1.0)
		await fade(peak_alpha, up_duration).finished
		await fade(min_alpha, down_duration).finished
		
	if player == null:
		return
		
	await fade(0.0, max(warning_end_fade_duration, 0.01)).finished
		
	if player == null:
		return
		
	self.process_material.color.a = 1.0
	$Timer3.start()
	player.hpSystem.take_damage()

func _on_timer_3_timeout() -> void:
	if player == null:
		$Timer3.stop()
		return
	
	$Timer3.start()
	player.hpSystem.take_damage()
