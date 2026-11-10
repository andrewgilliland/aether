extends RefCounted

const HERO := preload("res://scenes/hero/hero.tscn")
const SwingTarget := preload("res://tests/support/swing_target.gd")
const Tuning := preload("res://scripts/tuning.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "swing"]
## Physics frames a whole Swing takes, with a little to spare.
const SWING_FRAMES := 22

var runner: SceneTree


func test_full_strength_swing_strikes_what_is_ahead() -> void:
	var hero := await _spawn_hero_facing("move_right")
	var ahead := _add_target(hero, Vector2(16, -4))
	var behind := _add_target(hero, Vector2(-16, -4))
	await _swing()
	runner.check_equal(ahead.swings.size(), 1, "struck the one ahead once")
	if ahead.swings.size() == 1:
		runner.check_equal(ahead.swings[0].damage, Tuning.FULL_STRENGTH_DAMAGE, "full damage")
		runner.check_equal(ahead.swings[0].away, Vector2.RIGHT, "knocked away from him")
	runner.check_equal(behind.swings.size(), 0, "left the one behind alone")
	_finish(hero)


func test_one_swing_strikes_everything_in_reach_once_each() -> void:
	var hero := await _spawn_hero_facing("move_down")
	var left := _add_target(hero, Vector2(-9, 10))
	var right := _add_target(hero, Vector2(9, 10))
	await _swing()
	runner.check_equal(left.swings.size(), 1, "left one struck once")
	runner.check_equal(right.swings.size(), 1, "right one struck once")
	_finish(hero)


func test_a_swing_that_misses_still_empties_the_gauge() -> void:
	var hero := await _spawn_hero_facing("move_up")
	runner.check(hero.gauge.is_full(), "full before")
	Input.action_press("swing")
	await runner.frames(3)
	Input.action_release("swing")
	runner.check_equal(hero.gauge.level, 0.0, "empty during the Swing")
	_finish(hero)


func test_swinging_again_at_once_does_minimum_damage() -> void:
	var hero := await _spawn_hero_facing("move_right")
	var target := _add_target(hero, Vector2(16, -4))
	await _swing()
	await _swing()
	runner.check_equal(target.swings.size(), 2, "struck by both Swings")
	if target.swings.size() == 2:
		runner.check_equal(target.swings[1].damage, Tuning.MINIMUM_SWING_DAMAGE, "second Swing is weak")
	_finish(hero)


func test_waiting_restores_full_strength() -> void:
	var hero := await _spawn_hero_facing("move_right")
	var target := _add_target(hero, Vector2(16, -4))
	await _swing()
	await runner.frames(int(Tuning.RECHARGE_SECONDS * 60.0) + 4)
	runner.check(hero.gauge.is_full(), "gauge refilled")
	await _swing()
	if target.swings.size() == 2:
		runner.check_equal(target.swings[1].damage, Tuning.FULL_STRENGTH_DAMAGE, "full damage again")
	else:
		runner.check(false, "expected two Swings to land, got %s" % target.swings.size())
	_finish(hero)


func test_a_swing_roots_him_until_it_ends() -> void:
	var hero := await _spawn_hero_facing("move_right")
	var start: Vector2 = hero.position
	Input.action_press("swing")
	await runner.frames(2)
	Input.action_release("swing")
	Input.action_press("move_right")
	await runner.frames(8)
	runner.check(hero.is_swinging(), "still swinging")
	runner.check_equal(hero.position, start, "rooted while swinging")
	runner.check_equal(hero.animation(), &"swing_right", "swing animation")
	await runner.frames(SWING_FRAMES + 10)
	runner.check(not hero.is_swinging(), "Swing over")
	runner.check(hero.position.x > start.x + 5.0, "walks again afterwards")
	_finish(hero)


## A Hero standing at the origin who has turned to face the way `action` moves him.
func _spawn_hero_facing(action: String) -> CharacterBody2D:
	_release_all()
	var world := Node2D.new()
	runner.root.add_child(world)
	var hero: CharacterBody2D = HERO.instantiate()
	world.add_child(hero)
	Input.action_press(action)
	await runner.frames(2)
	Input.action_release(action)
	await runner.frames(2)
	hero.position = Vector2.ZERO
	return hero


func _add_target(hero: CharacterBody2D, at: Vector2) -> StaticBody2D:
	var target: StaticBody2D = SwingTarget.new()
	target.position = at
	hero.get_parent().add_child(target)
	return target


## Press Swing and wait for the whole Swing to finish.
func _swing() -> void:
	Input.action_press("swing")
	await runner.frames(2)
	Input.action_release("swing")
	await runner.frames(SWING_FRAMES)


func _finish(hero: CharacterBody2D) -> void:
	_release_all()
	hero.get_parent().queue_free()


func _release_all() -> void:
	for action in ACTIONS:
		Input.action_release(action)
