--[[
-------------------------------------------------------------------------------
      Menori
      @author rozenmad
      2023
-------------------------------------------------------------------------------
]]

--[[--
Helper class for loading aseprite spritesheet animations. Also it contains other useful functions.
]]
-- @module SpriteLoader

local json = require 'libs.rxijson.json'

local modules     = (...):gsub('%.[^%.]+$', '') .. "."
local Sprite      = require(modules .. 'sprite')

local SpriteUtils = {}
local cache = setmetatable({}, {__mode = 'v'})

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

--- Create sprite from image.
-- @param image [Image](https://love2d.org/wiki/Image)
-- @treturn menori.Sprite object
function SpriteUtils.from_image(image)
      local w, h = image:getDimensions()
      return Sprite(
            { love.graphics.newQuad(0, 0, w, h, w, h) }, image
      )
end

--- Create a (Quad array) from tileset image.
-- @param image [Image](https://love2d.org/wiki/Image)
-- @tparam number w Tile width.
-- @tparam number h Tile height.
-- @tparam number ox Offset from beginnig of image by x.
-- @tparam number oy Offset from beginnig of image by y.
-- @tparam number mx margin x.
-- @tparam number my margin y.
-- @treturn table Array of [Quad](https://love2d.org/wiki/Quad) objects
function SpriteUtils.create_quad_array_from_tileset(image, w, h, ox, oy, mx, my)
      ox = ox or 0
      oy = oy or 0
      mx = mx or 0
      my = my or 0
      local image_w, image_h = image:getDimensions()
      local quads = {}
      local iws = math.floor((image_w - ox) / (w + mx))
      local ihs = math.floor((image_h - oy) / (h + my))
      for j = 0, ihs - 1 do
            for i = 0, iws - 1 do
                  local px = i * w + i * mx
                  local py = j * h + i * my
                  quads[#quads + 1] = love.graphics.newQuad(px, py, w, h, image_w, image_h)
            end
      end
      return quads
end

--- Create sprite from tileset image.
-- @param image [Image](https://love2d.org/wiki/Image)
-- @tparam number w Tile width.
-- @tparam number h Tile height.
-- @tparam number ox Offset from beginnig of image by x.
-- @tparam number oy Offset from beginnig of image by y.
-- @tparam number mx margin x.
-- @tparam number my margin y.
-- @treturn menori.Sprite object
function SpriteUtils.from_tileset(image, w, h, ox, oy, mx, my)
      return Sprite(SpriteUtils.create_quad_array_from_tileset(image, w, h, ox, oy, mx, my), image)
end

--- Load sprite from aseprite spritesheet using sprite cache list.
-- @tparam string filename
-- @treturn menori.Sprite object
function SpriteUtils.from_aseprite_spritesheet(filename)
      if not cache[filename] then cache[filename] = load_aseprite_sprite_sheet(filename) end
      return cache[filename]
end

--- Find aseprite spritesheet in cache list.
-- @tparam string name
-- @treturn menori.Sprite object
function SpriteUtils.find_spritesheet(name)
      return cache[name]
end

return SpriteUtils