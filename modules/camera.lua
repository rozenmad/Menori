--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- Camera for 2D scenes.
-- @module Camera
local class         	= require 'menori.modules.libs.class'
local matrix4x4     	= require 'menori.modules.libs.matrix4x4'
local scenedispatcher 	= require 'menori.modules.scenedispatcher'

local cpml = require 'libs.cpml'
local vec3 = cpml.vec3

local camera = class('Camera')

--- Constructor
function camera:constructor()
	self._update = true
	self.x = 0
	self.y = 0
	self.rotation = 0
	self.sx = 1
	self.sy = 1
	self.ox = 0
	self.oy = 0
	self.matrix = matrix4x4()

	self._camera_2d_mode = true
end

function camera:set_center_offset(ox, oy)
	self.ox = math.floor(scenedispatcher.w / 2) + (ox or 0)
	self.oy = math.floor(scenedispatcher.h / 2) + (oy or 0)
end

function camera:_apply_transform()
	if self._update then
		local sx = 1 / self.sx
		local sy = 1 / self.sy

		self.matrix:identity()
		self.matrix:translate(self.ox, self.oy, 0)
		self.matrix:scale(sx, sy, 1)
		self.matrix:translate(-self.x, -self.y, 0)
		self.matrix:rotate(-self.rotation, vec3.unit_z)

		self._update = false
	end
	love.graphics.applyTransform(self.matrix:to_temp_transform_object())
end

function camera:get_viewport()
	local x, y = self:get_position()
	return x, y, scenedispatcher.w, scenedispatcher.h
end

function camera:move(dx, dy)
	self._update = true
	self.x = self.x + (dx or 0)
	self.y = self.y + (dy or 0)
end

function camera:rotate(angle)
	self._update = true
	self.rotation = angle
end

function camera:scale(sx, sy)
	self._update = true
	sx = sx or 1
	self.sx = sx
	self.sy = sy or sx
end

function camera:set_center(nx, ny, w, h)
	self.ox = w * nx
	self.oy = h * ny
end

function camera:set_position(x, y)
	self._update = true
	self.x = x or self.x
	self.y = y or self.y
end

function camera:get_position()
	return self.x - self.ox, self.y - self.oy
end

function camera:set_position_inside_bound(x, y, w, h)
	local x1 = x + self.ox
	local x2 = x - self.ox
	local y1 = y + self.oy
	local y2 = y - self.oy
	if x2 < 0 then x = self.ox end
	if x1 > w then x = w - self.ox end
	if y2 < 0 then y = self.oy end
	if y1 > h then y = h - self.oy end
	self:set_position(x, y)
end

return camera