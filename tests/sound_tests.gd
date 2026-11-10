extends RefCounted

const HERO := preload("res://scenes/hero/hero.tscn")
const PUFFHOP := preload("res://scenes/enemies/puffhop.tscn")
const WORLD := preload("res://scenes/world.tscn")
const Tuning := preload("res://scripts/tuning.gd")
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "swing"]

var runner: SceneTree
var _stage: Node2D


func test_every_sound_player_has_a_sound_to_play() -> void:
	for scene in [HERO, PUFFHOP, WORLD]:
		var root: Node = scene.instantiate()
		var players := root.find_children("*", "AudioStreamPlayer", true, false)
		players.append_array(root.find_children("*", "AudioStreamPlayer2D", true, false))
		runner.check(players.size() > 0, "%s has sound players" % root.name)
		for player in players:
			var stream: AudioStream = player.stream
			runner.check(stream != null and stream.get_length() > 0.05, "%s/%s has a sound" % [root.name, player.name])
		root.free()


func test_a_swing_is_heard_and_a_weak_one_sounds_higher() -> void:
	var hero := _spawn(HERO)
	var sound: AudioStreamPlayer = hero.get_node("Sounds/Swing")
	await runner.frames(2)
	await _press_swing()
	runner.check(sound.playing, "heard")
	runner.check_equal(sound.pitch_scale, 1.0, "Full-Strength Swing at normal pitch")
	await runner.frames(22)
	await _press_swing()
	runner.check(sound.pitch_scale > 1.3, "weak Swing pitched up, at %s" % sound.pitch_scale)
	_finish()


func test_the_gauge_filling_is_heard_once_it_is_full() -> void:
	var hero := _spawn(HERO)
	var sound: AudioStreamPlayer = hero.get_node("Sounds/GaugeFull")
	await runner.frames(10)
	runner.check(not sound.playing, "silent while it simply starts full")
	await _press_swing()
	var heard_early := false
	for i in 200:
		if hero.gauge.is_full():
			break
		heard_early = heard_early or sound.playing
		await runner.frames(1)
	runner.check(not heard_early, "silent while refilling")
	runner.check(hero.gauge.is_full(), "gauge refilled")
	runner.check(sound.playing, "heard as it fills")
	_finish()


func test_being_hurt_and_falling_are_heard() -> void:
	var hero := _spawn(HERO)
	await runner.frames(2)
	hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.LEFT)
	runner.check(hero.get_node("Sounds/Hurt").playing, "hurt")
	runner.check(not hero.get_node("Sounds/Fallen").playing, "not fallen yet")
	await runner.frames(int(Tuning.MERCY_SECONDS * 60.0) + 4)
	hero.take_contact(Tuning.HERO_HEALTH, Vector2.LEFT)
	runner.check(hero.get_node("Sounds/Fallen").playing, "fallen")
	_finish()


func test_a_puffhop_is_heard_when_struck_and_when_defeated() -> void:
	var puffhop := _spawn(PUFFHOP)
	await runner.frames(2)
	puffhop.take_swing(1, Vector2.RIGHT)
	runner.check(puffhop.get_node("Sounds/Struck").playing, "struck")
	puffhop.take_swing(Tuning.PUFFHOP_HEALTH, Vector2.RIGHT)
	runner.check(puffhop.get_node("Sounds/Defeated").playing, "defeated")
	_finish()


func test_a_puffhop_hop_is_heard() -> void:
	var puffhop := _spawn(PUFFHOP)
	var sound: AudioStreamPlayer2D = puffhop.get_node("Sounds/Hop")
	var heard := false
	for i in 200:
		heard = heard or sound.playing
		await runner.frames(1)
	runner.check(heard, "hopped within a few seconds")
	_finish()


func test_the_world_plays_looping_music_and_marks_a_transition() -> void:
	var world := WORLD.instantiate()
	runner.root.add_child(world)
	await runner.frames(2)
	var music: AudioStreamPlayer = world.get_node("Music")
	runner.check(music.playing, "music playing")
	runner.check_equal((music.stream as AudioStreamWAV).loop_mode, AudioStreamWAV.LOOP_FORWARD, "music repeats")
	runner.check_equal(music.volume_db, Tuning.MUSIC_VOLUME_DB, "at the tuned loudness")
	world.travel("res://scenes/zones/deep_woods.tscn", "West")
	runner.check(world.get_node("TransitionSound").playing, "Transition heard")
	for i in 120:
		await runner.frames(1)
		if not world.is_travelling():
			break
	runner.check(music.playing, "music carries on in the new Zone")
	world.free()


func _spawn(scene: PackedScene) -> CharacterBody2D:
	for action in ACTIONS:
		Input.action_release(action)
	_stage = Node2D.new()
	runner.root.add_child(_stage)
	var body: CharacterBody2D = scene.instantiate()
	_stage.add_child(body)
	return body


func _press_swing() -> void:
	Input.action_press("swing")
	await runner.frames(2)
	Input.action_release("swing")


func _finish() -> void:
	for action in ACTIONS:
		Input.action_release(action)
	_stage.free()
	_stage = null
