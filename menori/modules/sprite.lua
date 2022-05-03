--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Sprite class is a helper object for drawing textures that can contain a set of frames and play animations.
]]
-- @module menori.Sprite

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

local sprite = class('Sprite')

--- init
-- @param quads table of [Quad](https://love2d.org/wiki/Quad) objects
-- @param image [Image](https://love2d.org/wiki/Image)
function sprite:init(quads, image)
	self.quads = quads
	self.image = image
	self.index = 1
	self.ox = 0
	self.oy = 0

	self.stop = false
	self.duration_accumulator = 0
	self.duration = 0.2 / self:get_frame_count()
end

--- Clone (shallow copy).
-- @return Sprite object
function sprite:clone()
	return sprite:new(self.quads, self.image)
end

--- Get current frame viewport.
-- @treturn number x
-- @treturn number y
-- @treturn number w
-- @treturn number h
function sprite:get_frame_viewport()
	return self.quads[self.index]:getViewport()
end

--- Get index of current frame.
-- @treturn number index
function sprite:get_frame_index()
	return self.index
end

--- Set frame by index.
-- @tparam number index frame index
function sprite:set_frame_index(index)
	assert(index <= #self.quads, string.format('Sprite frame is out of range - %i, max - %i', index, #self.quads))
	self.index = index
end

--- Set sprite pivot.
-- @tparam number px
-- @tparam number py
function sprite:set_pivot(px, py)
	local x, y, w, h = self:get_frame_viewport()
	self.ox = px * w
	self.oy = py * h
end

--- Get frame count.
-- @treturn number
function sprite:get_frame_count()
	return #self.quads
end

--- Get frame uv position [0 - 1]
-- @tparam number i frame index
-- @treturn number x1
-- @treturn number x2
-- @treturn number y1
-- @treturn number y2
function sprite:get_frame_uv(i)
	local quad = self.quads[i]
	local image_w, image_h = quad:getTextureDimensions()
	local x, y, w, h = quad:getViewport()
	return x / image_w, (x + w) / image_w, y / image_h, (y + h) / image_h
end

--- Reset animation.
-- @tparam number duration
-- @return self
function sprite:reset(duration)
	self.index = 1
	self.duration = duration / self:get_frame_count()
	self.stop = false
	self.duration_accumulator = 0
	return self
end

--- Sprite update function.
-- @tparam number dt
function sprite:update(dt)
	if self.stop then return end

	self.duration_accumulator = self.duration_accumulator + dt
	if self.duration_accumulator > self.duration then
		self.duration_accumulator = 0
		self.index = self.index + 1
		if self.index > self:get_frame_count() then
			self.index = self.index - 1
			self.stop = true
		end
	end
end

--- Sprite draw function.
function sprite:draw(x, y, angle, sx, sy, ox, oy, ...)
	ox = (ox or 0) + self.ox
	oy = (oy or 0) + self.oy
	love.graphics.draw(self.image, self.quads[self.index], x, y, angle, sx, sy, ox, oy, ...)
end

return sprite