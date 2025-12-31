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

local CapsuleModel = menori.ModelNode:extend('CapsuleModel')
function CapsuleModel:init(x, y, z, radius, height)
	CapsuleModel.super.init(self, menori.Capsule(radius, height))
	self.is_capsule = true
	self.radius = radius
	self.height = height
	self:set_position(x, y, z)
end

local TriangleModel = menori.ModelNode:extend('TriangleModel')
function TriangleModel:init(x, y, z, v1, v2, v3)
	TriangleModel.super.init(self, menori.Triangle(v1, v2, v3))
	self.v1 = v1
    self.v2 = v2
    self.v3 = v3
    self.is_triangle = true
	self:set_position(x, y, z)
end

local SphereModel = menori.ModelNode:extend('SphereModel')
function SphereModel:init(x, y, z, radius)
	SphereModel.super.init(self, menori.Sphere(radius))
	self.radius = radius
    self.is_sphere = true
	self:set_position(x, y, z)
end

local PlaneModel = menori.ModelNode:extend('PlaneModel')
function PlaneModel:init(x, y, z, width, height, v_segments, h_segments)
	PlaneModel.super.init(self, menori.Plane(width, height, v_segments, h_segments))
	self.width = width
    self.height = height
    self.v_segments = v_segments
    self.h_segments = h_segments
    self.is_plane = true
	self:set_position(x, y, z)
end

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local world = physics.world(12, -9.81, true)
	self.world = world

	------------ PLAYER BOX ---------------
	local platform_body = physics.box(1, 1, 1)
	world:add_body(platform_body)
	platform_body:set_body_type('dynamic')
	platform_body.restitution = 0.0
	-- platform_body:set_sensor(true)
	-- platform_body.is_sleeping = true
	-- platform_body:set_mask(2)

	local platform = BoxModel(2, 0.5, 0, 1, 1, 1)
	platform_body:set_position(2, 0.5, 0)
	platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	self.platform = platform
	self.root_node:attach(platform)
	platform.body = platform_body

	-- ------------ PLAYER PLANE ---------------
	-- local platform_body = physics.plane(2, 2, 1, 1)
	-- world:add_body(platform_body)
	-- platform_body:set_body_type('dynamic')
	-- platform_body.restitution = 0.0
	-- -- platform_body.is_sleeping = true

	-- local platform = PlaneModel(2, 0.5, 0, 2, 2, 1, 1)
	-- platform_body:set_position(2, 0.5, 0)
	-- platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	-- self.platform = platform
	-- self.root_node:attach(platform)
	-- platform.body = platform_body

	-- -------------- PLAYER CAPSULE ---------------
	-- local platform_body = physics.capsule(0.5, 1)
	-- world:add_body(platform_body)
	-- platform_body:set_body_type('dynamic')
	-- platform_body.restitution = 0.0
	-- -- platform_body.friction = 0.0
	-- platform_body:set_position(2, 0.5, 0)
	-- -- platform_body.is_sleeping = true

	-- local platform = CapsuleModel(2, 0.5, 0, 0.5, 1)
	-- platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	-- self.platform = platform
	-- self.root_node:attach(platform)
	-- platform.body = platform_body

	-- ------------ PLAYER TRIANGLE ---------------
	-- local platform_body = physics.triangle({0, 2, 0},{-2, 0, 1}, {2, 0, -1})
	-- world:add_body(platform_body)
	-- platform_body:set_body_type('dynamic')
	-- platform_body.restitution = 0.0
	-- platform_body:set_position(2, 0.5, 0)

	-- local platform = TriangleModel(2, 0.5, 0, {0, 2, 0},{-2, 0, 1}, {2, 0, -1})
	-- platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	-- self.platform = platform
	-- self.root_node:attach(platform)
	-- platform.body = platform_body

	-- ------------ PLAYER SPHERE ---------------
	-- local platform_body = physics.sphere(0.5)
	-- world:add_body(platform_body)
	-- platform_body:set_body_type('dynamic')
	-- platform_body.restitution = 0.0
	-- platform_body:set_position(2, 0.5, 0)

	-- local platform = SphereModel(2, 0.5, 0, 0.5)
	-- platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	-- self.platform = platform
	-- self.root_node:attach(platform)
	-- platform.body = platform_body

	------------- STATIC BOX ---------------
	local platform2_body = physics.box(1, 1, 1)
	world:add_body(platform2_body)

	local platform2 = BoxModel(2, -5, 0, 1, 1, 1)
	platform2_body:set_position(2, -5, 0)
	platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform2)
	platform2.body = platform2_body
	-- platform2_body:set_category(2)

	------------- STATIC BOX ---------------
	local platform2_body = physics.box(1, 1, 1)
	world:add_body(platform2_body)

	local platform2 = BoxModel(1, -4, 0, 1, 1, 1)
	platform2_body:set_position(1, -4, 0)
	platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform2)
	platform2.body = platform2_body

	------------- STATIC CAPSULE ---------------
	local platform2_body = physics.capsule(1, 2)
	world:add_body(platform2_body)
	platform2_body:set_position(-2, -4, 0)

	local platform2 = CapsuleModel(-2, -4, 0, 1, 2)
	platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform2)
	platform2.body = platform2_body

	------------- STATIC TRIANGLE ---------------
	local platform2_body = physics.triangle({1, 0, 0}, {0, 1, 0}, {0, 0, 1})
	world:add_body(platform2_body)
	platform2_body:set_position(6, -4, 0)

	local platform2 = TriangleModel(6, -4, 0, {1, 0, 0}, {0, 1, 0}, {0, 0, 1})
	platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform2)
	platform2.body = platform2_body

	------------- STATIC SPHERE ---------------
	local platform2_body = physics.sphere(0.5)
	world:add_body(platform2_body)
	platform2_body:set_position(-10, -1, 0)

	local platform2 = SphereModel(-2, -1, 0, 0.5)
	platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform2)
	platform2.body = platform2_body

	------------- STATIC PLANE ---------------
	local plane_body = physics.plane(10, 10, 1, 1)
	world:add_body(plane_body)
	plane_body:set_position(0, -10, 0)

	local plane_visual = PlaneModel(0, -10, 0, 10, 10, 1, 1)
	plane_visual.material:set('baseColor', {0.4, 0.7, 0.9, 1})
	plane_visual.material:set('emissive', {0.1, 0.1, 0.1, 1})
	self.root_node:attach(plane_visual)
	plane_visual.body = plane_body

	for i = 1, 100, 1 do
		----------- STATIC BOX ---------------
		local platform2_body = physics.box(1, 1, 1)
		world:add_body(platform2_body)
		platform2_body:set_position(i, i, i)

		local platform2 = BoxModel(i, i, i, 1, 1, 1)
		platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
		self.root_node:attach(platform2)
		platform2.body = platform2_body
	end

	for i = 1, 10, 1 do
		------------- STATIC BOX ---------------
		local platform2_body = physics.box(1, 1, 1)
		world:add_body(platform2_body)
		platform2_body:set_position(-4 + i, 0, 0)

		local platform2 = BoxModel(-4 + i, 0, 0, 1, 1, 1)
		platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
		self.root_node:attach(platform2)
		platform2.body = platform2_body

		------------- DYNAMIC BOX ---------------
		local platform2_body = physics.box(1, 1, 1)
		world:add_body(platform2_body)
		platform2_body:set_body_type('dynamic')
		-- platform2_body.restitution = 0.0
		platform2_body:set_position(-4 + i, 2, 0)

		local platform2 = BoxModel(-4 + i, 2, 0, 1, 1, 1)
		platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
		self.root_node:attach(platform2)
		platform2.body = platform2_body
	end

	local node = menori.objLoader.load('examples/assets/cube.obj')
	node.children[1].material:set('baseColor', {0.7, 0.7, 0.9, 1})
	self.root_node:attach(node)

	self.x_angle = 0
	self.y_angle = -30
	self.view_scale = 10
