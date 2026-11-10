## Something a Swing can strike, which remembers every Swing it took.
extends StaticBody2D

## One entry per Swing taken: { damage: int, away: Vector2 }.
var swings: Array[Dictionary] = []


func _init() -> void:
	collision_layer = 1 << 2
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(12, 8)
	shape.shape = box
	add_child(shape)


func take_swing(damage: int, away: Vector2) -> void:
	swings.append({ "damage": damage, "away": away })
