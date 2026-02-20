@tool
extends Area2D
class_name CameraLimiter2D

@export var limit_priority: int = 0
@export var player_group: StringName = &"player"
@export var include_root_area: bool = true
@export var auto_collect_child_areas: bool = true
@export var extra_areas: Array[Area2D] = []
@export var default_size: Vector2 = Vector2(640.0, 360.0):
	set(value):
		default_size = value.max(Vector2.ONE)
		_sync_shape_size()

var limiter_areas: Array[Area2D] = []
var _tracked_bodies_by_area: Dictionary = {}

func _ready() -> void:
	if include_root_area:
		_ensure_collision_shape(self)
	_sync_shape_size()
	set_notify_transform(true)
	refresh_limiter_areas()
	set_physics_process(true)

func _exit_tree() -> void:
	for area in _tracked_bodies_by_area.keys():
		var tracked_bodies: Dictionary = _tracked_bodies_by_area[area]
		for body in tracked_bodies.keys():
			if is_instance_valid(body) and body.has_method("pop_camera_limits"):
				body.pop_camera_limits(area)
	_tracked_bodies_by_area.clear()

func _notification(what: int) -> void:
	if what == NOTIFICATION_CHILD_ORDER_CHANGED:
		refresh_limiter_areas()
	if what == NOTIFICATION_TRANSFORM_CHANGED and _has_tracked_bodies():
		_push_to_tracked_bodies()

func _physics_process(_delta: float) -> void:
	if _has_tracked_bodies():
		_push_to_tracked_bodies()

func _on_area_body_entered(body: Node2D, area: Area2D) -> void:
	if not body.is_in_group(player_group):
		return
	if not body.has_method("push_camera_limits"):
		return

	var tracked_bodies: Dictionary = _tracked_bodies_by_area.get(area, {})
	tracked_bodies[body] = true
	_tracked_bodies_by_area[area] = tracked_bodies
	body.push_camera_limits(area, _get_world_limit_rect(area), limit_priority)

func _on_area_body_exited(body: Node2D, area: Area2D) -> void:
	if not _tracked_bodies_by_area.has(area):
		return

	var tracked_bodies: Dictionary = _tracked_bodies_by_area[area]
	if not tracked_bodies.has(body):
		return

	tracked_bodies.erase(body)
	if tracked_bodies.is_empty():
		_tracked_bodies_by_area.erase(area)
	else:
		_tracked_bodies_by_area[area] = tracked_bodies

	if body.has_method("pop_camera_limits"):
		body.pop_camera_limits(area)

func _push_to_tracked_bodies() -> void:
	var areas_to_erase: Array[Area2D] = []

	for area in _tracked_bodies_by_area.keys():
		if not is_instance_valid(area):
			areas_to_erase.append(area)
			continue

		var tracked_bodies: Dictionary = _tracked_bodies_by_area[area]
		if tracked_bodies.is_empty():
			areas_to_erase.append(area)
			continue

		var rect := _get_world_limit_rect(area)
		var invalid_bodies: Array[Node2D] = []
		for body in tracked_bodies.keys():
			if not is_instance_valid(body):
				invalid_bodies.append(body)
				continue
			if body.has_method("push_camera_limits"):
				body.push_camera_limits(area, rect, limit_priority)

		for invalid_body in invalid_bodies:
			tracked_bodies.erase(invalid_body)

		if tracked_bodies.is_empty():
			areas_to_erase.append(area)
		else:
			_tracked_bodies_by_area[area] = tracked_bodies

	for area in areas_to_erase:
		_tracked_bodies_by_area.erase(area)

func _get_world_limit_rect(area: Area2D) -> Rect2:
	var collision_shape := _get_collision_shape(area)
	if collision_shape == null:
		return Rect2(area.global_position, Vector2.ZERO)

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		return Rect2(area.global_position, Vector2.ZERO)

	var half_size := rectangle_shape.size * 0.5
	var points := PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y)
	])

	var xf := collision_shape.global_transform
	var min_point := xf * points[0]
	var max_point := min_point

	for i in range(1, points.size()):
		var p := xf * points[i]
		min_point.x = min(min_point.x, p.x)
		min_point.y = min(min_point.y, p.y)
		max_point.x = max(max_point.x, p.x)
		max_point.y = max(max_point.y, p.y)

	return Rect2(min_point, max_point - min_point)

func _get_collision_shape(area: Area2D) -> CollisionShape2D:
	for child in area.get_children():
		if child is CollisionShape2D:
			return child
	return null

func _ensure_collision_shape(area: Area2D) -> void:
	var collision_shape := _get_collision_shape(area)
	if collision_shape != null:
		return

	collision_shape = CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	var rectangle_shape := RectangleShape2D.new()
	rectangle_shape.size = default_size
	collision_shape.shape = rectangle_shape
	area.add_child(collision_shape)
	if Engine.is_editor_hint():
		collision_shape.owner = get_tree().edited_scene_root

func _sync_shape_size() -> void:
	if not include_root_area:
		return

	var collision_shape := _get_collision_shape(self)
	if collision_shape == null:
		return

	var rectangle_shape := collision_shape.shape as RectangleShape2D
	if rectangle_shape == null:
		rectangle_shape = RectangleShape2D.new()
		collision_shape.shape = rectangle_shape
	rectangle_shape.size = default_size

func _rebuild_limiter_areas() -> void:
	limiter_areas.clear()

	if include_root_area:
		limiter_areas.append(self)

	if auto_collect_child_areas:
		_collect_child_areas_recursive(self)

	for area in extra_areas:
		if area and not limiter_areas.has(area):
			limiter_areas.append(area)

func refresh_limiter_areas() -> void:
	_rebuild_limiter_areas()
	_connect_limiter_areas()

func _collect_child_areas_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Area2D and child != self and not limiter_areas.has(child):
			limiter_areas.append(child)
		_collect_child_areas_recursive(child)

func _connect_limiter_areas() -> void:
	for area in limiter_areas:
		if area == null:
			continue

		var entered_callable := Callable(self, "_on_area_body_entered").bind(area)
		var exited_callable := Callable(self, "_on_area_body_exited").bind(area)

		if not area.body_entered.is_connected(entered_callable):
			area.body_entered.connect(entered_callable)
		if not area.body_exited.is_connected(exited_callable):
			area.body_exited.connect(exited_callable)

func _has_tracked_bodies() -> bool:
	for area in _tracked_bodies_by_area.keys():
		var tracked_bodies: Dictionary = _tracked_bodies_by_area[area]
		if not tracked_bodies.is_empty():
			return true
	return false
