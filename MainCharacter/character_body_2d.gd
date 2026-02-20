extends CharacterBody2D

@export var speed = 200.0
@export var jump_velocity = -450.0
@export var wall_slide_speed = 150.0
@export var wall_jump_force = 400.0
@export var dash_speed = 500.0
@export var dash_duration = 0.4
@export var dash_cooldown = 3.0
@export var jump_cooldown = 1.0
@export_group("Dash Reflect")
@export var dash_reflect_push_x: float = 800.0
@export var dash_reflect_push_y: float = 520.0
@export var dash_reflect_random_x: float = 90.0

@export_group("Dash UI")
@export var indicator_anchor: Control.LayoutPreset = Control.PRESET_BOTTOM_RIGHT
@export var indicator_margin: int = 100
@export var indicator_offset: Vector2 = Vector2(-20, -20)
@export var indicator_scale: Vector2 = Vector2(2.0, 2.0)

@onready var hpSystem: CanvasLayer = $CanvasGroup/HealthSystem

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var facing_direction = 1.0
var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var jump_cooldown_timer = 0.0
var web_count = 0
@export var web_slowdown_factor = 0.4
var is_stunned = false

@onready var dash_indicator = $CanvasLayer/DashIndicator
var recharge_sound: AudioStreamPlayer
var stun_reasons: Dictionary = {}
var stun_timers: Dictionary = {}
var damage_ignore_reasons: Dictionary = {}
var damage_ignore_timers: Dictionary = {}

func _ready():
	recharge_sound = AudioStreamPlayer.new()
	recharge_sound.stream = load("res://bam1.mp3")
	add_child(recharge_sound)
	
	add_to_group("player")
	if not has_node("CanvasLayer"):
		var cl = CanvasLayer.new()
		add_child(cl)
		var progress = TextureProgressBar.new()
		progress.name = "DashIndicator"
		progress.fill_mode = TextureProgressBar.FILL_CLOCKWISE
		progress.step = 0.01
		progress.max_value = dash_cooldown
		progress.value = dash_cooldown
		progress.texture_under = load("dash.png")
		progress.texture_progress = load("dash.png")
		progress.texture_filter = TEXTURE_FILTER_NEAREST
		progress.tint_under = Color(0.2, 0.2, 0.2, 0.5)
		progress.tint_progress = Color(1, 1, 1, 1)
		progress.scale = indicator_scale
		progress.set_anchors_and_offsets_preset(indicator_anchor, Control.PRESET_MODE_KEEP_SIZE, indicator_margin)
		progress.position += indicator_offset
		cl.add_child(progress)
		dash_indicator = progress

	if dash_indicator:
		dash_indicator.scale = indicator_scale


func _physics_process(delta):
	var target_rotation = 0.0
	if is_on_wall_only():
		target_rotation = deg_to_rad(-90 if $AnimatedSprite2D.flip_h else 90)
	$AnimatedSprite2D.rotation = lerp_angle($AnimatedSprite2D.rotation, target_rotation, 10.0 * delta)


	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			recharge_sound.play()
		if dash_indicator:
			dash_indicator.value = dash_cooldown - dash_cooldown_timer
	
	if jump_cooldown_timer > 0:
		jump_cooldown_timer -= delta

	if is_stunned:
		if is_dashing:
			is_dashing = false
			set_damage_ignore(&"dash", false)
			$AnimatedSprite2D.rotation = 0
		velocity.x = move_toward(velocity.x, 0, speed)
		move_and_slide()
		return

	if is_dashing:
		dash_timer -= delta
		var progress = 1.0 - (dash_timer / dash_duration)
		$AnimatedSprite2D.rotation = progress * TAU * facing_direction
		if dash_timer <= 0:
			is_dashing = false
			set_damage_ignore(&"dash", false)
			$AnimatedSprite2D.rotation = 0
		move_and_slide()
		return

	if not is_on_floor():
		if is_on_wall_only() and velocity.y > 0:
			velocity.y += (gravity * 0.5) * delta
			velocity.y = min(velocity.y, wall_slide_speed)
		else:
			velocity.y += gravity * delta

	var jump_attempt = Input.is_action_just_pressed("move_up")

	if jump_attempt and jump_cooldown_timer <= 0:
		if is_on_floor():
			velocity.y = jump_velocity
			jump_cooldown_timer = jump_cooldown
		elif is_on_wall_only():
			velocity.y = jump_velocity
			velocity.x = get_wall_normal().x * wall_jump_force
			jump_cooldown_timer = jump_cooldown

	var direction = Input.get_axis("move_left", "move_right")
	
	var current_speed = speed
	if web_count > 0:
		current_speed *= web_slowdown_factor
	
	if direction:
		velocity.x = direction * current_speed
		facing_direction = sign(direction)
		$AnimatedSprite2D.flip_h = facing_direction > 0
		if $AnimatedSprite2D.animation != "roll" or not $AnimatedSprite2D.is_playing():
			$AnimatedSprite2D.play("default")
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		if $AnimatedSprite2D.animation != "roll" or not $AnimatedSprite2D.is_playing():
			$AnimatedSprite2D.stop()

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
		start_dash()

	move_and_slide()

