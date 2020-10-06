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

function scenedispatcher:init_scene_viewport(w, h)
	self.w = w
	self.h = h
	self.canvas = lovg.newCanvas(self.w, self.h, {format = 'normal', msaa = 0})
	self.canvas:setFilter('nearest', 'nearest')

	self:update_viewport()
	self.next_scene = nil
	self.depthstencil = true
	self.effect = default_effect
end

function scenedispatcher:update_viewport()
	local w, h = love.window.getMode()
	local dpi_scale = love.window.getDPIScale()
	w = math.floor(w / dpi_scale)
	h = math.floor(h / dpi_scale)
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

function scenedispatcher:set(name)
	local scene = list[name]
	assert(scene)
	current_scene = scene
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
	love.graphics.setCanvas({self.canvas, depthstencil = self.depthstencil})
	lovg.clear()
	if current_scene then current_scene:render(dt) end
	if self.next_scene then
		if self.effect.update then self.effect:update() end
		if self.effect.render then self.effect:render() end
		if self.effect:completed() then
			current_scene = self.next_scene
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

return scenedispatcher()