--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
]]

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')

local ffi
if type(jit) == 'table' or jit.status() then
	ffi = require 'ffi'
end

local geometry_buffer = class('GeometryBuffer')

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

function geometry_buffer:init(size, format, mode)
	self.mode = mode or 'triangles'
	self.format = format
	self.bytesize = 0
	for i, v in ipairs(format) do
		self.bytesize = self.bytesize + data_format[v.format]
	end
	self:reallocate(size)
end

function geometry_buffer:reallocate(size)
	self.size = size
	self.mesh = love.graphics.newMesh(self.format, size, self.mode, 'dynamic')

	local temp_data = love.data.newByteData(size * self.bytesize)
	if self.data then
		local dst = temp_data:getFFIPointer()
		local src = self.data:getFFIPointer()
		ffi.copy(dst, src, self.data:getSize())
	end
	self.data = temp_data
	self.ptr = ffi.cast('unsigned char*', self.data:getFFIPointer())
end

function geometry_buffer:set_indices(arr)
	self.mesh:setVertexMap(arr)
end

function geometry_buffer:get_data_pointer(index)
	return self.ptr + (self.bytesize * index)
end

function geometry_buffer:update(count)
	count = count or self.size
	self.mesh:setVertices(self.data, 1, count)
end

return geometry_buffer