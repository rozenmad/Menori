--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

--[[--
An environment is a class that sends information about the current settings of the environment
(such as ambient color, fog, light sources, camera transformation matrices) etc to the shader.
]]
-- @classmod Environment

local modules = (...):match('(.*%menori.modules.)')

local utils       = require (modules .. 'libs.utils')
local UniformList = require (modules .. 'core3d.uniform_list')
local ml          = require (modules .. 'ml')

local Environment = UniformList:extend('Environment')

local temp_projection_m = ml.mat4()
local temp_int_view_m = ml.mat4()

----
-- The public constructor.
-- @param camera Camera that will be associated with this environment.
function Environment:init(camera)
	Environment.super.init(self)

	self.camera = camera
	self.lights = {}

	self._shader_object_cache = nil
end

----
-- Add light source.
-- @tparam strign uniform_name Name of uniform used in the shader
-- @tparam menori.UniformList light Light source object
function Environment:add_light(uniform_name, light)
	local t = self.lights[uniform_name] or {}
	self.lights[uniform_name] = t
	table.insert(t, light)
end

----
-- Send all the environment uniforms to the shader.
-- This function can be used when creating your own display objects, or for shading technique.
-- This method is called automatically when the environment is used in scene:render_nodes()
-- @param shader [LOVE Shader](https://love2d.org/wiki/Shader)
function Environment:send_uniforms_to(shader)
	local camera = self.camera
	self:send_to(shader)

	local render_to_canvas = love.graphics.getCanvas() ~= nil
	temp_projection_m:copy(camera.m_projection)
	if render_to_canvas then temp_projection_m[6] = -temp_projection_m[6] end

	shader:send("m_view", 'column', camera.m_view.data)
	shader:send("m_projection", 'column', temp_projection_m.data)

	if shader:hasUniform("m_inv_view") then
		temp_int_view_m:copy(camera.m_view)
		temp_int_view_m:inverse()
		shader:send("m_inv_view", "column", temp_int_view_m.data)
	end

	self:send_light_sources_to(shader)
end

----
-- Set a Shader as current pixel effect or vertex shaders.
-- All drawing operations until the next apply will be drawn using the Shader object specified.
-- This method is called automatically when the environment is used in scene:render_nodes()
-- @param shader [LOVE Shader](https://love2d.org/wiki/Shader)
function Environment:apply_shader(shader)
	--if self._shader_object_cache ~= shader then
		love.graphics.setShader(shader)

		self:send_uniforms_to(shader)
		self._shader_object_cache = shader
	--end
end

----
-- Send light sources uniforms to the shader.
-- This function can be used when creating your own display objects, or for shading technique.
-- This method is called automatically when the environment is used in scene:render_nodes()
-- @param shader [LOVE Shader](https://love2d.org/wiki/Shader)
function Environment:send_light_sources_to(shader)
	for k, v in pairs(self.lights) do
		utils.noexcept_send_uniform(shader, k .. '_count', #v)
		for i, light in ipairs(v) do
			light:send_to(shader, k .. "[" .. (i - 1) .. "].")
		end
	end
end

return Environment

---
-- Camera object associated with the current Environment.
-- @field camera (menori.Camera or menori.PerspectiveCamera)

---
-- UniformList object. Uniforms in the list are automatically sent to the shader, which will be used to display objects with this environment.
-- @tfield menori.UniformList uniform_list

---
-- List of light sources.
-- @tfield table lights