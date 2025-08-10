--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--[[--
Plane shape.
]]

local modules = (...):match('(.*%menori.modules.)')

local Mesh = require (modules .. 'core3d.mesh')
local vertexformat = require (modules .. 'core3d.shapes.vertexformat')

--- The public constructor.
-- Creates a menori.Mesh with a plane shape.
-- @function Plane
-- @number width Plane width (default: 2)
-- @number height Plane height (default: 2)
-- @number width_segments Number of width segments (default: 1)
-- @number height_segments Number of height segments (default: 1)
local function Plane(width, height, v_segments, h_segments)
	width = width or 2
	height = height or 2
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