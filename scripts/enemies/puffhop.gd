## A Puffhop: an Enemy that moves by hopping. It wanders until it notices the
## Hero, then hops after him, and harms him by touch.
## Its origin is at its feet.
extends CharacterBody2D

const Tuning := preload("res://scripts/tuning.gd")
const Health := preload("res://scripts/combat/health.gd")

## Emitted once, when its health runs out.
signal defeated

const SPRITE_REST_OFFSET := -8.0

var health := Health.new(Tuning.PUFFHOP_HEALTH)
## The Zone it must stay inside. Left empty, it is not confined.
var bounds := Rect2()

var _chasing := false
var _hop_direction := Vector2.ZERO
var _hop_time := 0.0     # seconds left in the air; 0 on the ground
var _rest_time := 0.0    # seconds left before the next hop
var _stun_time := 0.0
var _knock_time := 0.0
var _knock_velocity := Vector2.ZERO
var _flash := 0.0
var _defeated := false
var _rng := RandomNumberGenerator.new()

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _touch: Area2D = $Touch
@onready var _hop_sound: AudioStreamPlayer2D = $Sounds/Hop
@onready var _struck_sound: AudioStreamPlayer2D = $Sounds/Struck
@onready var _defeated_sound: AudioStreamPlayer2D = $Sounds/Defeated


func _ready() -> void:
	add_to_group("enemy")
	_rng.randomize()
	_rest_time = _rng.randf_range(0.2, 1.0)
	_sprite.play(&"idle")


## Whether a Puffhop this far from the Hero is after him. One that is already
## chasing keeps it up for longer than it takes to start.
static func keeps_chasing(distance: float, chasing: bool) -> bool:
	if chasing:
		return distance <= Tuning.PUFFHOP_GIVE_UP_DISTANCE
	return distance <= Tuning.PUFFHOP_NOTICE_DISTANCE


func is_chasing() -> bool:
	return _chasing


func is_stunned() -> bool:
	return _stun_time > 0.0


func is_defeated() -> bool:
	return _defeated


## Struck by a Swing: hurt, knocked `away`, and Stunned.
func take_swing(damage: int, away: Vector2) -> void:
	if _defeated:
		return
	_flash = 1.0
	_land()
	if health.take(damage):
		_be_defeated()
		return
	_struck_sound.play()
	_knock_velocity = away * Tuning.KNOCKBACK_SPEED
	_knock_time = Tuning.KNOCKBACK_SECONDS
	_stun_time = Tuning.PUFFHOP_STUN_SECONDS


func _physics_process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 5.0)
	(_sprite.material as ShaderMaterial).set_shader_parameter("flash", _flash)
	if _defeated:
		return
	if _knock_time > 0.0:
		_knock_time -= delta
		velocity = _knock_velocity
		move_and_slide()
		_stay_in_bounds()
	if _stun_time > 0.0:
		_stun_time -= delta
		return
	_hop_or_rest(delta)
	_stay_in_bounds()
	_harm_hero_on_touch()


func _hop_or_rest(delta: float) -> void:
	var hero := _hero()
	_chasing = hero != null and keeps_chasing(global_position.distance_to(hero.global_position), _chasing)
	if _hop_time > 0.0:
		_hop_time -= delta
		var speed := Tuning.PUFFHOP_CHASE_SPEED if _chasing else Tuning.PUFFHOP_WANDER_SPEED
		velocity = _hop_direction * speed
		move_and_slide()
		var progress := 1.0 - maxf(_hop_time, 0.0) / Tuning.PUFFHOP_HOP_SECONDS
		_sprite.offset.y = SPRITE_REST_OFFSET - sin(progress * PI) * Tuning.PUFFHOP_HOP_HEIGHT
		if _hop_time <= 0.0:
			_land()
		return
	_rest_time -= delta
	if _rest_time > 0.0:
		return
	if _chasing:
		_hop_direction = global_position.direction_to(hero.global_position)
	else:
		_hop_direction = Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU))
	_hop_time = Tuning.PUFFHOP_HOP_SECONDS
	_hop_sound.play()
	_sprite.stop()
	_sprite.frame = 0


func _land() -> void:
	_hop_time = 0.0
	_sprite.offset.y = SPRITE_REST_OFFSET
	_sprite.play(&"idle")
	if _chasing:
		_rest_time = Tuning.PUFFHOP_CHASE_REST_SECONDS
	else:
		_rest_time = _rng.randf_range(Tuning.PUFFHOP_WANDER_REST_MIN_SECONDS, Tuning.PUFFHOP_WANDER_REST_MAX_SECONDS)


func _harm_hero_on_touch() -> void:
	for body in _touch.get_overlapping_bodies():
		if body.has_method("take_contact"):
			var away := global_position.direction_to(body.global_position)
			if away == Vector2.ZERO:
				away = Vector2.DOWN
			body.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, away)


func _stay_in_bounds() -> void:
	if bounds.size != Vector2.ZERO:
		global_position = global_position.clamp(bounds.position, bounds.end)


func _be_defeated() -> void:
	_defeated = true
	remove_from_group("enemy")
	collision_layer = 0
	defeated.emit()
	_defeated_sound.play()
	var fade := create_tween()
	fade.tween_property(_sprite, "modulate:a", 0.0, 0.3)
	# Linger a moment unseen so the sound is not cut off.
	fade.tween_interval(0.1)
	fade.tween_callback(queue_free)


# The Hero, unless there is none or he is Fallen.
func _hero() -> Node2D:
	var hero := get_tree().get_first_node_in_group("hero") as Node2D
	if hero == null or hero.is_fallen():
		return null
	return hero
