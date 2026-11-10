extends RefCounted

const HERO := preload("res://scenes/hero/hero.tscn")
const PUFFHOP := preload("res://scenes/enemies/puffhop.tscn")
const Puffhop := preload("res://scripts/enemies/puffhop.gd")
const Tuning := preload("res://scripts/tuning.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "swing"]

var runner: SceneTree
var _world: Node2D


func test_it_notices_the_hero_nearby_and_gives_up_far_away() -> void:
	runner.check(Puffhop.keeps_chasing(70.0, false), "notices at 70")
	runner.check(not Puffhop.keeps_chasing(100.0, false), "does not notice at 100")
	runner.check(Puffhop.keeps_chasing(100.0, true), "keeps chasing at 100")
	runner.check(not Puffhop.keeps_chasing(140.0, true), "gives up at 140")


func test_three_full_strength_swings_defeat_it() -> void:
	var puffhop := _spawn_puffhop(Vector2.ZERO)
	var defeats := [0]
	puffhop.defeated.connect(func() -> void: defeats[0] += 1)
	puffhop.take_swing(Tuning.FULL_STRENGTH_DAMAGE, Vector2.RIGHT)
	puffhop.take_swing(Tuning.FULL_STRENGTH_DAMAGE, Vector2.RIGHT)
	runner.check(not puffhop.is_defeated(), "survives two")
	runner.check_equal(puffhop.health.current, 5, "5 health left")
	puffhop.take_swing(Tuning.FULL_STRENGTH_DAMAGE, Vector2.RIGHT)
	runner.check(puffhop.is_defeated(), "defeated by the third")
	runner.check_equal(defeats[0], 1, "says so once")
	runner.check(not puffhop.is_in_group("enemy"), "no longer counts as an Enemy")
	await runner.frames(30)
	runner.check(not is_instance_valid(puffhop), "gone after fading out")
	_finish()


func test_being_struck_knocks_it_away_and_stuns_it() -> void:
	var puffhop := _spawn_puffhop(Vector2.ZERO)
	puffhop.take_swing(1, Vector2.RIGHT)
	runner.check(puffhop.is_stunned(), "stunned at once")
	await runner.frames(12)
	runner.check(puffhop.position.x > 15.0, "knocked right, x is %s" % puffhop.position.x)
	runner.check(absf(puffhop.position.y) < 0.5, "straight along the Swing")
	var landed: Vector2 = puffhop.position
	await runner.frames(8)
	runner.check_equal(puffhop.position, landed, "does not move while stunned")
	await runner.frames(12)
	runner.check(not puffhop.is_stunned(), "stun wears off")
	_finish()


func test_touching_the_hero_harms_him_and_knocks_him_away() -> void:
	var hero := _spawn_hero(Vector2(8, 0))
	_spawn_puffhop(Vector2.ZERO)
	await runner.frames(20)
	runner.check_equal(hero.health.current, Tuning.HERO_HEALTH - Tuning.PUFFHOP_CONTACT_DAMAGE, "lost 5 health")
	runner.check(hero.position.x > 20.0, "knocked away to the right, x is %s" % hero.position.x)
	runner.check(hero.is_in_mercy_window(), "Mercy Window open")
	_finish()


func test_he_flinches_while_knocked_back_then_stands_again() -> void:
	var hero := _spawn_hero(Vector2.ZERO)
	await runner.frames(2)
	hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.LEFT)
	await runner.frames(4)
	runner.check_equal(hero.animation(), &"hurt_down", "flinching")
	await runner.frames(12)
	runner.check_equal(hero.animation(), &"idle_down", "standing again")
	_finish()


func test_mercy_window_stops_further_harm_until_it_closes() -> void:
	var hero := _spawn_hero(Vector2(8, 0))
	var puffhop := _spawn_puffhop(Vector2.ZERO)
	await runner.frames(6)
	var after_first: int = hero.health.current
	runner.check_equal(after_first, 45, "first touch landed")
	# Hold the Puffhop on top of him for most of the Mercy Window.
	for i in 45:
		puffhop.position = hero.position
		await runner.frames(1)
	runner.check_equal(hero.health.current, after_first, "no harm while the window is open")
	for i in 30:
		puffhop.position = hero.position
		await runner.frames(1)
	runner.check(hero.health.current < after_first, "harmed again once it closes")
	_finish()


