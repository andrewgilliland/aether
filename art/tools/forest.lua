-- Builds art/forest_tiles.aseprite (a sheet of 16x16 tiles) and art/tree.aseprite.
--
-- Sheet layout, 12 tiles across:
--   row 0      grass_a, grass_b, flowers, bridge, bush, rock
--   rows 1-4   path meeting grass, 47 tiles
--   rows 5-8   water meeting grass, 47 tiles
--   rows 9-12  thicket meeting grass, 47 tiles
-- Each set of 47 holds one tile for every way its eight neighbours can be the
-- same ground or not. tools/build_zones.gd in the game picks them by the same
-- numbering (see blob_masks below).
-- Run inside Aseprite (batch): dofile this file.
local M = dofile("/Users/andrewgilliland/Code/Godot/aether/art/tools/pixel.lua")

local tiles = {}
tiles.grass_a = {
  "4444444444444444",
  "4454444444434444",
  "4544444444344444",
  "4444444444444544",
  "4444434444445444",
  "4444344444444444",
  "4444444454444444",
  "4444444544444444",
  "4344444444444344",
  "3444444444443444",
  "4444445444444444",
  "4444454444444444",
  "4444444444344444",
  "4454444443444444",
  "4544444444444454",
  "4444444444444544",
}
tiles.grass_b = {
  "4444444444444444",
  "4444444444444444",
  "4443444444454444",
  "4434344444545444",
  "4443444444454444",
  "4444444444444444",
  "4444444444444444",
  "4444445444444444",
  "4444454544444344",
  "4444445444443434",
  "4444444444444344",
  "4444444444444444",
  "4544444444444444",
  "5454444434444444",
  "4544444343444444",
  "4444444434444444",
}
tiles.flowers = {
  "................",
  "................",
  "...W............",
  "..WYW......R....",
  "...W......RyR...",
  "...3.......R....",
  "...........3....",
  "................",
  "................",
  ".......W........",
  "......WYW.......",
  ".......W........",
  ".......3........",
  "................",
  "................",
  "................",
}
tiles.path = {
  "TTTTTTTTTTTTTTTT",
  "TTTTuTTTTTTTTtTT",
  "TTTuuTTTTTTTTTTT",
  "TTTTTTTTTtTTTTTT",
  "TTTTTTTTttTTTTTT",
  "TtTTTTTTTTTTTuTT",
  "TTTTTTTTTTTTuuTT",
  "TTTTTuTTTTTTTTTT",
  "TTTTTTTTTTTTTTTT",
  "TTTTTTTTTTtTTTTT",
  "TTuTTTTTTTTTTTTT",
  "TuuTTTTTTTTTTTtT",
  "TTTTTTTtTTTTTTTT",
  "TTTTTTttTTTTuTTT",
  "TTTTTTTTTTTTTTTT",
  "TTTTTTTTTTTTTTTT",
}
tiles.water = {
  "bbbbbbbbbbbbbbbb",
  "bbbwwwbbbbbbbbbb",
  "bbwbbbwbbbbbbbbb",
  "bbbbbbbbbbbwwbbb",
  "bbbbbbbbbbwbbwbb",
  "BBbbbbbbbbbbbbbb",
  "bbBBbbbbbbbbbbbb",
  "bbbbbbbbbbbbbbbb",
  "bbbbbbbwwwbbbbbb",
  "bbbbbbwbbbwbbbbb",
  "bbbbbbbbbbbbbBBb",
  "bbbbbbbbbbbbbbbB",
  "bbfbbbbbbbbbbbbb",
  "bwwwbbbbbbbbbbbb",
  "wbbbwbbbbbbfbbbb",
  "bbbbbbbbbbbbbbbb",
}
tiles.bush = {
  "................",
  "................",
  ".....1111.......",
  "...11455511.....",
  "..1445554431....",
  ".145554443331...",
  ".145544433321...",
  "14554443333221..",
  "14544433332221..",
  "13443333322221..",
  "13333333222221..",
  ".1333322222211..",
  ".1122222222211..",
  "..11122222111...",
  "....1111111.....",
  "................",
}
tiles.rock = {
  "................",
  "................",
  "................",
  "................",
  ".....KKKKK......",
  "...KKGGWGGKK....",
  "..KGGGWGGGGgK...",
  ".KGGWGGGGGGggK..",
  ".KGGGGGGGgGggK..",
  "KGGGGGGggGgggpK.",
  "KGgGGGggggggppK.",
  "KggGggggggpgppK.",
  ".KgggggpppppPK..",
  "..KKPPPPPPPKK...",
  "....KKKKKKK.....",
  "................",
}
tiles.bridge = {
  "KKKKKKKKKKKKKKKK",
  "DtDDtDDDtDDtDDDt",
  "dddddddddddddddd",
  "tTtdtttdtTtdtttd",
  "tttdtTtdtttdtttd",
  "tttdtttdtttdtTtd",
  "tTtdtttdtttdtttd",
  "tttdtttdtTtdtttd",
  "tttdtTtdtttdtttd",
  "tttdtttdtttdtTtd",
  "tTtdtttdtttdtttd",
  "tttdtttdtTtdtttd",
  "tttdtTtdtttdtttd",
  "dddddddddddddddd",
  "DtDDtDDDtDDtDDDt",
  "KKKKKKKKKKKKKKKK",
}
local misc = { "grass_a", "grass_b", "flowers", "bridge", "bush", "rock" }

