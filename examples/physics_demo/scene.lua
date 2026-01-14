-- Physics example using Menori with new physics API
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

local physics = menori.Physics

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

	self.world = physics.newWorld({0, -9.81, 0})

	self.physics_objects = {}

	------------ PLAYER BOX ---------------
	local boxShape = physics.newShape("box", 0.5, 0.5, 0.5)
	local platform_body = physics.newBody(self.world, boxShape, 1, {2, 0.5, 0})
	platform_body:setRestitution(0.0)
	platform_body:setDamping(0.1, 0.1)
	platform_body:setFriction(1)
	-- platform_body:setAngularFactor(0, 0, 0)

	local platform = BoxModel(2, 0.5, 0, 1, 1, 1)
	platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	self.platform = platform
	self.root_node:attach(platform)

	platform.body = platform_body
	table.insert(self.physics_objects, {visual = platform, body = platform_body})

	------------- STATIC BOX ---------------
	local boxShape2 = physics.newShape("box", 0.5, 0.5, 0.5)
	local platform2_body = physics.newBody(self.world, boxShape2, 0, {2, -5, 0})
	platform2_body:setRestitution(0.5)

	local platform2 = BoxModel(2, -5, 0, 1, 1, 1)
	platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform2)
	table.insert(self.physics_objects, {visual = platform2, body = platform2_body})

	------------- STATIC BOX ---------------
	local boxShape3 = physics.newShape("box", 0.5, 0.5, 0.5)
	local platform3_body = physics.newBody(self.world, boxShape3, 0, {1, -4, 0})
	platform3_body:setRestitution(0.5)

	local platform3 = BoxModel(1, -4, 0, 1, 1, 1)
	platform3.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(platform3)
	table.insert(self.physics_objects, {visual = platform3, body = platform3_body})

	------------- STATIC CAPSULE ---------------
	local capsuleShape = physics.newShape("capsule", 1, 2)
	local capsule_body = physics.newBody(self.world, capsuleShape, 0, {-2, -4, 0})
	capsule_body:setRestitution(0.5)

	local capsule = CapsuleModel(-2, -4, 0, 1, 2)
	capsule.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(capsule)
	table.insert(self.physics_objects, {visual = capsule, body = capsule_body})

	------------- STATIC SPHERE ---------------
	local sphereShape = physics.newShape("sphere", 0.5)
	local sphere_body = physics.newBody(self.world, sphereShape, 0, {-2, -1, 0})
	sphere_body:setRestitution(0.5)

	local sphere = SphereModel(-2, -1, 0, 0.5)
	sphere.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	self.root_node:attach(sphere)
	table.insert(self.physics_objects, {visual = sphere, body = sphere_body})

	for x = 1, 10 do
		for y = 1, 10 do
			local boxShape = physics.newShape("box", 0.5, 0.5, 0.5)
			local box_body = physics.newBody(self.world, boxShape, 0, {x * 2, y * 2, x * 2})
			box_body:setRestitution(0.2)

			local box = BoxModel(x * 2, y * 2, x * 2, 1, 1, 1)
			box.material:set('baseColor', {0.9, 0.4, 0.4, 1})
			self.root_node:attach(box)
			table.insert(self.physics_objects, {visual = box, body = box_body})
		end
	end

	for i = 1, 10 do
		local boxShape = physics.newShape("box", 0.5, 0.5, 0.5)
		local static_box_body = physics.newBody(self.world, boxShape, 0, {-4 + i, 0, 0})
		static_box_body:setRestitution(0.3)

		local static_box = BoxModel(-4 + i, 0, 0, 1, 1, 1)
		static_box.material:set('baseColor', {0.9, 0.4, 0.4, 1})
		self.root_node:attach(static_box)
		table.insert(self.physics_objects, {visual = static_box, body = static_box_body})

		if i % 2 ~= 0 then
			local dynamicBoxShape = physics.newShape("box", 0.5, 0.5, 0.5)
			local dynamic_box_body = physics.newBody(self.world, dynamicBoxShape, 1, {-4 + i, 2, 0})
			dynamic_box_body:setRestitution(0.4)
			dynamic_box_body:setDamping(0.1, 0.1)

			local dynamic_box = BoxModel(-4 + i, 2, 0, 1, 1, 1)
			dynamic_box.material:set('baseColor', {0.4, 0.9, 0.4, 1})
			self.root_node:attach(dynamic_box)
			table.insert(self.physics_objects, {visual = dynamic_box, body = dynamic_box_body})
		end
	end

	-- local node = menori.objLoader.load('examples/assets/cube.obj')
	-- node.children[1].material:set('baseColor', {0.7, 0.7, 0.9, 1})
	-- self.root_node:attach(node)

	self.x_angle = 0
	self.y_angle = -30
	self.view_scale = 15
end

function scene:update(dt)
	self:update_camera()

	self.world:update(dt)

	for _, obj in ipairs(self.physics_objects) do
		local x, y, z = obj.body:getPosition()
		obj.visual:set_position(x, y, z)

		local rx, ry, rz, rw = obj.body:getRotation()
		obj.visual:set_rotation(quat(rx, ry, rz, rw))
	end

	if love.keyboard.isDown('space') then
		local x, y, z = self.platform.body:getLinearVelocity()
		self.platform.body:setLinearVelocity(x, 5, z)
	end

	if love.keyboard.isDown('w') then
		local x, y, z = self.platform.body:getLinearVelocity()
		self.platform.body:setLinearVelocity(x, y, -3)
	end

	if love.keyboard.isDown('s') then
		local x, y, z = self.platform.body:getLinearVelocity()
		self.platform.body:setLinearVelocity(x, y, 3)
	end

	if love.keyboard.isDown('a') then
		local x, y, z = self.platform.body:getLinearVelocity()
		self.platform.body:setLinearVelocity(-3, y, z)
	end

	if love.keyboard.isDown('d') then
		local x, y, z = self.platform.body:getLinearVelocity()
		self.platform.body:setLinearVelocity(3, y, z)
	end

	if love.keyboard.isDown('r') then
		local x, y, z = self.platform.body:getPosition()
		local result = self.world:rayCast(
			{x, y, z},
			{x + 5, y - 5, z}
		)
		if result.hit then
			print("Ray hit at:", result.position[1], result.position[2], result.position[3])
		end
	end

	self:update_nodes(self.root_node, self.environment)
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

	love.graphics.setColor(1, 1, 1)
	love.graphics.print(string.format("Objects: %d", #self.physics_objects), 10, 50)
end

function scene:mousemoved(x, y, dx, dy)
	self.y_angle = self.y_angle - dy * 0.5
	self.x_angle = self.x_angle - dx * 0.5
	self.y_angle = ml.utils.clamp(self.y_angle, -45, 45)
end

function scene:wheelmoved(x, y)
	self.view_scale = self.view_scale - y * 0.2
	self.view_scale = math.max(5, math.min(self.view_scale, 50))
end

function scene:keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end

	if key == 'r' then
		self.platform.body:setPosition(2, 0.5, 0)
		self.platform.body:setLinearVelocity(0, 0, 0)
		self.platform.body:setAngularVelocity(0, 0, 0)
	end

	if key == 'f' then
		local force = {
			(math.random() - 0.5) * 100,
			math.random() * 50,
			(math.random() - 0.5) * 100
		}
		self.platform.body:applyForce(force)
	end

	if key == 'i' then
		local impulse = {
			(math.random() - 0.5) * 20,
			math.random() * 10,
			(math.random() - 0.5) * 20
		}
		self.platform.body:applyImpulse(impulse)
	end
end

return scene