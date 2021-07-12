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
local ml = require (modules .. 'ml')
local vec3 = ml.vec3

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
		mode = 'triangles',
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

function Model.get_attribute_index(attribute, format)
	for i, v in ipairs(format) do
		if v[1] == attribute then
			return i
		end
	end
end

function Model.calculate_bound(mesh)
      local t = {}

	local count = mesh:getVertexCount()
	if count then
		local format = mesh:getVertexFormat()
		local pindex = Model.get_attribute_index('VertexPosition', format)

		local x, y, z = mesh:getVertexAttribute(1, pindex)
		t.x1, t.x2 = x, x
		t.y1, t.y2 = y, y
		t.z1, t.z2 = z, z

		for i = 2, mesh:getVertexCount() do
			local x, y, z = mesh:getVertexAttribute(i, pindex)
			if x < t.x1 then t.x1 = x elseif x > t.x2 then t.x2 = x end
			if y < t.y1 then t.y1 = y elseif y > t.y2 then t.y2 = y end
			if z < t.z1 then t.z1 = z elseif z > t.z2 then t.z2 = z end
		end
	end
	return {
		x = t.x1,
		y = t.y1,
		z = t.z1,
		w = t.x2 - t.x1,
		h = t.y2 - t.y1,
		d = t.z2 - t.z1,
	}
end

--- init
-- @tparam table primitives List of primitives
function Model:init(primitives)
	self.primitives = {}
	for i, p in ipairs(primitives) do
		local mesh = Model.create_mesh_from_primitive(p)
		self.primitives[i] = {
			mesh = mesh,
			material = p.material,
			bound = Model.calculate_bound(mesh),
		}
	end
end

function Model:apply_matrix(m)
      local t = {}
	local temp_v3 = vec3(0, 0, 0)

	for i, p in ipairs(self.primitives) do
		local mesh = p.mesh
		local format = mesh:getVertexFormat()
		local pindex = Model.get_attribute_index('VertexPosition', format)

		for j = 1, mesh:getVertexCount() do
			local x, y, z = mesh:getVertexAttribute(j, pindex)
			temp_v3:set(x, y, z)
			m:multiply_vec3(temp_v3, temp_v3)

			mesh:setVertexAttribute(j, pindex, temp_v3.x, temp_v3.y, temp_v3.z)
		end
	end
end

return Model