local T, COLS = 16, 12

-- How each ground looks: its fill, and the lines drawn where it meets grass.
local function thicket_key(x, y)
  local h = (x * 7 + y * 13 + x * y * 3) % 17
  if h == 0 or h == 9 then return "1" elseif h == 4 then return "3" else return "2" end
end
local function from_rows(rows) return function(x, y) return rows[y + 1]:sub(x + 1, x + 1) end end
local KINDS = {
  { name = "path", base = from_rows(tiles.path), line = "t" },
  { name = "water", base = from_rows(tiles.water), line = "1", second = "B", foam = "f" },
  { name = "thicket", base = thicket_key, line = "3" },
}

-- Neighbour bits: a set bit means that neighbour is the same ground.
-- N=1 E=2 S=4 W=8 NE=16 SE=32 SW=64 NW=128. A corner only matters when both
-- sides next to it are the same ground, which leaves 47 distinct tiles; they
-- are numbered in ascending order of these masks.
local function blob_masks()
  local list = {}
  for m = 0, 255 do
    local c = m & 15
    if (m & 16) ~= 0 and (m & 1) ~= 0 and (m & 2) ~= 0 then c = c | 16 end
    if (m & 32) ~= 0 and (m & 4) ~= 0 and (m & 2) ~= 0 then c = c | 32 end
    if (m & 64) ~= 0 and (m & 4) ~= 0 and (m & 8) ~= 0 then c = c | 64 end
    if (m & 128) ~= 0 and (m & 1) ~= 0 and (m & 8) ~= 0 then c = c | 128 end
    if c == m then list[#list + 1] = m end
  end
  return list
end

-- How far grass creeps in along an edge: 0, 1 or 2 pixels, varying along it.
local function rag(n) return ((n * 7) % 5 == 0) and 2 or (((n * 3) % 4 == 0) and 0 or 1) end

local function blob_tile(img, ox, oy, kind, mask, seed)
  local function same(bit) return (mask & bit) ~= 0 end
  for y = 0, 15 do
    for x = 0, 15 do
      -- Distance past the ragged edge, taking the nearest edge or inner corner.
      local past = 99
      local function consider(d, depth) if d - depth < past then past = d - depth end end
      if not same(1) then consider(y, rag(seed + x)) end
      if not same(2) then consider(15 - x, rag(seed + y + 5)) end
      if not same(4) then consider(15 - y, rag(seed + x + 10)) end
      if not same(8) then consider(x, rag(seed + y + 15)) end
      if same(1) and same(2) and not same(16) then consider((15 - x) + y, 2) end
      if same(4) and same(2) and not same(32) then consider((15 - x) + (15 - y), 2) end
      if same(4) and same(8) and not same(64) then consider(x + (15 - y), 2) end
      if same(1) and same(8) and not same(128) then consider(x + y, 2) end
      local key
      if past < 0 then key = "4"
      elseif past == 0 then key = kind.line
      elseif past == 1 and kind.second then key = kind.second
      elseif past == 2 and kind.foam and (x + y) % 5 < 3 then key = kind.foam
      else key = kind.base(x, y) end
      img:drawPixel(ox + x, oy + y, M.col[key])
    end
  end
end

local masks = blob_masks()
assert(#masks == 47, "expected 47 blob tiles, got " .. #masks)
local rows_per_kind = 4
local s = M.new_sprite(T * COLS, T * (1 + rows_per_kind * #KINDS))
local img = Image(s.width, s.height, ColorMode.RGB)
for i, name in ipairs(misc) do
  M.stamp(img, tiles[name], (i - 1) * T, 0)
  local slice = s:newSlice(Rectangle((i - 1) * T, 0, T, T))
  slice.name = name
end
for k, kind in ipairs(KINDS) do
  local top = 1 + (k - 1) * rows_per_kind
  for i, mask in ipairs(masks) do
    local index = i - 1
    blob_tile(img, (index % COLS) * T, (top + index // COLS) * T, kind, mask, index * 3)
  end
end
s:newCel(s.layers[1], 1, img, Point(0, 0))
s:saveAs(M.ART .. "forest_tiles.aseprite")

-- Tree: a canopy of overlapping leaf clumps lit from the upper left, on a
-- trunk. 48x64; the base of the trunk is at the middle of row 61.
local TW, TH = 48, 64
local tree = Image(TW, TH, ColorMode.RGB)

local trunk_column = "...KDtDDdK.."
local trunk_foot = {
  "...KDDtDdK..",
  "...KDtDDdK..",
  "..KDDtDDddK.",
  ".KDDtDDDDddK",
  "KDDtDKdDKdDK",
  ".KKK.KKK.KK.",
}
for y = 40, 55 do M.stamp(tree, { trunk_column }, 18, y) end
M.stamp(tree, trunk_foot, 18, 56)

-- Back-to-front: clumps listed later sit in front.
local lobes = {
  { 17, 13, 9 }, { 31, 13, 9 }, { 24, 19, 13 },
  { 10, 27, 9 }, { 38, 27, 9 }, { 16, 36, 9 }, { 32, 36, 9 }, { 24, 38, 10 },
}
local function lobe_at(x, y)
  local found = nil
  for i, l in ipairs(lobes) do
    local dx, dy = x - l[1], y - l[2]
    if dx * dx + dy * dy <= l[3] * l[3] + 1 then found = i end
  end
  return found
end
for y = 0, TH - 1 do
  for x = 0, TW - 1 do
    local i = lobe_at(x, y)
    if i then
      local l = lobes[i]
      local light = ((x - l[1]) * -0.55 + (y - l[2]) * -0.83) / l[3]
      local key
      if light > 0.6 then key = "5"
      elseif light > 0.2 then key = "4"
      elseif light > -0.35 then key = "3"
      else key = "2" end
      local h = (x * 7 + y * 13) % 11
      if key == "3" and h == 0 then key = "4" end
      if key == "4" and h == 3 then key = "5" end
      if key == "2" and h == 5 then key = "3" end
      local edge = not (lobe_at(x - 1, y) and lobe_at(x + 1, y) and lobe_at(x, y - 1) and lobe_at(x, y + 1))
      local below = lobe_at(x, y + 1)
      if edge then
        key = "1"
      elseif below and below ~= i and below > i then
        key = "2"
      end
      tree:drawPixel(x, y, M.col[key])
    end
  end
end

local ts = M.new_sprite(TW, TH)
ts:newCel(ts.layers[1], 1, tree, Point(0, 0))
ts:saveAs(M.ART .. "tree.aseprite")
return { blob_tiles = #masks }
