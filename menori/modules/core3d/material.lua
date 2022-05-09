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

local class = require (modules .. 'libs.class')
local utils = require (modules .. 'libs.utils')
local UniformList = require (modules .. 'core3d.uniform_list')

local Material = UniformList:extend('Material', {
      clone = utils.copy
})

Material.default_shader = love.graphics.newShader([[
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
            return baseColor * texcolor * color;
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
