## An Entrance: a place on a Zone's boundary where the Hero leaves to, or
## arrives from, a neighbouring Zone. Its name is how the neighbour refers to it.
extends Area2D

## Emitted when the Hero steps (or is knocked) onto it.
signal hero_entered(entrance: Area2D)

## The Zone this leads to, and the name of the matching Entrance there.
@export_file("*.tscn") var to_zone := ""
@export var to_entrance := ""
## Where the Hero stands on arriving here, relative to this Entrance. It must
## be clear of the Entrance itself, or he would leave again at once.
@export var arrival_offset := Vector2.ZERO


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1
	body_entered.connect(_on_body_entered)


## Where the Hero stands on arriving through this Entrance.
func arrival_point() -> Vector2:
	return position + arrival_offset


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("hero"):
		hero_entered.emit(self)
