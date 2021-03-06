--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local Node = require 'menori.modules.node'
local ShaderObject = require 'menori.modules.shaderobject'
local Model = Node:extend('Model')

local cpml = require 'libs.cpml'

Model.default_shader = ShaderObject([[
#ifdef VERTEX
	uniform mat4 m_model;
	uniform mat4 m_view;
	uniform mat4 m_projection;
	attribute vec3 aNormal;

	vec4 position(mat4 transform_projection, vec4 vertex_position) {
		return m_projection * m_view * m_model * vertex_position;
	}
#endif
]])

Model.mesh_format = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"aNormal", "float", 3},
}

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

function Model.create_primitive(vertices, image)
	return { vertices = vertices, indices = Model.generate_indices(#vertices), material = { image_data = image } }
end

function Model:constructor(node, shader)
	Model.super.constructor(self)
	self.local_matrix:set_position_and_rotation(cpml.vec3(node.translation), cpml.quat(node.rotation))
	self.local_matrix:scale(cpml.vec3(node.scale))

	self.shader = shader or Model.default_shader

	self.primitives = {}
	for i, p in ipairs(node.primitives) do
		self.primitives[i] = Model.create_mesh_from_primitive(p)
	end
end

function Model:render(scene, environment, shader)
	shader = shader or self.shader
	shader:attach()
	environment:send_uniforms_to(shader)

	shader:send_matrix('m_model', self.world_matrix)
	for _, v in ipairs(self.primitives) do
		love.graphics.draw(v)
	end
	shader:detach()
end

return Model