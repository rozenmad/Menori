-- Minimal example of using Menori
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

--class inherited from Scene.
local scene = menori.Scene:extend('minimal_scene')

function scene:init()
	scene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local gltf = menori.glTFLoader.load('examples/assets/etrian_odyssey_3_monk.glb')

	-- build a scene node tree from the gltf data and initialize the animations
	local scenes = menori.NodeTreeBuilder.create(gltf, function (scene, builder)
		self.animations = menori.glTFAnimations(builder.animations)
		self.animations:set_action(1)
	end)

	-- adding scene to the root node.
	self.root_node:attach(scenes[1])
	self.angle = 0
end

function scene:render()
	love.graphics.clear(0.3, 0.25, 0.2)
	-- recursively draw the scene nodes
	self:render_nodes(self.root_node, self.environment, {
		node_sort_comp = menori.Scene.alpha_mode_comp
	})
end

function scene:update(dt)
	-- recursively update the scene nodes
	self:update_nodes(self.root_node, self.environment)
	self.angle = self.angle + 0.25

	-- rotate the camera
	local q = quat.from_euler_angles(0, math.rad(self.angle), math.rad(10)) * vec3.unit_z * 2.0
	local v = vec3(0, 0.5, 0)
	self.camera.center = v
	self.camera.eye = q + v
	self.camera:update_view_matrix()

	-- updating scene animations
	self.animations:update(dt)
end

return scene