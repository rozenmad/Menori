--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
The main class for managing scenes and the viewport.
]]
-- @module menori.Application

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

local list = {}
local current_scene
local accumulator = 0
local tick_period = 1.0 / 60.0
local ox = 0
local oy = 0

local application = class('Application')

local lovg = love.graphics
local default_effect = nil

--- Constructor.
function application:constructor()
	self.next_scene = nil
	self.effect = default_effect
end

--- Resize viewport.
-- @tparam number w
-- @tparam number h
-- @tparam table opt (Optional)
function application:resize_viewport(w, h, opt)
	opt = opt or {}
	self.resizable = (w == nil or h == nil)
	if self.resizable then
		w, h = love.graphics.getDimensions()
	end
	self.x = opt.x
	self.y = opt.y
	self.w = (w - (self.x or 0))
	self.h = (h - (self.y or 0))
	self.sx = 1
	self.sy = 1
	local filter = opt.filter or 'nearest'
	self.canvas = lovg.newCanvas(self.w, self.h, { format = opt.format, msaa = opt.msaa })
	self.canvas:setFilter(filter, filter)

	self:_update_viewport_position()
end

--- Get viewport dimensions.
-- @treturn number w
-- @treturn number h
function application:get_dimensions()
	return self.w, self.h
end

function application:_update_viewport_position()
	local dpi = love.window.getDPIScale()
	local window_w, window_h = love.window.getMode()

	local w = math.floor(window_w / dpi)
	local h = math.floor(window_h / dpi)
	if not self.x and not self.y then
		local _sx = w / self.w
		local _sy = h / self.h
		local canvas_scale = math.min(_sx, _sy)
		self.sx = canvas_scale
		self.sy = canvas_scale

		self.x = 0
		self.y = 0

		ox = (w - self.w * self.sx) / 2
		oy = (h - self.h * self.sy) / 2
	else
		ox = self.x
		oy = self.y
	end
end

--- Change scene with a transition effect.
-- @tparam string name
function application:switch_scene(effect, name)
	self.next_scene = list[name]
	assert(effect)
	assert(self.next_scene)
	self.effect = effect
end

--- Add scene to the scene list.
-- @tparam string name
function application:add_scene(name, scene_object)
	list[name] = scene_object
end

--- Get scene from the scene list by the name.
-- @tparam string name
-- @return Scene object
function application:get_scene(name)
	return list[name]
end

--- Set current scene by the name.
-- @tparam string name
function application:set_scene(name)
	self:_change_scene(list[name])
end

function application:_change_scene(next_scene)
	assert(next_scene)
	local a = current_scene
	local b = next_scene

	if a and a.on_leave then a:on_leave() end
	if b and b.on_enter then b:on_enter() end
	current_scene = b
end

--- Get current scene.
-- @return Scene object
function application:get_current_scene()
	return current_scene
end

--- Application update function.
-- @tparam number dt
function application:update(dt)
	local update_count = 0
	accumulator = accumulator + dt
	while accumulator >= tick_period do
		update_count = update_count + 1
		if current_scene and current_scene.update then current_scene:update(dt) end

		accumulator = accumulator - tick_period
		if update_count > 3 then
			accumulator = 0
			break
		end
	end
end

--- Application render function.
-- @tparam number dt
function application:render(dt)
	lovg.setCanvas({ self.canvas, depth = true })
	lovg.clear()
	lovg.push()
	if current_scene and current_scene.render then current_scene:render(dt) end
	if self.next_scene then
		if self.effect.update then self.effect:update() end
		if self.effect.render then self.effect:render() end
		if self.effect:completed() then
			self:_change_scene(self.next_scene)
			self.next_scene = nil
			self.effect = nil
		end
	end
	lovg.setCanvas()
	lovg.setShader()
	lovg.pop()

	lovg.draw(self.canvas, ox, oy, 0, self.sx, self.sy)
end

local instance = application()

--- Resize callback.
function application.resize(w, h)
	if instance.resizable then
		instance:resize_viewport()
	else
		instance:update_viewport_position()
	end
	for _, v in pairs(list) do
		if v.resize then v:resize(w, h) end
	end
end

--- Mousemoved callback.
function application.mousemoved(x, y, dx, dy, istouch)
	for _, v in pairs(list) do
		if v.mousemoved then v:mousemoved(x, y, dx, dy, istouch) end
	end
end

return instance