extends GPUParticles2D


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		$Timer.start()


func _on_timer_timeout() -> void:
	$Timer.stop()
	print("You Died")

@onready var warning: TextureRect= $TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	warning.modulate.a = 0.0
	for i in range(3):
		await fade(1.0, 0.5).finished
		await fade(0.0, 0.5).finished
	amount = 1000

func fade(target_alpha: float, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(warning, "modulate:a", target_alpha, duration)
	return tween
