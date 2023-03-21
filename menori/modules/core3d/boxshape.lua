--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

--[[--
Box shape.
]]

local modules = (...):match('(.*%menori.modules.)')

local Mesh = require (modules .. 'core3d.mesh')

local vertexformat
if love._version_major > 11 then
	vertexformat = {
		{format = "floatvec3", name = "VertexPosition"},
		{format = "floatvec4", name = "VertexColor"},
	}
else
	vertexformat = {
		{"VertexPosition", "float", 3},
		{"VertexColor", "float", 4},
	}
end

--- The public constructor.
-- Creates a menori.Mesh with a cube shape.
-- @function BoxShape
-- @number sx Box shape width
-- @number sy Box shape height
-- @number sz Box shape depth
local function BoxShape(sx, sy, sz)
	sx = sx / 2
	sy = sy / 2
	sz = sz / 2
	local vertices = {
		{-sx,-sy,-sz, 1, 1, 1, 1}, {-sx, sy,-sz, 1, 1, 1, 1}, { sx,-sy,-sz, 1, 1, 1, 1}, { sx, sy,-sz, 1, 1, 1, 1},
		{ sx,-sy, sz, 1, 1, 1, 1}, { sx, sy, sz, 1, 1, 1, 1}, {-sx,-sy, sz, 1, 1, 1, 1}, {-sx, sy, sz, 1, 1, 1, 1},
		{-sx,-sy, sz, 1, 1, 1, 1}, {-sx, sy, sz, 1, 1, 1, 1}, {-sx,-sy,-sz, 1, 1, 1, 1}, {-sx, sy,-sz, 1, 1, 1, 1},
		{ sx,-sy,-sz, 1, 1, 1, 1}, { sx, sy,-sz, 1, 1, 1, 1}, { sx,-sy, sz, 1, 1, 1, 1}, { sx, sy, sz, 1, 1, 1, 1},
		{-sx, sy,-sz, 1, 1, 1, 1}, {-sx, sy, sz, 1, 1, 1, 1}, { sx, sy,-sz, 1, 1, 1, 1}, { sx, sy, sz, 1, 1, 1, 1},
		{-sx,-sy,-sz, 1, 1, 1, 1}, { sx,-sy,-sz, 1, 1, 1, 1}, {-sx,-sy, sz, 1, 1, 1, 1}, { sx,-sy, sz, 1, 1, 1, 1},
	}

	return Mesh.from_primitive(vertices, {
		vertexformat = vertexformat, indices = Mesh.generate_indices(24)
	})
end

return BoxShape