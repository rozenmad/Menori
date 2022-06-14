--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
	this module based on CPML - Cirno's Perfect Math Library
	https://github.com/excessive/cpml/blob/master/modules/intersect.lua
--]]

--[[--
Intersect.
menori.ml.intersect
]]
-- @classmod intersect

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3    = require(modules .. "vec3")

local DBL_EPSILON = 2.2204460492503131e-16

local intersect = {}
intersect.__index = intersect

---
-- See [cpml](https://github.com/excessive/cpml/blob/cf707cb6af59c8be13918ea4ac9478eba9e8a7a0/modules/intersect.lua#L101).
-- @tparam table ray
-- ray.position  is a vec3;
-- ray.direction is a vec3.
-- @tparam table triangle
-- triangle[1]   is a vec3 or array;
-- triangle[2]   is a vec3 or array;
-- triangle[3]   is a vec3 or array.
-- @bool[opt] backface_cull
function intersect.ray_triangle(ray, triangle, backface_cull)
	local t1 = vec3(triangle[1])
	local t2 = vec3(triangle[2])
	local t3 = vec3(triangle[3])

	local e1 = t2:sub(t2, t1)
	local e2 = t3:sub(t3, t1)

	local h = vec3.cross(ray.direction, e2)
	local a = vec3.dot(h, e1)

	-- if a is negative, ray hits the backface
	if backface_cull and a < 0 then
		return false
	end

	-- if a is too close to 0, ray does not intersect triangle
	if math.abs(a) <= DBL_EPSILON then
		return false
	end

	local f = 1 / a
	local s = ray.position - t1
	local u = vec3.dot(s, h) * f

	-- ray does not intersect triangle
	if u < 0 or u > 1 then
		return false
	end

	local q = vec3.cross(s, e1)
	local v = vec3.dot(ray.direction, q) * f

	-- ray does not intersect triangle
	if v < 0 or u + v > 1 then
		return false
	end

	-- at this stage we can compute t to find out where
	-- the intersection point is on the line
	local t = vec3.dot(q, e2) * f

	-- return rayhit (point, distance, triangle normal)
	if t >= DBL_EPSILON then
		return {
                  point = h:set(ray.direction):scale(t):add(h, ray.position),
                  distance = t,
                  normal = vec3.cross(e1, e2):normalize(),
            }
	end

	-- ray does not intersect triangle
	return false
end

function intersect.aabb_aabb(a, b)
	return
		a.min.x <= b.max.x and
		a.max.x >= b.min.x and
		a.min.y <= b.max.y and
		a.max.y >= b.min.y and
		a.min.z <= b.max.z and
		a.max.z >= b.min.z
end

return intersect