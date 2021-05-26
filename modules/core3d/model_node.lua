local Node = require 'menori.modules.node'
local ShaderObject = require 'menori.modules.shaderobject'

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

function ModelNode:constructor(model_instance, shader, matrix)
	ModelNode.super.constructor(self)
      if matrix then
            self.local_matrix:copy(matrix)
      end

	self.shader = shader or ModelNode.default_shader
	self.model_instance = model_instance
end

function ModelNode:render(scene, environment, shader)
	shader = shader or self.shader
	shader:attach()
	environment:send_uniforms_to(shader)

	shader:send_matrix('m_model', self.world_matrix)
	for _, v in ipairs(self.model_instance.primitives) do
		love.graphics.draw(v)
	end
	shader:detach()
end

return ModelNode