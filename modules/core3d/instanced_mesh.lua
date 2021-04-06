--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local class = require 'menori.modules.libs.class'
local geometry_buffer = require 'menori.modules.core3d.geometry_buffer'
local model = require 'menori.modules.core3d.model'
local ffi = require 'ffi'

local instanced_mesh = class('InstancedMesh')

function instanced_mesh:constructor(primitive, image, instanced_format, shader)
	self.shader = shader

	self.hashtable = {}
	self.inverse_hashtable = {}

	self.mesh_data = model.create_mesh_from_primitive(primitive)
	self.mesh_data:setTexture(image)

	self.instanced_buffer_size = 128
	self.instanced_buffer = geometry_buffer(self.instanced_buffer_size, instanced_format)

	--self.instance_data_ptr = self.instanced_buffer:get_data_pointer('float*')

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

function instanced_mesh:set_texture(image)
	self.mesh_data:setTexture(image)
end

function instanced_mesh:update_instanced_buffer()
	if self.count > 0 then
		self.instanced_buffer:update(self.count)
	end
end

function instanced_mesh:get_instance_data(index, userdata, ct)
	if index + 1 > self.instanced_buffer.size then
		self:_detach_buffers()
		self.instanced_buffer:reallocate(index + index)
		self:_attach_buffers()
	end
	--[[if userdata then
		self.hashtable[index + 1] = userdata -- start from 0, size - 1
		self.inverse_hashtable[userdata.id] = index + 1
	end]]
	local ptr = self.instanced_buffer:get_data_pointer(index)
	return ffi.cast(ct, ptr)
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
	for i, v in ipairs(buffer.format) do
		self.mesh_data:attachAttribute(v[1], buffer.mesh, "perinstance")
	end
end

function instanced_mesh:_detach_buffers()
	local buffer = self.instanced_buffer
	for i, v in ipairs(buffer.format) do
		self.mesh_data:detachAttribute(v[1])
	end
end

function instanced_mesh:draw(environment, world_matrix, shader)
	shader = shader or self.shader
	shader:attach()
	environment:send_uniforms_to(shader)
	shader:send_matrix('m_model', world_matrix)
	love.graphics.drawInstanced(self.mesh_data, self.count)
	shader:detach()
end

return instanced_mesh