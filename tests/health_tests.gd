extends RefCounted

const Health := preload("res://scripts/combat/health.gd")
const MercyWindow := preload("res://scripts/combat/mercy_window.gd")
const Tuning := preload("res://scripts/tuning.gd")

var runner: SceneTree


func test_health_starts_full() -> void:
	var health := Health.new(50)
	runner.check_equal(health.current, 50, "current")
	runner.check_equal(health.fraction(), 1.0, "fraction")
	runner.check(not health.is_spent(), "not spent")


func test_taking_damage_lowers_it() -> void:
	var health := Health.new(50)
	runner.check(not health.take(5), "survives 5")
	runner.check_equal(health.current, 45, "45 left")


func test_it_never_goes_below_zero_and_reports_running_out() -> void:
	var health := Health.new(25)
	health.take(10)
	health.take(10)
	runner.check(health.take(10), "third hit of 10 uses up 25")
	runner.check_equal(health.current, 0, "stops at zero")
	runner.check(health.is_spent(), "spent")


func test_negative_damage_does_not_heal() -> void:
	var health := Health.new(50)
	health.take(20)
	health.take(-10)
	runner.check_equal(health.current, 30, "unchanged by negative damage")


func test_restore_refills_it() -> void:
	var health := Health.new(50)
	health.take(50)
	health.restore()
	runner.check_equal(health.current, 50, "full again")


func test_mercy_window_is_closed_until_opened() -> void:
	var mercy := MercyWindow.new()
	runner.check(not mercy.is_open(), "closed at first")
	mercy.open()
	runner.check(mercy.is_open(), "open after a blow")


func test_mercy_window_closes_after_its_time() -> void:
	var mercy := MercyWindow.new()
	mercy.open()
	mercy.advance(Tuning.MERCY_SECONDS * 0.9)
	runner.check(mercy.is_open(), "still open at 90%")
	mercy.advance(Tuning.MERCY_SECONDS * 0.2)
	runner.check(not mercy.is_open(), "closed once the time is up")
