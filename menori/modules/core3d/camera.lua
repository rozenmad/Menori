--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Perspective camera class.
]]
-- @module menori.PerspectiveCamera

local modules = (...):match('(.*%menori.modules.)')
local class       = require (modules .. 'libs.class')
local ml          = require (modules .. 'ml')
local application = require (modules .. 'application')

local mat4 = ml.mat4
local vec3 = ml.vec3
local quat = ml.quat

local PerspectiveCamera = class('PerspectiveCamera')

--- Constructor
function PerspectiveCamera:constructor(fov, aspect, nclip, fclip)
	fov = fov or 60
	aspect = aspect or 1.6666667
	nclip = nclip or 0.1
	fclip = fclip or 512.0

	self.m_projection = mat4():perspective_LH_NO(fov, aspect, nclip, fclip)
	self.m_inv_projection = self.m_projection:clone():inverse()
	self.m_view = mat4()

	self.center = vec3( 0, 0, 0 )
	self.eye 	= vec3( 0, 0, 1 )
	self.up 	= vec3( 0,-1, 0 )

	self.swap_look_at = false
end

-- Updating the view matrix.
function PerspectiveCamera:update_view_matrix()
	self.m_view:identity()
	if self.swap_look_at then
		self.m_view:look_at(self.center, self.eye, self.up)
	else
		self.m_view:look_at(self.eye, self.center, self.up)
	end
	return self.m_view
end

function PerspectiveCamera:get_corner_normals(viewport)
	viewport = viewport or {0.0, 0.0, application.w, application.h}

	local temp_view = self.m_view:clone()
	temp_view[12] = 0
	temp_view[13] = 0
	temp_view[14] = 0
	local inverse_vp = self.m_projection * temp_view

	return {
		vec3(mat4.unproject(vec3(viewport[1], viewport[2], 1), inverse_vp, viewport)),
		vec3(mat4.unproject(vec3(viewport[1], viewport[4], 1), inverse_vp, viewport)),
		vec3(mat4.unproject(vec3(viewport[3], viewport[2], 1), inverse_vp, viewport)),
		vec3(mat4.unproject(vec3(viewport[3], viewport[4], 1), inverse_vp, viewport)),
	}
end

--- Returns a ray going from camera through a screen point.
-- @tparam number x Screen position x
-- @tparam number y Screen position y
-- @tparam table viewport (Optional) Viewport rectangle (x, y, w, h)
-- @return vec3
function PerspectiveCamera:screen_point_to_ray(x, y, viewport)
	viewport = viewport or {0.0, 0.0, application.w, application.h}

	local temp_view = self.m_view:clone()
	temp_view[12] = 0
	temp_view[13] = 0
	temp_view[14] = 0
	local inverse_vp = self.m_projection * temp_view

	return vec3(mat4.unproject(vec3(x, y, 1), inverse_vp, viewport))
end

--- Set camera position.
-- @param position vec3 object
function PerspectiveCamera:set_position(position)
	local direction = self:get_direction()
	self.eye = position + direction
	self.center = position
end

--- Get camera position.
-- @return vec3
function PerspectiveCamera:get_position()
	return self.center
end

--- Move camera.
-- @param delta vec3 Delta
function PerspectiveCamera:move(delta)
	self.eye = self.eye + delta
	self.center = self.center + delta
end

--- Set camera direction.
-- @param direction vec3 Direction
-- @tparam number distance (Optional)
function PerspectiveCamera:set_direction(direction, distance)
	distance = distance or 1
	self.center = self.eye + direction * distance
end

--- Rotate camera.
-- @tparam number y Yaw Angle in radians
-- @tparam number p Pitch Angle in radians
-- @tparam number r Roll Angle in radians
function PerspectiveCamera:rotate(y, p, r)
	local v = vec3(1, 0, 0)

	local _y = quat.from_angle_axis(math.rad(y), 0, 1, 0)
	local _p = quat.from_angle_axis(math.rad(p), 0, 0, 1)
	local _r = quat.from_angle_axis(math.rad(r), 1, 0, 0)
	local euler = _y * _p * _r

	local v = euler:mul_vec3(v)
	self.eye = self.center + vec3(v.x, v.y, v.z)
end

--- Get direction.
-- @return vec3
function PerspectiveCamera:get_direction()
	return (self.center - self.eye):normalize()
end

return PerspectiveCamera