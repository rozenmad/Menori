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
local vert, frag
if love._version_major > 11 then
      vert = require(modules .. 'shaders.default_12_vert')
      frag = require(modules .. 'shaders.default_12_frag')
      Material.default_shader = love.graphics.newShader(vert, frag)
else
      vert = require(modules .. 'shaders.default_11_vert')
      frag = require(modules .. 'shaders.default_12_frag')
      Material.default_shader = love.graphics.newShader(vert, frag)
end

Material.default_vert = vert
Material.default_frag = frag

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

      self.alpha_mode = 'OPAQUE'
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
