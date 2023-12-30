--[[
-------------------------------------------------------------------------------
      Menori Co.
      @author rozenmad
      2023
-------------------------------------------------------------------------------
]]

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')

local canvas = class('Canvas')

local default_opt = {}

function canvas:init(opt)
      opt = opt or default_opt
      local window_w, window_h = love.window.getMode()

      self.adaptive = opt.adaptive ~= false

      self.w = opt.w
      self.h = opt.h

      self.ox = 0
      self.oy = 0

      self.scale = 1

      self.color = {1, 1, 1}
      self.alpha = 1

      self.window_w = window_w
      self.window_h = window_h

      self.clear_color = {1, 1, 1, 1}

      if not self.adaptive then
            self.w = self.window_w
            self.h = self.window_h
      end

      if not self.w or not self.h then
            local t = { window = {}, audio = {}, modules = {}  }
            love.conf(t)

            self.w, self.h = t.window.width or 800, t.window.height or 600
      end

      self.canvas = love.graphics.newCanvas(self.w, self.h, {
            type = opt.type, format = opt.format, readable = opt.readable, msaa = opt.msaa, dpiscale = opt.dpiscale, mipmaps = opt.mipmaps
      })
      self.render_settings = {
            self.canvas, depth = opt.depth, stencil = opt.stencil
      }
end

function canvas:set_clear_color(r, g, b, a)
      self.clear_color[1] = r
      self.clear_color[2] = g
      self.clear_color[3] = b
      self.clear_color[4] = a
end

function canvas:render_to(callback, ...)
      local temp = love.graphics.getCanvas()
      love.graphics.setCanvas(self.render_settings)
      love.graphics.push()

      callback(...)

      love.graphics.pop()
      love.graphics.setCanvas(temp)
end

function canvas:draw()
      local r, g, b = self.color[1], self.color[2], self.color[3]
      love.graphics.setColor(r, g, b, self.alpha)

      if self.adaptive then
            love.graphics.draw(self.canvas, self.ox, self.oy, 0, self.scale, self.scale)
      else
            love.graphics.draw(self.canvas, 0, 0)
      end
end

function canvas:resize(w, h)
      self.window_w = w
      self.window_h = h

      if self.adaptive then
            self.sx = self.window_w / self.w
            self.sy = self.window_h / self.h

            self.scale = math.min(self.sx, self.sy)

            self.ox = (self.window_w - self.w * self.scale) * 0.5
            self.oy = (self.window_h - self.h * self.scale) * 0.5
      else
            self.canvas:release()
            self.canvas = love.graphics.newCanvas(w, h)
            self.render_settings.canvas = self.canvas

            self.w = self.window_w
            self.h = self.window_h

            self.sx = 1
            self.sy = 1

            self.scale = 1

            self.ox = 0
            self.oy = 0
      end
end

function canvas:convert_mouse_position(mx, my)
      mx = math.max(0, math.min(self.w, (mx - self.ox) * 1.0/self.scale))
      my = math.max(0, math.min(self.h, (my - self.oy) * 1.0/self.scale))

      return mx, my
end

return canvas