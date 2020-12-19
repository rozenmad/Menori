--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- Image manager (__instance__)
-- @module ImageLoader
local imageloader = {}

local list = setmetatable({}, {__mode = 'v'})

local filter = 'nearest'
love.graphics.setDefaultFilter(filter, filter)

function imageloader.load(filename, mipmaps)
	local image = love.graphics.newImage(filename, { mipmaps = mipmaps })
	if mipmaps then
		image:setMipmapFilter('nearest', 0.0)
	end
	list[filename] = image
	return image
end

--- Find image in cache list or load if not exist in cache.
-- @return [Image](https://love2d.org/wiki/Image)
function imageloader.find(filename)
	return list[filename] or imageloader.load(filename)
end

--- Check image exist in cache list.
-- @treturn boolean
function imageloader.has(filename)
	return list[filename] ~= nil
end

function imageloader.from_tileset_image(image, x, y, w, h)
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
	return quads
end

return
imageloader