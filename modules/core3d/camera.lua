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
	fclip = fclip or 32.0

	self.m_projection = matrix4x4():perspective_LH_NO(fov, aspect, nclip, fclip)
	self.m_inv_projection = self.m_projection:clone():inverse()
	self.m_view = matrix4x4()

	self.center 	= vec3( 0, 0, 0)
	self.eye 		= vec3( 0, 0, 1)
	self.up 		= vec3( 0,-1, 0)
end

function PerspectiveCamera:update_view_matrix()
	self.m_view:identity()
	self.m_view:look_at(self.eye, self.center, self.up)
	return self.m_view
end

function PerspectiveCamera:get_corner_normals()
	local x1 = 0
	local y1 = 0
	local x2 = SceneDispatcher.w
	local y2 = SceneDispatcher.h
	local viewport = {0.0, 0.0, x2, y2}

	local temp_view = self.m_view:clone()
	temp_view[12] = 0
	temp_view[13] = 0
	temp_view[14] = 0
	local inverse_vp = self.m_projection * temp_view

	return {
		vec3(matrix4x4.unproject(vec3(x1, y1, 1), inverse_vp, viewport)),
		vec3(matrix4x4.unproject(vec3(x1, y2, 1), inverse_vp, viewport)),
		vec3(matrix4x4.unproject(vec3(x2, y1, 1), inverse_vp, viewport)),
		vec3(matrix4x4.unproject(vec3(x2, y2, 1), inverse_vp, viewport)),
	}
end

function PerspectiveCamera:rotate_position(angle)
	local v = self:direction()

	self.eye.z = self.center.z + (math.sin(angle)*v.x + math.cos(angle)*v.z)
	self.eye.x = self.center.x + (math.cos(angle)*v.x - math.sin(angle)*v.z)
end

function PerspectiveCamera:direction( ... )
	return (self.eye - self.center):normalize()
end

return PerspectiveCamera