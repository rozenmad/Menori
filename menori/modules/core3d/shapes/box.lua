--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Box shape factory function.
-- @module Box

local modules = (...):match('(.*%menori.modules.)')

local Mesh = require (modules .. 'core3d.mesh')
local vertexformat = require (modules .. 'core3d.shapes.vertexformat')

local function addPlane(vertices, indices, vertex_count, u_dir, v_dir, w_dir, u_len, v_len, u_seg, v_seg, w_pos, normal)
	for iy = 0, v_seg do
		local v = iy / v_seg
		local y = (v - 0.5) * v_len

		for ix = 0, u_seg do
			local u = ix / u_seg
			local x = (u - 0.5) * u_len

			local px = u_dir[1] * x + v_dir[1] * y + w_dir[1] * w_pos
			local py = u_dir[2] * x + v_dir[2] * y + w_dir[2] * w_pos
			local pz = u_dir[3] * x + v_dir[3] * y + w_dir[3] * w_pos

			table.insert(vertices, {
				px, py, pz, normal[1], normal[2], normal[3], 1, 1, 1, 1, u, 1 - v
			})
		end
	end

	for iy = 0, v_seg - 1 do
		for ix = 0, u_seg - 1 do
			local a = vertex_count + iy * (u_seg + 1) + ix + 1
			local b = a + 1
			local c = a + (u_seg + 1)
			local d = c + 1

			table.insert(indices, a)
			table.insert(indices, b)
			table.insert(indices, c)

			table.insert(indices, b)
			table.insert(indices, d)
			table.insert(indices, c)
		end
	end

	return vertex_count + (u_seg + 1) * (v_seg + 1)
end

--- Creates a `menori.Mesh` with a box geometry.
-- A box is a rectangular cuboid with configurable dimensions and subdivision segments.
-- @function Box
-- @tparam number width Box width along the X-axis (default: 1)
-- @tparam number height Box height along the Y-axis (default: 1)
-- @tparam number depth Box depth along the Z-axis (default: 1)
-- @tparam number w_segments Number of segments along the width (default: 1)
-- @tparam number h_segments Number of segments along the height (default: 1)
-- @tparam number d_segments Number of segments along the depth (default: 1)
-- @treturn menori.Mesh A new `menori.Mesh` object containing the box geometry
-- @usage
-- -- Create a unit cube with default parameters
-- local box = menori.Box()
--
-- -- Create a box with custom dimensions
-- local box = menori.Box(2, 3, 1)
--
-- -- Create a subdivided box
-- local box = menori.Box(1, 1, 1, 4, 4, 4)
--
-- -- Create a ModelNode with box
-- local model_node = menori.ModelNode(box)
local function Box(width, height, depth, w_segments, h_segments, d_segments)
	width = width or 1
	height = height or 1
	depth = depth or 1
	w_segments = w_segments or 1
	h_segments = h_segments or 1
	d_segments = d_segments or 1

	local hw = width / 2
	local hh = height / 2
	local hd = depth / 2

	local vertices = {}
	local indices = {}
	local vertex_count = 0

	vertex_count = addPlane(vertices, indices, vertex_count, { 1, 0, 0}, { 0, 1, 0}, { 0, 0, 1}, width, height, w_segments, h_segments, hd, { 0, 0, 1})
	vertex_count = addPlane(vertices, indices, vertex_count, {-1, 0, 0}, { 0, 1, 0}, { 0, 0,-1}, width, height, w_segments, h_segments, hd, { 0, 0,-1})
	vertex_count = addPlane(vertices, indices, vertex_count, { 0, 0,-1}, { 0, 1, 0}, { 1, 0, 0}, depth, height, d_segments, h_segments, hw, { 1, 0, 0})
	vertex_count = addPlane(vertices, indices, vertex_count, { 0, 0, 1}, { 0, 1, 0}, {-1, 0, 0}, depth, height, d_segments, h_segments, hw, {-1, 0, 0})
	vertex_count = addPlane(vertices, indices, vertex_count, { 1, 0, 0}, { 0, 0,-1}, { 0, 1, 0}, width,  depth, w_segments, d_segments, hh, { 0, 1, 0})
	vertex_count = addPlane(vertices, indices, vertex_count, { 1, 0, 0}, { 0, 0, 1}, { 0,-1, 0}, width,  depth, w_segments, d_segments, hh, { 0,-1, 0})

	return Mesh {
		vertices = vertices,
		vertexformat = vertexformat,
		indices = indices
	}
end

return Box
