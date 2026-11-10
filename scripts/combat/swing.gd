## The rules of a Swing: how hard it lands and where.
extends RefCounted

const Tuning := preload("res://scripts/tuning.gd")
const Facing := preload("res://scripts/hero/facing.gd")


## Damage of a Swing made with the Recharge Gauge at `gauge_level` (0.0-1.0):
## proportional to the gauge, but never less than the minimum.
static func damage(gauge_level: float) -> int:
	var proportional := roundi(Tuning.FULL_STRENGTH_DAMAGE * clampf(gauge_level, 0.0, 1.0))
	return maxi(Tuning.MINIMUM_SWING_DAMAGE, proportional)


## The area a Swing lands in when made from `origin` toward `facing`:
## a box just ahead of the swinger, wider across the Swing than along it.
static func reach(origin: Vector2, facing: int) -> Rect2:
	var ahead: Vector2 = Facing.VECTORS[facing]
	var size := Vector2(Tuning.SWING_REACH_DEPTH, Tuning.SWING_REACH_WIDTH)
	if ahead.x == 0.0:
		size = Vector2(Tuning.SWING_REACH_WIDTH, Tuning.SWING_REACH_DEPTH)
	var centre := origin + ahead * Tuning.SWING_REACH_AHEAD
	return Rect2(centre - size / 2.0, size)
