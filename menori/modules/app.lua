--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
]]

--[[--
Singleton object.
The main class for managing scenes and the viewport.
]]
--- @classmod Application

local modules = (...):match('(.*%menori.modules.)')

local lovg = love.graphics
local app_mt = {}
app_mt.__index = app_mt

local graphics_w, graphics_h = love.graphics.getDimensions()

local app = {
      ox = 0, oy = 0, sx = 1, sy = 1,
      scenes = {},
      accumulator = 0,
      tick_period = 1.0 / 60.0,
}

function app_mt:get_current_scene()
	return self.current_scene
end

function app_mt:get_viewport()
      return self.ox, self.oy, self.w or graphics_w, self.h or graphics_h
end

function app_mt:get_viewport_w()
      return self.w or graphics_w
end
function app_mt:get_viewport_h()
      return self.h or graphics_h
end

function app_mt:add_scene(name, scene)
      self.scenes[name] = scene
end

function app_mt:set_scene(name)
      self.current_scene = self.scenes[name]
end

function app_mt:update(dt)
	local update_count = 0
	self.accumulator = self.accumulator + dt
	while self.accumulator >= self.tick_period do
		update_count = update_count + 1
		if self.current_scene and self.current_scene.update then self.current_scene:update(dt) end

		self.accumulator = self.accumulator - self.tick_period
		if update_count > 3 then
			self.accumulator = 0
			break
		end
	end
end

function app_mt:render(dt)
      if self.current_scene and self.current_scene.render then self.current_scene:render(dt) end
end

function app_mt:handle_event(eventname, ...)
      local current_scene = self.current_scene
      local event = current_scene[eventname]
      if current_scene and event then
            event(current_scene, ...)
      end
end

return setmetatable(app, app_mt)