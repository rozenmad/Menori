--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Triangle shape factory function.
-- @module Triangle

local modules = (...):match('(.*%menori.modules.)')

local Mesh = require (modules .. 'core3d.mesh')
local vertexformat = require (modules .. 'core3d.shapes.vertexformat')

--- Creates a `menori.Mesh` with a triangle shape.
-- @function Triangle
-- @tparam number|table v1 Triangle size for equilateral triangle (default: 1) or first vertex position {x, y, z}
-- @tparam table v2 Second vertex position {x, y, z} (required if v1 is a table)
-- @tparam table v3 Third vertex position {x, y, z} (required if v1 is a table)
-- @treturn menori.Mesh A new `menori.Mesh` object containing the triangle geometry
-- @usage
-- -- Create an equilateral triangle with default size (1)
-- local triangle = menori.Triangle()
-- 
-- -- Create an equilateral triangle with size 2
-- local triangle = menori.Triangle(2)
-- 
-- -- Create a custom triangle with three vertices
-- local triangle = menori.Triangle(
--     { 0,  1, 0},  -- first vertex
--     {-1, -1, 0},  -- second vertex
--     { 1, -1, 0}   -- third vertex
-- )
--
-- -- Create a ModelNode with triangle
-- local model_node = menori.ModelNode(triangle)
local function Triangle(v1, v2, v3)
	local vertices

	if type(v1) ~= 'table' then
		local size = v1 or 1
		local h = size * math.sqrt(3) / 2
		vertices = {
			{      0, h * 2/3, 0, 0, 0, 1, 1, 1, 1, 1, 0.5, 0},
			{-size/2,    -h/3, 0, 0, 0, 1, 1, 1, 1, 1,   0, 1},
			{ size/2,    -h/3, 0, 0, 0, 1, 1, 1, 1, 1,   1, 1},
		}
	else
		local ux, uy, uz = v2[1] - v1[1], v2[2] - v1[2], v2[3] - v1[3]
		local vx, vy, vz = v3[1] - v1[1], v3[2] - v1[2], v3[3] - v1[3]
		local nx = uy * vz - uz * vy
		local ny = uz * vx - ux * vz
		local nz = ux * vy - uy * vx
		local len = math.sqrt(nx*nx + ny*ny + nz*nz)
		if len ~= 0 then
			nx, ny, nz = nx/len, ny/len, nz/len
		end

		vertices = {
			{v1[1], v1[2], v1[3], nx, ny, nz, 1, 1, 1, 1, 0.5, 0},
			{v2[1], v2[2], v2[3], nx, ny, nz, 1, 1, 1, 1,   0, 1},
			{v3[1], v3[2], v3[3], nx, ny, nz, 1, 1, 1, 1,   1, 1},
		}
	end

	local indices = {1, 2, 3}

	return Mesh {
		vertices = vertices,
		vertexformat = vertexformat,
		indices = indices
	}
end

return Triangle