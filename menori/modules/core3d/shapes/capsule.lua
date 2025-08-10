--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--[[--
Capsule shape.
]]

local modules = (...):match('(.*%menori.modules.)')
local Mesh = require(modules .. 'core3d.mesh')
local vertexformat = require(modules .. 'core3d.shapes.vertexformat')

local function add_ring(vertices, radius, ring_radius, y, ny, v_segments, idx, total_height)
      for s = 0, v_segments do
            local theta = 2 * math.pi * s / v_segments
            local x = ring_radius * math.cos(theta)
            local z = ring_radius * math.sin(theta)
            local nx = x / radius
            local nz = z / radius

            local u = (s / v_segments)
            local v = 1 - ((y + total_height / 2) / total_height)

            vertices[idx] = {x, y, z, nx, ny, nz, 1, 1, 1, 1, u, v}
            idx = idx + 1
      end
      return idx
end

--- The public constructor.
-- Creates a menori.Mesh with a capsule shape.
-- @function Capsule
-- @number radius Capsule radius (default: 0.5)
-- @number height Total capsule height (including hemispheres) (default: 1)
-- @number v_segments Number of vertical segments (default: 8)
-- @number h_segments Number of horizontal segments (default: 16)
-- @number cylinder_segments Number of cylinder segments (default: 1)
local function Capsule(radius, height, v_segments, h_segments, cylinder_segments)
      radius = radius or 0.5
      height = height or 1
      v_segments = math.max(3, v_segments or 8)
      h_segments = math.max(1, h_segments or 16)
      cylinder_segments = math.max(1, cylinder_segments or 1)

      local half_cyl_height = (height - 2 * radius) / 2
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
            idx = add_ring(vertices, radius, ring_r, y, ny, v_segments, idx, height)
      end

      for r = 0, cylinder_segments do
            local t = r / cylinder_segments
            local y = half_cyl_height - t * (2 * half_cyl_height)
            idx = add_ring(vertices, radius, radius, y, 0, v_segments, idx, height)
      end

      for r = 1, h_segments do
            local phi = (math.pi / 2) * r / h_segments
            local ring_r = radius * math.cos(phi)
            local y = -radius * math.sin(phi) - half_cyl_height
            local ny = -math.sin(phi)
            idx = add_ring(vertices, radius, ring_r, y, ny, v_segments, idx, height)
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
