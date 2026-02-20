extends CanvasLayer

var heart_list: Array[TextureRect] = []
var health: int = 3
var is_dead := false


func _ready() -> void:
	var hearts_parent = $HBoxContainer
	for child in hearts_parent.get_children():
		heart_list.append(child)

		
func update_heart_display():
	if health == 0 and not is_dead:
		is_dead = true
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("set_stun"):
			player.set_stun(&"game_over", true)
		$"../GameOver".die()
	for i in range(heart_list.size()):
		heart_list[i].visible = i < health


func take_damage(amount: int = 1) -> bool:
	if amount <= 0 or is_dead:
		return false

	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("is_damage_ignored") and player.is_damage_ignored():
		if player.has_method("on_damage_ignored"):
			player.on_damage_ignored(amount)
		return false

	if health > 0:
		health = max(0, health - amount)
	update_heart_display()
	return true
