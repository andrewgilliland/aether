-- Builds art/puffhop.aseprite. Run inside Aseprite (batch): dofile this file.
local M = dofile("/Users/andrewgilliland/Code/Godot/aether/art/tools/pixel.lua")

local rest = {
  "..KK......KK....",
  ".KyYK....KYyK...",
  ".KYlYK..KYlYK...",
  ".KYlYK..KYlYK...",
  "..KYYKKKKYYK....",
  "..KYyyyyyyYYK...",
  ".KYyyyyyyyyYYK..",
  ".KYyKyyyyKyYYK..",
  "KYyyKyyyyKyyYoK.",
  "KYyyyyRRyyyyYoK.",
  "KYYyyyyyyyyYYoK.",
  "KYYYyyyyyyYYYoK.",
  ".KoYYYYYYYYYoK..",
  ".KooYYYYYYYooK..",
  "..KKoooooooKK...",
  "....KKKKKKK.....",
}
-- Squashed, about to hop: ears droop outward, body one pixel shorter.
local squash = {
  "................",
  "..KK......KK....",
  ".KyYK....KYyK...",
  ".KYlYK..KYlYK...",
  "..KYYKKKKYYK....",
  "..KYyyyyyyYYK...",
  ".KYyyyyyyyyYYK..",
  "KYyyKyyyyKyyYoK.",
  "KYyyKyyyyKyyYoK.",
  "KYyyyyRRyyyyYoK.",
  "KYYyyyyyyyyYYoK.",
  "KYYYyyyyyyYYYoK.",
  "KooYYYYYYYYYooK.",
  ".KooYYYYYYYooK..",
  "..KKoooooooKK...",
  "....KKKKKKK.....",
}

local s = M.sprite_from_frames({ rest, squash }, 0.25)
M.tag(s, "idle", 1, 2)
s:saveAs(M.ART .. "puffhop.aseprite")
return s
