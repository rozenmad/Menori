--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2025
-------------------------------------------------------------------------------
]]

--- Perspective camera class for 3D rendering.
-- Provides a perspective projection camera with configurable field of view, aspect ratio,
-- and near/far clipping planes. Supports view transformations and coordinate conversions.
-- @classmod PerspectiveCamera

local modules = (...):match('(.*%menori.modules.)')
local class = require (modules .. 'libs.class')
local ml 	= require (modules .. 'ml')
local app   = require (modules .. 'deprecated.app')

local mat4 = ml.mat4
local vec2 = ml.vec2
local vec3 = ml.vec3
local vec4 = ml.vec4

local PerspectiveCamera = class('PerspectiveCamera')

----
-- Creates a new PerspectiveCamera instance.
-- Initializes the camera with perspective projection.
-- @tparam number fov Field of view of the camera, in degrees (default: 60)
-- @tparam number aspect The aspect ratio (width/height) (default: 1.6666667)
-- @tparam number nclip The distance of the near clipping plane from the camera (default: 0.1)
-- @tparam number fclip The distance of the far clipping plane from the camera (default: 2048.0)
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
-- Updates the view matrix based on current eye, center, and up vectors.
-- Call this method after modifying the camera position or orientation.
function PerspectiveCamera:update_view_matrix()
	self.m_view:identity()
	self.m_view:look_at_RH(self.eye, self.center, self.up)
end

----
-- Generates a ray from the camera through a screen point.
-- Useful for ray casting, mouse picking, and collision detection.
-- @tparam number x Screen position x coordinate
-- @tparam number y Screen position y coordinate
-- @tparam table viewport Viewport rectangle {x, y, width, height}
-- @treturn table Ray data containing {origin = vec3, direction = vec3}
function PerspectiveCamera:screen_point_to_ray(x, y, viewport)
	viewport = viewport or {app:get_viewport()}

	local m_pos = vec3(mat4.unproject(vec3(x, y, 1), self.m_view, self.m_projection, viewport))
	local c_pos = self.eye:clone()
	local direction = vec3():sub(m_pos, self.eye):normalize()
	return {
		origin = c_pos, direction = direction
	}
end

----
-- Transforms a position from world space into screen space.
-- Converts 3D world coordinates to 2D screen coordinates.
-- @tparam number|table x World position x coordinate, or vec3 object containing world position
-- @tparam number y World position y coordinate (ignored if x is vec3)
-- @tparam number z World position z coordinate (ignored if x is vec3)
-- @tparam table viewport Screen viewport {x, y, width, height}
-- @treturn vec2 Screen space coordinates
function PerspectiveCamera:world_to_screen_point(x, y, z, viewport)
	if type(x) == 'table' then
		viewport = y
		x, y, z = x.x, x.y, x.z
	end

	viewport = viewport or {app:get_viewport()}

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
		(ndc_space_pos.x + 1) / 2 * viewport[3],
		(ndc_space_pos.y - 1) /-2 * viewport[4]
	)

	return screen_space_pos
end

----
-- Gets the normalized direction vector the camera is facing.
-- @treturn vec3 Normalized direction vector from eye to center
function PerspectiveCamera:get_direction()
	return (self.center - self.eye):normalize()
end

return PerspectiveCamera

--- Projection matrix for perspective transformation.
-- @tfield mat4 m_projection

--- Inverse projection matrix.
-- @tfield mat4 m_inv_projection

--- View matrix computed from eye, center, and up vectors.
-- Updated by calling update_view_matrix().
-- @tfield[readonly] mat4 m_view

--- Position where the camera is looking at.
-- @tfield vec3 center

--- Position of the camera in world space.
-- @tfield vec3 eye

--- Normalized up vector defining camera orientation.
-- @tfield vec3 up