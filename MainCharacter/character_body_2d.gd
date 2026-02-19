extends CharacterBody2D

@export var speed = 200.0
@export var jump_velocity = -450.0
@export var wall_slide_speed = 150.0
@export var wall_jump_force = 400.0
@export var dash_speed = 500.0
@export var dash_duration = 0.4
@export var dash_cooldown = 3.0
@export var jump_cooldown = 1.0

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

@onready var dash_indicator = $CanvasLayer/DashIndicator
var recharge_sound: AudioStreamPlayer

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
	if is_dashing:
		dash_timer -= delta
		var progress = 1.0 - (dash_timer / dash_duration)
		$AnimatedSprite2D.rotation = progress * TAU * facing_direction
		if dash_timer <= 0:
			is_dashing = false
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
