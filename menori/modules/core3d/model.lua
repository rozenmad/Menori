--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Class for initializing and storing mesh vertices and material.
]]
-- @module menori.Model

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')

local Model = class('Model')

local default_template = {1, 2, 3, 2, 4, 3}

Model.vertexformat_default = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"VertexNormal", "float", 3},
}

--- Сreates a primitive data structure.
-- @tparam table vertices Table or Data of vertices
-- @tparam table indices Table or Data of indices
-- @tparam number count Count of vertices
-- @param Image image Image object that is used when drawing the mesh
-- @tparam table vertexformat A table in the form of {attribute, ...}_
-- @tparam table color Сolor table that is used when drawing the mesh
-- @tparam number indices_type_size Size of the index type if the indices stored in Data [2 or 4]
function Model.create_primitive(vertices, indices, count, image, vertexformat, color, indices_type_size)
	local primitive = {
		vertexformat = vertexformat or Model.vertexformat_default,
		vertices = vertices,
		indices = indices,
		indices_type_size = indices_type_size,
		material = {
			base_color_texture = image,
			base_color_texture_coord = 0,
			base_color_factor = color or {1, 1, 1, 1},
		},
		count = count,
	}
	return {
		primitive
	}
end

--- Сreate mesh from primitive.
-- @tparam table primitive Primitive object created by Model.create_primitive function
function Model.create_mesh_from_primitive(primitive)
	local count = primitive.count or #primitive.vertices
	assert(count > 0)

	local vertexformat = primitive.vertexformat or Model.vertexformat_default
	local mode = primitive.mode or 'triangles'

	local mesh = love.graphics.newMesh(vertexformat, primitive.vertices, mode, 'dynamic')

	if primitive.indices then
		local idatatype
		if primitive.indices_type_size then
			idatatype = primitive.indices_type_size <= 2 and 'uint16' or 'uint32'
		end
		mesh:setVertexMap(primitive.indices, idatatype)
	end
	if primitive.material and primitive.material.base_color_texture then
		mesh:setTexture(primitive.material.base_color_texture)
	end
	return mesh
end

--- Generates indices for quadrilateral primitives.
-- @tparam number count Count of vertices
-- @tparam table template Template list that is used to generate indices in a specific sequence
function Model.generate_indices(count, template)
	template = template or default_template
	local indices = {}
	for j = 0, count / 4 - 1 do
		local v = j * 6
		local i = j * 4
		indices[v + 1] = i + template[1]
		indices[v + 2] = i + template[2]
		indices[v + 3] = i + template[3]
		indices[v + 4] = i + template[4]
		indices[v + 5] = i + template[5]
		indices[v + 6] = i + template[6]
	end
	return indices
end

--- Constructor
-- @tparam table primitives List of primitives
function Model:constructor(primitives)
	self.primitives = {}
	for i, p in ipairs(primitives) do
		self.primitives[i] = {
			mesh = Model.create_mesh_from_primitive(p),
			material = p.material,
		}
	end
end

return Model