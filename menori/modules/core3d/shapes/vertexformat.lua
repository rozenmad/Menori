--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

local vertexformat
if love._version_major > 11 then
	vertexformat = {
		{format = "floatvec3", name = "VertexPosition", location = 0},
		{format = "floatvec3", name = "VertexNormal", location = 1},
		{format = "floatvec4", name = "VertexColor", location = 2},
		{format = "floatvec2", name = "VertexTexCoord", location = 3},
	}
else
	vertexformat = {
		{"VertexPosition", "float", 3},
		{"VertexNormal", "float", 3},
		{"VertexColor", "float", 4},
		{"VertexTexCoord", "float", 2},
	}
end

return vertexformat