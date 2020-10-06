local class = require 'menori.modules.libs.class'
local ffi = require 'ffi'

local mesh_buffer = class('mesh_buffer')

function mesh_buffer:constructor(size, format)
    self.format = format
    self.bytedata_size = 0
    for i, v in ipairs(format) do
        self.bytedata_size = self.bytedata_size + ffi.sizeof(v[2]) * v[3]
    end

    self:reallocate(size)
end

function mesh_buffer:reallocate(size)
    self.size = size
    self.mesh = love.graphics.newMesh(self.format, size, nil, "dynamic")

    local temp_data = love.data.newByteData(size * self.bytedata_size)
    if self.data then
        local dst = temp_data:getFFIPointer()
        local src = self.data:getFFIPointer()
        ffi.copy(dst, src, self.data:getSize())
    end
    self.data = temp_data
end

function mesh_buffer:get_data_pointer(ct)
    return ffi.cast(ct, self.data:getFFIPointer())
end

function mesh_buffer:update(count)
    count = count or self.size
    self.mesh:setVertices(self.data, 1, count)
end

return mesh_buffer