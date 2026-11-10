-- Drawing helper for building Aether's sprites inside Aseprite.
-- Every sprite uses the one shared palette below; each colour has a
-- one-character key so a sprite can be written as rows of text.
local M = {}

M.ART = "/Users/andrewgilliland/Code/Godot/aether/art/"

-- Order here is the order in art/aether.gpl.
M.order = {
  { "K", "1f1633", "ink" },
  { "P", "3a2a52", "shadow" },
  { "p", "5a4a78", "dusk" },
  { "1", "12402e", "deep green" },
  { "2", "1e6a3a", "forest green" },
  { "3", "3a9a3c", "leaf green" },
  { "4", "6cc24a", "grass green" },
  { "5", "a8e05c", "light grass" },
  { "6", "dff29a", "pale leaf" },
  { "d", "4a2a1e", "dark brown" },
  { "D", "7a4a2a", "brown" },
  { "t", "b07a44", "tan" },
  { "T", "dcb070", "sand" },
  { "u", "f2dca4", "pale sand" },
  { "s", "c0704a", "skin shadow" },
  { "S", "eaa878", "skin" },
  { "l", "fbd6ae", "skin light" },
  { "h", "7a2a1a", "hair dark" },
  { "H", "b84a22", "hair" },
  { "i", "e87a34", "hair light" },
  { "n", "1e2e6e", "navy" },
  { "B", "2e5ab8", "blue" },
  { "b", "4e94e8", "sky blue" },
  { "w", "8accf4", "light water" },
  { "f", "d4f0fc", "foam" },
  { "g", "5c6682", "steel dark" },
  { "G", "9aa6c0", "steel" },
  { "W", "f8f8f0", "white" },
  { "o", "c07a18", "gold dark" },
  { "Y", "f0c030", "yellow" },
  { "y", "fce88a", "light yellow" },
  { "R", "d83848", "red" },
}

M.col = {}
for _, e in ipairs(M.order) do
  local r = tonumber(e[2]:sub(1, 2), 16)
  local g = tonumber(e[2]:sub(3, 4), 16)
  local b = tonumber(e[2]:sub(5, 6), 16)
  M.col[e[1]] = Color { r = r, g = g, b = b, a = 255 }
end

function M.palette()
  local pal = Palette(#M.order)
  for i, e in ipairs(M.order) do
    pal:setColor(i - 1, M.col[e[1]])
  end
  return pal
end

-- New RGB sprite carrying the shared palette.
function M.new_sprite(w, h)
  local s = Sprite(w, h, ColorMode.RGB)
  s:setPalette(M.palette())
  return s
end

-- Draw text rows onto an image. "." is transparent.
-- flip=true mirrors the rows horizontally.
function M.stamp(img, rows, ox, oy, flip)
  ox = ox or 0
  oy = oy or 0
  local w = #rows[1]
  for y, row in ipairs(rows) do
    if #row ~= w then
      error("row " .. y .. " is " .. #row .. " wide, expected " .. w .. ": " .. row)
    end
    for x = 1, w do
      local ch = row:sub(x, x)
      if ch ~= "." then
        local c = M.col[ch]
        if not c then error("unknown colour key '" .. ch .. "' in row " .. y) end
        local px = flip and (w - x) or (x - 1)
        img:drawPixel(ox + px, oy + y - 1, c)
      end
    end
  end
end

-- Build an image from rows.
function M.image(rows, flip)
  local img = Image(#rows[1], #rows, ColorMode.RGB)
  M.stamp(img, rows, 0, 0, flip)
  return img
end

-- Fill a sprite with one frame per entry of `frames` (each a list of rows),
-- on its first layer. Returns the sprite.
function M.sprite_from_frames(frames, duration)
  local w, h = #frames[1][1], #frames[1]
  local s = M.new_sprite(w, h)
  local layer = s.layers[1]
  for i, rows in ipairs(frames) do
    if i > 1 then s:newEmptyFrame() end
    s:newCel(layer, i, M.image(rows), Point(0, 0))
    s.frames[i].duration = duration or 0.15
  end
  return s
end

function M.tag(sprite, name, from, to)
  local t = sprite:newTag(from, to)
  t.name = name
  return t
end

return M
