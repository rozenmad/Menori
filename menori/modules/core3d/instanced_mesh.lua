--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
]]

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')
local geometry_buffer = require (modules .. 'core3d.geometry_buffer')

local lg = love.graphics

local ffi
if type(jit) == 'table' and jit.status() then
	ffi = require 'ffi'
end

local instanced_mesh = class('InstancedMesh')

function instanced_mesh:init(mesh, instanced_format)
	self.hashtable = {}
	self.inverse_hashtable = {}

	self.mesh = mesh
	self.instanced_buffer = geometry_buffer(16, instanced_format)

	self.count = 0
	self:_attach_buffers()
end

function instanced_mesh:increase_ic()
	self.count = self.count + 1
end

function instanced_mesh:decrease_ic()
	self.count = self.count - 1
end

function instanced_mesh:set_ic(count)
	count = count or 0
	self.count = count
end

function instanced_mesh:update_instanced_buffer()
	if self.count > 0 then
		self.instanced_buffer:update(self.count)
	end
end

function instanced_mesh:get_instance_data(ctype, index)
	index = index or 0
	if index + 1 > self.instanced_buffer.size then
		self:_detach_buffers()
		self.instanced_buffer:reallocate(index + index)
		self:_attach_buffers()
	end
	--[[if userdata then
		self.hashtable[index + 1] = userdata -- start from 0, size - 1
		self.inverse_hashtable[userdata.id] = index + 1
	end]]
	self._need_update = true
	local ptr = self.instanced_buffer:get_data_pointer(index)
	return ffi.cast(ctype, ptr)
end

function instanced_mesh:remove_instance(userdata)
	--[[local size = #self.hashtable
	for i, v in ipairs(self.hashtable) do
		if v == userdata then
			local iptr = self.instance_data_ptr + ((i - 1) * format_offset)
			local last = self.instance_data_ptr + ((size - 1) * format_offset)

			iptr[0] = last[0]
			iptr[1] = last[1]
			iptr[2] = last[2]
			self.hashtable[i] = self.hashtable[size]
			table.remove(self.hashtable)
			return true
		end
	end
	return false]]
	local a_count = self.instanced_buffer.attributes_count
	local size = #self.hashtable
	local i = self.inverse_hashtable[userdata.id]
	if i ~= nil then
		local iptr = self.instance_data_ptr + ((i - 1) * a_count)
		local last = self.instance_data_ptr + ((size - 1) * a_count)

		iptr[0] = last[0]
		iptr[1] = last[1]
		iptr[2] = last[2]
		local last_userdata = self.hashtable[size]
		self.hashtable[i] = last_userdata
		table.remove(self.hashtable)
		self.inverse_hashtable[last_userdata.id] = i

		self.inverse_hashtable[userdata.id] = nil
		return true
	end
	return false
end

function instanced_mesh:_attach_buffers()
	local buffer = self.instanced_buffer
	local primitive = self.mesh.primitives[1]
	for i, v in ipairs(buffer.format) do
		primitive.mesh:attachAttribute(v.name, buffer.mesh, "perinstance")
	end
end

function instanced_mesh:_detach_buffers()
	local buffer = self.instanced_buffer
	local primitive = self.mesh.primitives[1]
	for i, v in ipairs(buffer.format) do
		primitive.mesh:detachAttribute(v.name)
	end
end

function instanced_mesh:draw(material)
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

	local primitives = self.mesh.primitives
	for i = 1, #primitives do
		local mesh = primitives[i].mesh
		mesh:setTexture(material.main_texture)
		lg.drawInstanced(mesh, self.count)
	end
end

return instanced_mesh