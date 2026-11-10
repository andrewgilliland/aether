## Facing: which of four directions a character looks toward.
##
## Movement is free in eight directions but there are only four Facings, so
## this decides which one a movement direction turns the character to.
extends RefCounted

enum { DOWN, UP, LEFT, RIGHT }

const NAMES := { DOWN: "down", UP: "up", LEFT: "left", RIGHT: "right" }
const VECTORS := {
	DOWN: Vector2.DOWN, UP: Vector2.UP, LEFT: Vector2.LEFT, RIGHT: Vector2.RIGHT,
}

## How much stronger one axis must be before a move counts as not diagonal.
const DIAGONAL_TOLERANCE := 0.01


## The Facing after moving in `direction` while facing `current`.
## Standing still keeps the Facing. A diagonal keeps the Facing when it
## already points along one of the diagonal's two axes, so the character does
## not flip back and forth; otherwise the diagonal turns him sideways.
static func from_movement(direction: Vector2, current: int) -> int:
	if direction == Vector2.ZERO:
		return current
	var horizontal := RIGHT if direction.x > 0.0 else LEFT
	var vertical := DOWN if direction.y > 0.0 else UP
	var difference := absf(direction.x) - absf(direction.y)
	if difference > DIAGONAL_TOLERANCE:
		return horizontal
	if difference < -DIAGONAL_TOLERANCE:
		return vertical
	if current == horizontal or current == vertical:
		return current
	return horizontal
