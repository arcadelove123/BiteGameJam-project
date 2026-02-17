extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("web")

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("enter_web"):
		body.enter_web()

func _on_body_exited(body):
	if body.is_in_group("player") and body.has_method("exit_web"):
		body.exit_web()
