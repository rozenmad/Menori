-- Raycast BVH Menori Example
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
local ml_utils = ml.utils

local tips = {
	{ text = "Debug BVH (press Q): ", key = 'q', boolean = true },
}

local scene = menori.Scene:extend('raycast_bvh_scene')

local function debug_bvh(tree, aabb_root)
	local nodes = {tree.root_node}
      while #nodes > 0 do
            local node = table.remove(nodes)
            if node:element_count() > 0 then
			local size = node.extents:size()
			local boxshape = menori.BoxShape(size.x, size.y, size.z)
			local material = menori.Material()
			material.wireframe = true
			material.mesh_cull_mode = 'none'
			material.alpha_mode = 'BLEND'
			material:set('baseColor', {1.0, 1.0, 1.0, 1.0})
			local t = menori.ModelNode(boxshape, material)
			t:set_position(node.extents:center())
			aabb_root:attach(t)
            end
            if node._node0 then
                  nodes[#nodes+1] = node._node0
            end
            if node._node1 then
                  nodes[#nodes+1] = node._node1
            end
      end
end

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()
	self.aabb_root = self.root_node:attach(menori.Node())

	local boxshape = menori.BoxShape(0.2, 0.2, 0.2)
	local material = menori.Material()
	material:set('baseColor', {1.0, 1.0, 0.0, 1.0})
	self.box = menori.ModelNode(boxshape, material)
	self.root_node:attach(self.box)

	local gltf = menori.glTFLoader.load('examples/assets/pokemon_firered_-_players_room.glb')
	local scenes = menori.NodeTreeBuilder.create(gltf, function (scene, builder)
		-- Create BVH for each mesh node.
		scene:traverse(function (node)
			if node.is_model_node then
				node.bvh = ml.bvh(node, 10)
				debug_bvh(node.bvh, self.aabb_root)
			end
		end)
	end)

	self.root_node:attach(scenes[1])

	self.x_angle = 0
	self.y_angle = -30
	self.view_scale = 10
end

function scene:render()
	love.graphics.clear(0.3, 0.25, 0.2)

	-- Recursively draw all the nodes that were attached to the root node.
	-- Sorting nodes by transparency.
	self:render_nodes(self.root_node, self.environment, {
		node_sort_comp = menori.Scene.alpha_mode_comp
	})

	love.graphics.setColor(1, 0.1, 0.2, 0.5)

	-- Convert the position of the box from world coordinates to screen coordinates and draw a circle.
	local screen_space_pos = self.camera:world_to_screen_point(self.box:get_world_position())
	love.graphics.circle('line', screen_space_pos.x, screen_space_pos.y, 32)

	-- Draw tips on the screen.
	love.graphics.setColor(1, 0.5, 0, 1)
	local y = 45
	for _, v in ipairs(tips) do
		love.graphics.print(v.text .. (v.boolean and "On" or "Off"), 10, y)
		y = y + 15
	end
	love.graphics.print("Click the left mouse button to place the box.", 10, y+0)
	love.graphics.print("Hold the right mouse button to rotate the camera.", 10, y+40)
end

function scene:update_camera()
	local q = quat.from_euler_angles(0, math.rad(self.x_angle), math.rad(self.y_angle)) * vec3.unit_z * self.view_scale
	local v = vec3(0, 0.5, 0)
	self.camera.center = v
	self.camera.eye = q + v
	self.camera:update_view_matrix()

	self.environment:set_vector('view_position', self.camera.eye)
end

function scene:mousepressed(x, y, button, istouch, presses)
	-- Placing the box at the last intersection point with the mesh.
	if button == 1 and self.box.render_flag then
		local boxshape = menori.BoxShape(0.2, 0.2, 0.2)
		local material = menori.Material()
		local r = love.math.random()
		local g = love.math.random()
		local b = love.math.random()
		material:set('baseColor', {r, g, b, 1.0})
		self.box = menori.ModelNode(boxshape, material)
		self.root_node:attach(self.box)
	end
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

function scene:update()
	self:update_camera()
	self:update_nodes(self.root_node, self.environment)

	-- Convert screen point to ray.
	local mx, my = love.mouse.getPosition()
	local ray = self.camera:screen_point_to_ray(mx, my)

	-- Check the intersection of the ray with each node-mesh containing the BVH.
	local intersect_list = {}
	self.root_node:traverse(function (node)
		if node.bvh then
			local t = node.bvh:intersect_ray(ray)
			if #t > 0 then
				table.insert(intersect_list, t[1])
			end
		end
	end)

	-- Sorted by distance.
	table.sort(intersect_list, function (a, b)
		return a.t < b.t
	end)

	-- Set the position of the box at the intersection point of the ray and the mesh.
	local p = intersect_list[1]
	if p then
		self.box.render_flag = true
		self.box:set_position(p.point)
	else
		self.box.render_flag = false
	end

	self.aabb_root.render_flag = tips[1].boolean
end

function scene:keyreleased(key)
	for _, v in ipairs(tips) do
		if key == v.key then
			v.boolean = not v.boolean
		end
	end
end

return scene