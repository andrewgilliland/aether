## The Recharge Gauge: the Hero's readiness to Swing, from 0.0 just after a
## Swing up to 1.0. It starts full.
extends RefCounted

const Tuning := preload("res://scripts/tuning.gd")

## 0.0 (empty) to 1.0 (a Swing now would be Full-Strength).
var level := 1.0


func is_full() -> bool:
	return level >= 1.0


## Let `seconds` of recharging pass.
func advance(seconds: float) -> void:
	level = minf(1.0, level + seconds / Tuning.RECHARGE_SECONDS)


## Empty the gauge for a Swing and return the level it was spent at.
## A Swing always empties it, whether or not the Swing lands.
func spend() -> float:
	var spent := level
	level = 0.0
	return spent
