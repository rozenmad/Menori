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
local UniformList = require (modules .. 'core3d.uniform_list')

--- Class members
-- @table Environment
-- @field camera The camera associated with the current Environment.
-- @field uniform_list List of uniforms of the current Environment. Uniforms in the list are automatically sent to the shader, which will be used to display objects with this environment.
-- @field lights List of light sources.

local Environment = class('Environment')

--- Constructor
-- @tparam Сamera camera camera that will be associated with this environment
function Environment:constructor(camera)
	self.camera = camera

	self.uniform_list = UniformList()
	self.lights = {}
end

--- Add light source.
-- @tparam LightObject light
function Environment:add_light(light)
	self.lights[#self.lights + 1] = light
end

--- Sends all the environment uniforms to the shader. This function can be used when creating your own display objects, or for shading technique.
-- @tparam Shader
function Environment:send_uniforms_to(shader)
	self.uniform_list:send_to(shader)

	local camera = self.camera
	shader:send("m_view", camera.m_view.data)
	shader:send("m_projection", camera.m_projection.data)

	self:send_light_sources_to(shader)
end

local function noexcept_send_uniform(shader, name, ...)
	if shader:hasUniform(name) then
      	shader:send(name, ...)
	end
end

--- Sends light sources uniforms to the shader. This function can be used when creating your own display objects, or for shading technique.
-- @tparam Shader
function Environment:send_light_sources_to(shader)
	noexcept_send_uniform(shader, 'light_count', #self.lights)
	for i = 1, #self.lights do
		local light = self.lights[i]
		local light_index_str =  "lights[" .. (i - 1) .. "]."
		light:to_uniforms(shader, light_index_str)
	end
end

return
Environment