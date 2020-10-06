--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- An Environment contains the uniform values specific for a location. For example, the lights are part of the Environment.
-- @module Environment
local class = require 'menori.modules.libs.class'

local Environment = class('Environment')

local cpml = require 'libs.cpml'
local vec3 = cpml.vec3

local directional_light = class('DirectionalLight')

function directional_light:constructor(dx, dy, dz, color)
	self.direction = vec3(dx, dy, dz):normalize()
	self.color = color
	self.type = 1
end

function directional_light:to_uniforms(shader, light_index_str)
	shader:send(light_index_str .. 'direction', {self.direction:unpack()})
	shader:send(light_index_str .. 'color', self.color)
	shader:send(light_index_str .. 'type', self.type)
end

--- Constructor
function Environment:constructor(camera)
	self.camera = camera

	self.uniform_table = {
		fog_color = {love.math.colorFromBytes(0, 0, 0, 255)},
		fog_density = 0.05,
		fog_indent = 0.0,
		ambient_color = {1.0, 1.0, 1.0}
	}

	self.lights = {}
	self.shader = Environment.default_shader
end

function Environment:set_optional_uniform(name, value)
	self.uniform_table[name] = value
end

function Environment:add_direction_light(dx, dy, dz, color)
	self.lights[#self.lights + 1] = directional_light(dx, dy, dz, color)
end

function Environment:add_light(light)
	self.lights[#self.lights + 1] = light
end

--- Set fog color
function Environment:set_fog_color(r, g, b, a)
	self.uniform_table.fog_color = {r, g, b, a}
end

function Environment:send_uniforms_to(shader)
	local camera = self.camera
	shader:send_matrix("m_view", camera.m_view)
	shader:send_matrix("m_projection", camera.m_projection)

	for k, v in pairs(self.uniform_table) do
		shader:send(k, v)
	end

	self:send_light_sources_to(shader)
end

function Environment:send_light_sources_to(shader)
	shader:send('light_count', #self.lights)
	for i = 1, #self.lights do
		local light_index_str =  "lights[" .. (i - 1) .. "]."
		local light = self.lights[i]

		light:to_uniforms(shader, light_index_str)
	end
end

return
Environment