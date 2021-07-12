--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Description.
]]
-- @module menori.SpriteLoader

local json = require 'libs.rxijson.json'

local modules     = (...):gsub('%.[^%.]+$', '') .. "."
local ImageLoader = require(modules .. 'imageloader')
local Sprite      = require(modules .. 'sprite')

local spriteloader = {}
local list = setmetatable({}, {__mode = 'v'})

local function load_aseprite_sprite_sheet(path, name)
	local filename = path .. name
	local data = json.decode(love.filesystem.read(filename .. '.json'))
	local meta = data.meta

	local image = ImageLoader.load(path .. meta.image)

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

	local spritesheet = {}

	for _, slice in ipairs(meta.slices) do
		local quads = {}
		for i, key in ipairs(slice.keys) do
			local bounds = key.bounds

			local frame = frames[i].frame
			local ox = frame.x
			local oy = frame.y
			quads[i] = love.graphics.newQuad(ox+bounds.x, oy+bounds.y, bounds.w, bounds.h, iw, ih)
		end

		spritesheet[slice.name] = Sprite:new(quads, image, slice.pivot)
	end

	return spritesheet
end

--- Create sprite from image.
-- @param image [Image](https://love2d.org/wiki/Image)
-- @return New sprite
function spriteloader.from_image(image)
	local w, h = image:getDimensions()
	return Sprite({love.graphics.newQuad(0, 0, w, h, w, h)}, image)
end

--- Create sprite from tileset image.
-- @param image [Image](https://love2d.org/wiki/Image)
-- @tparam number offsetx
-- @tparam number offsety
-- @tparam number w
-- @tparam number h
-- @return Sprite object
function spriteloader.from_tileset_image(image, offsetx, offsety, w, h)
	return Sprite(ImageLoader.create_tileset_from_image(offsetx, offsety, w, h), image)
end

--- Load sprite from Aseprite Sprite Sheet using sprite cache list.
-- @tparam string path
-- @tparam string name
-- @return Sprite object
function spriteloader.load_sprite_sheet(path, name)
	if not list[name] then list[name] = load_aseprite_sprite_sheet(path, name) end
	return list[name]
end

--- Find Aseprite Sprite Sheet in cache list.
-- @tparam string name
-- @return Sprite object
function spriteloader.find_sprite_sheet(name)
	return list[name]
end

return
spriteloader