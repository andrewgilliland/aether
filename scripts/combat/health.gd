## Health: how much more harm a character can take.
extends RefCounted

var maximum: int
var current: int


func _init(full_health: int) -> void:
	maximum = full_health
	current = full_health


## Lose `damage` health. Returns true if this left none.
func take(damage: int) -> bool:
	current = maxi(0, current - maxi(0, damage))
	return current == 0


func is_spent() -> bool:
	return current == 0


func restore() -> void:
	current = maximum


## 0.0 (none left) to 1.0 (unhurt).
func fraction() -> float:
	return float(current) / float(maximum)
