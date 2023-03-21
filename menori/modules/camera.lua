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

local app   = require (modules .. 'app')
local class = require (modules .. 'libs.class')
local ml    = require (modules .. 'ml')

local mat4 = ml.mat4
local vec3 = ml.vec3
local vec2 = ml.vec2
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

      self.px = 0.5
      self.py = 0.5
      self.matrix = mat4()

      self._camera_2d_mode = true

      local _, _, viewport_w, viewport_h = self:get_viewport()
      self:set_bounding_box(viewport_w, viewport_h)
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
            local _, _, dw, dh = self:get_viewport()

            local sx = 1 / self.sx
            local sy = 1 / self.sy

            local s = math.sin(self.angle * 0.5)
            local c = math.cos(self.angle * 0.5)

            self._q.z = s
            self._q.w = c

            local rox = dw * self.sx
            local roy = dh * self.sy
            local ox = (self.bound_w-rox) * (0.5 - self.px)
            local oy = (self.bound_h-roy) * (0.5 - self.py)

            self._p:set(-self.x+ox, -self.y+oy, 0)
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
      local _, _, w, h = app:get_viewport()
      local x, y = self:get_position()
      return 0, 0, w, h
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

function camera:get_bound()
      return self.bound_w , self.bound_h
end

--- Set camera bounding box.
-- @tparam number w bounding box width.
-- @tparam number h bounding box height.
-- @tparam number pvx normalized center x inside bounding box.
-- @tparam number pvy normalized center y inside bounding box.
function camera:set_bounding_box(w, h, pvx, pvy)
      self.bound_w = w
      self.bound_h = h
end

return camera