## A Damage Number: the Health a blow just took, shown over whoever took it.
## It stays over them as they are knocked away, drifts upward, fades, and
## removes itself.
extends Node2D

const Tuning := preload("res://scripts/tuning.gd")
const PixelFont := preload("res://scripts/hud/pixel_font.gd")

## Colour of a number over an Enemy, and over the Hero.
const DEALT := Color("f8f8f0")
const TAKEN := Color("d83848")

## The damage shown, in what colour, and who it is shown over.
var amount := 0
var tint := DEALT
var struck: Node2D

var _feet := Vector2.ZERO
var _height := 0.0
var _rise := 0.0


## Show `damage` over `over`, `height` pixels above its feet. The number
## lives beside it, not inside it, so it outlasts an Enemy that is Defeated.
static func pop(over: Node2D, damage: int, colour := DEALT, height := Tuning.DAMAGE_NUMBER_HEIGHT) -> Node2D:
	var number: Node2D = new()
	number.amount = damage
	number.tint = colour
	number.struck = over
	number._feet = over.position
	number._height = height
	over.get_parent().add_child(number)
	return number


func _ready() -> void:
	add_to_group("damage_number")
	# Above everything standing in the Zone, whatever its place in the y-sort.
	z_index = 50
	_place()
	var drift := create_tween()
	drift.set_parallel(true)
	drift.tween_property(self, "_rise", Tuning.DAMAGE_NUMBER_RISE, Tuning.DAMAGE_NUMBER_SECONDS)
	drift.tween_property(self, "modulate:a", 0.0, Tuning.DAMAGE_NUMBER_SECONDS * 0.4).set_delay(Tuning.DAMAGE_NUMBER_SECONDS * 0.6)
	drift.chain().tween_callback(queue_free)


func _process(_delta: float) -> void:
	if is_instance_valid(struck):
		_feet = struck.position
	_place()


func _place() -> void:
	position = (_feet + Vector2(0, -_height - _rise)).round()


func _draw() -> void:
	var text := str(amount)
	var corner := Vector2(-PixelFont.width(text) / 2.0, -PixelFont.CELL.y).round()
	PixelFont.draw(self, text, corner, tint)
