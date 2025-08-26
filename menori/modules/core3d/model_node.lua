--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Class for drawing Mesh objects. (Inherited from menori.Node class)
-- ModelNode is a specialized node that renders 3D mesh geometry with materials.
-- It handles transformation matrices, skeletal animation joints, and material properties.
-- @classmod ModelNode
-- @see Node

local modules = (...):match('(.*%menori.modules.)')

local Node        = require (modules .. 'node')
local ml          = require (modules .. 'ml')
local Material    = require (modules .. 'core3d.material')
local ShaderUtils = require (modules .. 'shaders.utils')
local ffi         = require (modules .. 'libs.ffi')

local vec3     = ml.vec3
local bound3   = ml.bound3

local ModelNode = Node:extend('ModelNode')

local matrix_bytesize = 16*4

----
-- The public constructor.
-- @tparam menori.Mesh mesh The mesh object to render
-- @tparam[opt=Material.default] menori.Material material The material object (a new copy will be created)
-- @usage
-- -- Create a ModelNode with a mesh and default material
-- local model = ModelNode(mesh)
--
-- -- Create a ModelNode with a custom material
-- local material = menori.Material()
-- local model = ModelNode(mesh, material)
function ModelNode:init(mesh, material)
	ModelNode.super.init(self)
	material = material or Material.default

	self.is_model_node = true
	self.material = material:clone()
	self.material.attributes = mesh.vertexformat
	self.mesh = mesh

	self.material._needs_update = true
	self:update_shader()
end

function ModelNode:_ensure_joints_texture()
	local size = math.max(math.ceil(math.sqrt(#self.joints * 4) / 4) * 4, 4)
	if self.joints_size ~= size then
		self.joints_size = size
		self.joints_data = love.image.newImageData(self.joints_size, self.joints_size, 'rgba32f')
		self.joints_texture = love.graphics.newImage(self.joints_data)
	end
end

function ModelNode:update_shader()
	if self.material.shader and not self.material._needs_update then
		return
	end
	self.material.shader = ShaderUtils.create_shader(self.material, self.mesh)
	self.material._needs_update = false
end

----
-- Clone the ModelNode object.
-- Creates a copy of the ModelNode with the same mesh and a cloned material.
-- @treturn menori.ModelNode A new cloned ModelNode object
function ModelNode:clone()
	local t = ModelNode(self.mesh, self.material)
	ModelNode.super.clone(self, t)
	return t
end

----
-- Calculate axis-aligned bounding box (AABB) with current transformations applied.
-- Computes the world-space bounding box by transforming the mesh's local bounds
-- using the current world transformation matrix.
-- @treturn bound3 The transformed bounding box in world coordinates
function ModelNode:calculate_aabb()
	local bound = self.mesh.bound
	local min = bound.min
	local max = bound.max
	self:recursive_update_transform()
	local m = self.world_matrix
	local t = {
		m:multiply_vec3(vec3(min.x, min.y, min.z)),
		m:multiply_vec3(vec3(max.x, min.y, min.z)),
		m:multiply_vec3(vec3(min.x, min.y, max.z)),

		m:multiply_vec3(vec3(min.x, max.y, min.z)),
		m:multiply_vec3(vec3(max.x, max.y, min.z)),
		m:multiply_vec3(vec3(min.x, max.y, max.z)),

		m:multiply_vec3(vec3(max.x, min.y, max.z)),
		m:multiply_vec3(vec3(max.x, max.y, max.z)),
	}

	local aabb = bound3(
		vec3(math.huge), vec3(-math.huge)
	)
	for i = 1, #t do
		local v = t[i]
		if aabb.min.x > v.x then aabb.min.x = v.x elseif aabb.max.x < v.x then aabb.max.x = v.x end
		if aabb.min.y > v.y then aabb.min.y = v.y elseif aabb.max.y < v.y then aabb.max.y = v.y end
		if aabb.min.z > v.z then aabb.min.z = v.z elseif aabb.max.z < v.z then aabb.max.z = v.z end
	end

	return aabb
end

----
-- Draw a ModelNode object.
-- This function renders the model using the current material and handles skeletal animation
-- if joints are present. It's called implicitly in the hierarchy when a node is drawn with scene:render_nodes()
-- @tparam menori.Scene scene The scene object used for rendering context
-- @tparam menori.Environment environment The environment object providing lighting and other rendering parameters
-- @usage
-- -- This is typically called automatically by the scene
-- scene:render_nodes()
-- 
-- -- Or manually for custom rendering
-- model_node:render(scene, environment)
function ModelNode:render(scene, environment)
	self:update_shader()
	local shader = self.material.shader

	environment:apply_shader(shader)
	shader:send('m_model', 'column', self.world_matrix.data)

	if self.joints then
		-- if self.skeleton_node then
		--       shader:send('m_skeleton', self.skeleton_node.world_matrix.data)
		-- end

		self:_ensure_joints_texture()

		for i = 1, #self.joints do
			local node = self.joints[i]

			if ffi then
				local ptr = ffi.cast('char*', self.joints_data:getFFIPointer()) + (i-1) * matrix_bytesize
				ffi.copy(ptr, node.joint_matrix.e+1, matrix_bytesize)
			else
				-- https://github.com/rozenmad/Menori/pull/7
				local e = node.joint_matrix.e
				local p = (i - 1) * 4
				local y = p / self.joints_size
				self.joints_data:setPixel((p + 0) % self.joints_size, y, e[01], e[02], e[03], e[04])
				self.joints_data:setPixel((p + 1) % self.joints_size, y, e[05], e[06], e[07], e[08])
				self.joints_data:setPixel((p + 2) % self.joints_size, y, e[09], e[10], e[11], e[12])
				self.joints_data:setPixel((p + 3) % self.joints_size, y, e[13], e[14], e[15], e[16])
			end
		end

		self.joints_texture:replacePixels(self.joints_data)
		shader:send('joints_texture', self.joints_texture)
	end

	self.mesh:draw(self.material)
end

return ModelNode

---
-- Own copy of the Material that is bound to the model.
-- This is a cloned copy of the material passed to the constructor, allowing
-- independent modification without affecting the original material.
-- @field material menori.Material

---
-- The menori.Mesh object that is bound to the model.
-- @field mesh menori.Mesh