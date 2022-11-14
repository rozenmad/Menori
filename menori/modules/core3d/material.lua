--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
]]

--[[--
Base class for materials. A material describes the appearance of an object. (Inherited from UniformList)
]]
-- @classmod Material
-- @see UniformList

local modules = (...):match('(.*%menori.modules.)')

local utils = require (modules .. 'libs.utils')
local UniformList = require (modules .. 'core3d.uniform_list')

local Material = UniformList:extend('Material', {
      clone = utils.copy
})

Material.default_shader = love.graphics.newShader([[
varying vec4 pos;

#ifdef VERTEX
      uniform mat4 m_model;
      uniform mat4 m_view;
      uniform mat4 m_projection;

      vec4 position(mat4 transform_projection, vec4 vertex_position) {
            pos = vertex_position * m_model;
            return pos * m_view * m_projection;
      }
#endif
#ifdef PIXEL
      uniform vec4 baseColor;
      uniform vec4 fog_color;
      uniform vec3 camera_position;
      
      float fogFactorExp2(const float dist, const float density) {
            const float LOG2 = -1.442695;
            float d = density * dist;
            return clamp(exp2(d * d * LOG2), 0.0, 1.0);
      }
      
      vec4 effect(vec4 color, Image t, vec2 texture_coords, vec2 screen_coords)
      {
            vec4 texcolor = Texel(t, texture_coords);
            if( texcolor.a <= 0.0f ) discard;
            float distance_to_fragment = distance(pos.xyz, camera_position);
            float fog_factor = fogFactorExp2(distance_to_fragment, 0.02);
            vec4 result = texcolor * color;
            vec4 albedo = mix(fog_color, result, fog_factor);
            return albedo;
      }
#endif
]])

----
-- The public constructor.
-- @tparam string name Name of the material.
-- @param[opt=Material.default_shader] shader [LOVE Shader](https://love2d.org/wiki/Shader)
function Material:init(name, shader)
      Material.super.init(self)

      self.name = name
      self.shader = shader or Material.default_shader

      self.depth_test = true
      self.depth_func = 'less'

      self.wireframe = false
      self.mesh_cull_mode = 'back'

      self.main_texture = nil
end

Material.default = Material("Default")
Material.default:set('baseColor', {1, 1, 1, 1})
return Material

---
-- Material name.
-- @field name

---
-- The shader object that is bound to the material. (default_shader by default)
-- @field shader

---
-- Depth test flag. (Enabled by default)
-- @field depth_test

---
-- Depth comparison func (mode) used for depth testing.
-- @field depth_func

---
-- Sets whether wireframe lines will be used when drawing.
-- @field wireframe

---
-- Sets whether back-facing triangles in a Mesh are culled.
-- @field mesh_cull_mode

---
-- The texture to be used in mesh:setTexture(). (uniform Image MainTex) in shader.
-- @field main_texture
