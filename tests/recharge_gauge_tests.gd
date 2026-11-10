extends RefCounted

const RechargeGauge := preload("res://scripts/combat/recharge_gauge.gd")
const Swing := preload("res://scripts/combat/swing.gd")
const Facing := preload("res://scripts/hero/facing.gd")
const Tuning := preload("res://scripts/tuning.gd")

var runner: SceneTree


func test_gauge_starts_full() -> void:
	var gauge := RechargeGauge.new()
	runner.check(gauge.is_full(), "full at the start")


func test_spending_empties_it_and_reports_the_level_spent() -> void:
	var gauge := RechargeGauge.new()
	runner.check_equal(gauge.spend(), 1.0, "spent at full")
	runner.check_equal(gauge.level, 0.0, "empty afterwards")
	runner.check_equal(gauge.spend(), 0.0, "spent again at empty")


func test_it_refills_over_the_recharge_time() -> void:
	var gauge := RechargeGauge.new()
	gauge.spend()
	gauge.advance(Tuning.RECHARGE_SECONDS * 0.4)
	runner.check(absf(gauge.level - 0.4) < 0.001, "40%% of the way, got %s" % gauge.level)
	runner.check(not gauge.is_full(), "not yet full")
	gauge.advance(Tuning.RECHARGE_SECONDS)
	runner.check_equal(gauge.level, 1.0, "never above full")
	runner.check(gauge.is_full(), "full again")


func test_full_strength_swing_does_full_damage() -> void:
	runner.check_equal(Swing.damage(1.0), Tuning.FULL_STRENGTH_DAMAGE, "at 100%")


func test_damage_is_proportional_to_the_gauge() -> void:
	runner.check_equal(Swing.damage(0.4), 4, "at 40%")
	runner.check_equal(Swing.damage(0.75), 8, "at 75%")


func test_damage_is_never_below_the_minimum() -> void:
	runner.check_equal(Swing.damage(0.0), 1, "at 0%")
	runner.check_equal(Swing.damage(0.04), 1, "at 4%")


func test_reach_lies_ahead_of_the_swinger() -> void:
	var origin := Vector2(100, 100)
	for facing in [Facing.DOWN, Facing.UP, Facing.LEFT, Facing.RIGHT]:
		var ahead: Vector2 = Facing.VECTORS[facing]
		var reach := Swing.reach(origin, facing)
		runner.check(reach.has_point(origin + ahead * 14.0), "covers just ahead, facing %s" % Facing.NAMES[facing])
		runner.check(not reach.has_point(origin - ahead * 8.0), "not behind, facing %s" % Facing.NAMES[facing])
		runner.check(not reach.has_point(origin + ahead * 40.0), "not far away, facing %s" % Facing.NAMES[facing])


func test_reach_is_wider_across_than_along() -> void:
	var right := Swing.reach(Vector2.ZERO, Facing.RIGHT)
	runner.check(right.size.y > right.size.x, "facing right it is taller than deep")
	var down := Swing.reach(Vector2.ZERO, Facing.DOWN)
	runner.check(down.size.x > down.size.y, "facing down it is wider than deep")
