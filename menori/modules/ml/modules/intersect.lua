--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
	this module based on CPML - Cirno's Perfect Math Library
	https://github.com/excessive/cpml/blob/master/modules/intersect.lua
--]]

--- Intersect.
-- menori.ml.intersect
-- @module intersect

local modules = (...):gsub('%.[^%.]+$', '') .. "."
local vec3 = require (modules .. "vec3")

local DBL_EPSILON = 2.2204460492503131e-16
local FLT_EPSILON = 1e-6

local math_sqrt, math_min, math_max, math_abs = math.sqrt, math.min, math.max, math.abs

local function dot(ax, ay, az, bx, by, bz)
	return ax*bx + ay*by + az*bz
end

local function cross(ax, ay, az, bx, by, bz)
	return
		ay*bz - az*by,
		az*bx - ax*bz,
		ax*by - ay*bx
end

local function length2(ax, ay, az)
	return ax*ax + ay*ay + az*az
end

local function normalize(ax, ay, az)
	local l2 = ax*ax + ay*ay + az*az
	if l2 > 0 then
		local l = math_sqrt(l2)
		return ax/l, ay/l, az/l
	end
	return 0, 0, 0
end

local function vt_unpack(v)
	return v.x or v[1], v.y or v[2], v.z or v[3]
end

local function point_in_triangle_scalar(
		px, py, pz,
		nx, ny, nz,
		p1x, p1y, p1z,
		p2x, p2y, p2z,
		p3x, p3y, p3z
)
	local e1x, e1y, e1z = p2x - p1x, p2y - p1y, p2z - p1z
	local e2x, e2y, e2z = p3x - p2x, p3y - p2y, p3z - p2z
	local e3x, e3y, e3z = p1x - p3x, p1y - p3y, p1z - p3z

	local p1px, p1py, p1pz = px - p1x, py - p1y, pz - p1z
	local p2px, p2py, p2pz = px - p2x, py - p2y, pz - p2z
	local p3px, p3py, p3pz = px - p3x, py - p3y, pz - p3z

	local n1x, n1y, n1z = cross(e1x,e1y,e1z, nx,ny,nz)
	local n2x, n2y, n2z = cross(e2x,e2y,e2z, nx,ny,nz)
	local n3x, n3y, n3z = cross(e3x,e3y,e3z, nx,ny,nz)

	local r1 = dot(n1x,n1y,n1z, p1px,p1py,p1pz)
	local r2 = dot(n2x,n2y,n2z, p2px,p2py,p2pz)
	local r3 = dot(n3x,n3y,n3z, p3px,p3py,p3pz)

	return (r1 > 0 and r2 > 0 and r3 > 0) or (r1 <= 0 and r2 <= 0 and r3 <= 0)
end

local function closest_point_on_triangle_scalar(
		px, py, pz,
		ax, ay, az,
		bx, by, bz,
		cx, cy, cz
)
	local abx, aby, abz = bx - ax, by - ay, bz - az
	local acx, acy, acz = cx - ax, cy - ay, cz - az
	local apx, apy, apz = px - ax, py - ay, pz - az

	local d1 = dot(abx,aby,abz, apx,apy,apz)
	local d2 = dot(acx,acy,acz, apx,apy,apz)
	if d1 <= 0.0 and d2 <= 0.0 then return ax,ay,az end

	local bpx,bpy,bpz = px - bx, py - by, pz - bz
	local d3 = dot(abx,aby,abz, bpx,bpy,bpz)
	local d4 = dot(acx,acy,acz, bpx,bpy,bpz)
	if d3 >= 0.0 and d4 <= d3 then return bx,by,bz end

	local vc = d1*d4 - d3*d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0 then
		local v = d1 / (d1 - d3)
		return ax + abx*v, ay + aby*v, az + abz*v
	end

	local cpx, cpy, cpz = px - cx, py - cy, pz - cz
	local d5 = dot(abx,aby,abz, cpx,cpy,cpz)
	local d6 = dot(acx,acy,acz, cpx,cpy,cpz)
	if d6 >= 0.0 and d5 <= d6 then return cx, cy, cz end

	local vb = d5*d2 - d1*d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0 then
		local w = d2 / (d2 - d6)
		return ax + acx*w, ay + acy*w, az + acz*w
	end

	local va = d3*d6 - d5*d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0 then
		local w = (d4 - d3) / ((d4 - d3) + (d5 - d6))
		return bx + (cx - bx)*w, by + (cy - by)*w, bz + (cz - bz)*w
	end

	local denom = 1.0 / (va + vb + vc)
	local v = vb * denom
	local w = vc * denom
	return ax + abx*v + acx*w, ay + aby*v + acy*w, az + abz*v + acz*w
end

