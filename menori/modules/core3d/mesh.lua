--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Mesh class for initializing and storing mesh vertices.
-- Provides functionality for creating, manipulating, and rendering 3D mesh geometry
-- with support for custom vertex formats and transformations.
-- @classmod Mesh

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')
local ml    = require (modules .. 'ml')
local utils = require (modules .. 'libs.utils')

local vec3 = ml.vec3
local mat4 = ml.mat4
local bound3 = ml.bound3
local lg = love.graphics

local Mesh = class('Mesh')

local default_template = {1, 2, 3, 2, 4, 3}
local convert_format

Mesh.MAX_MORPH_TARGETS = 8

if love._version_major > 11 then
	Mesh.default_vertexformat = {
		{format = "floatvec3", name = "VertexPosition", location = 0},
		{format = "floatvec2", name = "VertexTexCoord", location = 1},
		{format = "floatvec3", name = "VertexNormal"  , location = 2},
	}
	convert_format = function(attribute)
		return attribute.format
	end
else
	Mesh.default_vertexformat = {
		{"VertexPosition", "float", 3},
		{"VertexTexCoord", "float", 2},
		{"VertexNormal"  , "float", 3},
	}
	convert_format = function(attribute)
		local count = attribute[3]
		if count > 1 then
			return 'vec' .. count
		else
			return 'float'
		end
	end
end

local function calculate_bound(lg_mesh_obj)
	local t = {}

	local count = lg_mesh_obj:getVertexCount()
	if count then
		local format = lg_mesh_obj:getVertexFormat()
		local pindex = Mesh.get_attribute_index('VertexPosition', format)

		local x, y, z = lg_mesh_obj:getVertexAttribute(1, pindex)
		t.x1, t.x2 = x, x
		t.y1, t.y2 = y, y
		t.z1, t.z2 = z, z

		for i = 2, lg_mesh_obj:getVertexCount() do
			x, y, z = lg_mesh_obj:getVertexAttribute(i, pindex)
			if x < t.x1 then t.x1 = x elseif x > t.x2 then t.x2 = x end
			if y < t.y1 then t.y1 = y elseif y > t.y2 then t.y2 = y end
			if z < t.z1 then t.z1 = z elseif z > t.z2 then t.z2 = z end
		end
	end
	return bound3(
		vec3(t.x1, t.y1, t.z1),
		vec3(t.x2, t.y2, t.z2)
	)
end

----
-- Generate indices for quadrilateral primitives.
-- @static
-- @tparam number count Count of vertices
-- @tparam table template Template list that is used to generate indices in a specific sequence
function Mesh.generate_indices(count, template)
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

----
-- Gets the attribute index from the vertex format.
-- Searches for a specific vertex attribute by name in the vertex format table.
-- @static
-- @tparam string attribute The attribute name to find (e.g., "VertexPosition", "VertexNormal")
-- @tparam table format Vertex format table containing attribute definitions
-- @treturn number|nil The index of the attribute, or nil if not found
function Mesh.get_attribute_index(attribute, format)
	for i, v in ipairs(format) do
		if v[1] == attribute or v.name == attribute then
			return i
		end
	end
end

----
-- Assigns location indices to vertex format attributes.
-- Ensures each vertex attribute has a unique location for shader binding.
-- @static
-- @tparam table vertexformat Vertex format table to process
-- @tparam table used_locations Optional table of already used location indices
-- @treturn table,table Modified vertex format and updated used locations table
function Mesh.set_locations(vertexformat, used_locations)
	used_locations = used_locations or {}
	vertexformat = utils.copy(vertexformat)

	for _, v in ipairs(vertexformat) do
		if v.location and not used_locations[v.location] then
			used_locations[v.location] = {
				name = v.name or v[1], format = convert_format(v), location = v.location,
			}
		end
	end

	local next_location = 0
	for _, v in ipairs(vertexformat) do
		if not v.location then
			while used_locations[next_location] do
				next_location = next_location + 1
			end
			v.location = next_location
			used_locations[next_location] = {
				name = v.name or v[1], format = convert_format(v), location = v.location,
			}

		end
	end
	return vertexformat, used_locations
end

