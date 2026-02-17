extends CanvasLayer

@onready var color_rect: ColorRect= $ColorRect
@onready var wasted: TextureRect = $TextureRect2
@onready var button = $RetryButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	color_rect.color.a = 0.0
	wasted.modulate.a = 0.0

func fade(target_alpha: float, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", target_alpha, duration)
	return tween

func label_fade(target_alpha: float, duration: float = 1.0):
	var tween = wasted.create_tween()
	tween.tween_property(wasted, "modulate:a", target_alpha, duration)
	return tween


func _on_button_pressed() -> void:
	await fade(0.5, 2.0)
	await label_fade(1, 4.0).finished
	
	get_tree().reload_current_scene()
