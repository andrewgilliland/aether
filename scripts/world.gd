## The World: the whole explorable space. It holds the Hero and the one Zone
## he is in, and makes the Transition when he steps onto an Entrance.
extends Node

const HERO := preload("res://scenes/hero/hero.tscn")
const Tuning := preload("res://scripts/tuning.gd")

## The Zone the game starts in; the Hero stands at its Start.
@export_file("*.tscn") var first_zone := "res://scenes/zones/forest_clearing.tscn"

var hero: CharacterBody2D
var zone: Node2D

var _travelling := false

@onready var _zone_holder: Node = $ZoneHolder
@onready var _black: ColorRect = $Fade/Black
@onready var _music: AudioStreamPlayer = $Music
@onready var _transition_sound: AudioStreamPlayer = $TransitionSound


func _ready() -> void:
	hero = HERO.instantiate()
	_black.color.a = 0.0
	$Hud/Readout.watch(hero)
	_enter(first_zone, "")
	_start_music()


## True while a Transition is fading out or in.
func is_travelling() -> bool:
	return _travelling


## Transition: fade out, move the Hero to `to_entrance` in the Zone scene at
## `to_zone`, and fade back in. He arrives as he left, hurt or not.
func travel(to_zone: String, to_entrance: String) -> void:
	if _travelling:
		return
	_travelling = true
	hero.set_physics_process(false)
	zone.process_mode = Node.PROCESS_MODE_DISABLED
	_transition_sound.play()
	await _fade_to(1.0)
	zone.release()
	zone.queue_free()
	_enter(to_zone, to_entrance)
	hero.set_physics_process(true)
	await _fade_to(0.0)
	_travelling = false


func _enter(zone_path: String, entrance_name: String) -> void:
	zone = (load(zone_path) as PackedScene).instantiate()
	_zone_holder.add_child(zone)
	# Deferred: an Entrance reports from inside the physics step, where a Zone
	# may not be switched off.
	zone.hero_leaving.connect(travel, CONNECT_DEFERRED)
	zone.receive(hero, entrance_name)


func _fade_to(alpha: float) -> void:
	var fade := create_tween()
	fade.tween_property(_black, "color:a", alpha, Tuning.TRANSITION_FADE_SECONDS)
	await fade.finished


# The music file is a plain recording; it is told here to repeat end to end.
func _start_music() -> void:
	var loop := _music.stream as AudioStreamWAV
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(loop.get_length() * loop.mix_rate)
	_music.volume_db = Tuning.MUSIC_VOLUME_DB
	_music.play()