local function closest_point_segment_segment_scalar(
		p1x, p1y, p1z,
		q1x, q1y, q1z,
		p2x, p2y, p2z,
		q2x, q2y, q2z
)
	local d1x, d1y, d1z = q1x - p1x, q1y - p1y, q1z - p1z
	local d2x, d2y, d2z = q2x - p2x, q2y - p2y, q2z - p2z
	local rx,ry,rz = p1x - p2x, p1y - p2y, p1z - p2z
	local a = dot(d1x,d1y,d1z, d1x,d1y,d1z)
	local e = dot(d2x,d2y,d2z, d2x,d2y,d2z)
	local s, t

	if a <= FLT_EPSILON and e <= FLT_EPSILON then
		return p1x, p1y, p1z, p2x, p2y, p2z
	end

	if a <= FLT_EPSILON then
		s = 0.0
		t = math_min(math_max(dot(d2x,d2y,d2z, rx,ry,rz) / e, 0.0), 1.0)
	else
		local c = dot(d1x,d1y,d1z, rx,ry,rz)
		if e <= FLT_EPSILON then
			t = 0.0
			s = math_min(math_max(-c / a, 0.0), 1.0)
		else
			local b = dot(d1x,d1y,d1z, d2x,d2y,d2z)
			local denom = a*e - b*b
			if math_abs(denom) > FLT_EPSILON then
				s = (b*dot(d2x, d2y, d2z, rx, ry, rz) - c*e) / denom
				s = math_min(math_max(s, 0.0), 1.0)
			else
				s = 0.0
			end
			local tnom = b*s + dot(d2x,d2y,d2z, rx,ry,rz)
			if tnom < 0.0 then
				t = 0.0
				s = math_min(math_max(-c / a, 0.0), 1.0)
			elseif tnom > e then
				t = 1.0
				s = math_min(math_max((b - c) / a, 0.0), 1.0)
			else
				t = tnom / e
			end
		end
	end

	return
		p1x + d1x*s, p1y + d1y*s, p1z + d1z*s,
		p2x + d2x*t, p2y + d2y*t, p2z + d2z*t
end

