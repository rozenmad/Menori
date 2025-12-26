-- Intersect tests example of using Menori
--[[
-------------------------------------------------------------------------------
	Menori
	@author Max-Dil
	2025
-------------------------------------------------------------------------------
]]

local menori = require 'menori'

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat

local physics = menori.Physics()

local scene = menori.Scene:extend('physics_scene')

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local world = physics.world(0, -9.81, 0, false)

	local platform_body = physics.body(world, 2, 0.5, 0, 'static')
	local platform = physics.box(2, 0.5, 0, 1, 1, 1)
	platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	self.root_node:attach(platform)
	self.platform = platform
	platform_body:add_shape(platform)

	self.x_angle = 0
	self.y_angle = -30
	self.view_scale = 10
end

function scene:update(dt)
	self:update_camera()
	self:update_nodes(self.root_node, self.environment)
end

function scene:update_camera()
	local q = quat.from_euler_angles(0, math.rad(self.x_angle), math.rad(self.y_angle)) * vec3.unit_z * self.view_scale
	local v = vec3(0, 0.5, 0)
	self.camera.center = v
	self.camera.eye = q + v
	self.camera:update_view_matrix()

	self.environment:set_vector('view_position', self.camera.eye)
end

function scene:render()
	love.graphics.clear(0.3, 0.25, 0.2)

	self:render_nodes(self.root_node, self.environment, {
		node_sort_comp = menori.Scene.alpha_mode_comp
	})

	local mx, my = love.mouse.getPosition()
	love.graphics.circle('line', mx, my, 8)
end

return scene