--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
An environment is a class that sends information about the current settings of the environment (such as ambient color, fog, light sources, camera transformation matrices) etc to the shader.
]]
-- @module menori.Environment

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')
local ml 	= require (modules .. 'ml')

local vec3 = ml.vec3

local Environment = class('Environment')

local directional_light = class('DirectionalLight')

function directional_light:constructor(dx, dy, dz, color)
	self.direction = vec3(dx, dy, dz):normalize()
	self.color = color
	self.type = 1
	self.enabled = true
end

function directional_light:to_uniforms(shader, light_index_str)
	if self.enabled then
		shader:send(light_index_str .. 'direction', {self.direction:unpack()})
		shader:send(light_index_str .. 'color', self.color)
		shader:send(light_index_str .. 'type', self.type)
	else
		shader:send(light_index_str .. 'type', 0)
	end
end

local point_light = class('PointLight')

function point_light:constructor(x, y, z, color, power, distance)
	self.position = vec3(x, y, z)
	self.color = color
	self.power = power
	self.distance = distance
	self.type = 2
	self.enabled = true
end

function point_light:to_uniforms(shader, light_index_str)
	if self.enabled then
		shader:send(light_index_str .. 'position', {self.position:unpack()})
		shader:send(light_index_str .. 'color', self.color)
		shader:send(light_index_str .. 'distance', self.distance)
		shader:send(light_index_str .. 'power', self.power)
		shader:send(light_index_str .. 'type', self.type)
	else
		shader:send(light_index_str .. 'type', 0)
	end
end

--- Constructor
-- @param camera Сamera object that will be associated with this environment
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

--- Set optional uniform
-- @tparam string name
-- @tparam any value
function Environment:set_optional_uniform(name, value)
	self.uniform_table[name] = value
end

function Environment:add_direction_light(...)
	self.lights[#self.lights + 1] = directional_light(...)
end

function Environment:add_point_light(...)
	self.lights[#self.lights + 1] = point_light(...)
end

--- Add light source
-- @tparam string name
-- @tparam any value
function Environment:add_light(light)
	self.lights[#self.lights + 1] = light
end

--- Set fog color
-- @tparam number r
-- @tparam number g
-- @tparam number b
-- @tparam number a
function Environment:set_fog_color(r, g, b, a)
	self.uniform_table.fog_color = {r, g, b, a}
end

--- Sends all the environment uniforms to the shader. This function can be used when creating your own display objects, or for shading technique.
-- @param shader Shader object
function Environment:send_uniforms_to(shader)
	local camera = self.camera
	shader:send_matrix("m_view", camera.m_view)
	shader:send_matrix("m_projection", camera.m_projection)

	for k, v in pairs(self.uniform_table) do
		shader:send(k, v)
	end

	self:send_light_sources_to(shader)
end

--- Sends light sources uniforms to the shader. This function can be used when creating your own display objects, or for shading technique.
-- @param shader Shader object
function Environment:send_light_sources_to(shader)
	shader:send('light_count', #self.lights)
	for i = 1, #self.lights do
		local light = self.lights[i]
		local light_index_str =  "lights[" .. (i - 1) .. "]."
		light:to_uniforms(shader, light_index_str)
	end
end

return
Environment