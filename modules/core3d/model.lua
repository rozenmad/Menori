--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local Model = {}

Model.mesh_format = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"aNormal", "float", 3},
}

function Model.create_primitive(vertices, image)
	return { vertices = vertices, indices = Model.generate_indices(#vertices), material = { image_data = image } }
end

function Model.create_mesh_from_primitive(primitive, mode)
	assert(#primitive.vertices > 0)
	mode = mode or 'triangles'
	local mesh = love.graphics.newMesh(Model.mesh_format, primitive.vertices, mode)

	mesh:setVertexMap(primitive.indices)
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

function Model.create(mesh)
	local model_instance = {
		primitives = {},
		translation = mesh.translation,
		rotation = mesh.rotation,
		scale = mesh.scale,
	}
	for i, p in ipairs(mesh.primitives) do
		model_instance.primitives[i] = Model.create_mesh_from_primitive(p)
	end
	return model_instance
end

return Model