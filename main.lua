local menori = require 'menori'
local application = menori.Application

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat

local NewScene = menori.Scene:extend('NewScene')

function NewScene:init()
	NewScene.super.init(self)

	local aspect = menori.Application.w/menori.Application.h
	self.camera = menori.PerspectiveCamera(60, aspect, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local gltf = menori.glTFLoader.load('example_assets/etrian_odyssey_3_monk/scene.gltf')
	local scenes = menori.NodeTreeBuilder.create(gltf, function (scene, builder)
		self.animations = menori.glTFAnimations(builder.animations)
		self.animations:set_action(1)

		scene:traverse(function (node)
			if node.mesh then
				--local bound = node:get_aabb()
				--local size = bound:size()
				--local boxshape = menori.BoxShape(size.x, size.y, size.z)
				--local material = menori.Material()
				--material.wireframe = true
				--material.mesh_cull_mode = 'none'
				--material:set('baseColor', {1, 1, 1, 1})
				--local t = menori.ModelNode(boxshape, material)
				--t:set_position(bound:center())
				--self.root_node:attach(t)
			end
		end)
      end)

	self.root_node:attach(scenes[1])

	self.y_angle = 20
end


function NewScene:render()
	love.graphics.clear(0.3, 0.25, 0.2)

	self:render_nodes(self.root_node, self.environment, {
		node_sort_comp = menori.Scene.alpha_mode_comp
	})
end

function NewScene:update_camera()
	local q = quat.from_euler_angles(0, math.rad(self.y_angle), math.rad(10)) * vec3.unit_z * 2.0
	local v = vec3(0, 0.6, 0)
	self.camera.center = v
	self.camera.eye = q + v
	self.camera:update_view_matrix()
end

function NewScene:update()
	self:update_camera()
	self:update_nodes(self.root_node, self.environment)

	self.animations:update(0.016)
end

function love.load()
	local w, h = 960, 540
	application:resize_viewport(w*2, h*2)

	application:add_scene('new_scene', NewScene())
	application:set_scene('new_scene')
end

function love.draw()
	application:render()
      love.graphics.print(love.timer.getFPS(), 10, 10)
end

function love.update(dt)
	application:update(dt)

	if love.keyboard.isDown('escape') then
		love.event.quit()
	end
end