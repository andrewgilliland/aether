-- Exports every art source to a horizontal PNG sheet in assets/.
-- Sprites that have animation tags also get a Godot SpriteFrames resource
-- (assets/<name>.tres) with one animation per tag. A tag set to repeat a fixed
-- number of times becomes a non-looping animation.
-- Run inside Aseprite (batch): dofile this file.
local ROOT = "/Users/andrewgilliland/Code/Godot/aether/"

local function write_sprite_frames(name, s)
  local w, h = s.width, s.height
  local out = {}
  local function add(line) out[#out + 1] = line end
  add(string.format('[gd_resource type="SpriteFrames" load_steps=%d format=3]', #s.frames + 2))
  add("")
  add(string.format('[ext_resource type="Texture2D" path="res://assets/%s.png" id="1"]', name))
  for i = 1, #s.frames do
    add("")
    add(string.format('[sub_resource type="AtlasTexture" id="f%d"]', i))
    add('atlas = ExtResource("1")')
    add(string.format("region = Rect2(%d, 0, %d, %d)", (i - 1) * w, w, h))
  end
  add("")
  add("[resource]")
  local anims = {}
  for _, tag in ipairs(s.tags) do
    local from, to = tag.fromFrame.frameNumber, tag.toFrame.frameNumber
    local frames = {}
    for i = from, to do
      frames[#frames + 1] = string.format('{\n"duration": 1.0,\n"texture": SubResource("f%d")\n}', i)
    end
    anims[#anims + 1] = string.format(
      '{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.2f\n}',
      table.concat(frames, ", "), (tag.repeats == 0) and "true" or "false", tag.name,
      1.0 / s.frames[from].duration)
  end
  add("animations = [" .. table.concat(anims, ", ") .. "]")
  add("")
  local f = assert(io.open(ROOT .. "assets/" .. name .. ".tres", "w"))
  f:write(table.concat(out, "\n"))
  f:close()
end

local done = {}
for _, name in ipairs({ "hero", "slash", "puffhop", "forest_tiles", "tree", "font" }) do
  local s = Sprite { fromFile = ROOT .. "art/" .. name .. ".aseprite" }
  app.sprite = s
  app.command.ExportSpriteSheet {
    ui = false,
    type = SpriteSheetType.HORIZONTAL,
    textureFilename = ROOT .. "assets/" .. name .. ".png",
  }
  if #s.tags > 0 then write_sprite_frames(name, s) end
  done[#done + 1] = name .. " (" .. #s.frames .. " frames, " .. #s.tags .. " tags)"
  s:close()
end
return done
