--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Instance that contains functions for loading and searching images in the cache list.
The cache list is a weak reference to the images.
]]
-- @module menori.ImageLoader

local imageloader = {}
local list = setmetatable({}, {__mode = 'v'})

local filter = 'nearest'
love.graphics.setDefaultFilter(filter, filter)

local function load_image(filename, opt)
	local image = love.graphics.newImage(filename, opt)
	list[filename] = image
	return image
end

--- Load image in cache list or find it.
-- @return [Image](https://love2d.org/wiki/Image)
function imageloader.load(filename, opt)
	if not list[filename] then list[filename] = load_image(filename, opt) end
	return list[filename]
end

--- Find image in cache list.
-- @return [Image](https://love2d.org/wiki/Image)
function imageloader.find(filename)
	return list[filename]
end

--- Create a tileset from an image.
-- @return table List of [Quad](https://love2d.org/wiki/Quad)
function imageloader.create_tileset_from_image(image, offsetx, offsety, w, h)
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

return imageloader