local function segment_triangle_min_distance2(
		a0x, a0y, a0z,
		a1x, a1y, a1z,
		p0x, p0y, p0z,
		p1x, p1y, p1z,
		p2x, p2y, p2z
)
	local e0x, e0y, e0z = p1x - p0x, p1y - p0y, p1z - p0z
	local e1x, e1y, e1z = p2x - p0x, p2y - p0y, p2z - p0z
	local nx, ny, nz = cross(e0x,e0y,e0z, e1x,e1y,e1z)

	local bestAx, bestAy, bestAz = 0, 0, 0
	local bestBx, bestBy, bestBz = 0, 0, 0
	local bestD2 = math.huge

	-- 0) вырожденный треугольник
	-- local nnorm2 = length2(nx,ny,nz)
	-- if nnorm2 <= FLT_EPSILON * FLT_EPSILON then
	--       local c1x,c1y,c1z, c2x,c2y,c2z, d2

	--       -- p0-p1
	--       c1x,c1y,c1z, c2x,c2y,c2z = closest_point_segment_segment_scalar(a0x,a0y,a0z, a1x,a1y,a1z, p0x,p0y,p0z, p1x,p1y,p1z)
	--       d2 = length2(c1x - c2x, c1y - c2y, c1z - c2z)
	--       if d2 < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2, c1x,c1y,c1z, c2x,c2y,c2z end

	--       -- p1-p2
	--       c1x,c1y,c1z, c2x,c2y,c2z = closest_point_segment_segment_scalar(a0x,a0y,a0z, a1x,a1y,a1z, p1x,p1y,p1z, p2x,p2y,p2z)
	--       d2 = length2(c1x - c2x, c1y - c2y, c1z - c2z)
	--       if d2 < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2, c1x,c1y,c1z, c2x,c2y,c2z end

	--       -- p2-p0
	--       c1x,c1y,c1z, c2x,c2y,c2z = closest_point_segment_segment_scalar(a0x,a0y,a0z, a1x,a1y,a1z, p2x,p2y,p2z, p0x,p0y,p0z)
	--       d2 = length2(c1x - c2x, c1y - c2y, c1z - c2z)
	--       if d2 < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2, c1x,c1y,c1z, c2x,c2y,c2z end

	--       local d2a = length2(a0x - p0x, a0y - p0y, a0z - p0z)
	--       if d2a < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2a, a0x,a0y,a0z, p0x,p0y,p0z end
	--       d2a = length2(a0x - p1x, a0y - p1y, a0z - p1z)
	--       if d2a < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2a, a0x,a0y,a0z, p1x,p1y,p1z end
	--       d2a = length2(a0x - p2x, a0y - p2y, a0z - p2z)
	--       if d2a < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2a, a0x,a0y,a0z, p2x,p2y,p2z end

	--       local d2b = length2(a1x - p0x, a1y - p0y, a1z - p0z)
	--       if d2b < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2b, a1x,a1y,a1z, p0x,p0y,p0z end
	--       d2b = length2(a1x - p1x, a1y - p1y, a1z - p1z)
	--       if d2b < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2b, a1x,a1y,a1z, p1x,p1y,p1z end
	--       d2b = length2(a1x - p2x, a1y - p2y, a1z - p2z)
	--       if d2b < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2b, a1x,a1y,a1z, p2x,p2y,p2z end

	--       return bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz, nx,ny,nz
	-- end

	local da = dot(a0x - p0x, a0y - p0y, a0z - p0z, nx, ny, nz)
	local db = dot(a1x - p0x, a1y - p0y, a1z - p0z, nx, ny, nz)
	if da * db <= 0.0 then
		local denom = da - db
		if math_abs(denom) > FLT_EPSILON then
			local t = da / (da - db)
			if t >= 0.0 and t <= 1.0 then
				local lx, ly, lz = a1x - a0x, a1y - a0y, a1z - a0z
				local xx, yy, zz = a0x + lx*t, a0y + ly*t, a0z + lz*t
				if point_in_triangle_scalar(xx,yy,zz, nx,ny,nz, p0x,p0y,p0z, p1x,p1y,p1z, p2x,p2y,p2z) then
					return 0.0, xx, yy, zz, xx, yy, zz, nx, ny, nz
				end
			end
		end
	end

	local qx, qy, qz = closest_point_on_triangle_scalar(a0x,a0y,a0z, p0x,p0y,p0z, p1x,p1y,p1z, p2x,p2y,p2z)
	local dx, dy, dz = a0x - qx, a0y - qy, a0z - qz
	local d20 = dx*dx + dy*dy + dz*dz
	if d20 < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d20, a0x,a0y,a0z, qx,qy,qz end

	local rx, ry, rz = closest_point_on_triangle_scalar(a1x,a1y,a1z, p0x,p0y,p0z, p1x,p1y,p1z, p2x,p2y,p2z)
	local dx2, dy2, dz2 = a1x - rx, a1y - ry, a1z - rz
	local d21 = dx2*dx2 + dy2*dy2 + dz2*dz2
	if d21 < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d21, a1x,a1y,a1z, rx,ry,rz end

	if bestD2 > FLT_EPSILON then
		local c1x,c1y,c1z, c2x,c2y,c2z, d2
		-- p0-p1
		c1x,c1y,c1z, c2x,c2y,c2z = closest_point_segment_segment_scalar(a0x,a0y,a0z, a1x,a1y,a1z, p0x,p0y,p0z, p1x,p1y,p1z)
		d2 = length2(c1x - c2x, c1y - c2y, c1z - c2z)
		if d2 < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2, c1x,c1y,c1z, c2x,c2y,c2z end

		-- p1-p2
		c1x,c1y,c1z, c2x,c2y,c2z = closest_point_segment_segment_scalar(a0x,a0y,a0z, a1x,a1y,a1z, p1x,p1y,p1z, p2x,p2y,p2z)
		d2 = length2(c1x - c2x, c1y - c2y, c1z - c2z)
		if d2 < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2, c1x,c1y,c1z, c2x,c2y,c2z end

		-- p2-p0
		c1x,c1y,c1z, c2x,c2y,c2z = closest_point_segment_segment_scalar(a0x,a0y,a0z, a1x,a1y,a1z, p2x,p2y,p2z, p0x,p0y,p0z)
		d2 = length2(c1x - c2x, c1y - c2y, c1z - c2z)
		if d2 < bestD2 then bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz = d2, c1x,c1y,c1z, c2x,c2y,c2z end
	end

	return bestD2, bestAx,bestAy,bestAz, bestBx,bestBy,bestBz, nx,ny,nz
end


local intersect = {}
intersect.__index = intersect

----
-- Tests intersection between a ray and a triangle.
-- @tparam table ray Ray definition {origin=vec3|table, direction=vec3|table}
-- @tparam table triangle Triangle vertices {vec3|table, vec3|table, vec3|table}
-- @tparam[opt=nil] boolean backface_cull If true, ignores back-facing triangles
-- @treturn table|false Intersection data {point=vec3, normal=vec3, t=number} or false if no hit
function intersect.ray_triangle(ray, triangle, backface_cull)
	local ox, oy, oz = vt_unpack(ray.origin)
	local dx, dy, dz = vt_unpack(ray.direction)

	local p0x, p0y, p0z = vt_unpack(triangle[1])
	local p1x, p1y, p1z = vt_unpack(triangle[2])
	local p2x, p2y, p2z = vt_unpack(triangle[3])

	local e1x, e1y, e1z = p1x - p0x, p1y - p0y, p1z - p0z
	local e2x, e2y, e2z = p2x - p0x, p2y - p0y, p2z - p0z

	local hx, hy, hz = cross(dx,dy,dz, e2x,e2y,e2z)

	local a = dot(hx,hy,hz, e1x,e1y,e1z)

	if backface_cull and a < 0 then
		return false
	end

	if math_abs(a) <= DBL_EPSILON then
		return false
	end

	local f = 1.0 / a

	local sx, sy, sz = ox - p0x, oy - p0y, oz - p0z
	local u = dot(sx,sy,sz, hx,hy,hz) * f
	if u < 0 or u > 1 then
		return false
	end

	local qx, qy, qz = cross(sx,sy,sz, e1x,e1y,e1z)

	local v = dot(dx,dy,dz, qx,qy,qz) * f
	if v < 0 or u + v > 1 then
		return false
	end

	local t = dot(e2x,e2y,e2z, qx,qy,qz) * f
	if t >= DBL_EPSILON then
		local px = ox + dx * t
		local py = oy + dy * t
		local pz = oz + dz * t

		local nx, ny, nz = normalize(cross(e1x,e1y,e1z, e2x,e2y,e2z))

		return {
			point  = {px, py, pz},
			normal = {nx, ny, nz},
			t      = t,
		}
	end

	return false