----
-- The public constructor.
-- Initializes a mesh with vertices, optional indices, vertex format, etc.
-- @tparam table primitive Table containing mesh data with following fields:
-- @tparam table primitive.vertices Array of vertex data
-- @tparam[opt] table primitive.vertexformat Vertex format specification (uses default if not provided)
-- @tparam[opt] table primitive.indices Index array for vertex mapping
-- @tparam[opt] string primitive.mode Drawing mode (default: "triangles")
-- @tparam[opt] number primitive.count Vertex count override
-- @tparam[opt] number primitive.material_index Material index
-- @tparam[opt] number primitive.indices_tsize Index data type size
function Mesh:init(primitive)
	local count = primitive.count or #primitive.vertices
	assert(count > 0)

	local vertexformat, used_locations = Mesh.set_locations(primitive.vertexformat or Mesh.default_vertexformat)

	local mode = primitive.mode or 'triangles'

	local lg_mesh = lg.newMesh(vertexformat, primitive.vertices, mode, 'static')

	if primitive.indices then
		local idatatype
		if primitive.indices_tsize then
			idatatype = primitive.indices_tsize <= 2 and 'uint16' or 'uint32'
		end
		lg_mesh:setVertexMap(primitive.indices, idatatype)
	end

	self.morph_targets = {}
	self:_init_morph_targets(used_locations, primitive, lg_mesh)

	self.vertex_attribute_index = Mesh.get_attribute_index('VertexPosition', lg_mesh:getVertexFormat())
	self.lg_mesh = lg_mesh
	self.vertexformat = vertexformat
	self.material_index = primitive.material_index
	self.bound = calculate_bound(lg_mesh)
	self.used_locations = used_locations

	self.target_weights = primitive.target_weights
end

function Mesh:_init_morph_targets(used_locations, primitive, lg_mesh)
	local morph_count = 0
	local morph_target_vertexformat
	if primitive.targets then
		for i, target in ipairs(primitive.targets) do
			for _, attribute in pairs(target) do
				local attribute_name
				if love._version_major > 11 then
					local name = attribute.format.name
					attribute_name = 'Target' .. name  .. (i - 1)
					attribute.format.name = attribute_name
				else
					local name = attribute.format[1]
					attribute_name = 'Target' .. name  .. (i - 1)
					attribute.format[1] = attribute_name
				end
				local vertexformat = {
					attribute.format
				}
				morph_target_vertexformat, used_locations = Mesh.set_locations(vertexformat, used_locations)
				local morph_target_mesh = love.graphics.newMesh(morph_target_vertexformat, attribute.data, 'triangles', 'static')

				table.insert(self.morph_targets, morph_target_vertexformat[1])

				lg_mesh:attachAttribute(attribute_name, morph_target_mesh)
				morph_count = morph_count + 1
				if morph_count >= Mesh.MAX_MORPH_TARGETS then
					return
				end
			end
		end
	end
end

----
-- Renders the mesh using the specified material.
-- @tparam menori.Material material The material to use when drawing the mesh
function Mesh:draw(material)
	local shader = material.shader
	material:send_to(shader)

	if self.target_weights then
		if shader:hasUniform("TargetWeights") then
			shader:send("TargetWeights", unpack(self.target_weights))
		end
	end

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

	local mesh = self.lg_mesh
	mesh:setTexture(material.main_texture)
	lg.draw(mesh)
end

function Mesh:has_attribute(attribute_name)
	return Mesh.get_attribute_index(attribute_name, self.vertexformat)
end

----
-- Gets the bounding box of the mesh.
-- @treturn bound3 Axis-aligned bounding box
function Mesh:get_bound()
	return self.bound
end

----
-- Gets the total number of vertices in the mesh.
-- @treturn number Vertex count
function Mesh:get_vertex_count()
	return self.lg_mesh:getVertexCount()
end

----
-- Gets a specific vertex attribute value by name and vertex index.
-- @tparam string name Attribute name (e.g., "VertexPosition", "VertexNormal")
-- @tparam number index Vertex index
-- @tparam[opt] table out Output table to store results
-- @treturn table Table containing the attribute values
function Mesh:get_vertex_attribute(name, index, out)
	local mesh = self.lg_mesh
	local attribute_index = Mesh.get_attribute_index(name, mesh:getVertexFormat())

	out = out or {}
	table.insert(out, {
		mesh:getVertexAttribute(index, attribute_index)
	})
	return out
end

