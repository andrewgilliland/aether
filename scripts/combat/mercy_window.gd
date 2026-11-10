## The Mercy Window: the short period after the Hero is struck during which
## he cannot be harmed again.
extends RefCounted

const Tuning := preload("res://scripts/tuning.gd")

## Seconds until it closes; 0 when closed.
var remaining := 0.0


func open() -> void:
	remaining = Tuning.MERCY_SECONDS


func close() -> void:
	remaining = 0.0


func is_open() -> bool:
	return remaining > 0.0


func advance(seconds: float) -> void:
	remaining = maxf(0.0, remaining - seconds)
