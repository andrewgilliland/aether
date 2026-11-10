## Runs every tests/*_tests.gd suite headless and exits non-zero on failure.
##
##   godot --headless --path . -s tests/run.gd
##
## A suite extends RefCounted, has a `runner` variable, and any number of
## `test_*` methods that call `runner.check(...)`. Tests may `await`.
extends SceneTree

var _checks := 0
var _failures := 0
var _current := ""


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		print("  FAIL  %s: %s" % [_current, message])


func check_equal(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s (expected %s, got %s)" % [message, expected, actual])


## Wait for `count` physics frames.
func frames(count: int) -> void:
	for i in count:
		await physics_frame


func _run() -> void:
	var files := DirAccess.get_files_at("res://tests")
	files.sort()
	for file in files:
		if not file.ends_with("_tests.gd"):
			continue
		var script: GDScript = load("res://tests/" + file)
		if script == null or not script.can_instantiate():
			_current = file
			check(false, "suite did not load")
			continue
		var suite: RefCounted = script.new()
		suite.set("runner", self)
		for method in suite.get_method_list():
			var method_name: String = method.name
			if method_name.begins_with("test_"):
				_current = "%s %s" % [file, method_name]
				await suite.call(method_name)
	print("%d checks, %d failed" % [_checks, _failures])
	quit(1 if _failures > 0 else 0)
