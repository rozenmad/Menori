--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
]]

--[[--
Camera for 2D scenes.
]]
-- @classmod Camera

local modules = (...):match('(.*%menori.modules.)')

--local Application = require (modules .. 'application')
local class = require (modules .. 'libs.class')
local ml    = require (modules .. 'ml')

local mat4 = ml.mat4
local vec3 = ml.vec3
local quat = ml.quat

local camera = class('Camera')

--- The public constructor.
function camera:init()
	self._update = true

	self._q = quat(0, 0, 0, 1)
	self._p = vec3(0)
	self._s = vec3(0)

	self.x = 0
	self.y = 0
	self.angle = 0
	self.sx = 1
	self.sy = 1
	self.ox = 0
	self.oy = 0
	self.matrix = mat4()

	self._camera_2d_mode = true

	self:set_bounding_box(0, 0, 0, 0)
end

--- Set camera pivot.
-- @tparam number nx normalized x
-- @tparam number ny normalized y
function camera:set_pivot(nx, ny)
	local _, _, viewport_w, viewport_h = self:get_viewport()
	nx = nx or 0.5
	ny = ny or 0.5
	self.ox = math.floor(viewport_w * nx)
	self.oy = math.floor(viewport_h * ny)
	self._update = true
end

function camera:_apply_transform()
	--local sx = 1 / self.sx
	--local sy = 1 / self.sy
	if self._update then
		local sx = 1 / self.sx
		local sy = 1 / self.sy

		local s = math.sin(self.angle * 0.5)
		local c = math.cos(self.angle * 0.5)

		self._q.z = s
		self._q.w = c

		self._p:set(-self.x, -self.y, 0)
		self._s:set(sx, sy, 1)

		--self.matrix:compose(self._p, self._q, self._s)

		self.matrix:identity()

		self.matrix:translate(self.ox, self.oy, 0)
		self.matrix:scale(self._s)
		self.matrix:rotate(self._q)
		self.matrix:translate(self._p)

		self._update = false
	end
	--love.graphics.applyTransform(love.math.newTransform(-self.x, -self.y, self.angle, sx, sy, self.ox, self.oy))
	love.graphics.applyTransform(self.matrix:to_temp_transform_object())
end

--- Get viewport.
-- @treturn number x
-- @treturn number y
-- @treturn number w
-- @treturn number h
function camera:get_viewport()
	local w, h = love.graphics.getDimensions()
	local x, y = self:get_position()
	return x, y, w, h
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
	self.angle = angle
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
	self.x = self.x
	self.y = self.y
end

--- Get camera position.
-- @treturn number self.x - self.ox
-- @treturn number self.y - self.oy
function camera:get_position()
	return self.x - self.ox, self.y - self.oy
end

--- Set camera bounding box.
-- @tparam number w bounding box width.
-- @tparam number h bounding box height.
-- @tparam number pvx normalized center x inside bounding box.
-- @tparam number pvy normalized center y inside bounding box.
function camera:set_bounding_box(w, h, pvx, pvy)
	self.bound_w = w
	self.bound_h = h
	self.bound_pvx = pvx
	self.bound_pvy = pvy
	self._edges = self:calculate_distance_to_edge(self.sx, self.sy)

	--self:set_adjust_to_screen()
end

function camera:adjust_screen()
      local window_w, window_h = love.graphics.getDimensions()

      local sx = window_w / self.bound_w
      local sy = window_h / self.bound_h
      local min, max = math.min(sx, sy), math.max(sx, sy)
	self.sx = 1/max
	self.sy = 1/max
end

function camera:calculate_distance_to_edge(sx, sy)
	local _, _, viewport_w, viewport_h = self:get_viewport()

	local w = self.bound_w
	local h = self.bound_h
	local bound_oxs = self.bound_pvx
	local bound_oys = self.bound_pvy

	local oxs = (self.ox / viewport_w)
	local oys = (self.oy / viewport_h)
	local ixs = 1 - oxs
	local iys = 1 - oys

	local bound_ixs = 1 - bound_oxs
	local bound_iys = 1 - bound_oys

	viewport_w = viewport_w * sx
	viewport_h = viewport_h * sy

	local x1 = (viewport_w * oxs) - (w * bound_oxs)
	local x2 = (w * bound_ixs) - (viewport_w * ixs)

	local y1 = (viewport_h * oys) - (h * bound_oys)
	local y2 = (h * bound_iys) - (viewport_h * iys)

	return {
		x1 = x1,
		x2 = x2,
		y1 = y1,
		y2 = y2,
	}
end

function camera:get_distance_to_edge(position_apply)
	if position_apply then
		local d = self._edges
		return {
			x1 = self.x - d.x1,
			x2 = d.x2 - self.x,
			y1 = self.y - d.y1,
			y2 = d.y2 - self.y,
		}
	else
		return self._edges
	end
end

function camera:get_position_from_normalize(nx, ny, sx, sy)
	local edges = self:calculate_distance_to_edge(sx, sy)

	local w, h = edges.x2 - edges.x1, edges.y2 - edges.y1
	nx = edges.x1 + nx * w
	ny = edges.y1 + ny * h
	return nx, ny
end


--- Set camera position inside bounding box.
-- @tparam number x position x
-- @tparam number y position y
function camera:set_position_inside_bound(x, y)
	local x1 = self._edges.x1
	local x2 = self._edges.x2
	local y1 = self._edges.y1
	local y2 = self._edges.y2

	local px = x
	local py = y

	if py > y2 then py = y2 end if py < y1 then py = y1 end
	if px > x2 then px = x2 end if px < x1 then px = x1 end

	if x1 >= x2 then px = 0 end
	if y1 >= y2 then py = 0 end

	self:set_position(px, py)
end

return camera