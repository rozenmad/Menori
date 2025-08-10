--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Plane shape factory function.
-- @module Plane

local modules = (...):match('(.*%menori.modules.)')

local Mesh = require (modules .. 'core3d.mesh')
local vertexformat = require (modules .. 'core3d.shapes.vertexformat')

--- Creates a `menori.Mesh` with a plane geometry.
-- @function Plane
-- @tparam number width Width of the plane along the X-axis.
-- @tparam number height Height of the plane along the Y-axis.
-- @tparam number v_segments Number of vertical subdivisions (parallel to the Y-axis).
-- @tparam number h_segments Number of horizontal subdivisions (parallel to the X-axis).
-- @treturn menori.Mesh A new `menori.Mesh` object representing the generated plane.
-- @usage
-- -- Create a default 1x1 plane with no subdivisions
-- local plane = menori.Plane()
--
-- -- Create a 4x3 plane with no subdivisions
-- local plane = menori.Plane(4, 3)
--
-- -- Create a 1x1 plane subdivided into a 10x10 grid
-- local plane = menori.Plane(1, 1, 10, 10)
--
-- -- Create a ModelNode with plane
-- local model_node = menori.ModelNode(plane)
local function Plane(width, height, v_segments, h_segments)
	width = width or 1
	height = height or 1
	v_segments = v_segments or 1
	h_segments = h_segments or 1

	local half_width = width / 2
	local half_height = height / 2

	local vertices = {}
	for row = 0, h_segments do
		local v = (row / h_segments)
		local y = v * height - half_height

		for col = 0, v_segments do
			local u = (col / v_segments)
			local x = u * width - half_width

			table.insert(vertices, {
				x, y, 0, 0, 0, 1, 1, 1, 1, 1, u, 1 - v
			})
		end
	end

	local indices = {}
	for r = 0, h_segments - 1 do
		for c = 0, v_segments - 1 do
			local base = r * (v_segments + 1) + c
			local next_row = base + (v_segments + 1)

			table.insert(indices, base + 1)
			table.insert(indices, base + 2)
			table.insert(indices, next_row + 1)

			table.insert(indices, base + 2)
			table.insert(indices, next_row + 2)
			table.insert(indices, next_row + 1)
		end
	end

	return Mesh {
		vertices = vertices,
		vertexformat = vertexformat,
		indices = indices
	}
end

return Plane