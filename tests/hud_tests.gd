extends RefCounted

const WORLD := preload("res://scenes/world.tscn")
const HudText := preload("res://scripts/hud/hud_text.gd")
const PixelFont := preload("res://scripts/hud/pixel_font.gd")
const Tuning := preload("res://scripts/tuning.gd")

var runner: SceneTree


func test_health_reads_as_current_over_maximum() -> void:
	runner.check_equal(HudText.health(50, 50), "50/50", "unhurt")
	runner.check_equal(HudText.health(5, 50), "5/50", "nearly gone")
	runner.check_equal(HudText.health(0, 50), "0/50", "none left")


func test_gauge_reads_as_a_whole_percentage() -> void:
	runner.check_equal(HudText.gauge(0.0), "0%", "empty")
	runner.check_equal(HudText.gauge(0.4), "40%", "part way")
	runner.check_equal(HudText.gauge(1.0), "100%", "full")


func test_gauge_never_reads_full_before_it_is() -> void:
	runner.check_equal(HudText.gauge(0.999), "99%", "almost full is not full")


func test_health_is_low_at_three_tenths_or_less() -> void:
	runner.check(not HudText.is_low_health(20, 50), "20 of 50 is not low")
	runner.check(HudText.is_low_health(15, 50), "15 of 50 is low")
	runner.check(HudText.is_low_health(0, 50), "0 is low")


func test_the_font_has_every_glyph_the_hud_uses() -> void:
	for text in ["HP", HudText.health(50, 50), HudText.gauge(1.0), "0123456789"]:
		for i in text.length():
			runner.check(PixelFont.GLYPHS.contains(text[i]), "glyph for '%s'" % text[i])
	var sheet_width: int = PixelFont.SHEET.get_width()
	runner.check_equal(sheet_width, PixelFont.GLYPHS.length() * PixelFont.CELL.x, "sheet holds exactly those glyphs")


func test_the_hud_follows_the_hero() -> void:
	var world := WORLD.instantiate()
	runner.root.add_child(world)
	for enemy in world.zone.enemies():
		enemy.free()
	var hud: Control = world.get_node("Hud/Readout")
	await runner.frames(2)
	runner.check_equal(hud.reading(), "HP 50/50 100%", "at the start")
	world.hero.take_contact(Tuning.PUFFHOP_CONTACT_DAMAGE, Vector2.LEFT)
	runner.check_equal(hud.reading(), "HP 45/50 100%", "after a touch")
	await runner.frames(20)
	Input.action_press("swing")
	await runner.frames(3)
	Input.action_release("swing")
	runner.check_equal(hud.reading(), "HP 45/50 0%", "mid-Swing")
	await runner.frames(int((Tuning.SWING_SECONDS + Tuning.RECHARGE_SECONDS) * 60.0) + 6)
	runner.check_equal(hud.reading(), "HP 45/50 100%", "recharged")
	world.free()