func test_a_stunned_puffhop_does_no_contact_damage() -> void:
	var hero := _spawn_hero(Vector2(40, 0))
	var puffhop := _spawn_puffhop(Vector2.ZERO)
	puffhop.take_swing(1, Vector2.RIGHT)
	for i in 18:
		puffhop.position = hero.position
		await runner.frames(1)
	runner.check(puffhop.is_stunned(), "still stunned")
	runner.check_equal(hero.health.current, Tuning.HERO_HEALTH, "no harm from a stunned Puffhop")
	for i in 20:
		puffhop.position = hero.position
		await runner.frames(1)
	runner.check(hero.health.current < Tuning.HERO_HEALTH, "harms him once the stun wears off")
	_finish()


func test_it_hops_after_a_hero_it_has_noticed() -> void:
	var hero := _spawn_hero(Vector2(70, 0))
	var puffhop := _spawn_puffhop(Vector2.ZERO)
	await runner.frames(100)
	runner.check(puffhop.is_chasing() or hero.is_in_mercy_window(), "chasing him")
	runner.check(puffhop.position.x > 15.0, "closed the distance, x is %s" % puffhop.position.x)
	_finish()


func test_it_ignores_a_hero_too_far_away() -> void:
	_spawn_hero(Vector2(300, 0))
	var puffhop := _spawn_puffhop(Vector2.ZERO)
	await runner.frames(60)
	runner.check(not puffhop.is_chasing(), "not chasing")
	_finish()


func test_it_stays_inside_its_zone() -> void:
	_spawn_hero(Vector2(60, 0))
	var puffhop := _spawn_puffhop(Vector2.ZERO)
	puffhop.bounds = Rect2(-10, -10, 20, 20)
	await runner.frames(150)
	runner.check(puffhop.position.x <= 10.0, "held at the edge, x is %s" % puffhop.position.x)
	puffhop.take_swing(1, Vector2.LEFT)
	await runner.frames(15)
	runner.check(puffhop.position.x >= -10.0, "knockback cannot push it out, x is %s" % puffhop.position.x)
	_finish()


func test_a_swing_from_the_hero_hurts_it() -> void:
	var hero := _spawn_hero(Vector2.ZERO)
	Input.action_press("move_right")
	await runner.frames(2)
	Input.action_release("move_right")
	var puffhop := _spawn_puffhop(hero.position + Vector2(16, 0))
	Input.action_press("swing")
	await runner.frames(12)
	Input.action_release("swing")
	runner.check_equal(puffhop.health.current, Tuning.PUFFHOP_HEALTH - Tuning.FULL_STRENGTH_DAMAGE, "took a Full-Strength Swing")
	runner.check(puffhop.position.x > hero.position.x + 16.0, "knocked away from him")
	_finish()


func test_the_hero_falls_when_his_health_runs_out() -> void:
	var hero := _spawn_hero(Vector2.ZERO)
	var falls := [0]
	hero.fell.connect(func() -> void: falls[0] += 1)
	hero.health.take(Tuning.HERO_HEALTH - 3)
	hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.RIGHT)
	runner.check(hero.is_fallen(), "fallen")
	runner.check_equal(hero.animation(), &"fallen", "shown fallen")
	runner.check_equal(falls[0], 1, "says so once")
	var where: Vector2 = hero.position
	Input.action_press("move_right")
	await runner.frames(10)
	runner.check_equal(hero.position, where, "cannot walk while fallen")
	hero.take_contact(5, Vector2.RIGHT)
	runner.check_equal(falls[0], 1, "cannot fall twice")
	_finish()


func _world_node() -> Node2D:
	if _world == null:
		_release_all()
		_world = Node2D.new()
		runner.root.add_child(_world)
	return _world


func _spawn_hero(at: Vector2) -> CharacterBody2D:
	var hero: CharacterBody2D = HERO.instantiate()
	hero.position = at
	_world_node().add_child(hero)
	return hero


func _spawn_puffhop(at: Vector2) -> CharacterBody2D:
	var puffhop: CharacterBody2D = PUFFHOP.instantiate()
	puffhop.position = at
	_world_node().add_child(puffhop)
	return puffhop


func _finish() -> void:
	_release_all()
	_world.free()
	_world = null


func _release_all() -> void:
	for action in ACTIONS:
		Input.action_release(action)
