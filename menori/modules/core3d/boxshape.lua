--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
]]

--[[--
Class for drawing box shape. (Inherited from menori.ModelNode class)
]]
-- @classmod BoxShape

local modules = (...):match('(.*%menori.modules.)')

local Mesh          = require (modules .. 'core3d.mesh')
local ModelNode     = require (modules .. 'core3d.model_node')

local vertexformat = {
      {"VertexPosition", "float", 3},
      {"VertexColor", "float", 4},
}

local boxshape = ModelNode:extend('boxshape')
function boxshape:init(bound, wireframe, r, g, b, a)
      boxshape.super.init(self)
      local center = bound:center()
      local s = bound:size()
      local sx = s.x / 2
      local sy = s.y / 2
      local sz = s.z / 2
      local vertices = {
            {-sx,-sy,-sz, 1, 1, 1, 1}, {-sx, sy,-sz, 1, 1, 1, 1}, { sx,-sy,-sz, 1, 1, 1, 1}, { sx, sy,-sz, 1, 1, 1, 1},
            { sx,-sy, sz, 1, 1, 1, 1}, { sx, sy, sz, 1, 1, 1, 1}, {-sx,-sy, sz, 1, 1, 1, 1}, {-sx, sy, sz, 1, 1, 1, 1},
            {-sx,-sy, sz, 1, 1, 1, 1}, {-sx, sy, sz, 1, 1, 1, 1}, {-sx,-sy,-sz, 1, 1, 1, 1}, {-sx, sy,-sz, 1, 1, 1, 1},
            { sx,-sy,-sz, 1, 1, 1, 1}, { sx, sy,-sz, 1, 1, 1, 1}, { sx,-sy, sz, 1, 1, 1, 1}, { sx, sy, sz, 1, 1, 1, 1},
            {-sx, sy,-sz, 1, 1, 1, 1}, {-sx, sy, sz, 1, 1, 1, 1}, { sx, sy,-sz, 1, 1, 1, 1}, { sx, sy, sz, 1, 1, 1, 1},
            {-sx,-sy,-sz, 1, 1, 1, 1}, { sx,-sy,-sz, 1, 1, 1, 1}, {-sx,-sy, sz, 1, 1, 1, 1}, { sx,-sy, sz, 1, 1, 1, 1},
      }

      self:set_position(center)

      self.mesh = Mesh.from_primitive(vertices, {
            vertexformat = vertexformat, indices = Mesh.generate_indices(24)
      })
      self.material.wireframe = wireframe or false
      self.material:set('baseColor', {r or 1, g or 1, b or 1, a or 1})
end

function boxshape:render(...)
      boxshape.super.render(self, ...)
end

return boxshape