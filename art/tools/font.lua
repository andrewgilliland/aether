-- Builds art/font.aseprite: the HUD's pixel font. Each glyph is 5x7 in white
-- with a one-pixel ink outline, in a 7x9 cell, so it reads over any ground.
-- The glyphs sit left to right in the order of GLYPHS; scripts/hud/pixel_font.gd
-- in the game lists the same order.
-- Run inside Aseprite (batch): dofile this file.
local M = dofile("/Users/andrewgilliland/Code/Godot/aether/art/tools/pixel.lua")

local GLYPHS = "0123456789HP/%"
local SHAPES = {
  ["0"] = { ".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###." },
  ["1"] = { "..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###." },
  ["2"] = { ".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####" },
  ["3"] = { ".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###." },
  ["4"] = { "...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#." },
  ["5"] = { "#####", "#....", "####.", "....#", "....#", "#...#", ".###." },
  ["6"] = { ".###.", "#....", "#....", "####.", "#...#", "#...#", ".###." },
  ["7"] = { "#####", "....#", "...#.", "..#..", "..#..", "..#..", "..#.." },
  ["8"] = { ".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###." },
  ["9"] = { ".###.", "#...#", "#...#", ".####", "....#", "....#", ".###." },
  ["H"] = { "#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#" },
  ["P"] = { "####.", "#...#", "#...#", "####.", "#....", "#....", "#...." },
  ["/"] = { "....#", "....#", "...#.", "..#..", ".#...", "#....", "#...." },
  ["%"] = { "##..#", "##..#", "...#.", "..#..", ".#...", "#..##", "#..##" },
}
local CW, CH = 7, 9

local s = M.new_sprite(CW * #GLYPHS, CH)
local img = Image(s.width, s.height, ColorMode.RGB)
for i = 1, #GLYPHS do
  local shape = SHAPES[GLYPHS:sub(i, i)]
  local ox = (i - 1) * CW + 1
  local function lit(x, y)
    return y >= 1 and y <= 7 and x >= 1 and x <= 5 and shape[y]:sub(x, x) == "#"
  end
  -- Outline first: ink on every empty pixel that touches the glyph.
  for y = 0, 8 do
    for x = 0, 6 do
      if not lit(x, y) then
        local touches = false
        for dy = -1, 1 do
          for dx = -1, 1 do
            if lit(x + dx, y + dy) then touches = true end
          end
        end
        if touches then img:drawPixel(ox - 1 + x, y, M.col["K"]) end
      else
        img:drawPixel(ox - 1 + x, y, M.col["W"])
      end
    end
  end
end
s:newCel(s.layers[1], 1, img, Point(0, 0))
s:saveAs(M.ART .. "font.aseprite")
return { glyphs = #GLYPHS }
