--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Sphere shape factory function.
-- @module Sphere

local modules = (...):match('(.*%menori.modules.)')

local Mesh = require (modules .. 'core3d.mesh')
local vertexformat = require (modules .. 'core3d.shapes.vertexformat')

--- Creates a `menori.Mesh` with a sphere geometry.
-- @function Sphere
-- @tparam number radius Sphere radius (default: 1)
-- @tparam number v_segments Number of vertical segments (default: 16)
-- @tparam number h_segments Number of horizontal segments (default: 32)
-- @treturn menori.Mesh A new `menori.Mesh` object containing the sphere geometry
-- @usage
-- -- Create a sphere with default parameters
-- local sphere = menori.Sphere()
-- 
-- -- Create a sphere with radius 2
-- local sphere = menori.Sphere(2)
-- 
-- -- Create a low-poly sphere with custom segment counts
-- local sphere = menori.Sphere(1, 4, 8)
--
-- -- Create a ModelNode with sphere
-- local model_node = menori.ModelNode(sphere)
local function Sphere(radius, v_segments, h_segments)
	radius = radius or 1
	v_segments = math.max(3, v_segments or 16)
	h_segments = math.max(2, h_segments or 32)

	local vertices = {}

	for r = 0, h_segments do
		local v = (r / h_segments)
		local phi = math.pi * v
		local y = radius * math.cos(phi)
		local ring_radius = radius * math.sin(phi)

		for s = 0, v_segments do
			local u = (s / v_segments)
			local theta = 2 * math.pi * u
			local x = ring_radius * math.cos(theta)
			local z = ring_radius * math.sin(theta)

			local nx, ny, nz = x/radius, y/radius, z/radius
			table.insert(vertices, {x, y, z, nx, ny, nz, 1, 1, 1, 1, u, v})
		end
	end

	local indices = {}
	for r = 0, h_segments - 1 do
		for s = 0, v_segments - 1 do
			local current = r * (v_segments + 1) + s
			local next = current + v_segments + 1

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

return Sphere