--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- PerspectiveCamera for 3D scenes.
-- @module PerspectiveCamera
local class 			= require 'menori.modules.libs.class'
local matrix4x4 		= require 'menori.modules.libs.matrix4x4'
local SceneDispatcher 	= require 'menori.modules.scenedispatcher'

local cpml = require 'libs.cpml'
local vec3 = cpml.vec3

local PerspectiveCamera = class('PerspectiveCamera')

--- Constructor
function PerspectiveCamera:constructor(fov, aspect, nclip, fclip)
	fov = fov or 60
	aspect = aspect or 1.6666667
	nclip = nclip or 0.1
	fclip = fclip or 2048.0

	self.m_projection = matrix4x4():perspective_LH_NO(fov, aspect, nclip, fclip)
	self.m_inv_projection = self.m_projection:clone():inverse()
	self.m_view = matrix4x4()

	self.center 	= vec3( 0, 0, 0)
	self.eye 		= vec3( 0, 0, 1)
	self.up 		= vec3( 0,-1, 0)

	self.swap_look_at = false
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
	viewport = viewport or {0.0, 0.0, SceneDispatcher.w, SceneDispatcher.h}

	local temp_view = self.m_view:clone()
	temp_view[12] = 0
	temp_view[13] = 0
	temp_view[14] = 0
	local inverse_vp = self.m_projection * temp_view

	return {
		vec3(matrix4x4.unproject(vec3(viewport[1], viewport[2], 1), inverse_vp, viewport)),
		vec3(matrix4x4.unproject(vec3(viewport[1], viewport[4], 1), inverse_vp, viewport)),
		vec3(matrix4x4.unproject(vec3(viewport[3], viewport[2], 1), inverse_vp, viewport)),
		vec3(matrix4x4.unproject(vec3(viewport[3], viewport[4], 1), inverse_vp, viewport)),
	}
end

function PerspectiveCamera:get_unproject_point(x, y, viewport)
	viewport = viewport or {0.0, 0.0, SceneDispatcher.w, SceneDispatcher.h}

	local temp_view = self.m_view:clone()
	temp_view[12] = 0
	temp_view[13] = 0
	temp_view[14] = 0
	local inverse_vp = self.m_projection * temp_view

	return vec3(matrix4x4.unproject(vec3(x, y, 1), inverse_vp, viewport))
end

function PerspectiveCamera:move(direction)
	self.eye = self.eye + direction
end

function PerspectiveCamera:set_direction(direction, distance)
	distance = distance or 1
	self.center = self.eye + direction * distance
end

function PerspectiveCamera:rotate_position(angle)
	local v = self:direction()

	self.eye.z = self.center.z + (math.sin(angle)*v.x + math.cos(angle)*v.z)
	self.eye.x = self.center.x + (math.cos(angle)*v.x - math.sin(angle)*v.z)
end

function PerspectiveCamera:direction( ... )
	return (self.center - self.eye):normalize()
end

return PerspectiveCamera