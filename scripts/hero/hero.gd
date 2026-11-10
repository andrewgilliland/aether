## The Hero: the single player-controlled character.
## His origin is at his feet, so sorting by y puts him behind or in front of
## things correctly.
##
## Anything on the "enemy" physics layer with a
## `take_swing(damage: int, away: Vector2)` method can be struck by his Swing.
## Enemies harm him by calling `take_contact`.
extends CharacterBody2D

const Tuning := preload("res://scripts/tuning.gd")
const Facing := preload("res://scripts/hero/facing.gd")
const Health := preload("res://scripts/combat/health.gd")
const MercyWindow := preload("res://scripts/combat/mercy_window.gd")
const RechargeGauge := preload("res://scripts/combat/recharge_gauge.gd")
const Swing := preload("res://scripts/combat/swing.gd")

## Emitted when his health runs out. Whoever holds him decides the Respawn.
signal fell

const ENEMY_LAYER := 1 << 2
## Where a Swing is measured from, relative to his feet.
const SWING_ORIGIN := Vector2(0, -6)
## Seconds each blink lasts while the Mercy Window is open.
const BLINK_SECONDS := 0.08

var facing: int = Facing.DOWN
var health := Health.new(Tuning.HERO_HEALTH)
var gauge := RechargeGauge.new()

var _mercy := MercyWindow.new()
var _fallen := false
var _knock_time := 0.0
var _knock_velocity := Vector2.ZERO

# A Swing in progress: seconds since it began (negative when not swinging),
# the damage it does, and what it has already struck.
var _swing_time := -1.0
var _swing_damage := 0
var _swing_struck: Array[Object] = []

@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _slash: AnimatedSprite2D = $Slash
@onready var _swing_sound: AudioStreamPlayer = $Sounds/Swing
@onready var _hurt_sound: AudioStreamPlayer = $Sounds/Hurt
@onready var _fallen_sound: AudioStreamPlayer = $Sounds/Fallen
@onready var _gauge_full_sound: AudioStreamPlayer = $Sounds/GaugeFull


func _ready() -> void:
	add_to_group("hero")
	_slash.visible = false
	_show_moving(false)


func _physics_process(delta: float) -> void:
	if _fallen:
		return
	_mercy.advance(delta)
	_sprite.visible = not _mercy.is_open() or fmod(_mercy.remaining, BLINK_SECONDS * 2.0) < BLINK_SECONDS
	if _knock_time > 0.0:
		_knock_time -= delta
		velocity = _knock_velocity
		move_and_slide()
		return
	if is_swinging():
		_continue_swing(delta)
		return
	var was_full := gauge.is_full()
	gauge.advance(delta)
	if gauge.is_full() and not was_full:
		_gauge_full_sound.play()
	if Input.is_action_just_pressed("swing"):
		_begin_swing()
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	facing = Facing.from_movement(direction, facing)
	velocity = direction * Tuning.HERO_WALK_SPEED
	move_and_slide()
	_show_moving(direction != Vector2.ZERO)


## True while a Swing roots him in place.
func is_swinging() -> bool:
	return _swing_time >= 0.0


## True from the moment his health runs out until he is revived.
func is_fallen() -> bool:
	return _fallen


## True while he cannot be harmed because he was just struck.
func is_in_mercy_window() -> bool:
	return _mercy.is_open()


## Harmed by touching an Enemy: hurt and knocked `away`, unless the Mercy
## Window is open. Opens the Mercy Window.
func take_contact(damage: int, away: Vector2) -> void:
	if _fallen or _mercy.is_open():
		return
	_end_swing()
	if health.take(damage):
		_fall()
		return
	_hurt_sound.play()
	_mercy.open()
	_knock_velocity = away * Tuning.KNOCKBACK_SPEED
	_knock_time = Tuning.KNOCKBACK_SECONDS
	_play("hurt_")


## Stand him up at `at`, unhurt and ready, as at a Respawn.
func revive(at: Vector2) -> void:
	position = at
	health.restore()
	gauge.level = 1.0
	_mercy.close()
	_fallen = false
	_knock_time = 0.0
	velocity = Vector2.ZERO
	facing = Facing.DOWN
	_sprite.rotation = 0.0
	_sprite.position = Vector2.ZERO
	_sprite.visible = true
	_show_moving(false)


## The name of the animation playing now, e.g. "walk_right".
## Facing left plays the right-facing animation mirrored.
func animation() -> StringName:
	return _sprite.animation


func is_mirrored() -> bool:
	return _sprite.flip_h


func _fall() -> void:
	_fallen = true
	velocity = Vector2.ZERO
	facing = Facing.DOWN
	# The fallen frame is drawn standing, eyes shut; he is laid on his side.
	_sprite.flip_h = false
	_sprite.play(&"fallen")
	_fallen_sound.play()
	_sprite.visible = true
	_sprite.rotation = PI / 2.0
	_sprite.position = Vector2(-16, -10)
	fell.emit()


func _begin_swing() -> void:
	var level := gauge.spend()
	_swing_damage = Swing.damage(level)
	# A weak Swing sounds thinner and higher than a Full-Strength one.
	_swing_sound.pitch_scale = lerpf(Tuning.WEAK_SWING_PITCH, 1.0, level)
	_swing_sound.play()
	_swing_time = 0.0
	_swing_struck.clear()
	velocity = Vector2.ZERO
	_play("swing_")
	_slash.rotation = Facing.VECTORS[facing].angle()
	_slash.show_behind_parent = facing == Facing.UP
	_slash.visible = true
	_slash.play(&"slash")


func _continue_swing(delta: float) -> void:
	_swing_time += delta
	if _swing_time >= Tuning.SWING_WINDUP_SECONDS:
		_strike_what_is_in_reach()
	if _swing_time >= Tuning.SWING_SECONDS:
		_end_swing()
		_show_moving(false)


func _end_swing() -> void:
	_swing_time = -1.0
	_slash.visible = false


# Each thing in reach is struck once per Swing, however long it stays there.
func _strike_what_is_in_reach() -> void:
	var area := Swing.reach(global_position + SWING_ORIGIN, facing)
	var box := RectangleShape2D.new()
	box.size = area.size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = box
	query.transform = Transform2D(0.0, area.get_center())
	query.collision_mask = ENEMY_LAYER
	query.collide_with_areas = true
	for found in get_world_2d().direct_space_state.intersect_shape(query):
		var target: Object = found.collider
		if target in _swing_struck or not target.has_method("take_swing"):
			continue
		_swing_struck.append(target)
		target.take_swing(_swing_damage, Facing.VECTORS[facing])


func _show_moving(walking: bool) -> void:
	_play("walk_" if walking else "idle_")


func _play(prefix: String) -> void:
	var side: int = Facing.RIGHT if facing == Facing.LEFT else facing
	var facing_name: String = Facing.NAMES[side]
	var wanted := StringName(prefix + facing_name)
	_sprite.flip_h = facing == Facing.LEFT
	if _sprite.animation != wanted or not _sprite.is_playing():
		_sprite.play(wanted)
