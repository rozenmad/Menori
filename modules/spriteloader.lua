--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- Sprite loader for slices or images.
-- @module SpriteLoader
local JSON = require 'libs.json'

local modules 		= (...):gsub('%.[^%.]+$', '') .. "."
local ImageLoader 	= require(modules .. 'imageloader')
local Sprite 		= require(modules .. 'sprite')

local spriteloader = {}
local list = setmetatable({}, {__mode = 'v'})

local function load_slice(path, name)
	local filename = path .. name
	local data = JSON.decode(love.filesystem.read(filename .. '.json'))
	local meta = data.meta

	local image = ImageLoader.find(path .. meta.image)

	local iw, ih = image:getDimensions()

	local spritesheet = {}

	for _, slice in ipairs(meta.slices) do
		local quads = {}
		for i, key in ipairs(slice.keys) do
			local bounds = key.bounds

			local frame = data.frames[i].frame
			local ox = frame.x
			local oy = frame.y
			quads[i] = love.graphics.newQuad(ox+bounds.x, oy+bounds.y, bounds.w, bounds.h, iw, ih)
		end

		spritesheet[slice.name] = Sprite:new(quads, image, slice.pivot)
	end

	return spritesheet
end

--- Create sprite from image.
function spriteloader.from_image(image)
	local w, h = image:getDimensions()
	return Sprite:new({love.graphics.newQuad(0, 0, w, h, w, h)}, image)
end

--- Load sprite from Aseprite array slices using sprite cache list.
function spriteloader.load_slice(path, name)
	if not list[name] then list[name] = load_slice(path, name) end
	return list[name]
end

function spriteloader.find_slice(name)
	return list[name]
end

return
spriteloader