end

----
-- Tests intersection between a ray and a plane.
-- @tparam table ray Ray definition {origin=vec3|table, direction=vec3|table}
-- @tparam vec3|table position A point on the plane
-- @tparam vec3|table normal Plane normal
-- @treturn table|false Intersection data {point=vec3, normal=vec3, t=number} or false if no hit
function intersect.ray_plane(ray, position, normal)
	local ox, oy, oz = vt_unpack(ray.origin)
	local dx, dy, dz = vt_unpack(ray.direction)
	local px, py, pz = vt_unpack(position)
	local nx, ny, nz = vt_unpack(normal)

	local denom = dot(nx,ny,nz, dx,dy,dz)

	if math_abs(denom) < FLT_EPSILON then
		return false
	end

	local dpx, dpy, dpz = px - ox, py - oy, pz - oz
	local t = dot(dpx,dpy,dpz, nx,ny,nz) / denom

	if t < FLT_EPSILON then
		return false
	end

	local ix, iy, iz = ox + dx*t, oy + dy*t, oz + dz*t

	return {
		point  = {ix, iy, iz},
		normal = {nx, ny, nz},
		t      = t,
	}
end

----
-- Tests intersection between a ray and a sphere.
-- @tparam table ray Ray definition {origin=vec3|table, direction=vec3|table}
-- @tparam vec3|table center Sphere center
-- @tparam number radius Sphere radius
-- @treturn table|false Intersection data {point=vec3, normal=vec3, t=number} or false if no hit
function intersect.ray_sphere(ray, center, radius)
	local ox, oy, oz = vt_unpack(ray.origin)
	local dx, dy, dz = vt_unpack(ray.direction)
	local cx, cy, cz = vt_unpack(center)

	local lx, ly, lz = ox - cx, oy - cy, oz - cz

	local b = dot(lx,ly,lz, dx,dy,dz)
	local c = length2(lx, ly, lz) - radius*radius

	if c > 0 and b > 0 then
		return false
	end

	local discr = b*b - c
	if discr < 0 then
		return false
	end

	local t = -b - math_sqrt(discr)
	if t < 0 then t = 0 end

	local px, py, pz = ox + dx*t, oy + dy*t, oz + dz*t
	local nx, ny, nz = normalize(px - cx, py - cy, pz - cz)

	return {
		point  = {px, py, pz},
		normal = {nx, ny, nz},
		t      = t,
	}
end

----
-- Tests intersection between a ray and a capsule.
-- @tparam table ray Ray definition {origin=vec3|table, direction=vec3|table}
-- @tparam vec3|table p0 Capsule start point
-- @tparam vec3|table p1 Capsule end point
-- @tparam number radius Capsule radius
-- @treturn table|false Intersection data {point=vec3, normal=vec3, t=number} or false if no hit
function intersect.ray_capsule(ray, p0, p1, radius)
	local rpx, rpy, rpz = vt_unpack(ray.origin)
	local rdx, rdy, rdz = vt_unpack(ray.direction)
	local ax, ay, az = vt_unpack(p0)
	local bx, by, bz = vt_unpack(p1)

	local ray_length = 1e6
	local qx, qy, qz = rpx + rdx * ray_length, rpy + rdy * ray_length, rpz + rdz * ray_length

	local c1x, c1y, c1z, c2x, c2y, c2z = closest_point_segment_segment_scalar(
		rpx, rpy, rpz,
		qx, qy, qz,
		ax, ay, az,
		bx, by, bz
	)

	local dx, dy, dz = c1x - c2x, c1y - c2y, c1z - c2z
	local d2 = dx*dx + dy*dy + dz*dz

	if d2 > radius * radius then
		return false
	end

	local dist = math_sqrt(d2)
	local nx, ny, nz

	if dist > FLT_EPSILON then
		nx, ny, nz = normalize(dx, dy, dz)
	else
		nx, ny, nz = normalize(rdx, rdy, rdz)
	end

	local vx, vy, vz = c1x - rpx, c1y - rpy, c1z - rpz
	local t = vx*rdx + vy*rdy + vz*rdz

	return {
		point  = {c1x, c1y, c1z},
		normal = {nx, ny, nz},
		t      = t,
	}
