--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Capsule shape factory function.
-- @module Capsule

local modules = (...):match('(.*%menori.modules.)')
local Mesh = require(modules .. 'core3d.mesh')
local vertexformat = require(modules .. 'core3d.shapes.vertexformat')

local function add_ring(vertices, radius, ring_radius, y, ny, v_segments, idx, capsule_height)
	for s = 0, v_segments do
		local theta = 2 * math.pi * s / v_segments
		local x = ring_radius * math.cos(theta)
		local z = ring_radius * math.sin(theta)
		local nx = x / radius
		local nz = z / radius

		local u = (s / v_segments)
		local v = 1 - ((y + capsule_height / 2) / capsule_height)

		vertices[idx] = {x, y, z, nx, ny, nz, 1, 1, 1, 1, u, v}
		idx = idx + 1
	end
	return idx
end

--- Creates a `menori.Mesh` with a capsule geometry.
-- @function Capsule
-- @tparam number radius Capsule radius (default: 0.5)
-- @tparam number height Height of the cylindrical section only (default: 1)
-- @tparam number v_segments Number of vertical segments around the capsule (default: 8)
-- @tparam number h_segments Number of horizontal segments for each hemisphere (default: 16)
-- @tparam number cylinder_segments Number of segments along the cylinder height (default: 1)
-- @treturn menori.Mesh A new `menori.Mesh` object containing the capsule geometry
-- @usage
-- -- Create a capsule with default parameters
-- local capsule = menori.Capsule()
--
-- -- Create a capsule with radius 1 and height 3
-- local capsule = menori.Capsule(1, 3)
--
-- -- Create a detailed capsule with custom segment counts
-- local capsule = menori.Capsule(0.5, 2, 12, 24, 4)
--
-- -- Create a ModelNode with capsule
-- local model_node = menori.ModelNode(capsule)
local function Capsule(radius, height, v_segments, h_segments, cylinder_segments)
	radius = radius or 0.5
	height = height or 1
	v_segments = math.max(3, v_segments or 8)
	h_segments = math.max(1, h_segments or 16)
	cylinder_segments = math.max(1, cylinder_segments or 1)

	local capsule_height = height + radius * 2
	local half_cyl_height = height / 2
	if half_cyl_height < 0 then
		error("Capsule height must be >= 2 * radius")
	end

	local idx = 1

	local vertices = {}
	for r = h_segments, 1, -1 do
		local phi = (math.pi / 2) * r / h_segments
		local ring_r = radius * math.cos(phi)
		local y = radius * math.sin(phi) + half_cyl_height
		local ny = math.sin(phi)
		idx = add_ring(vertices, radius, ring_r, y, ny, v_segments, idx, capsule_height)
	end

	for r = 0, cylinder_segments do
		local t = r / cylinder_segments
		local y = half_cyl_height - t * (2 * half_cyl_height)
		idx = add_ring(vertices, radius, radius, y, 0, v_segments, idx, capsule_height)
	end

	for r = 1, h_segments do
		local phi = (math.pi / 2) * r / h_segments
		local ring_r = radius * math.cos(phi)
		local y = -radius * math.sin(phi) - half_cyl_height
		local ny = -math.sin(phi)
		idx = add_ring(vertices, radius, ring_r, y, ny, v_segments, idx, capsule_height)
	end

	local stride = v_segments + 1
	local rings = h_segments + (cylinder_segments + 1) + h_segments
	local indices = {}
	for r = 0, rings - 2 do
		for s = 0, v_segments - 1 do
			local current = r * stride + s
			local next = current + stride

			table.insert(indices, next + 1)
			table.insert(indices, current + 1)
			table.insert(indices, next + 2)

			table.insert(indices, next + 2)
			table.insert(indices, current + 1)
			table.insert(indices, current + 2)
		end
	end

	return Mesh {
		vertices = vertices,
		vertexformat = vertexformat,
		indices = indices
	}
end

return Capsule
