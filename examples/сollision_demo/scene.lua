-- Intersect tests example of using Menori
--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2023
-------------------------------------------------------------------------------
]]

local menori = require 'menori'

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat
local intersect = ml.intersect
local ml_utils = ml.utils

local MOVEMENT_SPEED = 0.05

-- Box Model Class
local BoxModel = menori.ModelNode:extend('BoxModel')

function BoxModel:init(x, y, z, w, h, d)
	BoxModel.super.init(self, menori.Box(w, h, d))

	self:set_position(x, y, z)
	self.is_box = true
end

-- Sphere Model Class
local SphereModel = menori.ModelNode:extend('SphereModel')

function SphereModel:init(x, y, z, radius)
	SphereModel.super.init(self, menori.Sphere(radius))
	self:set_position(x, y, z)
	self.is_sphere = true
	self.radius = radius
end

-- Capsule Model Class
local CapsuleModel = menori.ModelNode:extend('CapsuleModel')

function CapsuleModel:init(x, y, z, radius, height)
	CapsuleModel.super.init(self, menori.Capsule(radius, height))
	self:set_position(x, y, z)
	self.is_capsule = true
	self.radius = radius
	self.height = height
end

function CapsuleModel:rotate(angle)
	local q = quat.from_euler_angles(angle, 0, angle)
	self:set_rotation(q)
end

-- Check if capsule is standing on ground (terrain)
-- Uses capsule-triangle intersection tests with terrain mesh
function CapsuleModel:on_ground(root_node, threshold)
	local aabb = self:get_aabb()

	-- Expand AABB slightly downward to catch ground contact
	local expanded_aabb = ml.bound3(aabb.min, aabb.max)
	expanded_aabb:expand(vec3(0.0, -0.01, 0.0), vec3(0.0, 0.0, 0.0))
	local center = expanded_aabb:center()
	local p0 = {center.x, center.y - self.height/2, center.z}
	local p1 = {center.x, center.y + self.height/2, center.z}

	-- Collect all terrain triangles that intersect with expanded AABB
	local triangles = {}
	root_node:traverse(function(node)
		if node.is_terrain then
			local t = node.bvh:intersect_aabb(expanded_aabb)
			for _, tri in ipairs(t) do
				table.insert(triangles, tri)
			end
		end
	end)

	-- Test capsule against each triangle
	for _, tri in ipairs(triangles) do
		local hit = ml.intersect.capsule_triangle(
			p0, p1, self.radius, tri.triangle
		)
		if hit then
			local normal_y = hit.normal[2]

			-- Check if surface is walkable (normal points upward)
			-- and penetration depth exceeds threshold
			if normal_y > 0.5 and hit.depth > threshold then
				return true
			end
		end
	end
	return false
end

-- Resolve all collisions with other objects
-- Uses iterative approach to handle multiple simultaneous collisions
function CapsuleModel:resolve_collisions(root_node)
	local max_iterations = 5

	for _ = 1, max_iterations do
		local aabb = self:get_aabb()
		local center = aabb:center()
		local p0 = {center.x, center.y - self.height/2, center.z}
		local p1 = {center.x, center.y + self.height/2, center.z}
		local deepestCollision = nil
		local maxDepth = 0

		-- Check collision with all other objects
		for _, node in ipairs(root_node.children) do
			local other_aabb = node:get_aabb()
			-- Skip self and perform broad-phase AABB test first
			if node ~= self and intersect.aabb_aabb(aabb, other_aabb) then
				local hit

				-- Handle different collision types
				if node.is_terrain then
					local t = node.bvh:intersect_aabb(aabb)
					for _, tri in ipairs(t) do
						local hit = ml.intersect.capsule_triangle(
							p0, p1, self.radius, tri.triangle
						)
						if hit then
							if hit.depth > maxDepth then
								maxDepth = hit.depth
								deepestCollision = hit
							end
						end
					end
				elseif node.is_box then
					-- Capsule vs box collision
					local aabb = node:get_aabb()
					hit = intersect.capsule_aabb(p0, p1, self.radius, aabb)
				elseif node.is_capsule then
					-- Capsule vs capsule collision
					local b0, b1 = node:get_hemisphere_centers()
					hit = intersect.capsule_capsule(p0, p1, self.radius, b0, b1, node.radius)
				elseif node.is_sphere then
					-- Capsule vs sphere collision
					hit = intersect.capsule_sphere(p0, p1, self.radius, node.position, node.radius)
				end
				if hit then
					-- Track deepest collision for resolution
					if hit.depth > maxDepth then
						maxDepth = hit.depth
						deepestCollision = hit
					end
				end
			end
		end

		if not deepestCollision or maxDepth < 0.001 then
			return
		end

		local normal = vec3(deepestCollision.normal[1], deepestCollision.normal[2], deepestCollision.normal[3])

		local capsule_center = vec3(center.x, center.y, center.z)
		local hit_point = vec3(deepestCollision.point[1], deepestCollision.point[2], deepestCollision.point[3])
		local to_capsule = (capsule_center - hit_point):normalize()

		if vec3.dot(normal, to_capsule) < 0 then
			normal = -normal
		end

		-- Apply position correction with small epsilon to prevent sinking
		local correction = normal * (maxDepth + 0.001)
		local currentPos = self.position

		self:set_position(currentPos + correction)
	end
