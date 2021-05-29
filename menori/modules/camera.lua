--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Camera for 2D scenes.
]]
-- @module menori.Camera

local modules = (...):match('(.*%menori.modules.)')

local class       = require (modules .. 'libs.class')
local ml          = require (modules .. 'ml')
local application = require (modules .. 'application')

local mat4 = ml.mat4
local vec3 = ml.vec3

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
	self.matrix = mat4()

	self._camera_2d_mode = true
end

--- Set camera pivot.
-- @tparam number nx normalized x
-- @tparam number ny normalized y
function camera:set_pivot(nx, ny)
	nx = nx or 0.5
	ny = ny or 0.5
	self._update = false
	self.ox = math.floor(application.w * nx)
	self.oy = math.floor(application.h * ny)
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

--- Get viewport.
-- @treturn number x
-- @treturn number y
-- @treturn number w
-- @treturn number h
function camera:get_viewport()
	local x, y = self:get_position()
	return x, y, application.w, application.h
end

--- Move camera.
-- @tparam number dx delta x
-- @tparam number dy delta y
function camera:move(dx, dy)
	self._update = true
	self.x = self.x + (dx or 0)
	self.y = self.y + (dy or 0)
end

--- Rotate camera.
-- @tparam number angle in radians
function camera:rotate(angle)
	self._update = true
	self.rotation = angle
end

--- Scale camera.
-- @tparam number sx scale factor x
-- @tparam number sy scale factor y
function camera:scale(sx, sy)
	self._update = true
	sx = sx or 1
	self.sx = sx
	self.sy = sy or sx
end

--- Set camera position.
-- @tparam number x
-- @tparam number y
function camera:set_position(x, y)
	self._update = true
	self.x = x or self.x
	self.y = y or self.y
end

--- Get camera position.
-- @treturn number self.x - self.ox
-- @treturn number self.y - self.oy
function camera:get_position()
	return self.x - self.ox, self.y - self.oy
end

--- Deprecated
function camera:set_position_inside_bound(x, y, w, h)
	local x1 = x - self.ox
	local x2 = x + self.ox
	local y1 = y - self.oy
	local y2 = y + self.oy
	if x1 < 0 then x = self.ox end
	if y1 < 0 then y = self.oy end
	if x2 > w then x = w - self.ox end
	if y2 > h then y = h - self.oy end

	self:set_position(x, y)
end

return camera