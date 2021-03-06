local class = require 'menori.modules.libs.class'
local ffi = require 'ffi'

local geometry_buffer = class('mesh_buffer')

local function attribute_sizeof(type)
    if type == 'byte' then
        return 1
    elseif type == 'float' then
        return 4
    else
        return 2
    end
end

function geometry_buffer:constructor(size, format)
    self.format = format
    self.bytesize = 0
    self.attributes_count = 0
    for i, v in ipairs(format) do
        self.bytesize = self.bytesize + attribute_sizeof(v[2]) * v[3]
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
    self.ptr = ffi.cast('unsigned char*', self.data:getFFIPointer())
end

function geometry_buffer:get_data_pointer(index)
    return self.ptr + (self.bytesize * index)
end

function geometry_buffer:update(count)
    count = count or self.size
    self.mesh:setVertices(self.data, 1, count)
end

return geometry_buffer