end

-- Handle player input for movement
-- WASD controls with collision detection and gravity
function CapsuleModel:input(root_node)
	local p = self.position
	local inputMovement = vec3(0, 0, 0)

	if love.keyboard.isDown('w') then
		inputMovement = inputMovement - self:forward()
	end
	if love.keyboard.isDown('s') then
		inputMovement = inputMovement + self:forward()
	end
	if love.keyboard.isDown('a') then
		inputMovement = inputMovement - self:right()
	end
	if love.keyboard.isDown('d') then
		inputMovement = inputMovement + self:right()
	end

	-- Separate horizontal and vertical movement
	local horizontalMovement = vec3(inputMovement.x, 0, inputMovement.z):normalize() * MOVEMENT_SPEED
	local verticalMovement = vec3(0, -0.1, 0)

	-- Apply horizontal movement with collision resolution
	if horizontalMovement:length() > 0 then
		self:set_position(p + horizontalMovement)
		self:resolve_collisions(root_node)
	end

	-- Apply gravity if not on ground
	if not self:on_ground(root_node, 0.001) then
		local currentPos = self.position
		self:set_position(currentPos + verticalMovement)
		self:resolve_collisions(root_node)
	end
end

-- Get world-space positions of capsule hemisphere centers
function CapsuleModel:get_hemisphere_centers()
	local half = self.height * 0.5

	local mat = self.world_matrix
	local p0_world = mat:multiply_vec3(vec3(0, -half, 0))
	local p1_world = mat:multiply_vec3(vec3(0,  half, 0))

	return p0_world, p1_world
end

-- Generate a procedural terrain mesh
local function GenerateTerrain(size, step)
	size = size or 10
	step = step or 1.0

	local hs = size * 0.5

	local vertices = {}
	for z = 0, size do
		for x = 0, size do
			local px = x * step
			local pz = z * step
			local py = math.sin(px * 0.5) * 0.5 + math.cos(pz * 0.5) * 0.5

			local u, v = x / size, z / size

			table.insert(vertices, {px - hs, py, pz - hs, u, v, 0, 1, 0})
		end
	end

	local indices = {}
	local w = size + 1
	for z = 0, size - 1 do
		for x = 0, size - 1 do
			local i0 = z * w + x + 1
			local i1 = i0 + 1
			local i2 = i0 + w
			local i3 = i2 + 1

			table.insert(indices, i0)
			table.insert(indices, i3)
			table.insert(indices, i1)

			table.insert(indices, i0)
			table.insert(indices, i2)
			table.insert(indices, i3)
		end
	end

	return menori.Mesh {
		vertices = vertices, indices = indices
	}
end

--class inherited from Scene.
local scene = menori.Scene:extend('minimal_scene')