func start_dash():
	is_dashing = true
	set_damage_ignore(&"dash", true)
	if $AnimatedSprite2D.sprite_frames.has_animation("roll"):
		$AnimatedSprite2D.sprite_frames.set_animation_loop("roll", false)
	$AnimatedSprite2D.play("roll")
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	velocity.x = facing_direction * dash_speed
	velocity.y = 0
	if dash_indicator:
		dash_indicator.value = 0

func enter_web():
	web_count += 1

func exit_web():
	web_count = max(0, web_count - 1)

func take_damage(amount: int = 1) -> bool:
	if hpSystem and hpSystem.has_method("take_damage"):
		return hpSystem.take_damage(amount)
	return false

func _refresh_stun_state() -> void:
	is_stunned = not stun_reasons.is_empty()

func is_damage_ignored() -> bool:
	return not damage_ignore_reasons.is_empty()

func set_damage_ignore(reason: StringName, enabled: bool, duration: float = 0.0) -> void:
	if enabled:
		damage_ignore_reasons[reason] = true
		if duration > 0.0:
			var existing_timer: SceneTreeTimer = damage_ignore_timers.get(reason, null)
			if existing_timer and existing_timer.timeout.is_connected(_on_damage_ignore_timer_timeout.bind(reason)):
				existing_timer.timeout.disconnect(_on_damage_ignore_timer_timeout.bind(reason))
			var timer := get_tree().create_timer(duration)
			damage_ignore_timers[reason] = timer
			timer.timeout.connect(_on_damage_ignore_timer_timeout.bind(reason), CONNECT_ONE_SHOT)
	else:
		damage_ignore_reasons.erase(reason)
		damage_ignore_timers.erase(reason)

func _on_damage_ignore_timer_timeout(reason: StringName) -> void:
	set_damage_ignore(reason, false)

func on_damage_ignored(amount: int = 1) -> void:
	if amount <= 0:
		return
	if not is_dashing:
		return

	var horizontal_direction: float = - sign(facing_direction)
	if horizontal_direction == 0:
		horizontal_direction = -1.0
	var reflect_x: float = horizontal_direction * (dash_reflect_push_x + randf_range(-dash_reflect_random_x, dash_reflect_random_x))
	velocity = Vector2(reflect_x, -dash_reflect_push_y)

	is_dashing = false
	set_damage_ignore(&"dash", false)
	$AnimatedSprite2D.rotation = 0

func set_stun(reason: StringName, enabled: bool, duration: float = 0.0) -> void:
	if enabled:
		stun_reasons[reason] = true
		if is_dashing:
			is_dashing = false
			set_damage_ignore(&"dash", false)
			$AnimatedSprite2D.rotation = 0
		velocity.x = 0
		if duration > 0.0:
			var existing_timer: SceneTreeTimer = stun_timers.get(reason, null)
			if existing_timer and existing_timer.timeout.is_connected(_on_stun_timer_timeout.bind(reason)):
				existing_timer.timeout.disconnect(_on_stun_timer_timeout.bind(reason))
			var timer := get_tree().create_timer(duration)
			stun_timers[reason] = timer
			timer.timeout.connect(_on_stun_timer_timeout.bind(reason), CONNECT_ONE_SHOT)
	else:
		stun_reasons.erase(reason)
		stun_timers.erase(reason)

	_refresh_stun_state()


func _on_stun_timer_timeout(reason: StringName) -> void:
	set_stun(reason, false)


func stun(duration: float = 0.0):
	set_stun(&"default", true, duration)


func unstun():
	set_stun(&"default", false)
