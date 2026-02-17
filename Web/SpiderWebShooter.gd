extends Area2D

@export_group("Trigger Config")
@export var spawners: Array[Node2D]
@export var trigger_once: bool = true

var _has_triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if _has_triggered and trigger_once:
		return
		
	if body.is_in_group("player"):
		_has_triggered = true
		
		for spawner in spawners:
			if is_instance_valid(spawner) and spawner.has_method("shoot"):
				spawner.shoot()
			else:
				push_warning("SpiderWebShooter: Assigned spawner %s is invalid or missing 'shoot' method." % str(spawner))
