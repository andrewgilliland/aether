extends RefCounted

const Facing := preload("res://scripts/hero/facing.gd")

var runner: SceneTree


func test_straight_movement_turns_to_that_direction() -> void:
	runner.check_equal(Facing.from_movement(Vector2.RIGHT, Facing.DOWN), Facing.RIGHT, "right")
	runner.check_equal(Facing.from_movement(Vector2.LEFT, Facing.DOWN), Facing.LEFT, "left")
	runner.check_equal(Facing.from_movement(Vector2.UP, Facing.DOWN), Facing.UP, "up")
	runner.check_equal(Facing.from_movement(Vector2.DOWN, Facing.UP), Facing.DOWN, "down")


func test_standing_still_keeps_facing() -> void:
	for facing in [Facing.DOWN, Facing.UP, Facing.LEFT, Facing.RIGHT]:
		runner.check_equal(Facing.from_movement(Vector2.ZERO, facing), facing, "still")


func test_stronger_axis_wins() -> void:
	runner.check_equal(Facing.from_movement(Vector2(0.9, 0.3), Facing.UP), Facing.RIGHT, "mostly right")
	runner.check_equal(Facing.from_movement(Vector2(-0.2, -0.8), Facing.RIGHT), Facing.UP, "mostly up")


func test_diagonal_keeps_a_facing_that_lies_along_it() -> void:
	var down_right := Vector2(1, 1).normalized()
	runner.check_equal(Facing.from_movement(down_right, Facing.DOWN), Facing.DOWN, "keeps down")
	runner.check_equal(Facing.from_movement(down_right, Facing.RIGHT), Facing.RIGHT, "keeps right")


func test_diagonal_away_from_facing_turns_sideways() -> void:
	var down_right := Vector2(1, 1).normalized()
	runner.check_equal(Facing.from_movement(down_right, Facing.UP), Facing.RIGHT, "from up")
	runner.check_equal(Facing.from_movement(down_right, Facing.LEFT), Facing.RIGHT, "from left")
	var up_left := Vector2(-1, -1).normalized()
	runner.check_equal(Facing.from_movement(up_left, Facing.DOWN), Facing.LEFT, "from down")
