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
-- @module menori.Mesh

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')
local utils = require (modules .. 'libs.utils')

local ml = require (modules .. 'ml')
local vec3   = ml.vec3
local bound3 = ml.bound3

local Mesh = class('Mesh')

local default_template = {1, 2, 3, 2, 4, 3}

Mesh.default_vertexformat = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"VertexNormal"  , "float", 3},
}

local default_material = {}

local function create_mesh_from_primitive(primitive, base_texture)
	local count = primitive.count or #primitive.vertices
	assert(count > 0)

	local vertexformat = primitive.vertexformat or Mesh.default_vertexformat
	local mode = primitive.mode or 'triangles'

	local mesh = love.graphics.newMesh(vertexformat, primitive.vertices, mode, 'static')

	if primitive.indices then
		local idatatype
		if primitive.indices_tsize then
			idatatype = primitive.indices_tsize <= 2 and 'uint16' or 'uint32'
		end
		mesh:setVertexMap(primitive.indices, idatatype)
	end
	if base_texture then
		mesh:setTexture(base_texture)
	end
	return mesh
end

--- Generates indices for quadrilateral primitives.
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

function Mesh.get_attribute_index(attribute, format)
	for i, v in ipairs(format) do
		if v[1] == attribute then
			return i
		end
	end
end

function Mesh.calculate_bound(mesh)
      local t = {}

	local count = mesh:getVertexCount()
	if count then
		local format = mesh:getVertexFormat()
		local pindex = Mesh.get_attribute_index('VertexPosition', format)

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
	return bound3(vec3(t.x1, t.y1, t.z1), vec3(t.x2, t.y2, t.z2))
end

--- init
-- @tparam table primitives List of primitives
function Mesh:init(primitives)
	self.primitives = {}
	for i, p in ipairs(primitives) do
		local base_texture
		local material = p.material
		if material then
			if material.baseTexture then
				base_texture = material.baseTexture.source
			elseif material.emissiveTexture then
				base_texture = material.emissiveTexture.source
			end
		end
		local mesh = create_mesh_from_primitive(p, base_texture)
		self.primitives[i] = {
			mesh = mesh,
			material = material,
			bound = Mesh.calculate_bound(mesh),
		}
	end
end

function Mesh.from_primitive(vertices, opt)
	local primitive = {
		mode = opt.mode,
		vertexformat = opt.vertexformat,
		vertices = vertices,
		indices = opt.indices,
		material = opt.material or {
			baseTexture = {
				source = opt.texture
			},
			uniforms = {
				baseColor = {1, 1, 1, 1}
			}
		}
	}
	return Mesh{ primitive }
end

function Mesh:draw(shader)
	for _, p in ipairs(self.primitives) do
		if p.material.uniforms then
			for k, v in pairs(p.material.uniforms) do
				utils.noexcept_send_uniform(shader, k, v)
			end
		end
		love.graphics.draw(p.mesh)
	end
end

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

function Mesh:set_vertices(vertices, startvertex, iprimitive)
	iprimitive = iprimitive or 1
	self.primitives[iprimitive].mesh:setVertices(vertices, startvertex)
end

function Mesh:apply_matrix(m)
	local temp_v3 = vec3(0, 0, 0)

	for _, p in ipairs(self.primitives) do
		local mesh = p.mesh
		local format = mesh:getVertexFormat()
		local pindex = Mesh.get_attribute_index('VertexPosition', format)

		for j = 1, mesh:getVertexCount() do
			local x, y, z = mesh:getVertexAttribute(j, pindex)
			temp_v3:set(x, y, z)
			m:multiply_vec3(temp_v3, temp_v3)

			mesh:setVertexAttribute(j, pindex, temp_v3.x, temp_v3.y, temp_v3.z)
		end
	end
end

return Mesh