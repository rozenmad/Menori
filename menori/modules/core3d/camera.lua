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
local class = require (modules .. 'libs.class')
local ml    = require (modules .. 'ml')
local app   = require (modules .. 'application')

local mat4 = ml.mat4
local vec2 = ml.vec2
local vec3 = ml.vec3
local vec4 = ml.vec4

local PerspectiveCamera = class('PerspectiveCamera')

--- init
-- @tparam number fov
-- @tparam number aspect
-- @tparam number nclip
-- @tparam number fclip
function PerspectiveCamera:init(fov, aspect, nclip, fclip)
	fov = fov or 60
	aspect = aspect or 1.6666667
	nclip = nclip or 0.1
	fclip = fclip or 512.0

	self.m_projection = mat4():perspective_LH_NO(fov, aspect, nclip, fclip)
	self.m_inv_projection = self.m_projection:clone():inverse()
	self.m_view = mat4()

	self.center   = vec3( 0, 0, 0 )
	self.eye 	  = vec3( 0, 0, 1 )
	self.up 	  = vec3( 0,-1, 0 )
end

-- Updating the view matrix.
function PerspectiveCamera:update_view_matrix()
	self.m_view:identity()
	self.m_view:look_at(self.eye, self.center, self.up)
end

--- Returns a ray going from camera through a screen point.
-- @tparam number x screen position x
-- @tparam number y screen position y
-- @tparam table viewport (optional) viewport rectangle (x, y, w, h)
-- @treturn vec3
function PerspectiveCamera:screen_point_to_ray(x, y, viewport)
	viewport = viewport or {app.ox, app.oy, app.w * app.sx, app.h * app.sy}

	local m_pos = vec3(mat4.unproject(vec3(x, y, 1), self.m_view, self.m_projection, viewport))
	local c_pos = self.eye:clone()
	return {
		position = c_pos, direction = m_pos - self.eye
	}
end

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

--- Get direction.
-- @treturn vec3
function PerspectiveCamera:get_direction()
	return (self.center - self.eye):normalize()
end

return PerspectiveCamera