## Draws text in the game's pixel font (art/font.aseprite).
## It has only the glyphs the HUD needs; anything else is left as a gap.
extends RefCounted

const SHEET := preload("res://assets/font.png")
## The glyphs in the sheet, left to right. Must match art/tools/font.lua.
const GLYPHS := "0123456789HP/%"
## Each glyph's cell in the sheet, outline included.
const CELL := Vector2i(7, 9)
## How far each letter moves the pen: neighbouring outlines share a column.
const ADVANCE := 6


## Draw `text` on `canvas` with its top-left corner at `at`. `tint` colours
## the letters; their outline stays dark.
static func draw(canvas: CanvasItem, text: String, at: Vector2, tint := Color.WHITE) -> void:
	for i in text.length():
		var glyph := GLYPHS.find(text[i])
		if glyph < 0:
			continue
		var from := Rect2(Vector2(glyph * CELL.x, 0), CELL)
		canvas.draw_texture_rect_region(SHEET, Rect2(at + Vector2(i * ADVANCE, 0), CELL), from, tint)


## Width of `text` in pixels.
static func width(text: String) -> int:
	if text.is_empty():
		return 0
	return (text.length() - 1) * ADVANCE + CELL.x