----
-- Gets all triangles from the mesh with transformation applied.
-- @tparam mat4 matrix Transformation matrix to apply to vertices
-- @treturn table Array of triangles in format {{{x, y, z}, {x, y, z}, {x, y, z}}, ...}
function Mesh:get_triangles_transform(matrix)
	local triangles = {}
	local mesh = self.lg_mesh
	local attribute_index = Mesh.get_attribute_index('VertexPosition', mesh:getVertexFormat())
	local map = mesh:getVertexMap()
	if map then
		for i = 1, #map, 3 do
			local v1 = vec3(mesh:getVertexAttribute(map[i + 0], attribute_index))
			local v2 = vec3(mesh:getVertexAttribute(map[i + 1], attribute_index))
			local v3 = vec3(mesh:getVertexAttribute(map[i + 2], attribute_index))
			matrix:multiply_vec3(v1, v1)
			matrix:multiply_vec3(v2, v2)
			matrix:multiply_vec3(v3, v3)
			table.insert(triangles, {
				{v1:unpack()},
				{v2:unpack()},
				{v3:unpack()},
			})
		end
	end
	return triangles
end

----
-- Creates a cached array of triangles from the mesh vertices.
-- @treturn table Array of triangles in format {{{x, y, z}, {x, y, z}, {x, y, z}}, ...}
function Mesh:get_triangles()
	return self:get_triangles_transform(mat4())
end

----
-- Gets an array of mesh vertices as an array.
-- @tparam[opt=1] number start Starting vertex index
-- @tparam[opt] number count Number of vertices to retrieve (defaults to all remaining)
-- @treturn table Array of vertices, where each vertex is a table of attribute components
function Mesh:get_vertices(start, count)
	local mesh = self.lg_mesh
	start = start or 1
	count = count or mesh:getVertexCount()

	local vertices = {}
	for i = start, start + count - 1 do
		table.insert(vertices, {mesh:getVertex(i)})
	end
	return vertices
end

----
-- Gets transformed vertex positions as an array.
-- @tparam mat4 matrix Transformation matrix to apply
-- @tparam[opt=1] number start Starting vertex index
-- @tparam[opt] number count Number of vertices to retrieve  (defaults to all remaining)
-- @treturn table Array of vertices, where each vertex is a table of attribute components
function Mesh:get_vertices_transform(matrix, start, count)
	local mesh = self.lg_mesh
	start = start or 1
	count = count or mesh:getVertexCount()

	local vertices = {}
	for i = start, start + count - 1 do
		local v = vec3(mesh:getVertex(i))
		matrix:multiply_vec3(v, v)
		table.insert(vertices, {v:unpack()})
	end
	return vertices
end

--- Gets the vertex index mapping of the mesh.
-- @treturn table|nil Index array if present, nil otherwise
function Mesh:get_vertex_map()
	return self.lg_mesh:getVertexMap()
end

----
-- Updates mesh vertices with new data.
-- @tparam table vertices Array of vertices, where each vertex is a table of attribute components
-- @tparam number startvertex The vertex index from which insertion will start
function Mesh:set_vertices(vertices, startvertex)
	self.lg_mesh:setVertices(vertices, startvertex)
end

----
-- Applies a transformation matrix to all mesh vertex positions.
-- Permanently modifies the mesh geometry by transforming all vertex positions.
-- @tparam mat4 matrix Transformation matrix to apply to vertex positions
function Mesh:apply_matrix(matrix)
	local temp_v3 = vec3(0, 0, 0)

	local mesh = self.lg_mesh
	local format = mesh:getVertexFormat()
	local pindex = Mesh.get_attribute_index('VertexPosition', format)

	for j = 1, mesh:getVertexCount() do
		local x, y, z = mesh:getVertexAttribute(j, pindex)
		temp_v3:set(x, y, z)
		matrix:multiply_vec3(temp_v3, temp_v3)

		mesh:setVertexAttribute(j, pindex, temp_v3.x, temp_v3.y, temp_v3.z)
	end
end

return Mesh

--- 
-- Underlying LOVE Mesh object used for rendering.
-- @tfield love.Mesh lg_mesh

---
-- Vertex format specification used by this mesh.
-- @tfield table vertexformat

---
-- Material index.
-- @tfield number material_index

---
-- Cached bounding box of the mesh geometry.
-- @tfield bound3 bound

---
-- Location mapping table for vertex attributes.
-- @tfield table used_locations

---
-- Index of the VertexPosition attribute in the vertex format.
-- @tfield number vertex_attribute_index