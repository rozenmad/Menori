--[[
-------------------------------------------------------------------------------
      Menori
      @author rozenmad
      2022
-------------------------------------------------------------------------------
]]

--[[--
Sprite class is a helper object for drawing textures that can contain a set of frames and play animations.
]]
-- @classmod Sprite

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

local sprite = class('Sprite')

--- The public constructor.
-- @param quads table of [Quad](https://love2d.org/wiki/Quad) objects
-- @param image [Image](https://love2d.org/wiki/Image)
function sprite:init(quads, image)
      self.quads = quads
      self.image = image
      self.index = 1
      self.px = 0
      self.py = 0

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
      self.px = px
      self.py = py
end

--- Get frame count.
-- @treturn number
function sprite:get_frame_count()
      return #self.quads
end

--- Get normalized frame texture UV coordinates [0 - 1]
-- @tparam number i frame index
-- @treturn table {x1=, y1=, x2=, y2=}
function sprite:get_frame_uv(i)
      i = i or self.index
      local quad = self.quads[i]
      local image_w, image_h = quad:getTextureDimensions()
      local x, y, w, h = quad:getViewport()
      return {
            x1 = x / image_w,
            y1 = y / image_h,
            x2 = (x + w) / image_w,
            y2 = (y + h) / image_h,
      }
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

--- Sprite animation update function.
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
-- See [love.graphics.draw](https://love2d.org/wiki/love.graphics.draw).
-- @tparam number x
-- @tparam number y
-- @tparam number angle
-- @tparam number sx
-- @tparam number sy
-- @tparam number ox
-- @tparam number oy
-- @tparam number kx
-- @tparam number ky
function sprite:draw(x, y, angle, sx, sy, ox, oy, kx, ky)
      local _, _, w, h = self:get_frame_viewport()
      ox = (ox or 0) + self.px * w
      oy = (oy or 0) + self.py * h
      love.graphics.draw(self.image, self.quads[self.index], x, y, angle, sx, sy, ox, oy, kx, ky)
end

--- Sprite draw_in_viewport function.
-- Fits the sprite into the specified bounding rectangle.
-- @tparam number x
-- @tparam number y
-- @tparam string fit Must be 'max', 'min', 'fill' or 'none'
-- @tparam number bound_w Width of bounding volume
-- @tparam number bound_h Height of bounding volume
-- @tparam number align_nx normalized align x
-- @tparam number align_ny normalized align y
-- @tparam number angle
-- @tparam number sx
-- @tparam number sy
-- @tparam number kx
-- @tparam number ky
function sprite:draw_in_viewport(x, y, fit, viewport_w, viewport_h, align_nx, align_ny, angle, sx, sy, ox, oy, kx, ky)
      local iw, ih = self.image:getDimensions()

      sx = sx or 1
      sy = sy or 1

      align_nx = align_nx or 0.5
      align_ny = align_ny or 0.5

      viewport_w = viewport_w or iw
      viewport_h = viewport_h or ih

      if
      fit == 'none' then
      elseif
      fit == 'fill' then
            self.scale_x = viewport_w / iw
            self.scale_y = viewport_h / ih
      elseif
      fit == 'min' then
            self.scale_x = math.min(viewport_w / iw, viewport_h / ih)
            self.scale_y = self.scale_x
      elseif
      fit == 'max' then
            self.scale_x = math.max(viewport_w / iw, viewport_h / ih)
            self.scale_y = self.scale_x
      end

      sx = self.scale_x * sx
      sy = self.scale_y * sy

      x = x + align_nx * viewport_w - self.px * iw * sx
      y = y + align_ny * viewport_h - self.py * ih * sy

      love.graphics.draw(self.image, self.quads[self.index], x, y, angle, sx, sy, ox, oy, kx, ky)
end

return sprite