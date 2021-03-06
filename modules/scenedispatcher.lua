--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local class = require 'menori.modules.libs.class'

local list = {}
local current_scene
local accumulator = 0
local tick_period = 1.0 / 60.0
local ox = 0
local oy = 0
local canvas_scale = 1

local scenedispatcher = class('SceneDispatcher')

local lovg = love.graphics
local default_effect = nil

function scenedispatcher:constructor()
	self.next_scene = nil
	self.depthstencil = true
	self.effect = default_effect
end

function scenedispatcher:resize_viewport(w, h)
	self.resizable = w == nil or h == nil
	if self.resizable then
		w, h = love.graphics.getDimensions()
	end
	self.w = w
	self.h = h
	self.canvas = lovg.newCanvas(self.w, self.h, { format = 'normal', msaa = 0 })
	self.canvas:setFilter('nearest', 'nearest')

	self:update_viewport_position()
end

function scenedispatcher:getDimensions()
	return self.w, self.h
end

function scenedispatcher:update_viewport_position()
	local w, h = love.graphics.getDimensions()
	local dpi = love.window.getDPIScale()
	w = math.floor(w / dpi)
	h = math.floor(h / dpi)
	local sx = w / self.w
	local sy = h / self.h
	canvas_scale = math.min(sx, sy)

	ox = (w - self.w * canvas_scale) / 2
	oy = (h - self.h * canvas_scale) / 2
end

function scenedispatcher:switch(effect, name)
	self.next_scene = list[name]
	assert(effect)
	assert(self.next_scene)
	self.effect = effect
end

function scenedispatcher:add(name, scene_object)
	list[name] = scene_object
end

function scenedispatcher:get(name)
	return list[name]
end

function scenedispatcher:set(name)
	self:_change_scene(list[name])
end

function scenedispatcher:_change_scene(next_scene)
	assert(next_scene)
	local a = current_scene
	local b = next_scene

	love.mousepressed = b:_input_listeners_callback('mousepressed')
	love.mousereleased = b:_input_listeners_callback('mousereleased')
	love.textinput = b:_input_listeners_callback('textinput')
	love.mousemoved = b:_input_listeners_callback('mousemoved')
	love.keypressed = b:_input_listeners_callback('keypressed')
	love.keyreleased = b:_input_listeners_callback('keyreleased')
	love.wheelmoved = b:_input_listeners_callback('wheelmoved')

	if a and a.on_leave then a:on_leave() end
	if b and b.on_enter then b:on_enter() end
	current_scene = b
end

function scenedispatcher:get_current()
	return current_scene
end

function scenedispatcher:update(dt)
	local update_count = 0
	accumulator = accumulator + dt
	while accumulator >= tick_period do
		update_count = update_count + 1
		if current_scene then current_scene:update(dt) end

		accumulator = accumulator - tick_period
		if update_count > 3 then
			accumulator = 0
			break
		end
	end
end

function scenedispatcher:render(dt)
	love.graphics.setCanvas({ self.canvas, depthstencil = self.depthstencil })
	lovg.clear()
	if current_scene then current_scene:render(dt) end
	if self.next_scene then
		if self.effect.update then self.effect:update() end
		if self.effect.render then self.effect:render() end
		if self.effect:completed() then
			self:_change_scene(self.next_scene)
			self.next_scene = nil
			self.effect = nil
		end
	end
	love.graphics.setCanvas()
	lovg.setShader()
end

function scenedispatcher:present()
	lovg.draw(self.canvas, ox, oy, 0, canvas_scale, canvas_scale)
end

local instance = scenedispatcher()
function love.resize(w, h)
	if instance.resizable then
		instance:resize_viewport()
	else
		instance:update_viewport_position()
	end
	for _, v in pairs(list) do
		if v.resize then v:resize(w, h) end
	end
end

return instance