end

----
-- Tests intersection between a ray and an axis-aligned bounding box (AABB).
-- @tparam table ray Ray definition {origin=vec3|table, direction=vec3|table}
-- @tparam table aabb AABB definition {min=vec3|table, max=vec3|table}
-- @treturn table|false Intersection data {point=vec3, normal=vec3, t=number} or false if no hit
function intersect.ray_aabb(ray, aabb)
	local ox, oy, oz = vt_unpack(ray.origin)
	local dx, dy, dz = vt_unpack(ray.direction)
	local minx, miny, minz = vt_unpack(aabb.min)
	local maxx, maxy, maxz = vt_unpack(aabb.max)

	dx, dy, dz = normalize(dx, dy, dz)

	local dirfracx = math_abs(dx) > FLT_EPSILON and 1/dx or 1e32
	local dirfracy = math_abs(dy) > FLT_EPSILON and 1/dy or 1e32
	local dirfracz = math_abs(dz) > FLT_EPSILON and 1/dz or 1e32

	local t1 = (minx - ox) * dirfracx
	local t2 = (maxx - ox) * dirfracx
	local t3 = (miny - oy) * dirfracy
	local t4 = (maxy - oy) * dirfracy
	local t5 = (minz - oz) * dirfracz
	local t6 = (maxz - oz) * dirfracz

	local tmin = math_max(math_max(math_min(t1, t2), math_min(t3, t4)), math_min(t5, t6))
	local tmax = math_min(math_min(math_max(t1, t2), math_max(t3, t4)), math_max(t5, t6))

	if tmax < 0 then
		return false
	end

	if tmin > tmax then
		return false
	end

	local t = tmin
	local ix, iy, iz = ox + dx*t, oy + dy*t, oz + dz*t

	local nx, ny, nz =
		(t == t1 and -1 or t == t2 and 1 or 0),
		(t == t3 and -1 or t == t4 and 1 or 0),
		(t == t5 and -1 or t == t6 and 1 or 0)

	return {
		point  = {ix, iy, iz},
		normal = {nx, ny, nz},
		t      = t
	}
end

----
-- Tests intersection between two spheres.
-- @tparam vec3|table a_center Center of first sphere
-- @tparam number a_radius Radius of first sphere
-- @tparam vec3|table b_center Center of second sphere
-- @tparam number b_radius Radius of second sphere
-- @treturn table|false Collision data {normal=vec3, depth=number, point=vec3} or false if no collision
function intersect.sphere_sphere(a_center, a_radius, b_center, b_radius)
	local x1, y1, z1 = vt_unpack(a_center)
	local x2, y2, z2 = vt_unpack(b_center)

	local dx = x2 - x1
	local dy = y2 - y1
	local dz = z2 - z1

	local dist2 = dx*dx + dy*dy + dz*dz
	local r = a_radius + b_radius

	if dist2 > r * r then
		return false
	end

	local dist = math_sqrt(dist2)

	if dist < FLT_EPSILON then
		return {
			normal = {0, 1, 0},
			depth  = a_radius,
			point  = {x1, y1, z1},
		}
	end

	local nx, ny, nz = dx / dist, dy / dist, dz / dist
	local depth = r - dist

	local px = x1 + nx * (a_radius - depth * 0.5)
	local py = y1 + ny * (a_radius - depth * 0.5)
	local pz = z1 + nz * (a_radius - depth * 0.5)

	return {
		normal = {nx, ny, nz},
		depth  = depth,
		point  = {px, py, pz},
	}
end

----
-- Tests intersection between a sphere and an axis-aligned bounding box (AABB).
-- @tparam vec3|table center Sphere center
-- @tparam number radius Sphere radius
-- @tparam table aabb AABB definition {min=vec3|table, max=vec3|table}
-- @treturn table|false Collision data {normal=vec3, depth=number, point=vec3} or false if no collision
function intersect.sphere_aabb(center, radius, aabb)
	local cx, cy, cz = vt_unpack(center)
	local minx, miny, minz = vt_unpack(aabb.min)
	local maxx, maxy, maxz = vt_unpack(aabb.max)

	local px = math_max(minx, math_min(cx, maxx))
	local py = math_max(miny, math_min(cy, maxy))
	local pz = math_max(minz, math_min(cz, maxz))

	local dx = cx - px
	local dy = cy - py
	local dz = cz - pz

	local dist2 = dx*dx + dy*dy + dz*dz
	if dist2 > radius*radius then
		return false
	end

	local dist = math_sqrt(dist2)

	if dist2 < FLT_EPSILON then
		return {
			normal = {0, 1, 0},
			depth  = radius,
			point  = {cx, cy, cz}
		}
	end

	local nx, ny, nz = dx / dist, dy / dist, dz / dist
	local depth = radius - dist

	return {
		normal = {nx, ny, nz},
		depth  = depth,
		point  = {px, py, pz},
	}
