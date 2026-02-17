extends Node2D

@onready var leftCover: ColorRect = $LeftCover
@onready var rightCover: ColorRect = $RightCover

var in_left := true
var in_right := false

func _on_left_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		in_left = true
		in_right = false
		update_cover()

func _on_right_area_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		in_left = false
		in_right = true
		update_cover()

func _on_left_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		in_left = false
		in_right = true
		update_cover()

func _on_right_area_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		in_right = false
		in_left = true
		update_cover()

func update_cover():
	if in_left:
		var start := false
		if !start:
			fade_left(0.0, 3.0)
		else:
			fade_right(1.0, 0.5)
			fade_left(0.0, 0.5)
	elif in_right:
		fade_right(0.0, 0.5)
		fade_left(1.0, 0.5)
	else:
		fade_right(0.0, 0.5)
		fade_left(0.0, 0.5)
		
func fade_left(target_alpha: float, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(leftCover, "color:a", target_alpha, duration)
	return tween

func fade_right(target_alpha: float, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(rightCover, "color:a", target_alpha, duration)
	return tween
