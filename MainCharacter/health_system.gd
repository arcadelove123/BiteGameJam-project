extends CanvasLayer

var heart_list: Array[TextureRect] = []
var health: int = 3


func _ready() -> void:
	var hearts_parent = $HBoxContainer
	for child in hearts_parent.get_children():
		heart_list.append(child)

		
func update_heart_display():
	if health == 0:
		$"../GameOver".die()
	for i in range(heart_list.size()):
		heart_list[i].visible = i < health


func take_damage():
	if health > 0:
		health -= 1
	update_heart_display()
