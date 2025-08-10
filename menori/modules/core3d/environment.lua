--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Environment management class for 3D rendering.
-- An environment class that manages and sends information about the current rendering settings
-- (such as ambient color, fog, light sources, camera transformation matrices) to shaders.
-- Extends UniformList to provide automatic uniform management and light source handling.
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
-- Initializes the environment with a camera.
-- @tparam menori.Camera|menori.PerspectiveCamera camera Camera that will be associated with this environment
function Environment:init(camera)
	Environment.super.init(self)

	self.camera = camera
	self.lights = {}

	self._shader_object_cache = nil
end

----
-- Adds a light source to the environment.
-- Light sources are grouped by uniform name and sent to shaders as arrays.
-- @tparam string uniform_name Name of uniform used in the shader (e.g., "directional_lights", "point_lights")
-- @tparam menori.UniformList light Light source object that implements UniformList
function Environment:add_light(uniform_name, light)
	local t = self.lights[uniform_name] or {}
	self.lights[uniform_name] = t
	table.insert(t, light)
end

----
-- Sends all environment uniforms to the specified shader.
-- This function can be used when creating custom display objects or shading techniques.
-- This method is called automatically when the environment is used in scene:render_nodes().
-- @tparam love.Shader shader LOVE Shader object to send uniforms to
function Environment:send_uniforms_to(shader)
	local camera = self.camera
	self:send_to(shader)

	local render_to_canvas = love.graphics.getCanvas() ~= nil
	temp_projection_m:copy(camera.m_projection)

	if love._version_major <= 11 and render_to_canvas then
		temp_projection_m[6] = -temp_projection_m[6]
	end

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
-- Applies the shader and sends all environment uniforms to it.
-- Sets the shader as current and ensures all uniforms are transmitted.
-- This method is called automatically when the environment is used in scene:render_nodes().
-- @tparam love.Shader shader LOVE Shader object to apply and configure
function Environment:apply_shader(shader)
	--if self._shader_object_cache ~= shader then
		love.graphics.setShader(shader)

		self:send_uniforms_to(shader)
		self._shader_object_cache = shader
	--end
end

----
-- Sends light source uniforms to the shader.
-- Transmits all registered light sources as shader uniform arrays with count variables.
-- For each light group, sends a "_count" uniform and individual light data.
-- This function can be used when creating custom display objects or shading techniques.
-- This method is called automatically when the environment is used in scene:render_nodes().
-- @tparam love.Shader shader LOVE Shader object to send light uniforms to
function Environment:send_light_sources_to(shader)
	for k, v in pairs(self.lights) do
		utils.noexcept_send_uniform(shader, k .. '_count', #v)
		for i, light in ipairs(v) do
			light:send_to(shader, k .. "[" .. (i - 1) .. "].")
		end
	end
end

return Environment

--- Camera object associated with the current Environment.
-- @tfield menori.Camera|menori.PerspectiveCamera camera

--- Inherited UniformList functionality.
-- Uniforms in the list are automatically sent to the shader when rendering
-- objects with this environment.
-- @tfield menori.UniformList uniform_list

--- Collection of light sources organized by uniform name.
-- Each key maps to an array of light objects that implement UniformList.
-- @tfield table lights