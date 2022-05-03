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

local Node   = require (modules .. 'node')
local ml     = require (modules .. 'ml')
local vec3   = ml.vec3
local bound3 = ml.bound3

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
      uniform vec4 baseColor;
      vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords)
      {
            vec4 texcolor = Texel(t, texture_coords);
            if( texcolor.a <= 0.0f ) discard;
            return texcolor * baseColor * color;
      }
#endif
]])

--- init
-- @param mesh Mesh object
-- @param shader (Optional) ShaderObject which will be used for drawing
function ModelNode:init(mesh, shader)
	ModelNode.super.init(self)
      self.shader = shader or ModelNode.default_shader
	self.mesh = mesh

      self.color = ml.vec4(1)
end

function ModelNode:clone()
      local t = ModelNode(self.mesh, self.shader, false)
      ModelNode.super.clone(self, t)
      return t
end

function ModelNode:calculate_aabb(index)
      index = index or 1
      local b = self.mesh.primitives[index].bound
      self:recursive_update_transform()
      local m = self.world_matrix
      local t = {
            m:multiply_vec3(vec3(b.x    , b.y    ,     b.z)),
            m:multiply_vec3(vec3(b.x+b.w, b.y    ,     b.z)),
            m:multiply_vec3(vec3(b.x    , b.y    , b.z+b.d)),

            m:multiply_vec3(vec3(b.x    , b.y+b.h,     b.z)),
            m:multiply_vec3(vec3(b.x+b.w, b.y+b.h,     b.z)),
            m:multiply_vec3(vec3(b.x    , b.y+b.h, b.z+b.d)),

            m:multiply_vec3(vec3(b.x+b.w, b.y    , b.z+b.d)),
            m:multiply_vec3(vec3(b.x+b.w, b.y+b.h, b.z+b.d)),
      }

      local aabb = bound3()
      for i = 2, #t do
            local v = t[i]
            if aabb.min.x > v.x then aabb.min.x = v.x elseif aabb.max.x < v.x then aabb.max.x = v.x end
            if aabb.min.y > v.y then aabb.min.y = v.y elseif aabb.max.y < v.y then aabb.max.y = v.y end
            if aabb.min.z > v.z then aabb.min.z = v.z elseif aabb.max.z < v.z then aabb.max.z = v.z end
      end

      return aabb
end

function ModelNode:set_color(r, g, b, a)
      self.color:set(r, g, b, a)
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
      self.mesh:draw(shader)
end

return ModelNode