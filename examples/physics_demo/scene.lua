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

local BoxModel = menori.ModelNode:extend('BoxModel')

function BoxModel:init(x, y, z, w, h, d)
	BoxModel.super.init(self, menori.Box(w, h, d))

	self:set_position(x, y, z)
	self.is_box = true
end

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local world = physics.world(-9.81, true)
	self.world = world

	local platform_body = physics.box(1, 1, 1)
	world:add_body(platform_body)
	platform_body:set_body_type('dynamic')
	platform_body.restitution = 0.0
	-- platform_body.is_sleeping = true

	local platform = BoxModel(2, 0.5, 0, 1, 1, 1)
	platform_body:set_position(2, 0.5, 0)
	platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	self.platform = platform
	self.root_node:attach(platform)
	platform.body = platform_body

	local platform2_body = physics.box(1, 1, 1)
	world:add_body(platform2_body)

	local platform2 = BoxModel(2, -5, 0, 1, 1, 1)
	platform2_body:set_position(2, -5, 0)
	platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform2)
	platform2.body = platform2_body

	local platform2_body = physics.box(1, 1, 1)
	world:add_body(platform2_body)

	local platform2 = BoxModel(1, -4, 0, 1, 1, 1)
	platform2_body:set_position(1, -4, 0)
	platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform2)
	platform2.body = platform2_body

	self.x_angle = 0
	self.y_angle = -30
	self.view_scale = 10
end

function scene:update(dt)
	self:update_camera()
	self:update_nodes(self.root_node, self.environment)

	local platform_body_position = self.platform.body.position
	self.platform:set_position(platform_body_position.x, platform_body_position.y, platform_body_position.z)

	self.world:step(dt)
end

function scene:keypressed(key)
	if key == 'w' then
		self.platform.body:set_velocity(self.platform.body.velocity.x, 5, self.platform.body.velocity.z)
	elseif key == 'a' then
		self.platform.body:set_velocity(-3, self.platform.body.velocity.y, self.platform.body.velocity.z)
	elseif key == 'd' then
		self.platform.body:set_velocity(3, self.platform.body.velocity.y, self.platform.body.velocity.z)
	end
end

function scene:update_camera()
	local q = quat.from_euler_angles(0, math.rad(self.x_angle), math.rad(self.y_angle)) * vec3.unit_z * self.view_scale
	local v = self.platform.position
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

function scene:mousemoved(x, y, dx, dy)
	self.y_angle = self.y_angle - dy * 0.5
	self.x_angle = self.x_angle - dx * 0.5
	self.y_angle = ml.utils.clamp(self.y_angle, -45, 45)
end

function scene:wheelmoved(x, y)
	self.view_scale = self.view_scale - y * 0.2
end

return scene