extends RefCounted

const HERO := preload("res://scenes/hero/hero.tscn")
const PUFFHOP := preload("res://scenes/enemies/puffhop.tscn")
const Puffhop := preload("res://scripts/enemies/puffhop.gd")
const Tuning := preload("res://scripts/tuning.gd")
const DamageNumber := preload("res://scripts/hud/damage_number.gd")
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


func test_a_swing_that_lands_shows_its_damage() -> void:
	var hero := _spawn_hero(Vector2.ZERO)
	Input.action_press("move_right")
	await runner.frames(2)
	Input.action_release("move_right")
	var puffhop := _spawn_puffhop(hero.position + Vector2(16, 0))
	var stood_at: Vector2 = puffhop.position
	Input.action_press("swing")
	await runner.frames(12)
	Input.action_release("swing")
	var numbers := _numbers_over(puffhop)
	runner.check_equal(numbers.size(), 1, "one number for the one Swing")
	if numbers.size() == 1:
		runner.check_equal(numbers[0].amount, Tuning.FULL_STRENGTH_DAMAGE, "shows the damage done")
		runner.check(absf(numbers[0].position.x - puffhop.position.x) < 2.0, "stays over the Puffhop as it is knocked away")
		runner.check(numbers[0].position.y < puffhop.position.y - 10.0, "above it")
	# The first Swing knocked it out of reach: bring it back for a second.
	await runner.frames(22)
	puffhop.position = stood_at
	Input.action_press("swing")
	await runner.frames(12)
	Input.action_release("swing")
	var amounts := []
	for number in _numbers_over(puffhop):
		amounts.append(number.amount)
		runner.check_equal(number.tint, DamageNumber.DEALT, "damage dealt is shown in white")
	amounts.sort()
	runner.check_equal(amounts.size(), 2, "a second number for the second Swing")
	runner.check(amounts[0] < Tuning.FULL_STRENGTH_DAMAGE, "the weak Swing shows its smaller damage, got %s" % [amounts])
	await runner.frames(int(Tuning.DAMAGE_NUMBER_SECONDS * 60.0) + 10)
	runner.check_equal(_numbers_over(puffhop).size(), 0, "numbers clear themselves away")
	_finish()


func test_harm_to_the_hero_shows_as_a_red_number_over_him() -> void:
	var hero := _spawn_hero(Vector2.ZERO)
	await runner.frames(2)
	hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.LEFT)
	var numbers := _numbers_over(hero)
	runner.check_equal(numbers.size(), 1, "one number for the one blow")
	if numbers.size() == 1:
		runner.check_equal(numbers[0].amount, Tuning.PUFFHOP_CONTACT_DAMAGE, "shows the Health lost")
		runner.check_equal(numbers[0].tint, DamageNumber.TAKEN, "in red")
	hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.LEFT)
	runner.check_equal(_numbers_over(hero).size(), 1, "a blow the Mercy Window turns away shows nothing")
	await runner.frames(6)
	numbers = _numbers_over(hero)
	if numbers.size() == 1:
		runner.check(absf(numbers[0].position.x - hero.position.x) < 2.0, "stays over him as he is knocked away")
		runner.check(numbers[0].position.y < hero.position.y - 30.0, "above his head")
	_finish()


func test_the_blow_that_fells_him_shows_only_the_health_he_had_left() -> void:
	var hero := _spawn_hero(Vector2.ZERO)
	hero.health.take(Tuning.HERO_HEALTH - 3)
	hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.LEFT)
	var numbers := _numbers_over(hero)
	runner.check_equal(numbers.size(), 1, "the felling blow shows a number")
	if numbers.size() == 1:
		runner.check_equal(numbers[0].amount, 3, "the Health actually lost")
	_finish()


func test_a_swing_that_misses_shows_no_number() -> void:
	var hero := _spawn_hero(Vector2.ZERO)
	_spawn_puffhop(hero.position + Vector2(0, -60)).bounds = Rect2(-1, -61, 2, 2)
	Input.action_press("move_down")
	await runner.frames(2)
	Input.action_release("move_down")
	Input.action_press("swing")
	await runner.frames(20)
	Input.action_release("swing")
	runner.check_equal(runner.get_nodes_in_group("damage_number").size(), 0, "nothing struck, nothing shown")
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


## The Damage Numbers showing over `who` now.
func _numbers_over(who: Node2D) -> Array:
	var found := []
	for number in runner.get_nodes_in_group("damage_number"):
		if number.struck == who and not number.is_queued_for_deletion():
			found.append(number)
	return found


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
