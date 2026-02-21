extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var wasted: TextureRect = $TextureRect2
@onready var button = $RetryButton
@onready var option = $Panel
@onready var slider = $Panel/VBoxContainer/HSlider
@onready var mute = $Panel/VBoxContainer/HBoxContainer/HBoxContainer/CheckButton
@onready var fullScreen = $Panel/VBoxContainer/HBoxContainer/HBoxContainer2/CheckButton2

var bus_index = AudioServer.get_bus_index("Master")

func _ready() -> void:
	color_rect.color.a = 0.0
	wasted.modulate.a = 0.0
	var is_muted = AudioServer.is_bus_mute(bus_index)
	var mode = DisplayServer.window_get_mode()
	fullScreen.button_pressed = (mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
	mute.button_pressed = not is_muted

func fade(target_alpha: float, duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", target_alpha, duration)
	return tween

func label_fade(target_alpha: float, duration: float = 1.0):
	var tween = wasted.create_tween()
	tween.tween_property(wasted, "modulate:a", target_alpha, duration)
	return tween

func _on_button_pressed() -> void:
	die()


func _set_player_game_over_stun(enabled: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_stun"):
		player.set_stun(&"game_over", enabled)


func die():
	_set_player_game_over_stun(true)
	await fade(0.5, 2.0)
	await label_fade(1, 4.0).finished
	get_tree().reload_current_scene()

func _on_button_4_pressed() -> void:
	option.visible = false
	slider.scrollable = false
	mute.disabled = true
	fullScreen.disabled = true
	get_tree().paused = false

func _on_check_button_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(bus_index, not AudioServer.is_bus_mute(bus_index))

func _on_check_button_2_toggled(toggled_on: bool) -> void:
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_button_2_pressed() -> void:
	option.visible = true
	slider.scrollable = true
	mute.disabled = false
	fullScreen.disabled = false
	get_tree().paused = true
