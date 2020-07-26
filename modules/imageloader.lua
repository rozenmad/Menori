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
	local image = love.graphics.newImage(filename, {mipmaps = mipmaps})
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

return
imageloader