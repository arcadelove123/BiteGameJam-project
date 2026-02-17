extends Node2D

@export var web_scene: PackedScene = preload("res://Web/Web.tscn")

@export_group("Shooting Points")
@export var start_node: Marker2D
@export var target_node: Marker2D
@export var fallback_target_offset: Vector2 = Vector2(500, 0)

func shoot():
	var from = global_position
	if start_node:
		from = start_node.global_position
		
	var to = from + fallback_target_offset
	if target_node:
		to = target_node.global_position
		
	_perform_shoot(from, to)

func shoot_at(global_target: Vector2):
	var from = global_position
	if start_node:
		from = start_node.global_position
	
	_perform_shoot(from, global_target)

func _perform_shoot(from: Vector2, to: Vector2):
	if not web_scene:
		push_error("Web scene not assigned to WebSpawner!")
		return
		
	var web = web_scene.instantiate()
	get_tree().current_scene.add_child(web)
	web.setup(from, to)

func _input(event):
	if OS.is_debug_build() and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			shoot_at(get_global_mouse_position())
