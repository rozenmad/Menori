--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local class = require 'menori.modules.libs.class'

local Model = class('Model')

Model.vertexformat_default = {
	{"VertexPosition", "float", 3},
	{"aNormal", "float", 3},
	{"VertexTexCoord", "float", 2},
}

function Model.create_primitive(vertices, image)
	return { vertices = vertices, indices = Model.generate_indices(#vertices), material = { image_data = image } }
end

function Model.create_mesh_from_primitive(primitive, mode)
	local count = primitive.count or #primitive.vertices
	assert(count > 0)
	local vertexformat = primitive.vertexformat or Model.vertexformat_default
	mode = mode or 'triangles'
	for i, v in ipairs(vertexformat) do
		print(v[1], v[2], v[3])
	end 
	local mesh = love.graphics.newMesh(vertexformat, primitive.vertices, mode, 'dynamic')

	if primitive.indices then
		mesh:setVertexMap(primitive.indices, primitive.indices_type_size <= 2 and 'uint16' or 'uint32')
	end
	if primitive.material and primitive.material.image_data then
		mesh:setTexture(primitive.material.image_data)
	end
	return mesh
end

function Model.generate_indices(size)
	local indices = {}
	for j = 0, size / 4 - 1 do
		local v = j * 6
		local i = j * 4
		indices[v + 1] = i + 1
		indices[v + 2] = i + 2
		indices[v + 3] = i + 3
		indices[v + 4] = i + 2
		indices[v + 5] = i + 4
		indices[v + 6] = i + 3
	end
	return indices
end

function Model:constructor(mesh)
	self.primitives = {}
	for i, p in ipairs(mesh.primitives) do
		self.primitives[i] = Model.create_mesh_from_primitive(p)
	end
end

return Model