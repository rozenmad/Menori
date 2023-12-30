--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

--[[--
Class provides instancing functionality for Meshes.
]]
-- @classmod InstancedMesh

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

local lg = love.graphics

local InstancedMesh = class('InstancedMesh')

local default_format = {
      {name = "instance_position", format = "floatvec3"},
}

local data_format = {
      ["float"] = 4,
      ["floatvec2"] = 8,
      ["floatvec3"] = 12,
      ["floatvec4"] = 16,
      ["floatmat2x2"] = 16,
      ["floatmat2x3"] = 24,
      ["floatmat2x4"] = 32,
      ["floatmat3x2"] = 24,
      ["floatmat3x3"] = 36,
      ["floatmat3x4"] = 48,
      ["floatmat4x2"] = 32,
      ["floatmat4x3"] = 48,
      ["floatmat4x4"] = 64,
      ["int32"] = 4,
      ["int32vec2"] = 8,
      ["int32vec3"] = 12,
      ["int32vec4"] = 16,
      ["uint32"] = 4,
      ["uint32vec2"] = 8,
      ["uint32vec3"] = 12,
      ["uint32vec4"] = 16,
      ["snorm8vec4"] = 4,
      ["unorm8vec4"] = 4,
      ["int8vec4"] = 4,
      ["uint8vec4"] = 4,
      ["snorm16vec2"] = 4,
      ["snorm16vec4"] = 8,
      ["unorm16vec2"] = 4,
      ["unorm16vec4"] = 8,
      ["int16vec2"] = 4,
      ["int16vec4"] = 8,
      ["uint16"] = 2,
      ["uint16vec2"] = 4,
      ["uint16vec4"] = 8,
      ["bool"] = 4,
      ["boolvec2"] = 8,
      ["boolvec3"] = 12,
      ["boolvec4"] = 16,
}

----
-- The public constructor.
function InstancedMesh:init(lg_mesh, instanced_format)
	instanced_format = instanced_format or default_format
	self.lg_mesh = lg_mesh
	-- self.instanced_mesh_buffer = love.graphics.newBuffer(instanced_format, 16, { vertex = true })
	self.instanced_mesh_buffer = love.graphics.newMesh(instanced_format, 16, 'triangles', 'dynamic')

	self.format = instanced_format
	self.format_attribute_indices_map = {}
	for i, v in ipairs(self.format) do
		self.format_attribute_indices_map[v.name] = i
	end

	self.count = 0
	self:_attach_buffer()
end

function InstancedMesh:increase_count()
	self.count = self.count + 1
	self:_reallocate(self.count)
	return self.count
end

function InstancedMesh:decrease_count()
	self.count = self.count - 1
	return self.count
end

function InstancedMesh:set_count(count)
	count = count or 0
	self:_reallocate(self.count)
	self.count = count
end

function InstancedMesh:set_instance_data(index, attribute_name, ...)
	self:_reallocate(index)
	local attribute_index = self.format_attribute_indices_map[attribute_name]
	self.instanced_mesh_buffer:setVertexAttribute(index, attribute_index, ...)
end

function InstancedMesh:_reallocate(current_count)
	local instance_count = self.instanced_mesh_buffer:getVertexCount()
	if current_count > instance_count then
		self:_detach_buffer()
		local temp_mesh = love.graphics.newMesh(self.format, instance_count * 2, 'triangles', 'dynamic')
		for i = 1, instance_count do
			temp_mesh:setVertex(i, self.instanced_mesh_buffer:getVertex(i))
		end

		self.instanced_mesh_buffer:release()
		self.instanced_mesh_buffer = temp_mesh
		self:_attach_buffer()
	end
end

function InstancedMesh:_attach_buffer()
	for i, v in ipairs(self.format) do
		self.lg_mesh:attachAttribute(v.name, self.instanced_mesh_buffer, "perinstance")
	end
end

function InstancedMesh:_detach_buffer()
	for i, v in ipairs(self.format) do
		self.lg_mesh:detachAttribute(v.name)
	end
end

function InstancedMesh:draw(material)
	material:send_to(material.shader)

	if material.wireframe ~= lg.isWireframe() then
		lg.setWireframe(material.wireframe)
	end
	if material.depth_test then
		if material.depth_func ~= lg.getDepthMode() then
			lg.setDepthMode(material.depth_func, true)
		end
	else
		lg.setDepthMode()
	end
	if material.mesh_cull_mode ~= lg.getMeshCullMode() then
		lg.setMeshCullMode(material.mesh_cull_mode)
	end

	local mesh = self.lg_mesh
	mesh:setTexture(material.main_texture)
	lg.drawInstanced(mesh, self.count)
end

return InstancedMesh