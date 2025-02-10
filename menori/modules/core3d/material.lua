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

local ShaderUtils = require (modules .. 'shaders.utils')

local Material = UniformList:extend('Material', {
      clone = utils.copy
})

----
-- The public constructor.
-- @tparam string name Name of the material.
-- @param[opt=Material.default_shader] shader [LOVE Shader](https://love2d.org/wiki/Shader)
function Material:init(opt)
      Material.super.init(self)
      opt = opt or {}

      self.name = opt.name
      self.attributes = {}

      self.depth_test = true
      self.depth_func = 'less'

      self.wireframe = false
      self.mesh_cull_mode = 'back'

      self.alpha_mode = 'OPAQUE'
      self.main_texture = nil

      self.shader_vertcode = opt.shader_vertcode or ShaderUtils.cache['default_mesh_vert']
      self.shader_fragcode = opt.shader_fragcode or ShaderUtils.cache['default_mesh_frag']
      self.shader = opt.shader
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
