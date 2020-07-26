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

local ShaderObject = require 'menori.modules.shaderobject'

local Environment = class('Environment')

Environment.default_shader = ShaderObject([[
    uniform mat4 m_model;
    uniform mat4 m_view;
    uniform mat4 m_projection;
    #ifdef VERTEX
        vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return m_projection * m_view * m_model * vertex_position;
        }
    #endif
]])

local shader_cache_list = {}

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

function Environment:add_light(light)
	self.lights[#self.lights + 1] = light
end

--- Set fog color
function Environment:set_fog_color(r, g, b, a)
	self.uniform_table.fog_color = {r, g, b, a}
end

function Environment:_clear_shader_cache_list()
	--[[for k in pairs(shader_cache_list) do
	    shader_cache_list[k] = nil
	end]]
end

function Environment:send_uniforms_to(shader)
	print(shader)
	local camera = self.camera
	shader:send_matrix("m_view", camera.m_view)
	shader:send_matrix("m_projection", camera.m_projection)

	for k, v in pairs(self.uniform_table) do
		shader:send(k, v)
	end

	self:send_light_sources_uniforms(shader)
	--shader_cache_list[shader] = true
end

function Environment:send_light_sources_uniforms(shader)
	shader:send('light_count', #self.lights)
    for i = 1, #self.lights do
    	local light_index_str =  "lights[" .. (i - 1) .. "]."
    	local light = self.lights[i]

    	light:to_uniforms(shader, light_index_str)
    end
end

return
Environment