--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
]]

--[[--
Class for initializing and storing mesh vertices and material.
]]
-- @classmod Mesh

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')
local ml = require (modules .. 'ml')
local vec3 = ml.vec3
local bound3 = ml.bound3
local lg = love.graphics

local Mesh = class('Mesh')

local default_template = {1, 2, 3, 2, 4, 3}

Mesh.default_vertexformat = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"VertexNormal"  , "float", 3},
}

local function create_mesh_from_primitive(primitive, texture)
	local count = primitive.count or #primitive.vertices
	assert(count > 0)

	local vertexformat = primitive.vertexformat or Mesh.default_vertexformat
	local mode = primitive.mode or 'triangles'

	local lg_mesh = lg.newMesh(vertexformat, primitive.vertices, mode, 'static')

	if primitive.indices then
		local idatatype
		if primitive.indices_tsize then
			idatatype = primitive.indices_tsize <= 2 and 'uint16' or 'uint32'
		end
		lg_mesh:setVertexMap(primitive.indices, idatatype)
	end
	if texture then
		lg_mesh:setTexture(texture)
	end
	return lg_mesh
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
			local x, y, z = lg_mesh_obj:getVertexAttribute(i, pindex)
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

--- Generate indices for quadrilateral primitives.
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

--- Get the attribute index from the vertex format.
-- @static
-- @tparam string attribute The attribute to be found.
-- @tparam table format Vertex format table.
function Mesh.get_attribute_index(attribute, format)
	for i, v in ipairs(format) do
		if v[1] == attribute then
			return i
		end
	end
end

--- Create a menori.Mesh from vertices.
-- @static
-- @tparam table vertices that contains vertex data. See [LOVE Mesh](https://love2d.org/wiki/love.graphics.newMesh)
-- @tparam[opt] table opt that containing {mode=, vertexformat=, indices=, texture=}
function Mesh.from_primitive(vertices, opt)
	local primitive = {
		mode = opt.mode,
		vertexformat = opt.vertexformat,
		vertices = vertices,
		indices = opt.indices,
		texture = opt.texture
	}
	return Mesh{primitive}
end

--- The public constructor.
-- @tparam table primitives List of primitives
-- @tparam[opt] Image texture
function Mesh:init(primitives, texture)
	self.primitives = {}
	for i, p in ipairs(primitives) do
		local mesh = create_mesh_from_primitive(p, texture)
		self.primitives[i] = {
			mesh = mesh,
			material_index = p.material_index,
			bound = calculate_bound(mesh),
		}
	end
end

--- Draw a Mesh object on the screen.
-- @tparam menori.Material material The Material to be used when drawing the mesh.
function Mesh:draw(material)
	material:send_to(material.shader)

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

	for i = 1, #self.primitives do
		local mesh = self.primitives[i].mesh
		mesh:setTexture(material.main_texture)
		lg.draw(mesh)
	end
end

--- Create a cached array of triangles from the mesh vertices and return it.
-- @treturn table Triangles { {{x, y, z}, {x, y, z}, {x, y, z}}, ...}
function Mesh:get_triangles()
	if not self.triangles then
		local mesh = self.primitives[1].mesh
		self.triangles = {}
		local attribute_index = Mesh.get_attribute_index('VertexPosition', mesh:getVertexFormat())
		local map = mesh:getVertexMap()

		if map then
			for i = 1, #map, 3 do
				table.insert(self.triangles, {
					{mesh:getVertexAttribute(map[i + 0], attribute_index)},
					{mesh:getVertexAttribute(map[i + 1], attribute_index)},
					{mesh:getVertexAttribute(map[i + 2], attribute_index)},
				})
			end
		end
	end
	return self.triangles
end

--- Get an array of all mesh vertices.
-- @tparam[opt=1] int iprimitive The index of the primitive.
-- @treturn table The table in the form of {vertex, ...} where each vertex is a table in the form of {attributecomponent, ...}.
function Mesh:get_vertices(iprimitive)
	iprimitive = iprimitive or 1
	local mesh = self.primitives[iprimitive].mesh
	local count = mesh:getVertexCount()
	local vertices = {}
	for i = 1, count do
		table.insert(vertices, {mesh:getVertex(i)})
	end
	return vertices
end

--- Get an array of all mesh vertices.
-- @tparam table vertices The table in the form of {vertex, ...} where each vertex is a table in the form of {attributecomponent, ...}.
-- @tparam number startvertex The vertex from which the insertion will start.
-- @tparam[opt=1] int iprimitive The index of the primitive.
function Mesh:set_vertices(vertices, startvertex, iprimitive)
	iprimitive = iprimitive or 1
	self.primitives[iprimitive].mesh:setVertices(vertices, startvertex)
end

--- Apply the transformation matrix to the mesh vertices.
-- @tparam ml.mat4 matrix
function Mesh:apply_matrix(matrix)
	local temp_v3 = vec3(0, 0, 0)

	for _, p in ipairs(self.primitives) do
		local mesh = p.mesh
		local format = mesh:getVertexFormat()
		local pindex = Mesh.get_attribute_index('VertexPosition', format)

		for j = 1, mesh:getVertexCount() do
			local x, y, z = mesh:getVertexAttribute(j, pindex)
			temp_v3:set(x, y, z)
			matrix:multiply_vec3(temp_v3, temp_v3)

			mesh:setVertexAttribute(j, pindex, temp_v3.x, temp_v3.y, temp_v3.z)
		end
	end
end

return Mesh