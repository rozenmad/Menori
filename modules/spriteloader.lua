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

function spriteloader.from_tileset_image(image, x, y, w, h)
	local image_w, image_h = image:getDimensions()
	local quads = {}
	local iws = math.floor((image_w - x) / w)
	local ihs = math.floor((image_h - y) / h)
	for j = 0, ihs - 1 do
		for i = 0, iws - 1 do
			local px = i * w
			local py = j * h
			quads[#quads + 1] = love.graphics.newQuad(px, py, w, h, image_w, image_h)
		end
	end
	return Sprite:new(quads, image)
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