## What the HUD says: the wording of the Hero's Health and Recharge Gauge.
extends RefCounted

## Health at or below this fraction is shown as low.
const LOW_HEALTH := 0.3


## Health as "45/50".
static func health(current: int, maximum: int) -> String:
	return "%d/%d" % [current, maximum]


## The Recharge Gauge as a whole percentage, "0%" to "100%". It reads 100%
## only when the gauge is truly full, never by rounding up.
static func gauge(level: float) -> String:
	return "%d%%" % floori(clampf(level, 0.0, 1.0) * 100.0)


static func is_low_health(current: int, maximum: int) -> bool:
	return float(current) <= float(maximum) * LOW_HEALTH
