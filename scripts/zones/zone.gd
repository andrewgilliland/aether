## A Zone: one self-contained area of the World, holding the Hero while he is
## in it and the Enemies that live there.
##
## A Zone that is entered is reset: its Enemies are back at their starting
## places, unhurt. A Respawn counts as entering.
##
## A Zone scene needs these children:
##   Things         y-sorted Node2D; the Hero and Enemies are put here
##   PuffhopStarts  Marker2D children, one per Puffhop
##   Entrances      entrance.gd children, named as neighbours refer to them
##   Start          optional Marker2D: where the Hero stands if he did not
##                  come through an Entrance (the start of the game)
extends Node2D

const Tuning := preload("res://scripts/tuning.gd")
const PUFFHOP := preload("res://scenes/enemies/puffhop.tscn")

const TILE := 16
## How far inside the Zone's edge Enemies are kept.
const ENEMY_MARGIN := 8.0
const WALL_THICKNESS := 16.0

## Emitted when the Hero steps onto an Entrance: he is bound for `to_entrance`
## in the Zone scene at `to_zone`.
signal hero_leaving(to_zone: String, to_entrance: String)

@export var size_in_tiles := Vector2i(40, 30)

## The Zone's extent, in pixels.
var bounds := Rect2()

var _hero: CharacterBody2D
var _arrival := Vector2.ZERO
var _fallen_timer: Timer

@onready var _things: Node2D = $Things


func _ready() -> void:
	bounds = Rect2(Vector2.ZERO, Vector2(size_in_tiles * TILE))
	_fallen_timer = Timer.new()
	_fallen_timer.one_shot = true
	_fallen_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	_fallen_timer.timeout.connect(respawn)
	add_child(_fallen_timer)
	for entrance in $Entrances.get_children():
		entrance.hero_entered.connect(_on_entrance_entered)
	_wall_in()


## The Hero enters the Zone through the Entrance named `entrance_name`, or at
## the Start if no name is given. He arrives as he is: hurt stays hurt.
func receive(hero: CharacterBody2D, entrance_name := "") -> void:
	_hero = hero
	if entrance_name == "":
		_arrival = ($Start as Marker2D).position
	else:
		_arrival = $Entrances.get_node(entrance_name).arrival_point()
	_things.add_child(hero)
	hero.position = _arrival
	hero.fell.connect(_on_hero_fell)
	var camera: Camera2D = hero.get_node("Camera")
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
	camera.reset_smoothing()
	reset_enemies()


## The Hero leaves the Zone; he is handed back, out of the scene.
func release() -> CharacterBody2D:
	var hero := _hero
	hero.fell.disconnect(_on_hero_fell)
	_fallen_timer.stop()
	_things.remove_child(hero)
	_hero = null
	return hero


## The Enemies alive in the Zone now.
func enemies() -> Array[Node]:
	var found: Array[Node] = []
	for thing in _things.get_children():
		if thing.is_in_group("enemy"):
			found.append(thing)
	return found


## Put every Enemy back at its starting place, unhurt.
func reset_enemies() -> void:
	for thing in _things.get_children():
		if thing.has_method("take_swing"):
			thing.remove_from_group("enemy")
			thing.queue_free()
	for start in $PuffhopStarts.get_children():
		var puffhop := PUFFHOP.instantiate()
		puffhop.position = (start as Marker2D).position
		puffhop.bounds = bounds.grow(-ENEMY_MARGIN)
		_things.add_child(puffhop)


## Respawn: the Hero returns, unhurt, to where he entered, and the Zone resets.
func respawn() -> void:
	reset_enemies()
	_hero.revive(_arrival)


func _on_hero_fell() -> void:
	_fallen_timer.start(Tuning.HERO_FALLEN_SECONDS)


func _on_entrance_entered(entrance: Area2D) -> void:
	if _hero != null and not _hero.is_fallen():
		hero_leaving.emit(entrance.to_zone, entrance.to_entrance)


# Solid walls just outside the Zone's edges, so nothing walks off it.
func _wall_in() -> void:
	var t := WALL_THICKNESS
	var walls: Array[Rect2] = [
		Rect2(bounds.position.x - t, bounds.position.y - t, bounds.size.x + 2 * t, t),
		Rect2(bounds.position.x - t, bounds.end.y, bounds.size.x + 2 * t, t),
		Rect2(bounds.position.x - t, bounds.position.y, t, bounds.size.y),
		Rect2(bounds.end.x, bounds.position.y, t, bounds.size.y),
	]
	for wall in walls:
		var body := StaticBody2D.new()
		body.position = wall.get_center()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = wall.size
		shape.shape = box
		body.add_child(shape)
		add_child(body)
