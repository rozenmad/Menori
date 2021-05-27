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
-- @module menori.Sprite

local class = require 'menori.modules.libs.class'

local sprite = class('Sprite')

--- Constructor
function sprite:constructor(quads, image)
	self.quads = quads
	self.image = image
	self.index = 1
	self.ox = 0
	self.oy = 0

	self.stop = false
	self.duration_accumulator = 0
	self.duration = 0.2 / self:get_frame_count()
end

--- Clone (fast).
function sprite:clone()
	return sprite:new(self.quads, self.image)
end

--- Get current frame viewport.
function sprite:get_frame_viewport()
	return self.quads[self.index]:getViewport()
end

--- Get current index of frame.
function sprite:get_frame_index()
	return self.index
end

--- Set current frame.
function sprite:set_frame_index(index)
	assert(index <= #self.quads, string.format('Sprite frame is out of range - %i, max - %i', index, #self.quads))
	self.index = index
end

--- Set pivot.
function sprite:set_pivot(px, py)
	local x, y, w, h = self:get_frame_viewport()
	self.ox = px * w
	self.oy = py * h
end

--- Get frame count.
function sprite:get_frame_count()
	return #self.quads
end

--- Get frame uv position [0 - 1]
function sprite:get_frame_uv(i)
	local quad = self.quads[i]
	local image_w, image_h = quad:getTextureDimensions()
	local x, y, w, h = quad:getViewport()
	return {x / image_w, (x + w) / image_w, y / image_h, (y + h) / image_h}
end

--- Reset animation.
function sprite:reset(duration)
	self.duration = duration / self:get_frame_count()
	self.stop = false
	self.duration_accumulator = 0
	return self
end

--- Sprite update function.
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
function sprite:draw(x, y, ...)
	x = (x or 0) - self.ox
	y = (y or 0) - self.oy
	love.graphics.draw(self.image, self.quads[self.index], x, y, ...)
end

return sprite