end

----
-- Tests intersection between a sphere and a triangle.
-- @tparam vec3|table center Sphere center
-- @tparam number radius Sphere radius
-- @tparam table triangle Triangle vertices {vec3|table, vec3|table, vec3|table}
-- @treturn table|false Collision data {normal=vec3, depth=number, point=vec3} or false if no collision
function intersect.sphere_triangle(center, radius, triangle)
	local a0x, a0y, a0z = vt_unpack(center)
	local p0x, p0y, p0z = vt_unpack(triangle[1])
	local p1x, p1y, p1z = vt_unpack(triangle[2])
	local p2x, p2y, p2z = vt_unpack(triangle[3])

	local qx, qy, qz = closest_point_on_triangle_scalar(
		a0x, a0y, a0z,
		p0x, p0y, p0z,
		p1x, p1y, p1z,
		p2x, p2y, p2z
	)

	local dx, dy, dz = a0x - qx, a0y - qy, a0z - qz
	local dist2 = dx*dx + dy*dy + dz*dz

	if dist2 > radius * radius then
		return false
	end

	local hit_normal_x, hit_normal_y, hit_normal_z = normalize(dx, dy, dz)
	local dist = math_sqrt(dist2)
	local depth = radius - dist

	if dist <= FLT_EPSILON then
		local e0x, e0y, e0z = p1x - p0x, p1y - p0y, p1z - p0z
		local e1x, e1y, e1z = p2x - p0x, p2y - p0y, p2z - p0z
		hit_normal_x, hit_normal_y, hit_normal_z = cross(e0x,e0y,e0z, e1x,e1y,e1z)
		local len2 = length2(hit_normal_x, hit_normal_y, hit_normal_z)
		if len2 > FLT_EPSILON * FLT_EPSILON then
			local inv = 1.0 / math_sqrt(len2)
			hit_normal_x, hit_normal_y, hit_normal_z = hit_normal_x * inv, hit_normal_y * inv, hit_normal_z * inv
		else
			hit_normal_x, hit_normal_y, hit_normal_z = 0, 1, 0
		end
	end

	return {
		point  = {qx, qy, qz},
		depth  = depth,
		normal = {hit_normal_x, hit_normal_y, hit_normal_z},
	}
end

----
-- Tests intersection between a capsule and a sphere.
-- @tparam vec3|table p0 Capsule start point
-- @tparam vec3|table p1 Capsule end point
-- @tparam number capsule_radius Capsule radius
-- @tparam vec3|table center Sphere center
-- @tparam number sphere_radius Sphere radius
-- @treturn table|false Collision data {normal=vec3, depth=number, point=vec3} or false if no collision
function intersect.capsule_sphere(p0, p1, capsule_radius, center, sphere_radius)
	local x1, y1, z1 = vt_unpack(p0)
	local x2, y2, z2 = vt_unpack(p1)
	local sx, sy, sz = vt_unpack(center)

	local dx, dy, dz = x2 - x1, y2 - y1, z2 - z1
	local seg_len2   = dx*dx + dy*dy + dz*dz

	local t = 0
	if seg_len2 > FLT_EPSILON then
		t = dot(sx - x1, sy - y1, sz - z1, dx, dy, dz) / seg_len2
		t = math_max(0, math_min(1, t))
	end

	local cx = x1 + dx * t
	local cy = y1 + dy * t
	local cz = z1 + dz * t

	local vx, vy, vz = sx - cx, sy - cy, sz - cz
	local dist2 = vx*vx + vy*vy + vz*vz

	local r = capsule_radius + sphere_radius
	if dist2 > r*r then
		return false
	end

	local dist = math_sqrt(dist2)
	if dist < FLT_EPSILON then
		return {
			normal = {0, 1, 0},
			depth  = r,
			point  = {cx, cy, cz},
		}
	end

	local nx, ny, nz = vx / dist, vy / dist, vz / dist
	local depth = r - dist

	local px = sx - nx * (sphere_radius - depth * 0.5)
	local py = sy - ny * (sphere_radius - depth * 0.5)
	local pz = sz - nz * (sphere_radius - depth * 0.5)

	return {
		normal = {nx, ny, nz},
		depth  = depth,
		point  = {px, py, pz},
	}
end

