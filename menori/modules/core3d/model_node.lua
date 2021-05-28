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

local Node = require (modules .. 'node')
local ShaderObject = require (modules .. 'shaderobject')

local ModelNode = Node:extend('ModelNode')

ModelNode.default_shader = ShaderObject([[
#ifdef VERTEX
      uniform mat4 m_model;
      uniform mat4 m_view;
      uniform mat4 m_projection;

      vec4 position(mat4 transform_projection, vec4 vertex_position) {
            return m_projection * m_view * m_model * vertex_position;
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

--- Render function.
-- @param scene Scene that draws this object
-- @param environment Environment that is used when drawing the current object
-- @param shader ShaderObject that can replace the shader that is used for the current object
function ModelNode:render(scene, environment, shader)
	shader = shader or self.shader
	shader:attach()
	environment:send_uniforms_to(shader)

	shader:send_matrix('m_model', self.world_matrix)
	for _, v in ipairs(self.model.primitives) do
            --love.graphics.setColor(v.material.base_color_factor)
		love.graphics.draw(v.mesh)
            --love.graphics.setColor(1, 1, 1, 1)
	end
	shader:detach()
end

return ModelNode