function scene:init()
	scene.super.init(self)

	-- Setup camera and environment
	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	-- Create root node to hold all scene objects
	self.root_node = menori.Node()

	-- Generate and setup terrain with BVH for fast collision queries
	local terrain = GenerateTerrain(10, 1.0)
	self.terrain_model = menori.ModelNode(terrain)
	self.terrain_model.is_terrain = true
	self.terrain_model.bvh = menori.ml.bvh(self.terrain_model)
	self.root_node:attach(self.terrain_model)

	-- Create various test objects
	local node
	node = BoxModel(2, 0.5, 0, 1, 1, 1)
	self.root_node:attach(node)

	node = SphereModel(-2, 0.5, 0, 0.5)
	self.root_node:attach(node)

	self.capsule = CapsuleModel(0, 1, -2, 0.5, 1)
	self.root_node:attach(self.capsule)

	-- Camera control variables
	self.x_angle = 0
	self.y_angle = -30
	self.view_scale = 10

	self.capsule_angle = 0

	-- Player-controlled capsule
	self.player_capsule = CapsuleModel(0, 3, 0, 0.5, 1)
	self.root_node:attach(self.player_capsule)
end

function scene:render()
	love.graphics.clear(0.3, 0.25, 0.2)

	self:render_nodes(self.root_node, self.environment, {
		node_sort_comp = menori.Scene.alpha_mode_comp
	})

	-- Draw mouse cursor indicator
	local mx, my = love.mouse.getPosition()
	love.graphics.circle('line', mx, my, 8)

	local y = 45
	love.graphics.setColor(1, 0.5, 0, 1)

	love.graphics.print("W/A/S/D - Move player capsule", 10, y)
	love.graphics.print("Hold the right mouse button to rotate the camera.", 10, y + 15)
	love.graphics.print("Mouse Wheel - Zoom in/out", 10, y + 30)
	love.graphics.print("Mouse Hover - Highlight objects", 10, y + 45)
end

function scene:update(dt)
	-- Handle player input and physics
	self.player_capsule:input(self.root_node)

	self:update_camera()
	self:update_nodes(self.root_node, self.environment)

	self.capsule_angle = self.capsule_angle + 2 * dt
	self.capsule:rotate(self.capsule_angle)

	-- Mouse raycast for object highlighting
	local mx, my = love.mouse.getPosition()
	local ray = self.camera:screen_point_to_ray(mx, my)

	-- Reset all materials to default color
	for _, v in ipairs(self.root_node.children) do
		v.material:set('baseColor', {1, 1, 1, 1})
	end
	self.terrain_model.material:set('baseColor', {0.4, 0.4, 0.4, 1})
	self.player_capsule.material:set('baseColor', {0.4, 0.9, 0.7, 1})

	-- Test ray against all objects and highlight intersected ones
	self.root_node:traverse(function (node)
		local hit
		if node.is_box then
			local aabb = node:get_aabb()
			hit = intersect.ray_aabb(ray, aabb)
		elseif node.is_sphere then
			hit = intersect.ray_sphere(ray, node:get_world_position(), node.radius)
		elseif node.is_capsule then
			local p0, p1 = node:get_hemisphere_centers()
			hit = intersect.ray_capsule(ray, p0, p1, node.radius)
		end
		if hit then
			node.material:set('baseColor', {1, 0.3, 0.6, 1})
		end
	end)

	-- Reset player if they fall off the world
	if self.player_capsule.position.y < -4 then
		self.player_capsule:set_position(0, 3, 0)
	end
end

function scene:update_camera()
	local q = quat.from_euler_angles(0, math.rad(self.x_angle), math.rad(self.y_angle)) * vec3.unit_z * self.view_scale
	local v = self.player_capsule.position
	self.camera.center = v
	self.camera.eye = q + v
	self.camera:update_view_matrix()

	self.environment:set_vector('view_position', self.camera.eye)
	self.player_capsule:set_rotation(quat.from_euler_angles(0, math.rad(self.x_angle), 0))
end

-- camera control
function scene:mousemoved(x, y, dx, dy)
	if love.mouse.isDown(2) then
		self.y_angle = self.y_angle - dy * 0.2
		self.x_angle = self.x_angle - dx * 0.2
		self.y_angle = ml_utils.clamp(self.y_angle, -45, 45)
	end
end

function scene:wheelmoved(x, y)
	self.view_scale = self.view_scale - y * 0.2
end

return scene