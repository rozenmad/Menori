--[[
-------------------------------------------------------------------------------
      Menori
      @author rozenmad
      2022
-------------------------------------------------------------------------------
]]

--[[--
Helper class for loading aseprite spritesheet animations. Also it contains other useful functions.
]]
-- @module SpriteLoader

local json = require 'libs.rxijson.json'

local modules     = (...):gsub('%.[^%.]+$', '') .. "."
local Sprite      = require(modules .. 'sprite')

local SpriteLoader = {}
local list = setmetatable({}, {__mode = 'v'})

local function load_aseprite_sprite_sheet(filename)
      local path = filename:match("(.*/).+%.json$")
      local data = json.decode(love.filesystem.read(filename))
      local meta = data.meta

      local image = love.graphics.newImage(path .. meta.image)
      image:setFilter('nearest', 'nearest')

      local iw, ih = image:getDimensions()

      local frames
      if #data.frames <= 0 then -- if hash type
            frames = {}
            for _, v in pairs(data.frames) do
                  frames[#frames + 1] = v
            end
      else
            frames = data.frames
      end

      local quads = {}
      for i, v in ipairs(frames) do
            local frame = v.frame
            quads[i] = love.graphics.newQuad(frame.x, frame.y, frame.w, frame.h, iw, ih)
      end

      local spritesheet = {}
      for _, v in ipairs(meta.frameTags) do
            local t = {}
            for i = v.from + 1, v.to + 1 do
                  table.insert(t, quads[i])
            end
            spritesheet[v.name] = Sprite(t, image)
      end

      --[[local spritesheet = {}

      for _, slice in ipairs(meta.slices) do
            local quads = {}
            for i, key in ipairs(slice.keys) do
                  local bounds = key.bounds

                  local frame = frames[i].frame
                  local ox = frame.x
                  local oy = frame.y
                  quads[i] = love.graphics.newQuad(ox+bounds.x, oy+bounds.y, bounds.w, bounds.h, iw, ih)
            end

            spritesheet[slice.name] = Sprite(quads, image, slice.pivot)
      end]]

      return spritesheet
end

--- Create a tileset from an image.
-- @param image [Image](https://love2d.org/wiki/Image)
-- @tparam number offsetx Offset from beginnig of image by x.
-- @tparam number offsety Offset from beginnig of image by y.
-- @tparam number w Tile width.
-- @tparam number h Tile height.
-- @treturn table Array of [Quad](https://love2d.org/wiki/Quad) objects
function SpriteLoader.create_tileset_from_image(image, offsetx, offsety, w, h)
      local image_w, image_h = image:getDimensions()
      local quads = {}
      local iws = math.floor((image_w - offsetx) / w)
      local ihs = math.floor((image_h - offsety) / h)
      for j = 0, ihs - 1 do
            for i = 0, iws - 1 do
                  local px = i * w
                  local py = j * h
                  quads[#quads + 1] = love.graphics.newQuad(px, py, w, h, image_w, image_h)
            end
      end
      return quads
end

--- Create sprite from image.
-- @param image [Image](https://love2d.org/wiki/Image)
-- @treturn menori.Sprite object
function SpriteLoader.from_image(image)
      local w, h = image:getDimensions()
      return Sprite({love.graphics.newQuad(0, 0, w, h, w, h)}, image)
end

--- Create sprite from tileset image.
-- @param image [Image](https://love2d.org/wiki/Image)
-- @tparam number offsetx
-- @tparam number offsety
-- @tparam number w
-- @tparam number h
-- @treturn menori.Sprite object
function SpriteLoader.from_tileset_image(image, offsetx, offsety, w, h)
      return Sprite(SpriteLoader.create_tileset_from_image(image, offsetx, offsety, w, h), image)
end

--- Load sprite from aseprite spritesheet using sprite cache list.
-- @tparam string filename
-- @treturn menori.Sprite object
function SpriteLoader.from_aseprite_sprite_sheet(filename)
      if not list[filename] then list[filename] = load_aseprite_sprite_sheet(filename) end
      return list[filename]
end

--- Find aseprite spritesheet in cache list.
-- @tparam string name
-- @treturn menori.Sprite object
function SpriteLoader.find_sprite_sheet(name)
      return list[name]
end

return SpriteLoader