----
-- Tests intersection between two capsules.
-- @tparam vec3|table a0 First capsule start
-- @tparam vec3|table a1 First capsule end
-- @tparam number a_radius First capsule radius
-- @tparam vec3|table b0 Second capsule start
-- @tparam vec3|table b1 Second capsule end
-- @tparam number b_radius Second capsule radius
-- @treturn table|false Collision data {normal=vec3, depth=number, point=vec3} or false if no collision
function intersect.capsule_capsule(a0, a1, a_radius, b0, b1, b_radius)
	local ax0, ay0, az0 = vt_unpack(a0)
	local ax1, ay1, az1 = vt_unpack(a1)
	local bx0, by0, bz0 = vt_unpack(b0)
	local bx1, by1, bz1 = vt_unpack(b1)

	local pax, pay, paz, pbx, pby, pbz = closest_point_segment_segment_scalar(
		ax0, ay0, az0,
		ax1, ay1, az1,
		bx0, by0, bz0,
		bx1, by1, bz1
	)

	local vx, vy, vz = pbx - pax, pby - pay, pbz - paz
	local dist2 = vx*vx + vy*vy + vz*vz

	local r = a_radius + b_radius
	if dist2 > r*r then
		return false
	end

	local dist = math_sqrt(dist2)
	if dist < FLT_EPSILON then
		return {
			normal = {0, 1, 0},
			depth  = r,
			point  = {(pax + pbx) * 0.5, (pay + pby) * 0.5, (paz + pbz) * 0.5},
		}
	end

	local nx, ny, nz = vx / dist, vy / dist, vz / dist
	local depth = r - dist

	local pax_contact = pax + nx * a_radius
	local pay_contact = pay + ny * a_radius
	local paz_contact = paz + nz * a_radius

	local pbx_contact = pbx - nx * b_radius
	local pby_contact = pby - ny * b_radius
	local pbz_contact = pbz - nz * b_radius

	local cx = 0.5 * (pax_contact + pbx_contact)
	local cy = 0.5 * (pay_contact + pby_contact)
	local cz = 0.5 * (paz_contact + pbz_contact)

	return {
		normal = {nx, ny, nz},
		depth  = depth,
		point  = {cx, cy, cz},
	}
end

----
-- Tests intersection between a sphere and an axis-aligned bounding box (AABB).
-- @tparam vec3|table p0 Capsule start
-- @tparam vec3|table p1 Capsule end
-- @tparam number radius Capsule radius
-- @tparam table aabb AABB definition {min=vec3|table, max=vec3|table}
-- @treturn table|false Collision data {normal=vec3, depth=number, point=vec3} or false if no collision
function intersect.capsule_aabb(p0, p1, radius, aabb)
	local p0x, p0y, p0z = vt_unpack(p0)
	local p1x, p1y, p1z = vt_unpack(p1)

	local minx, miny, minz = vt_unpack(aabb.min)
	local maxx, maxy, maxz = vt_unpack(aabb.max)

	local cx = (minx + maxx) * 0.5
	local cy = (miny + maxy) * 0.5
	local cz = (minz + maxz) * 0.5

	local dx, dy, dz = p1x - p0x, p1y - p0y, p1z - p0z
	local seg_len2 = dx*dx + dy*dy + dz*dz

	local t = 0
	if seg_len2 > FLT_EPSILON then
		t = dot(cx - p0x, cy - p0y, cz - p0z, dx, dy, dz) / seg_len2
		t = math_max(0, math_min(1, t))
	end

	local sx = p0x + dx * t
	local sy = p0y + dy * t
	local sz = p0z + dz * t

	local px = math_max(minx, math_min(sx, maxx))
	local py = math_max(miny, math_min(sy, maxy))
	local pz = math_max(minz, math_min(sz, maxz))

	local vx, vy, vz = px - sx, py - sy, pz - sz
	local dist2 = vx*vx + vy*vy + vz*vz

	if dist2 > radius * radius then
		return false
	end

	local dist = math_sqrt(dist2)
	local depth = radius - dist

	local nx, ny, nz
	if dist > FLT_EPSILON then
		nx, ny, nz = vx / dist, vy / dist, vz / dist
	else
		nx, ny, nz = 0, 1, 0
	end

	return {
		normal = {nx, ny, nz},
		depth  = depth,
		point  = {px, py, pz},
	}
end

