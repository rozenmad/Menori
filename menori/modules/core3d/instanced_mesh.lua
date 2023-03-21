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
local GeometryBuffer = require (modules .. 'core3d.geometry_buffer')

local lg = love.graphics

local ffi
if type(jit) == 'table' or jit.status() then
	ffi = require 'ffi'
end

local InstancedMesh = class('InstancedMesh')

local default_format = {
      {name = "instance_position", format = "floatvec3"},
}

----
-- The public constructor.
function InstancedMesh:init(lg_mesh, instanced_format)
	self.lg_mesh = lg_mesh
	self.instanced_buffer = GeometryBuffer(16, instanced_format or default_format)

	self.count = 0
	self:_attach_buffers()
end

function InstancedMesh:increase_ic()
	self.count = self.count + 1
end

function InstancedMesh:decrease_ic()
	self.count = self.count - 1
end

function InstancedMesh:set_count(count)
	count = count or 0
	self.count = count
end

function InstancedMesh:update_instanced_buffer()
	if self.count > 0 then
		self.instanced_buffer:update(self.count)
	end
end

function InstancedMesh:get_instance_data(ctype, index)
	index = index or 0
	if index + 1 > self.instanced_buffer.size then
		self:_detach_buffers()
		self.instanced_buffer:reallocate(index + index)
		self:_attach_buffers()
	end
	self._need_update = true
	local ptr = self.instanced_buffer:get_data_pointer(index)
	return ffi.cast(ctype, ptr)
end

function InstancedMesh:_attach_buffers()
	local buffer = self.instanced_buffer
	for i, v in ipairs(buffer.format) do
		self.lg_mesh:attachAttribute(v.name, buffer.mesh, "perinstance")
	end
end

function InstancedMesh:_detach_buffers()
	local buffer = self.instanced_buffer
	for i, v in ipairs(buffer.format) do
		self.lg_mesh:detachAttribute(v.name)
	end
end

function InstancedMesh:draw(material)
	if self._need_update then
		self._need_update = false
		self:update_instanced_buffer()
	end

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