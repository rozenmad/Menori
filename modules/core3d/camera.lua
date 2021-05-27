--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local class       = require 'menori.modules.libs.class'
local ml          = require 'menori.modules.ml'
local application = require 'menori.modules.application'

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

	self.swap_look_at = true
end

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

function PerspectiveCamera:get_unproject_point(x, y, viewport)
	viewport = viewport or {0.0, 0.0, application.w, application.h}

	local temp_view = self.m_view:clone()
	temp_view[12] = 0
	temp_view[13] = 0
	temp_view[14] = 0
	local inverse_vp = self.m_projection * temp_view

	return vec3(mat4.unproject(vec3(x, y, 1), inverse_vp, viewport))
end

function PerspectiveCamera:set_position(position)
	local direction = self:get_direction()
	self.eye = position + direction
	self.center = position
end

function PerspectiveCamera:get_position()
	return self.center
end

function PerspectiveCamera:move(direction)
	self.eye = self.eye + direction
	self.center = self.center + direction
end

function PerspectiveCamera:set_direction(direction, distance)
	distance = distance or 1
	self.center = self.eye + direction * distance
end

function PerspectiveCamera:rotation(y, p, r)
	local v = vec3(1, 0, 0)

	local _y = quat.from_angle_axis(math.rad(y), 0, 1, 0)
	local _p = quat.from_angle_axis(math.rad(p), 0, 0, 1)
	local _r = quat.from_angle_axis(math.rad(r), 1, 0, 0)
	local euler = _y * _p * _r

	local v = euler:mul_vec3(v)
	self.eye = self.center + vec3(v.x, v.y, v.z)
end

function PerspectiveCamera:get_direction()
	return (self.center - self.eye):normalize()
end

return PerspectiveCamera