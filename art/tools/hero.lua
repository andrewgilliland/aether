-- Builds art/hero.aseprite (24x32 per frame). Run inside Aseprite (batch): dofile this file.
-- The Hero: short dark hair swept aside, steel shoulders and chest plate over
-- a blue tunic, red collar, sword sheathed on his back.
local M = dofile("/Users/andrewgilliland/Code/Godot/aether/art/tools/pixel.lua")
local function cat(...)
  local r = {}
  for _, t in ipairs({ ... }) do for _, row in ipairs(t) do r[#r + 1] = row end end
  return r
end
local BLANK = "........................"

-- Facing down: head and body (rows 0-24), then legs.
local down_top = {
  "........................",
  "........KKKKKKK.........",
  "......KKDDtDDDDKK.......",
  ".....KDDttDDDtDDDDdK....",
  ".....KDttDDDttDDDDdK....",
  ".....KdDDDDDtDDDdddK....",
  ".....KdSSSSDDDdSSddK....",
  ".....KdSSddSSSddSSdK....",
  ".....KdSSKSSSSSKSSdK....",
  ".....KsSSKSSSSSKSSsK....",
  ".....KsSSSSSsSSSSSsK....",
  "......KsSSSsssSSSsK.KK..",
  ".......KKsSSSSSsKK.KoYK.",
  ".........KKsSsKK..KDoK..",
  "......KKKGGRRRGGKKK.....",
  ".....KGWGGgRRRgGGGgK....",
  "....KGWgKnGGWGGnKGGgK...",
  "....KGGgKnGGGGgnKGggK...",
  "....KBBnKnBgggBnKBBnK...",
  "....KBBnKBbBBBBnKBBnK...",
  "....KDDdKBBBBBBnKDDdK...",
  "....KDDdKddoYoddKDDdK...",
  ".....KKKKBBBBBBnKKKK....",
  ".......KBbBBBBBBnK......",
  ".......KnBBBnBBBnK......",
}
-- Facing up: the scabbard crosses his back from the left shoulder to the right hip.
local up_top = {
  "........................",
  "........KKKKKKK.........",
  "......KKDDtDDDDKK.......",
  ".....KDDttDDDtDDDDdK....",
  ".....KDttDDDttDDDDdK....",
  ".....KdDDDDtDDDDDDdK....",
  ".....KdDDDtDDDDtDDdK....",
  ".....KdDDDDDDDDDDDdK....",
  ".....KddDDDdDDDdDDdK....",
  ".....KdddDdddDdddDdK....",
  "......KdddddddddddK.....",
  "...KK..KKdKdddKdKK......",
  "..KYoK.KKsSSSSSsKK......",
  "...KoDK..KKsSsKK........",
  "......KKKDdRRRGGKKK.....",
  ".....KGWGGDdRRgGGGgK....",
  "....KGWgKnGDdGGnKGGgK...",
  "....KGGgKnGGDdgnKGggK...",
  "....KBBnKnBggDdnKBBnK...",
  "....KBBnKBbBBBDdKBBnK...",
  "....KDDdKBBBBBBDKDDdK...",
  "....KDDdKdddtdddKDDdK...",
  ".....KKKKBBBBBBnKKKK....",
  ".......KBbBBBBBBnK......",
  ".......KnBBBnBBBnK......",
}
local legs_idle = {
  "........KppPKppPK.......",
  "........KppPKppPK.......",
  "........KgGgKgGgK.......",
  "........KDDdKDDdK.......",
  "........KDDdKDDdK.......",
  ".......KDDDdKdDDDK......",
  ".......KKKKKKKKKKK......",
}
local legs_stepL = {
  "........KppPKppPK.......",
  "........KgGgKgGgK.......",
  "........KDDdKDDdK.......",
  "........KDDdKdDDDK......",
  ".......KDDDdKKKKKK......",
  ".......KKKKKK...........",
}
local legs_stepR = {
  "........KppPKppPK.......",
  "........KgGgKgGgK.......",
  "........KDDdKDDdK.......",
  ".......KDDDdKDDdK.......",
  ".......KKKKKKdDDDK......",
  "............KKKKKK......",
}
-- Facing right, complete.
local right = {
  "........................",
  "........KKKKKKK.........",
  "......KKDDtDDDDKK.......",
  ".....KDDttDDDtDDDDK.....",
  ".....KDttDDDttDDDDDK....",
  ".....KdDDDDDDtDDDDdK....",
  ".....KdDDDDDdSSSSSSK....",
  ".....KdDDDDdSSSSddSK....",
  ".....KdDDDdSSSSSKSSK....",
  ".....KddDdSsSSSSKSSSK...",
  "......KdddSSSSSSSSsK....",
  "...KK.KKdsSSSSSssSK.....",
  "..KYoK..KKKsSSSSsK......",
  "...KoDK...KKsSsKK.......",
  ".....KdKKKKKKKK.........",
  ".....KdKGWGGgRRK........",
  ".....KdKnGWGgGnK........",
  ".....KdKnGGggGnK........",
  ".....KdKnBBBngnK........",
  ".....KdKBBbBnBnK........",
  ".....KdKBBDDdBnK........",
  ".....KdKddDDdodK........",
  ".....KdKBBKKKBnK........",
  ".....KdKBbBBBBnK........",
  ".....KdKnBBnBBnK........",
  "......K.KppPpPK.........",
  "........KppPpPK.........",
  "........KgGgGgK.........",
  "........KDDdDdK.........",
  "........KDDdDdK.........",
  "........KDDDdDdK........",
  "........KKKKKKKK........",
}

-- Poses are the standing pose with parts redrawn. Each patch is
-- { row, column, text } (both counted from 0) and overwrites that stretch.
local function patched(rows, ...)
  local out = {}
  for i, row in ipairs(rows) do out[i] = row end
  for _, patches in ipairs({ ... }) do
    for _, p in ipairs(patches) do
      local r, c, text = p[1] + 1, p[2], p[3]
      assert(c + #text <= #out[r], "patch runs off row " .. p[1])
      out[r] = out[r]:sub(1, c) .. text .. out[r]:sub(c + #text + 1)
    end
  end
  return out
end
local function rows_from(rows, first, last)
  local out = {}
  for i = first, last do out[#out + 1] = rows[i] end
  return out
end

-- Walking, facing down or up: each arm hangs a pixel lower as it swings
-- forward and a pixel higher as it swings back, opposite to the legs.
local arm_left_back = { { 19, 5, "DDd" }, { 21, 4, ".KKK" }, { 22, 5, "..." } }
local arm_left_forward = { { 20, 5, "BBn" }, { 22, 4, "KDDd" }, { 23, 5, "KK" } }
local arm_right_back = { { 19, 17, "DDd" }, { 21, 17, "KKK." }, { 22, 17, "..." } }
local arm_right_forward = { { 20, 17, "BBn" }, { 22, 17, "DDdK" }, { 23, 18, "KK" } }

local idle_down = cat(down_top, legs_idle)
local down_stepL = cat({ BLANK }, patched(down_top, arm_left_back, arm_right_forward), legs_stepL)
local down_stepR = cat({ BLANK }, patched(down_top, arm_left_forward, arm_right_back), legs_stepR)
local idle_up = cat(up_top, legs_idle)
local up_stepL = cat({ BLANK }, patched(up_top, arm_left_back, arm_right_forward), legs_stepL)
local up_stepR = cat({ BLANK }, patched(up_top, arm_left_forward, arm_right_back), legs_stepR)

-- Walking, facing right: legs apart, body one pixel lower, and the near arm
-- swinging ahead of him and behind. B is A with the other leg leading.
local right_top = rows_from(right, 1, 25)
local right_legs = rows_from(right, 26, 32)
local legs_strideA = {
  "......K.KppPpPK.........",
  ".......KppKKpPPK........",
  "......KgGK..KGgK........",
  ".....KDDK....KDDK.......",
  ".....KDDdK...KDDdK......",
  ".....KKKKK...KKKKK......",
}
local legs_strideB = {
  "......K.KPpppPK.........",
  ".......KPPKKppPK........",
  "......KGgK..KgGK........",
  ".....KDdK....KDDK.......",
  ".....KdDDK...KDDDK......",
  ".....KKKKK...KKKKK......",
}
local arm_ahead = { { 20, 8, "BBBnDDd" }, { 21, 8, "dddoDDd" }, { 22, 8, "BBBnKKK" } }
local arm_behind = { { 20, 8, "DDdBBBn" }, { 21, 8, "DDdddod" }, { 22, 8, "KKKBBBn" } }
local right_strideA = cat({ BLANK }, patched(right_top, arm_ahead), legs_strideA)
local right_strideB = cat({ BLANK }, patched(right_top, arm_behind), legs_strideB)

-- Swinging: the sword leaves his back (no hilt) and is in his hand. The arc
-- the blade leaves in the air is the separate slash sprite.
local no_hilt_down = { { 11, 19, "....." }, { 12, 18, "......" }, { 13, 17, "......." } }
local no_hilt_up = { { 11, 3, ".." }, { 12, 2, "...." }, { 13, 3, "...." } }
local no_hilt_right = { { 11, 3, ".." }, { 12, 2, "...." }, { 13, 3, "...." } }

-- Facing down: sword arm raised beside his head, blade up; then brought down
-- across his front, blade pointing at the ground.
local down_windup = patched(down_top, no_hilt_down, {
  { 11, 1, "KDdK" }, { 12, 1, "KDDK" }, { 13, 1, "KBBK" }, { 14, 2, "KBnK" }, { 15, 3, "KB" },
  { 18, 4, "KKKK" }, { 19, 4, "...." }, { 20, 4, "...." }, { 21, 4, "...." }, { 22, 5, "..." },
  { 10, 0, "KoYoK" }, { 1, 2, "K" },
  { 2, 1, "KWK" }, { 3, 1, "KWK" }, { 4, 1, "KWK" }, { 5, 1, "KWK" },
  { 6, 1, "KWK" }, { 7, 1, "KWK" }, { 8, 1, "KWK" }, { 9, 1, "KWK" },
})
local down_strike = patched(down_top, no_hilt_down, {
  { 20, 0, "....KBBBBBKKKKBnKDDdK..." },
  { 21, 0, "....KKKKKKDDdKddKDDdK..." },
  { 22, 0, "........KKDDdKBnKKKK...." },
  { 23, 0, ".......KBKoYoKBBnK......" },
  { 24, 10, "KWK" },
})
local legs_blade = patched(legs_idle, {
  { 0, 10, "KWK" }, { 1, 10, "KWK" }, { 2, 10, "KWK" }, { 3, 10, "KWK" }, { 4, 11, "K" },
})
-- Facing up: the same arm raised, blade up; then thrust away from us, hidden
-- by his body.
local up_windup = patched(up_top, no_hilt_up, {
  { 11, 20, "KdDK" }, { 12, 20, "KDDK" }, { 13, 20, "KBBK" }, { 14, 19, "KnBK" }, { 15, 20, "BK" },
  { 18, 17, "KKKK" }, { 19, 17, "...." }, { 20, 17, "...." }, { 21, 17, "...." }, { 22, 17, "..." },
  { 10, 19, "KoYoK" }, { 1, 21, "K" },
  { 2, 20, "KWK" }, { 3, 20, "KWK" }, { 4, 20, "KWK" }, { 5, 20, "KWK" },
  { 6, 20, "KWK" }, { 7, 20, "KWK" }, { 8, 20, "KWK" }, { 9, 20, "KWK" },
})
local up_strike = patched(up_top, no_hilt_up, {
  { 19, 17, "KKKK" }, { 20, 17, "...." }, { 21, 17, "...." }, { 22, 17, "..." },
})
-- Facing right: fist raised in front of his chin; then the arm thrust
-- straight ahead with the blade held upright.
local right_windup = patched(right_top, { { 11, 3, ".." }, { 12, 2, "...." } }, {
  { 13, 0, "..........KKsSsKKKKK...." },
  { 14, 0, ".....KdKKKKKKKKKDDdK...." },
  { 15, 0, ".....KdKGWGGgRRKBBnK...." },
  { 16, 0, ".....KdKnGWGgGnKBnK....." },
  { 17, 0, ".....KdKnGGggGnKKK......" },
  { 19, 8, "BBBBBBn" }, { 20, 8, "BBBBBBn" }, { 21, 8, "dddddod" }, { 22, 8, "BBBBBBn" },
})
local right_strike = patched(right_top, no_hilt_right, {
  { 17, 0, ".....KdKnGGggGnKKKoYoK.." },
  { 18, 0, ".....KdKnBBBBBBBBnDDdK.." },
  { 19, 0, ".....KdKBBBBBBnKKKKKKK.." },
  { 20, 8, "BBBBBBn" }, { 21, 8, "dddddod" }, { 22, 8, "BBBBBBn" },
  { 11, 18, "KWK" }, { 12, 18, "KWK" }, { 13, 18, "KWK" }, { 14, 18, "KWK" }, { 15, 18, "KWK" }, { 16, 18, "KWK" },
})

local swing_down_1 = cat(down_windup, legs_idle)
local swing_down_2 = cat(down_strike, legs_blade)
local swing_right_1 = cat(right_windup, right_legs)
local swing_right_2 = cat(right_strike, right_legs)
local swing_up_1 = cat(up_windup, legs_idle)
local swing_up_2 = cat(up_strike, legs_idle)

-- Hurt: eyes screwed shut, mouth open, flinching a pixel lower.
local eyes_shut_down = { { 8, 8, "KK" }, { 8, 15, "KK" }, { 9, 9, "S" }, { 9, 15, "S" } }
local legs_crouch = rows_from(legs_idle, 2, 7)
local hurt_down = cat({ BLANK }, patched(down_top, eyes_shut_down, { { 11, 11, "KKK" } }), legs_crouch)
local hurt_right = cat({ BLANK },
  patched(right_top, { { 8, 15, "KK" }, { 9, 16, "S" }, { 11, 15, "KK" } }), rows_from(right_legs, 2, 7))
local hurt_up = cat({ BLANK }, up_top, legs_crouch)
-- Fallen: eyes shut. The game lays this frame on its side.
local fallen = cat(patched(down_top, eyes_shut_down), legs_idle)

-- Facing left is the right-facing frames mirrored by the game.
local s = M.sprite_from_frames({
  idle_down, down_stepL, idle_down, down_stepR, idle_down,
  right, right_strideA, right, right_strideB, right,
  idle_up, up_stepL, idle_up, up_stepR, idle_up,
  swing_down_1, swing_down_2, swing_down_2,
  swing_right_1, swing_right_2, swing_right_2,
  swing_up_1, swing_up_2, swing_up_2,
  hurt_down, hurt_right, hurt_up, fallen,
}, 0.15)
for i = 16, 24 do s.frames[i].duration = 0.1 end
M.tag(s, "idle_down", 1, 1)
M.tag(s, "walk_down", 2, 5)
M.tag(s, "idle_right", 6, 6)
M.tag(s, "walk_right", 7, 10)
M.tag(s, "idle_up", 11, 11)
M.tag(s, "walk_up", 12, 15)
-- A Swing plays once; a tag that repeats once is exported as non-looping.
M.tag(s, "swing_down", 16, 18).repeats = 1
M.tag(s, "swing_right", 19, 21).repeats = 1
M.tag(s, "swing_up", 22, 24).repeats = 1
M.tag(s, "hurt_down", 25, 25)
M.tag(s, "hurt_right", 26, 26)
M.tag(s, "hurt_up", 27, 27)
M.tag(s, "fallen", 28, 28)
s:saveAs(M.ART .. "hero.aseprite")
return s
