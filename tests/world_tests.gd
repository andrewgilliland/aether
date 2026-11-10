extends RefCounted

const WORLD := preload("res://scenes/world.tscn")
const Tuning := preload("res://scripts/tuning.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "swing"]

var runner: SceneTree


func test_the_game_starts_in_the_forest_clearing() -> void:
	var world := _open_world()
	await runner.frames(2)
	runner.check_equal(String(world.zone.name), "ForestClearing", "first Zone")
	runner.check_equal(world.hero.position, world.zone.get_node("Start").position, "Hero at the Start")
	runner.check_equal(world.zone.enemies().size(), 3, "three Puffhops")
	world.free()


func test_walking_onto_an_entrance_makes_the_transition() -> void:
	var world := _open_world()
	var hero: CharacterBody2D = world.hero
	_remove_enemies(world)
	hero.health.take(7)
	hero.position = world.zone.get_node("Entrances/East").position + Vector2(-16, 0)
	Input.action_press("move_right")
	await _until_arrived(world, "DeepWoods")
	Input.action_release("move_right")
	runner.check_equal(String(world.zone.name), "DeepWoods", "now in the Deep Woods")
	var arrival: Vector2 = world.zone.get_node("Entrances/West").arrival_point()
	runner.check(hero.position.distance_to(arrival) < 40.0, "beside the matching Entrance, at %s" % hero.position)
	runner.check(hero.get_parent() == world.zone.get_node("Things"), "the same Hero, now in the new Zone")
	runner.check_equal(hero.health.current, Tuning.HERO_HEALTH - 7, "arrives as hurt as he left")
	runner.check_equal(world.zone.enemies().size(), 6, "six Puffhops here")
	runner.check_equal(world.get_node("ZoneHolder").get_child_count(), 1, "the old Zone is gone")
	world.free()


func test_going_back_finds_the_first_zone_reset() -> void:
	var world := _open_world()
	var hero: CharacterBody2D = world.hero
	world.zone.enemies()[0].take_swing(Tuning.PUFFHOP_HEALTH, Vector2.RIGHT)
	runner.check_equal(world.zone.enemies().size(), 2, "one Puffhop defeated")

	hero.position = world.zone.get_node("Entrances/East").position + Vector2(-16, 0)
	Input.action_press("move_right")
	await _until_arrived(world, "DeepWoods")
	Input.action_release("move_right")
	_remove_enemies(world)
	hero.position = world.zone.get_node("Entrances/West").position + Vector2(16, 0)
	Input.action_press("move_left")
	await _until_arrived(world, "ForestClearing")
	Input.action_release("move_left")

	runner.check_equal(String(world.zone.name), "ForestClearing", "back in the clearing")
	var arrival: Vector2 = world.zone.get_node("Entrances/East").arrival_point()
	runner.check(hero.position.distance_to(arrival) < 40.0, "beside the East Entrance, at %s" % hero.position)
	runner.check_equal(world.zone.enemies().size(), 3, "all three Puffhops are back")
	world.free()


func test_knockback_onto_an_entrance_makes_the_transition() -> void:
	var world := _open_world()
	var hero: CharacterBody2D = world.hero
	_remove_enemies(world)
	hero.position = world.zone.get_node("Entrances/East").position + Vector2(-20, 0)
	await runner.frames(2)
	hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.RIGHT)
	await _until_arrived(world, "DeepWoods")
	runner.check_equal(String(world.zone.name), "DeepWoods", "knocked through to the Deep Woods")
	runner.check(hero.is_in_mercy_window(), "the Mercy Window came with him")
	runner.check_equal(hero.health.current, Tuning.HERO_HEALTH - Tuning.PUFFHOP_CONTACT_DAMAGE, "still hurt")
	world.free()


func test_the_path_leads_from_the_start_to_the_deep_woods() -> void:
	var world := _open_world()
	_remove_enemies(world)
	Input.action_press("move_right")
	await _until_arrived(world, "DeepWoods", 700)
	Input.action_release("move_right")
	runner.check_equal(String(world.zone.name), "DeepWoods", "walked east all the way")
	world.free()


func _open_world() -> Node:
	for action in ACTIONS:
		Input.action_release(action)
	var world := WORLD.instantiate()
	runner.root.add_child(world)
	return world


func _remove_enemies(world: Node) -> void:
	for enemy in world.zone.enemies():
		enemy.free()


## Wait until the World has finished a Transition into the Zone called `zone_name`.
func _until_arrived(world: Node, zone_name: String, most_frames := 240) -> void:
	for i in most_frames:
		await runner.frames(1)
		if String(world.zone.name) == zone_name and not world.is_travelling():
			return
