-- Camera in one player physics Menori (ported to new physics API)
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

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(75, w/h, 0.1, 1000)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	self.world = physics.newWorld({0, -9.81, 0})

    self.physics_objects = {}

	------------ PLAYER CAPSULE ---------------
	local capsuleShape = physics.newShape("capsule", 0.5, 1.8)

	local platform_body = physics.newBody(self.world, capsuleShape, 1, {0, 0, 0})
	platform_body:setRestitution(0.0)
	platform_body:setDamping(0.1, 0.1)
	platform_body:setFriction(1)
	platform_body:setAngularFactor(0, 0, 0)

	local platform = CapsuleModel(0, 0, 0, 0.5, 1.8)
	platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	self.platform = platform
	self.root_node:attach(platform)
	platform.body = platform_body
    table.insert(self.physics_objects, {visual = platform, body = platform_body})

	------------- СТАТИЧЕСКАЯ ТЕРРАЙН И ОБЪЕКТЫ ---------------
	for x = -10, 10, 1 do
        for z = -10, 10, 1 do
			local boxShape = physics.newShape("box", 0.5, 0.5, 0.5)
			local platform2_body = physics.newBody(self.world, boxShape, 0, {x, -2, z})
			platform2_body:setRestitution(0.0)
			platform2_body:setFriction(1)

			local platform2 = BoxModel(x, -2, z, 1, 1, 1)
			platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
			self.root_node:attach(platform2)
			platform2.body = platform2_body
			table.insert(self.physics_objects, {visual = platform2, body = platform2_body})

            if x % 5 == 0 and z % 5 == 0 then
				local boxShape2 = physics.newShape("box", 0.5, 0.5, 0.5)
				local platform3_body = physics.newBody(self.world, boxShape2, 1, {x, -1, z})
				platform3_body:setRestitution(0.0)
				platform3_body:setDamping(0.1, 0.1)
				platform3_body:setFriction(1)

				local platform3 = BoxModel(x, -1, z, 1, 1, 1)
				platform3.material:set('baseColor', {0.2, 0.4, 0.4, 1})
				self.root_node:attach(platform3)
				platform3.body = platform3_body

				table.insert(self.physics_objects, {visual = platform3, body = platform3_body})
            end

            if math.random(1, 100) == 1 then
                for y = 1, math.random(1, 20), 1 do
					local boxShape3 = physics.newShape("box", 0.5, 0.5, 0.5)
					local platform4_body = physics.newBody(self.world, boxShape3, 0, {x, -2 + y, z})
					platform4_body:setRestitution(0.0)
					platform4_body:setFriction(1)

					local platform4 = BoxModel(x, -2 + y, z, 1, 1, 1)
					platform4.material:set('baseColor', {0.9, 0.9, 0.4, 1})
					self.root_node:attach(platform4)
					platform4.body = platform4_body
					table.insert(self.physics_objects, {visual = platform4, body = platform4_body})
                end
            end
        end
    end

	self.camera_pitch = 0
	self.camera_yaw = 0
	self.mouse_sensitivity = 0.2

	local screen_w, screen_h = love.graphics.getDimensions()
	love.mouse.setPosition(screen_w/2, screen_h/2)
    love.mouse.setVisible(false)
end

function scene:update(dt)
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
		self.platform.body:setLinearVelocity(
			math.sin(self.camera_yaw) * 3,
			y,
			math.cos(self.camera_yaw) * 3
		)
	end

	if love.keyboard.isDown('s') then
		local x, y, z = self.platform.body:getLinearVelocity()
		self.platform.body:setLinearVelocity(
			math.sin(self.camera_yaw) * -3,
			y,
			math.cos(self.camera_yaw) * -3
		)
	end

	if love.keyboard.isDown('a') then
		local x, y, z = self.platform.body:getLinearVelocity()
		self.platform.body:setLinearVelocity(
			math.sin(self.camera_yaw + math.pi/2) * 3,
			y,
			math.cos(self.camera_yaw + math.pi/2) * 3
		)
	end

	if love.keyboard.isDown('d') then
		local x, y, z = self.platform.body:getLinearVelocity()
		self.platform.body:setLinearVelocity(
			math.sin(self.camera_yaw - math.pi/2) * 3,
			y,
			math.cos(self.camera_yaw - math.pi/2) * 3
		)
	end

	self:update_first_person_camera()

	self:update_nodes(self.root_node, self.environment)
end

function scene:update_first_person_camera()
	local x, y, z = self.platform.body:getPosition()
	local player_pos = vec3(x, y, z)

	local forward = vec3(
		math.sin(self.camera_yaw) * math.cos(self.camera_pitch),
		math.sin(self.camera_pitch),
		math.cos(self.camera_yaw) * math.cos(self.camera_pitch)
	):normalize()

	local right = vec3.cross(forward, vec3(0, 1, 0)):normalize()
	local up = vec3.cross(right, forward):normalize()

	local eye_height = 1.4
	self.camera.eye = vec3(player_pos.x, player_pos.y + eye_height, player_pos.z)
	self.camera.center = self.camera.eye + forward
	self.camera.up = up

	self.camera:update_view_matrix()
	self.environment:set_vector('view_position', self.camera.eye)
end

function scene:render()
	love.graphics.clear(0.3, 0.25, 0.2)

	self:render_nodes(self.root_node, self.environment, {
		node_sort_comp = menori.Scene.alpha_mode_comp
	})

	local mx, my = love.graphics.getDimensions()
	love.graphics.setColor(1, 1, 1, 0.8)
	love.graphics.circle('line', mx/2, my/2, 5)
	love.graphics.line(mx/2 - 10, my/2, mx/2 + 10, my/2)
	love.graphics.line(mx/2, my/2 - 10, mx/2, my/2 + 10)
	love.graphics.setColor(1, 1, 1, 1)
end

function scene:mousemoved(x, y, dx, dy)
	self.camera_yaw = self.camera_yaw - dx * self.mouse_sensitivity * 0.04
	self.camera_pitch = ml.utils.clamp(
		self.camera_pitch - dy * self.mouse_sensitivity * 0.04,
		-math.pi/2 + 0.04,
		math.pi/2 - 0.04
	)

	local screen_w, screen_h = love.graphics.getDimensions()
	love.mouse.setPosition(screen_w/2, screen_h/2)
end

function scene:keypressed(key)
	if key == 'escape' then
		love.event.quit()
	end

	if key == 'r' then
		self.platform.body:setPosition(0, 0, 0)
		self.platform.body:setLinearVelocity(0, 0, 0)
		self.platform.body:setAngularVelocity(0, 0, 0)
	end
end

return scene