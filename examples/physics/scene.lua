-- Camera in one player physics Menori
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

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(75, w/h, 0.1, 1000)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local world = physics.world(10, -9.81, true)
	self.world = world

    self.dynamic_bodies = {}

	------------ PLAYER CAPSULE ---------------
	local platform_body = physics.capsule(0.5, 1.8)
	world:add_body(platform_body)
	platform_body:set_body_type('dynamic')
	platform_body.restitution = 0.0
	platform_body.friction = 0.0
	platform_body:set_position(0, 0, 0)

	local platform = CapsuleModel(0, 0, 0, 0.5, 1.8)
	platform.material:set('baseColor', {0.4, 0.9, 0.7, 1})
	self.platform = platform
	self.root_node:attach(platform)
	platform.body = platform_body
    table.insert(self.dynamic_bodies, {platform_body, platform})

	-- local gltf = menori.glTFLoader.load('examples/assets/etrian_odyssey_3_monk.glb')
	-- local scenes = menori.NodeTreeBuilder.create(gltf, function (scene, builder)
	-- 	self.animations = menori.glTFAnimations(builder.animations)
	-- 	self.animations:set_action(1)
	-- end)
	-- self.root_node:attach(scenes[1])

	------------- STATIC BOX ---------------
    for x = -10, 10, 1 do
        for z = -10, 10, 1 do
	        local platform2_body = physics.box(1, 1, 1)
	        world:add_body(platform2_body)
            platform2_body:set_position(x, -2, z)
            platform2_body.friction = 0.1
			platform2_body.restitution = 0.0

	        local platform2 = BoxModel(x, -2, z, 1, 1, 1)
	        platform2.material:set('baseColor', {0.9, 0.4, 0.4, 1})
	        self.root_node:attach(platform2)
	        platform2.body = platform2_body

            if x % 6 == 0 and z % 6 == 0 then
	            local platform2_body = physics.box(1, 1, 1)
	            world:add_body(platform2_body)
                platform2_body:set_body_type('dynamic')
                platform2_body:set_position(x, -1, z)
                platform2_body.friction = 0.0
                platform2_body.restitution = 0.0

	            local platform2 = BoxModel(x, -1, z, 1, 1, 1)
	            platform2.material:set('baseColor', {0.2, 0.4, 0.4, 1})
	            self.root_node:attach(platform2)
	            platform2.body = platform2_body

                table.insert(self.dynamic_bodies, {platform2_body, platform2})
            end

            if math.random(1, 100) == 1 then
                for y = 1, math.random(1, 25), 1 do
	                local platform2_body = physics.box(1, 1, 1)
	                world:add_body(platform2_body)
                    platform2_body:set_position(x, -2 + y, z)
                    platform2_body.friction = 0.1
					platform2_body.restitution = 0.0

	                local platform2 = BoxModel(x, -2 + y, z, 1, 1, 1)
	                platform2.material:set('baseColor', {0.9, 0.9, 0.4, 1})
	                self.root_node:attach(platform2)
	                platform2.body = platform2_body
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
	self.world:step(dt)

    for index, body in ipairs(self.dynamic_bodies) do
	    local platform_body_position = body[1].position
	    body[2]:set_position(platform_body_position.x, platform_body_position.y, platform_body_position.z)
    end

	if love.keyboard.isDown('space') then
		self.platform.body:set_velocity(self.platform.body.velocity.x, 5, self.platform.body.velocity.z)
	end
	if love.keyboard.isDown('s') then
		self.platform.body:set_velocity(
			math.sin(self.camera_yaw) * -3,
			self.platform.body.velocity.y,
			math.cos(self.camera_yaw) * -3
		)
	end
	if love.keyboard.isDown('w') then
		self.platform.body:set_velocity(
			math.sin(self.camera_yaw) * 3,
			self.platform.body.velocity.y,
			math.cos(self.camera_yaw) * 3
		)
	end
	if love.keyboard.isDown('a') then
    	self.platform.body:set_velocity(
			math.sin(self.camera_yaw + math.pi/2) * 3,
			self.platform.body.velocity.y,
			math.cos(self.camera_yaw + math.pi/2) * 3
		)
	end
	if love.keyboard.isDown('d') then
		self.platform.body:set_velocity(
			math.sin(self.camera_yaw - math.pi/2) * 3,
			self.platform.body.velocity.y,
			math.cos(self.camera_yaw - math.pi/2) * 3
		)
	end

	self:update_first_person_camera()

	self:update_nodes(self.root_node, self.environment)
end

function scene:update_first_person_camera()
	local player_pos = self.platform.position

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

	-- self:render_nodes(self.root_node, self.environment, {
	-- 	node_sort_comp = menori.Scene.alpha_mode_comp
	-- })

    self.world:render(self, self.environment)

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

return scene