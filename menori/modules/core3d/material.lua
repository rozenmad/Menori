local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')
local utils = require (modules .. 'libs.utils')
local UniformList = require (modules .. 'core3d.uniform_list')

local material = UniformList:extend('Material', {
      clone = utils.copy
})

material.default_shader = love.graphics.newShader([[
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

function material:init(name, shader)
      material.super.init(self)

      self.name = name
      self.shader = shader or material.default_shader

      self.depth_test = true
      self.depth_func = 'less'

      self.wireframe = false
      self.mesh_cull_mode = 'back'

      self.main_texture = nil -- in shader, uniform is called MainTex
end

material.default = material("Default")
return material