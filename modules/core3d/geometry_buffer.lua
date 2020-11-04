local class = require 'menori.modules.libs.class'
local ffi = require 'ffi'

local geometry_buffer = class('mesh_buffer')

function geometry_buffer:constructor(size, format)
    self.format = format
    self.bytesize = 0
    self.attributes_count = 0
    for i, v in ipairs(format) do
        self.bytesize = self.bytesize + ffi.sizeof(v[2]) * v[3]
        self.attributes_count = self.attributes_count + v[3]
    end

    self:reallocate(size)
end

function geometry_buffer:reallocate(size)
    self.size = size
    self.mesh = love.graphics.newMesh(self.format, size, nil, "dynamic")

    local temp_data = love.data.newByteData(size * self.bytesize)
    if self.data then
        local dst = temp_data:getFFIPointer()
        local src = self.data:getFFIPointer()
        ffi.copy(dst, src, self.data:getSize())
    end
    self.data = temp_data
end

function geometry_buffer:get_data_pointer(ct)
    return ffi.cast(ct, self.data:getFFIPointer())
end

function geometry_buffer:update(count)
    count = count or self.size
    self.mesh:setVertices(self.data, 1, count)
end

return geometry_buffer