## Opens the game and saves what the window shows at a few moments: the
## start, the bridge, and the Deep Woods after a Transition. Needs a real
## window (not --headless):
##
##   godot --path . -s tools/screenshot.gd -- /path/to/folder
##
## It writes start.png, hud.png, bridge.png and woods.png into the folder.
extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var folder := OS.get_cmdline_user_args()[0]
	var scene: PackedScene = load(ProjectSettings.get_setting("application/run/main_scene"))
	var world: Node = scene.instantiate()
	root.add_child(world)
	await _wait(20)
	_save(folder + "/start.png")

	# Hurt and part-way through recharging, to show the HUD off its defaults.
	world.hero.health.take(38)
	await _hold("swing", 3)
	await _wait(60)
	_save(folder + "/hud.png")
	world.hero.health.restore()

	world.hero.position = Vector2(400, 244)
	await _hold("move_right", 6)
	await _wait(4)
	_save(folder + "/bridge.png")

	world.hero.position = Vector2(622, 240)
	Input.action_press("move_right")
	for i in 200:
		await physics_frame
		if world.zone.name == "DeepWoods" and not world.is_travelling():
			break
	await _hold("move_right", 150)
	await _hold("move_up", 30)
	await _wait(4)
	_save(folder + "/woods.png")
	quit()


func _save(path: String) -> void:
	root.get_texture().get_image().save_png(path)
	print("saved ", path)


func _wait(frames: int) -> void:
	for i in frames:
		await physics_frame
	await process_frame


func _hold(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames:
		await physics_frame
	Input.action_release(action)