end

function scene:update(dt)
	self:update_camera()
	self:update_nodes(self.root_node, self.environment)

	local platform_body_position = self.platform.body.position
	self.platform:set_position(platform_body_position.x, platform_body_position.y, platform_body_position.z)

	-- local hits = self.world:raycast(platform_body_position.x - 0.25, platform_body_position.y - 0.5, platform_body_position.z,
	-- 	platform_body_position.x - 5, platform_body_position.y - 0.5, platform_body_position.z)
	-- print(#hits)

	self.world:step(dt)

	if love.keyboard.isDown('space') then
		self.platform.body:set_velocity(self.platform.body.velocity.x, 5, self.platform.body.velocity.z)
	end
	if love.keyboard.isDown('s') then
		self.platform.body:set_velocity(self.platform.body.velocity.x, self.platform.body.velocity.y, 3)
	end
	if love.keyboard.isDown('w') then
		self.platform.body:set_velocity(self.platform.body.velocity.x, self.platform.body.velocity.y, -3)
	end
	if love.keyboard.isDown('a') then
		self.platform.body:set_velocity(-3, self.platform.body.velocity.y, self.platform.body.velocity.z)
	end
	if love.keyboard.isDown('d') then
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

	-- self:render_nodes(self.root_node, self.environment, {
	-- 	node_sort_comp = menori.Scene.alpha_mode_comp
	-- })

	self.world:render(self, self.environment)

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