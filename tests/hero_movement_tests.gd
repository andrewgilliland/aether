extends RefCounted

const HERO := preload("res://scenes/hero/hero.tscn")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down"]

var runner: SceneTree


func test_walks_right_and_stops() -> void:
	var hero := _spawn_hero()
	Input.action_press("move_right")
	await runner.frames(30)
	runner.check(hero.position.x > 25.0, "moved right, x is %s" % hero.position.x)
	runner.check(absf(hero.position.y) < 0.01, "did not drift vertically")
	runner.check_equal(hero.animation(), &"walk_right", "walking animation")
	runner.check(not hero.is_mirrored(), "not mirrored facing right")
	_release_all()
	await runner.frames(2)
	var stopped_at := hero.position.x
	await runner.frames(10)
	runner.check_equal(hero.position.x, stopped_at, "stays put when released")
	runner.check_equal(hero.animation(), &"idle_right", "idle keeps the facing")
	_finish(hero)


func test_facing_left_mirrors_the_right_animation() -> void:
	var hero := _spawn_hero()
	Input.action_press("move_left")
	await runner.frames(10)
	runner.check(hero.position.x < -5.0, "moved left")
	runner.check_equal(hero.animation(), &"walk_right", "uses the right-facing frames")
	runner.check(hero.is_mirrored(), "mirrored facing left")
	_finish(hero)


func test_up_and_down_use_their_own_animations() -> void:
	var hero := _spawn_hero()
	Input.action_press("move_up")
	await runner.frames(10)
	runner.check_equal(hero.animation(), &"walk_up", "up")
	_release_all()
	Input.action_press("move_down")
	await runner.frames(10)
	runner.check_equal(hero.animation(), &"walk_down", "down")
	_finish(hero)


func test_diagonal_is_no_faster_than_straight() -> void:
	var hero := _spawn_hero()
	Input.action_press("move_right")
	await runner.frames(30)
	var straight := hero.position.length()
	_release_all()
	await runner.frames(2)
	var start := hero.position
	Input.action_press("move_right")
	Input.action_press("move_down")
	await runner.frames(30)
	var diagonal := (hero.position - start).length()
	runner.check(straight > 30.0, "walks at a useful speed, went %s" % straight)
	runner.check(absf(diagonal - straight) < 1.5, "diagonal went %s, straight went %s" % [diagonal, straight])
	_finish(hero)


func test_solid_things_block_him() -> void:
	var hero := _spawn_hero()
	var wall := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(8, 64)
	shape.shape = rectangle
	wall.add_child(shape)
	wall.position = Vector2(30, 0)
	hero.get_parent().add_child(wall)
	Input.action_press("move_right")
	await runner.frames(60)
	runner.check(hero.position.x < 26.0, "stopped by the wall, x is %s" % hero.position.x)
	runner.check(hero.position.x > 15.0, "reached the wall, x is %s" % hero.position.x)
	_finish(hero)


func _spawn_hero() -> CharacterBody2D:
	_release_all()
	var world := Node2D.new()
	runner.root.add_child(world)
	var hero: CharacterBody2D = HERO.instantiate()
	world.add_child(hero)
	return hero


func _finish(hero: CharacterBody2D) -> void:
	_release_all()
	hero.get_parent().queue_free()


func _release_all() -> void:
	for action in ACTIONS:
		Input.action_release(action)
