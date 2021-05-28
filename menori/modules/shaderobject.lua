--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Description.
]]
-- @module menori.ShaderObject

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

local shaderobject = class('ShaderObject')
local temp

function shaderobject:constructor(...)
	self.shader = love.graphics.newShader(...)
	local status, message = love.graphics.validateShader(true, ...)
	if not status then
		print(...)
		print(status, message)
	end
	return self
end

function shaderobject:attach()
	temp = love.graphics.getShader()
	love.graphics.setShader(self.shader)
end

function shaderobject:detach()
	temp = self.shader
	love.graphics.setShader(temp)
end

function shaderobject:send(name, ...)
	if self.shader:hasUniform(name) then
		self.shader:send(name, ...)
	end
end

function shaderobject:send_matrix(name, matrix, layout)
	if self.shader:hasUniform(name) then
		self.shader:send(name, matrix:to_temp_table())
	end
end

function shaderobject:send_color(name, ...)
	if self.shader:hasUniform(name) then
		self.shader:sendColor(name, ...)
	end
end

return shaderobject