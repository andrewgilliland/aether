-- Builds art/slash.aseprite: the arc a Swing's blade leaves in the air, drawn
-- for a Swing to the right. The game turns it in quarter turns for the other
-- Facings. The Hero stands at (6, 24) in this 32x48 frame.
-- Run inside Aseprite (batch): dofile this file.
local M = dofile("/Users/andrewgilliland/Code/Godot/aether/art/tools/pixel.lua")
local W, H = 32, 48
local CX, CY = 6, 24
local OUTER = 22        -- reach of the blade tip
local INNER_SHIFT = 6   -- the inner edge is a circle centred this far behind him
local INNER = 22.5

-- A crescent, thickest straight ahead and tapering to points above and below.
-- `from` and `to` bound the angle in degrees (0 is straight ahead, negative is up).
local function crescent(from, to, keys)
  local img = Image(W, H, ColorMode.RGB)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local dx, dy = x - CX, y - CY
      local d = math.sqrt(dx * dx + dy * dy)
      local ix = x - (CX - INNER_SHIFT)
      local d2 = math.sqrt(ix * ix + dy * dy)
      local angle = math.deg(math.atan(dy, dx))
      if d <= OUTER and d2 >= INNER and angle >= from and angle <= to then
        local key
        if d > OUTER - 1.2 then key = keys[1]
        elseif d2 < INNER + 1.2 then key = keys[3]
        else key = keys[2] end
        img:drawPixel(x, y, M.col[key])
      end
    end
  end
  return img
end

local frames = {
  crescent(-80, -5, { "W", "f", "w" }),  -- the blade starts above
  crescent(-80, 80, { "W", "W", "f" }),  -- the full arc, brightest
  crescent(10, 80, { "f", "w", "w" }),   -- the tail fades below
}
local s = M.new_sprite(W, H)
for i, img in ipairs(frames) do
  if i > 1 then s:newEmptyFrame() end
  s:newCel(s.layers[1], i, img, Point(0, 0))
  s.frames[i].duration = 0.1
end
M.tag(s, "slash", 1, 3).repeats = 1
s:saveAs(M.ART .. "slash.aseprite")
return s
