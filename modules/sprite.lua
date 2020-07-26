--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- Sprite.
-- @module Sprite
local class = require 'menori.modules.libs.class'

local sprite = class('Sprite')

--- Constructor
function sprite:constructor(quads, image)
	self.quads = quads
	self.image = image
	self.index = 1

	self.duration = 0.20
	self.duration_accumulator = 0
	self.max_loops = -1
	self.loop_counter = 0
	self.stop = false
end

function sprite:get_frame_viewport()
	return self.quads[self.index]:getViewport()
end

--- Clone (fast).
function sprite:clone()
	return sprite:new(self.quads, self.image)
end

--- Get origin.
function sprite:get_origin()
	return self.origin_x, self.origin_y
end

--- Set origin.
function sprite:set_origin(ox, oy)
	self.origin_x = ox
	self.origin_y = oy
	for i, v in ipairs(self.quads) do
		--v:setOrigin(ox, oy)
	end
	return self
end

function sprite:set_offset_pixels(px, py, w, h)
	local ox = px / w
	local oy = py / h
	self:set_origin(ox, oy)
	return self
end

--- Get current index of frame.
function sprite:get_frame_index()
	return self.index
end

--- Set current index of frame.
function sprite:set_frame_index(index)
	assert(index <= #self.quads, string.format('Sprite frame is out of range - %i, max - %i', index, #self.quads))
	self.index = index
end

--- Get frame count.
function sprite:get_frame_count()
	return #self.quads
end

function sprite:get_frame_quad(i)
	--assert(#self.quads > i)
	return self.quads[i]
end

function sprite:get_frame_uv(i)
	local quad = self:get_frame_quad(i)
	local image_w, image_h = quad:getTextureDimensions()
	local x, y, w, h = quad:getViewport()
	return {x / image_w, (x + w) / image_w, y / image_h, (y + h) / image_h}
end

function sprite:reset(time, max_loops)
	self.duration = time / self:get_frame_count()
	self.max_loops = max_loops
	self.stop = false
	self.duration_accumulator = 0
	self.loop_counter = 0
	return self
end

function sprite:update(dt)
	if self.stop then return end

	self.duration_accumulator = self.duration_accumulator + dt
	if self.duration_accumulator > self.duration then
		self.duration_accumulator = 0
		self.index = self.index + 1
		if self.index > self:get_frame_count() then
			self.loop_counter = self.loop_counter + 1
			if self.max_loops ~= -1 and self.loop_counter >= self.max_loops then
				self.index = self:get_frame_count()
				self.stop = true
			else
				self.index = 1
			end
		end
	end
end

--- Draw this sprite.
function sprite:draw(...)
	love.graphics.draw(self.image, self.quads[self.index], ...)
end

return sprite