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
local ml = require (modules .. 'ml')
local vec3 = ml.vec3

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

local function send_material_to(shader, material)
      for k, v in pairs(material) do
            utils.noexcept_send_uniform(shader, k, v)
      end
end

--- init
-- @param model Model objects
-- @param shader (Optional) ShaderObject which will be used for drawing
function ModelNode:init(model, shader)
	ModelNode.super.init(self)
      self.shader = shader or ModelNode.default_shader
	self.model = model
      self.color = ml.vec4(1)
end

function ModelNode:clone()
      local t = ModelNode(self.model, self.shader)
      ModelNode.super.clone(self, t)
      return t
end

function ModelNode:calculate_aabb(index)
      index = index or 1
      local b = self.model.primitives[index].bound
      local world_matrix = self.world_matrix

      local min = vec3(b.x, b.y, b.z)
      local max = vec3(b.x+b.w, b.y+b.h, b.z+b.d)

      world_matrix:multiply_vec3(min)
      world_matrix:multiply_vec3(max)

      return {min = min, max = max}
end

function ModelNode:set_color(r, g, b, a)
      self.color.x = r
      self.color.y = g
      self.color.z = b
      self.color.w = a
end

--- Render function.
-- @param scene Scene that draws this object
-- @param environment Environment that is used when drawing the current object
-- @param shader ShaderObject that can replace the shader that is used for the current object
function ModelNode:render(scene, environment, shader)
	shader = shader or self.shader

      environment:apply_shader(shader)

	shader:send('m_model', self.world_matrix.data)

      local c = self.color
      love.graphics.setColor(c.x, c.y, c.z, c.w)
	for _, v in ipairs(self.model.primitives) do
            send_material_to(shader, v.material)
		love.graphics.draw(v.mesh)
	end
end

return ModelNode