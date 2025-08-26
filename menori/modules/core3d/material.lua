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

	self.name = opt.name or 'base_material'
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

--- Sets a custom LOVE shader object directly.
-- Use this method if you already created a shader with `love.graphics.newShader`.
-- This bypasses automatic shader building and disables `_needs_update`.
-- @tparam Shader shader A [LOVE Shader](https://love2d.org/wiki/Shader) object
function Material:set_shader(shader)
	self.shader = shader
	self._needs_update = false
end

--- Sets custom shader code for this material.
-- Clears the current shader and marks it for update in the next render.
-- If `vertcode` or `fragcode` is `nil`, the previous value is preserved.
-- @tparam[opt] string vertcode Vertex shader GLSL code
-- @tparam[opt] string fragcode Fragment shader GLSL code
function Material:set_shader_code(vertcode, fragcode)
	if vertcode then
		self.shader_vertcode = vertcode
	end
	if fragcode then
		self.shader_fragcode = fragcode
	end
	self.shader = nil
	self._needs_update = true
end

--- Default material instance.
-- Pre-configured material with white base color.
-- @field default Material
Material.default = Material("Default")
Material.default:set('baseColor', {1, 1, 1, 1})
return Material

--- 
-- Material name.
-- @string[opt="base_material"] name

--- 
-- The shader object that is bound to the material.
-- @tfield love.Shader shader

--- 
-- Depth test flag.
-- @bool[opt=true] depth_test

--- 
-- Depth comparison function used for depth testing.
-- Possible values: 'never', 'less', 'equal', 'lequal', 'greater', 'notequal', 'gequal', 'always'
-- @string[opt="less"] depth_func

--- 
-- Sets whether wireframe lines will be used when drawing.
-- @bool[opt=false] wireframe

--- 
-- Sets whether back-facing triangles in a Mesh are culled.
-- Possible values: 'back', 'front', 'none'
-- @string[opt="back"] mesh_cull_mode

--- 
-- Alpha blending mode for transparency.
-- Possible values: 'OPAQUE', 'MASK', 'BLEND'
-- @string[opt="OPAQUE"] alpha_mode

--- 
-- The main texture to be used with mesh:setTexture().
-- Corresponds to uniform Image MainTex in shader.
-- @tfield love.Texture main_texture

--- 
-- Vertex shader source code.
-- @string shader_vertcode

--- 
-- Fragment shader source code.
-- @string shader_fragcode

--- 
-- Material attributes table.
-- @tfield table attributes