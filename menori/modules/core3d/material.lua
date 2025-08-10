--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Base class for materials. A material describes the appearance of an object.
-- This class is inherited from UniformList and provides material 
-- properties and shader management functionality.
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
--- The public constructor.
-- Creates a new menori.Material instance with optional parameters.
-- @param[opt] opt table Optional parameters table
-- @param[opt] opt.name string Material name
-- @param[opt] opt.shader Shader Custom shader [LOVE Shader](https://love2d.org/wiki/Shader) object
-- @param[opt] opt.shader_vertcode string Custom vertex shader code
-- @param[opt] opt.shader_fragcode string Custom fragment shader code
-- @usage
-- -- Create a basic material
-- local material = menori.Material()
-- 
-- -- Create a named material with custom shader
-- local material = menori.Material({
--     name = "MyMaterial",
--     shader = my_custom_shader,
-- })
--
-- -- Create a named material with custom shader code
-- local material = menori.Material({
--     name = "MyMaterial",
--     shader_vertcode = "vertex shader code here",
--     shader_fragcode = "fragment shader code here",
-- })
--
-- -- Create a ModelNode with material
-- local model_node = menori.ModelNode(mesh, material)
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

--- Default material instance.
-- Pre-configured material with white base color.
-- @field default Material
Material.default = Material("Default")
Material.default:set('baseColor', {1, 1, 1, 1})
return Material

--- Material name.
-- @field name string

--- The shader object that is bound to the material.
-- @field shader love.Shader

--- Depth test flag.
-- @field depth_test boolean (default: true)

--- Depth comparison function used for depth testing.
-- Possible values: 'never', 'less', 'equal', 'lequal', 'greater', 'notequal', 'gequal', 'always'
-- @field depth_func string (default: 'less')

--- Sets whether wireframe lines will be used when drawing.
-- @field wireframe boolean (default: false)

--- Sets whether back-facing triangles in a Mesh are culled.
-- Possible values: 'back', 'front', 'none'
-- @field mesh_cull_mode string (default: 'back')

--- Alpha blending mode for transparency.
-- Possible values: 'OPAQUE', 'MASK', 'BLEND'
-- @field alpha_mode string (default: 'OPAQUE')

--- The main texture to be used with mesh:setTexture().
-- Corresponds to uniform Image MainTex in shader.
-- @field main_texture love.Texture

--- Vertex shader source code.
-- @field shader_vertcode string

--- Fragment shader source code.
-- @field shader_fragcode string

--- Material attributes table.
-- @field attributes table