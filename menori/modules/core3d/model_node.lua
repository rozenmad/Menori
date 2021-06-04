--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Сlass for drawing models.
]]
-- @module menori.ModelNode

local modules = (...):match('(.*%menori.modules.)')

local utils = require (modules .. 'libs.utils')
local Node = require (modules .. 'node')

local ModelNode = Node:extend('ModelNode')

ModelNode.default_shader = love.graphics.newShader([[
#ifdef VERTEX
      uniform mat4 m_model;
      uniform mat4 m_view;
      uniform mat4 m_projection;

      // love2d use row major matrices by default, we have column major and need transpose it.
      // 11.3 love has bug with matrix layout in shader:send().
      vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return vertex_position * m_model * m_view * m_projection;
      }
#endif
#ifdef PIXEL
      vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords)
      {
            vec4 texcolor = Texel(t, texture_coords);
            if( texcolor.a <= 0.0 ) discard;
            return texcolor * color;
      }
#endif
]])

--- Constructor
-- @param model Model objects
-- @param matrix (Optional) Matrix transformations
-- @param shader (Optional) ShaderObject which will be used for drawing
function ModelNode:constructor(model, matrix, shader)
	ModelNode.super.constructor(self)
      self.shader = shader or ModelNode.default_shader
      if matrix then
            self.local_matrix:copy(matrix)
      end
	self.model = model
end

local function send_material_to(shader, material)
      for k, v in pairs(material) do
            utils.noexcept_send_uniform(shader, k, v)
      end
end

--- Render function.
-- @param scene Scene that draws this object
-- @param environment Environment that is used when drawing the current object
-- @param shader ShaderObject that can replace the shader that is used for the current object
function ModelNode:render(scene, environment, shader)
	shader = shader or self.shader
	love.graphics.setShader(shader)
	environment:send_uniforms_to(shader)

	shader:send('m_model', self.world_matrix.data)

	for _, v in ipairs(self.model.primitives) do
            send_material_to(shader, v.material)
		love.graphics.draw(v.mesh)
	end
	love.graphics.setShader()
end

return ModelNode