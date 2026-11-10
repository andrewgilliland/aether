## The HUD: the Hero's Health as numbers and his Recharge Gauge as a bar with
## a percentage, along the bottom-left of the screen.
extends Control

const HudText := preload("res://scripts/hud/hud_text.gd")
const PixelFont := preload("res://scripts/hud/pixel_font.gd")

const INK := Color("1f1633")
const SHADOW := Color("3a2a52")
const WHITE := Color("f8f8f0")
const RED := Color("d83848")
const GOLD_DARK := Color("c07a18")
const YELLOW := Color("f0c030")
const LIGHT_YELLOW := Color("fce88a")

## Top of the HUD's one line, and where each part starts along it.
const LINE_Y := 168.0
const LABEL_X := 6.0
const HEALTH_X := 22.0
const BAR := Rect2(60, 169, 50, 7)
const PERCENT_X := 114.0

var _hero: CharacterBody2D


## Show this Hero's Health and Recharge Gauge.
func watch(hero: CharacterBody2D) -> void:
	_hero = hero


## What the HUD reads now, e.g. "HP 45/50 80%". For tests.
func reading() -> String:
	if _hero == null:
		return ""
	return "HP %s %s" % [
		HudText.health(_hero.health.current, _hero.health.maximum),
		HudText.gauge(_hero.gauge.level),
	]


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _hero == null:
		return
	var health = _hero.health
	var low := HudText.is_low_health(health.current, health.maximum)
	PixelFont.draw(self, "HP", Vector2(LABEL_X, LINE_Y))
	PixelFont.draw(self, HudText.health(health.current, health.maximum), Vector2(HEALTH_X, LINE_Y), RED if low else WHITE)

	var level: float = _hero.gauge.level
	var full: bool = _hero.gauge.is_full()
	draw_rect(BAR, INK)
	var inside := BAR.grow(-1)
	draw_rect(inside, SHADOW)
	var filled := Rect2(inside.position, Vector2(roundf(inside.size.x * level), inside.size.y))
	draw_rect(filled, YELLOW if full else GOLD_DARK)
	# A lighter line along the top of the fill gives the bar some roundness.
	draw_rect(Rect2(filled.position, Vector2(filled.size.x, 1)), LIGHT_YELLOW if full else YELLOW)
	PixelFont.draw(self, HudText.gauge(level), Vector2(PERCENT_X, LINE_Y), LIGHT_YELLOW if full else WHITE)