----
-- Tests intersection between a capsule and a triangle.
-- @tparam vec3|table p0 Capsule start
-- @tparam vec3|table p1 Capsule end
-- @tparam number radius Capsule radius
-- @tparam table triangle Triangle vertices {vec3|table, vec3|table, vec3|table}
-- @treturn table|false Collision data {normal=vec3, depth=number, point=vec3} or false if no collision
function intersect.capsule_triangle(p0, p1, radius, triangle)
	local a0x, a0y, a0z = vt_unpack(p0)
	local a1x, a1y, a1z = vt_unpack(p1)
	local p0x, p0y, p0z = vt_unpack(triangle[1])
	local p1x, p1y, p1z = vt_unpack(triangle[2])
	local p2x, p2y, p2z = vt_unpack(triangle[3])

	local d2, ax,ay,az, bx,by,bz, nx,ny,nz = segment_triangle_min_distance2(
		a0x,a0y,a0z,
		a1x,a1y,a1z,
		p0x,p0y,p0z,
		p1x,p1y,p1z,
		p2x,p2y,p2z
	)

	if d2 > radius * radius then
		return false
	end

	local dx, dy, dz = ax - bx, ay - by, az - bz
	local dist = math_sqrt(math_max(d2, 0.0))
	local hit_normal_x, hit_normal_y, hit_normal_z

	if dist > FLT_EPSILON then
		hit_normal_x, hit_normal_y, hit_normal_z = normalize(dx, dy, dz)
	else
		local nlen2 = length2(nx, ny, nz)
		if nlen2 > FLT_EPSILON * FLT_EPSILON then
			local s = dot(a0x - p0x, a0y - p0y, a0z - p0z, nx, ny, nz)
			if s < 0.0 then nx,ny,nz = -nx,-ny,-nz end
			local inv = 1.0 / math_sqrt(nlen2)
			hit_normal_x, hit_normal_y, hit_normal_z = nx*inv, ny*inv, nz*inv
		else
			local dirx, diry, dirz = a1x - a0x, a1y - a0y, a1z - a0z
			local dlen2 = length2(dirx, diry, dirz)
			if dlen2 > FLT_EPSILON * FLT_EPSILON then
				hit_normal_x, hit_normal_y, hit_normal_z = normalize(dirx, diry, dirz)
			else
				hit_normal_x, hit_normal_y, hit_normal_z = 0, 1, 0
			end
		end
	end

	return {
		point  = {bx, by, bz},
		depth  = radius - dist,
		normal = {hit_normal_x, hit_normal_y, hit_normal_z},
	}
end

----
-- Tests intersection between two AABBs.
-- @tparam table a AABB {min=vec3, max=vec3}
-- @tparam table b AABB {min=vec3, max=vec3}
-- @treturn boolean True if intersecting, false otherwise
function intersect.aabb_aabb(a, b)
	return
		a.min.x <= b.max.x and
		a.max.x >= b.min.x and
		a.min.y <= b.max.y and
		a.max.y >= b.min.y and
		a.min.z <= b.max.z and
		a.max.z >= b.min.z
end

----
-- Checks if a point lies inside a triangle.
-- @tparam vec3|table point The point
-- @tparam vec3|table normal Triangle normal
-- @tparam table triangle Triangle vertices {vec3|table, vec3|table, vec3|table}
-- @treturn boolean True if point is inside triangle, false otherwise
function intersect.point_in_triangle(point, normal, triangle)
	local p1x, p1y, p1z = vt_unpack(point)
	local n1x, n1y, n1z = vt_unpack(normal)
	local v1x, v1y, v1z = vt_unpack(triangle[1])
	local v2x, v2y, v2z = vt_unpack(triangle[2])
	local v3x, v3y, v3z = vt_unpack(triangle[3])

	return point_in_triangle_scalar(
		p1x, p1y, p1z,
		n1x, n1y, n1z,
		v1x, v1y, v1z,
		v2x, v2y, v2z,
		v3x, v3y, v3z
	)
end

----
-- Finds the closest point on a triangle to a given point.
-- @tparam vec3|table point The point
-- @tparam table triangle Triangle vertices {vec3|table, vec3|table, vec3|table}
-- @treturn vec3 Closest point
function intersect.closest_point_on_triangle(point, triangle)
	local p1x, p1y, p1z = vt_unpack(point)
	local v1x, v1y, v1z = vt_unpack(triangle[1])
	local v2x, v2y, v2z = vt_unpack(triangle[2])
	local v3x, v3y, v3z = vt_unpack(triangle[3])

	local x, y, z = closest_point_on_triangle_scalar(
		p1x, p1y, p1z,
		v1x, v1y, v1z,
		v2x, v2y, v2z,
		v3x, v3y, v3z
	)
	return
		vec3(x, y, z)
end

----
-- Finds the closest points between two line segments.
-- @tparam vec3|table a1 First segment start
-- @tparam vec3|table a2 First segment end
-- @tparam vec3|table b1 Second segment start
-- @tparam vec3|table b2 Second segment end
-- @treturn vec3, vec3 Closest points
function intersect.closest_point_segment_segment(a1, a2, b1, b2)
	local a1x, a1y, a1z = vt_unpack(a1)
	local a2x, a2y, a2z = vt_unpack(a2)
	local b1x, b1y, b1z = vt_unpack(b1)
	local b2x, b2y, b2z = vt_unpack(b2)

	local x1, y1, z1, x2, y2, z2 = closest_point_segment_segment_scalar(
		a1x, a1y, a1z,
		a2x, a2y, a2z,
		b1x, b1y, b1z,
		b2x, b2y, b2z
	)

	return
		vec3(x1, y1, z1),
		vec3(x2, y2, z2)
end

return intersect