--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

--[[--
Perspective camera class.
]]
-- @classmod PerspectiveCamera

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')
local ml = require (modules .. 'ml')
local app = require (modules .. 'app')

local mat4 = ml.mat4
local vec2 = ml.vec2
local vec3 = ml.vec3
local vec4 = ml.vec4

local PerspectiveCamera = class('PerspectiveCamera')

----
-- The public constructor.
-- @tparam number fov Field of view of the Camera, in degrees.
-- @tparam number aspect The aspect ratio.
-- @tparam number nclip The distance of the near clipping plane from the the Camera.
-- @tparam number fclip The distance of the far clipping plane from the Camera.
function PerspectiveCamera:init(fov, aspect, nclip, fclip)
	fov = fov or 60
	aspect = aspect or 1.6666667
	nclip = nclip or 0.1
	fclip = fclip or 2048.0

	self.m_projection = mat4():perspective_RH_NO(fov, aspect, nclip, fclip)
	self.m_inv_projection = self.m_projection:clone():inverse()
	self.m_view = mat4()

	self.eye 	= vec3( 0, 0, 0 )
	self.center = vec3( 0, 0, 1 )
	self.up 	= vec3( 0, 1, 0 )
end

----
-- Updating the view matrix.
function PerspectiveCamera:update_view_matrix()
	self.m_view:identity()
	self.m_view:look_at_RH(self.eye, self.center, self.up)
end

----
-- Get a ray going from camera through screen point.
-- @tparam number x screen position x
-- @tparam number y screen position y
-- @tparam table viewport (optional) viewport rectangle (x, y, w, h)
-- @treturn table that containing {position = vec3, direction = vec3}
function PerspectiveCamera:screen_point_to_ray(x, y, viewport)
	viewport = viewport or {app:get_viewport()}

	local m_pos = vec3(mat4.unproject(vec3(x, y, 1), self.m_view, self.m_projection, viewport))
	local c_pos = self.eye:clone()
	local direction = vec3():sub(m_pos, self.eye):normalize()
	return {
		position = c_pos, direction = direction
	}
end

----
-- Transform position from world space into screen space.
-- @tparam number x
-- screen position x or vec3
-- @tparam number y screen position y
-- @tparam number z screen position z
-- @treturn vec2 object
function PerspectiveCamera:world_to_screen_point(x, y, z)
	if type(x) == 'table' then
		x, y, z = x.x, x.y, x.z
	end

	local m_proj = self.m_projection
	local m_view = self.m_view

	local view_p = m_view:multiply_vec4(vec4(x, y, z, 1))
	local proj_p = m_proj:multiply_vec4(view_p)

	if proj_p.w < 0 then
		return vec2(0, 0)
	end

	local ndc_space_pos = vec2(
		proj_p.x / proj_p.w,
		proj_p.y / proj_p.w
	)

	local screen_space_pos = vec2(
		(ndc_space_pos.x + 1) / 2 * app.w * app.sx,
		(ndc_space_pos.y + 1) / 2 * app.h * app.sy
	)

	return screen_space_pos
end

----
-- Get direction.
-- @treturn vec3 object
function PerspectiveCamera:get_direction()
	return (self.center - self.eye):normalize()
end

return PerspectiveCamera

---
-- Projection matrix.
-- @tfield mat4 m_projection

---
-- Inverse projection matrix.
-- @tfield mat4 m_inv_projection

---
-- View matrix.
-- @tfield[readonly] mat4 m_view

---
-- Position where the camera is looking at.
-- @tfield vec3 center

---
-- Position of the camera.
-- @tfield vec3 eye

---
-- Normalized up vector, how the camera is oriented.
-- @tfield vec3 up