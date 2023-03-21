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
--- @classmod App

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

--- Get current scene.
-- @return Scene object
function app_mt:get_current_scene()
      return self.current_scene
end

--- Get viewport dimensions.
-- @treturn number x
-- @treturn number y
-- @treturn number w
-- @treturn number h
function app_mt:get_viewport()
      return self.ox, self.oy, self.w or graphics_w, self.h or graphics_h
end

--- Get viewport width.
-- @treturn number
function app_mt:get_viewport_w()
      return self.w or graphics_w
end
--- Get viewport height.
-- @treturn number
function app_mt:get_viewport_h()
      return self.h or graphics_h
end

--- Add scene to the scene list.
-- @tparam string name
-- @tparam menori.Scene scene object
function app_mt:add_scene(name, scene)
      self.scenes[name] = scene
end

--- Get scene from the scene list by the name.
-- @tparam string name
-- @treturn menori.Scene object
function app_mt:set_scene(name)
      self.current_scene = self.scenes[name]
end


--- Main update function.
-- @tparam number dt
function app_mt:update(dt)
      self.accumulator = self.accumulator + dt

      local target_dt = self.tick_period

      local steps = math.floor(self.accumulator / target_dt)

      if steps > 0 then
            self.accumulator = self.accumulator - steps * target_dt
      end

      local interpolation_dt = self.accumulator / target_dt
      local scene = self.current_scene

      if scene and scene.update then
            self.current_scene.interpolation_dt = interpolation_dt
            self.current_scene.dt = target_dt

            while steps > 0 do
                  self.current_scene:update(target_dt)
                  steps = steps - 1
            end
      end
end

--- Main render function.
function app_mt:render()
      if self.current_scene and self.current_scene.render then
            self.current_scene:render()
      end
end


--- Handling any LOVE event. Redirects an event call to an overridden function in the active scene.
-- @tparam string eventname
function app_mt:handle_event(eventname, ...)
      local current_scene = self.current_scene
      if current_scene then
            local event = current_scene[eventname]
            if current_scene and event then
                  event(current_scene, ...)
            end
      end
end

return setmetatable(app, app_mt)