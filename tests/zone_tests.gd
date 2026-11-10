extends RefCounted

const HERO := preload("res://scenes/hero/hero.tscn")
const CLEARING := "res://scenes/zones/forest_clearing.tscn"
const WOODS := "res://scenes/zones/deep_woods.tscn"
const Tuning := preload("res://scripts/tuning.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "swing"]

var runner: SceneTree


func test_the_clearing_has_three_puffhops_and_the_woods_six() -> void:
	var clearing := _open(CLEARING)
	await runner.frames(2)
	runner.check_equal(clearing.enemies().size(), 3, "clearing")
	clearing.free()
	var woods := _open(WOODS, "West")
	await runner.frames(2)
	runner.check_equal(woods.enemies().size(), 6, "woods")
	woods.free()


func test_the_hero_starts_at_the_start_when_he_came_through_no_entrance() -> void:
	var zone := _open(CLEARING)
	var hero := _hero_in(zone)
	runner.check_equal(hero.position, zone.get_node("Start").position, "at the Start")
	zone.free()


func test_every_entrance_leads_to_a_matching_entrance() -> void:
	for path in [CLEARING, WOODS]:
		var zone: Node2D = load(path).instantiate()
		for entrance in zone.get_node("Entrances").get_children():
			var where := "%s %s" % [zone.name, entrance.name]
			runner.check(ResourceLoader.exists(entrance.to_zone), "%s leads to a Zone that exists" % where)
			var other: Node2D = load(entrance.to_zone).instantiate()
			var match_: Node = other.get_node_or_null("Entrances/" + entrance.to_entrance)
			runner.check(match_ != null, "%s has a matching Entrance" % where)
			if match_ != null:
				runner.check_equal(match_.to_entrance, String(entrance.name), "%s: the way back returns here" % where)
				runner.check(match_.arrival_offset.length() > 16.0, "%s: arriving does not land on the Entrance" % where)
			other.free()
		zone.free()


func test_respawn_returns_the_hero_unhurt_and_resets_the_enemies() -> void:
	var zone := _open(CLEARING)
	var hero := _hero_in(zone)
	var arrival: Vector2 = hero.position
	await runner.frames(2)
	var starts: Array[Vector2] = []
	for enemy in zone.enemies():
		starts.append(enemy.position)

	# Defeat one Puffhop, hurt another, wander off, then fall.
	zone.enemies()[0].take_swing(Tuning.PUFFHOP_HEALTH, Vector2.RIGHT)
	zone.enemies()[0].take_swing(Tuning.FULL_STRENGTH_DAMAGE, Vector2.RIGHT)
	runner.check_equal(zone.enemies().size(), 2, "one defeated")
	hero.position = arrival + Vector2(40, -30)
	hero.health.take(Tuning.HERO_HEALTH - 1)
	hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.LEFT)
	runner.check(hero.is_fallen(), "fallen")

	await runner.frames(int(Tuning.HERO_FALLEN_SECONDS * 60.0) - 10)
	runner.check(hero.is_fallen(), "lies there for a moment first")
	await runner.frames(20)

	runner.check(not hero.is_fallen(), "back on his feet")
	runner.check_equal(hero.position, arrival, "where he entered the Zone")
	runner.check_equal(hero.health.current, Tuning.HERO_HEALTH, "unhurt")
	runner.check(hero.gauge.is_full(), "ready to Swing")
	var enemies: Array = zone.enemies()
	runner.check_equal(enemies.size(), 3, "all three Puffhops back")
	for enemy in enemies:
		runner.check_equal(enemy.health.current, Tuning.PUFFHOP_HEALTH, "Puffhop unhurt")
		runner.check(enemy.position.distance_to(_nearest(starts, enemy.position)) < 6.0, "Puffhop near its starting place")
	zone.free()


func test_respawn_after_coming_through_an_entrance_returns_there() -> void:
	var zone := _open(WOODS, "West")
	var hero := _hero_in(zone)
	var arrival: Vector2 = zone.get_node("Entrances/West").arrival_point()
	runner.check_equal(hero.position, arrival, "arrives beside the Entrance")
	hero.position = arrival + Vector2(60, 0)
	hero.health.take(Tuning.HERO_HEALTH)
	hero.take_contact(1, Vector2.LEFT)
	await runner.frames(int(Tuning.HERO_FALLEN_SECONDS * 60.0) + 10)
	runner.check(not hero.is_fallen(), "back on his feet")
	runner.check_equal(hero.position, arrival, "back beside the Entrance he came through")
	zone.free()


func test_water_is_solid_but_the_bridge_is_not() -> void:
	var zone := _open(CLEARING)
	var hero := _hero_in(zone)
	_remove_enemies(zone)
	# North of the bridge the river blocks him.
	hero.position = Vector2(23 * 16, 11 * 16)
	Input.action_press("move_right")
	await runner.frames(120)
	runner.check(hero.position.x < 26 * 16, "stopped at the river bank, x is %s" % hero.position.x)
	# On the path the bridge carries him over.
	hero.position = Vector2(24 * 16, 15 * 16)
	await runner.frames(120)
	Input.action_release("move_right")
	runner.check(hero.position.x > 29 * 16, "crossed the bridge, x is %s" % hero.position.x)
	zone.free()


func test_thicket_and_the_zone_edge_are_solid() -> void:
	var zone := _open(CLEARING)
	var hero := _hero_in(zone)
	_remove_enemies(zone)
	Input.action_press("move_left")
	await runner.frames(150)
	Input.action_release("move_left")
	runner.check(hero.position.x > 2 * 16, "stopped by the thicket, x is %s" % hero.position.x)
	zone.free()


## A Zone with a Hero in it, arrived through `entrance` (or at the Start).
func _open(path: String, entrance := "") -> Node2D:
	for action in ACTIONS:
		Input.action_release(action)
	var zone: Node2D = load(path).instantiate()
	runner.root.add_child(zone)
	zone.receive(HERO.instantiate(), entrance)
	return zone


func _hero_in(zone: Node2D) -> CharacterBody2D:
	return zone.get_node("Things/Hero")


func _remove_enemies(zone: Node2D) -> void:
	for enemy in zone.enemies():
		enemy.free()


func _nearest(points: Array[Vector2], to: Vector2) -> Vector2:
	var best := points[0]
	for point in points:
		if point.distance_to(to) < best.distance_to(to):
			best = point
	return best
