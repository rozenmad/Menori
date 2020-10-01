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

	self.stop = false
	self.duration_accumulator = 0
	self.duration = 0.2 / self:get_frame_count()
end

function sprite:get_frame_viewport()
	return self.quads[self.index]:getViewport()
end

--- Clone (fast).
function sprite:clone()
	return sprite:new(self.quads, self.image)
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

function sprite:reset(duration)
	self.duration = duration / self:get_frame_count()
	self.stop = false
	self.duration_accumulator = 0
	return self
end

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

--- Draw this sprite.
function sprite:draw(...)
	love.graphics.draw(self.image, self.quads[self.index], ...)
end

return sprite