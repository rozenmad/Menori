local menori = require 'menori'
local application = menori.Application
local app = menori.app

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat
local mat4 = ml.mat4

local NewScene = menori.Scene:extend('NewScene')

function NewScene:init()
	NewScene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	self.root_node = menori.Node()

	local gltf = menori.glTFLoader.load('example_assets/pokemon_rse_-_pokemon_center.glb')
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
	self.y_angle = self.y_angle + 0.2
	local q = quat.from_euler_angles(0, math.rad(self.y_angle), math.rad(-30)) * vec3.unit_z * 3.0
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
	local w, h = 960, 480
	app:add_scene('new_scene', NewScene())
	app:set_scene('new_scene')

	canvas = love.graphics.newCanvas(w, h)
	sprite = menori.SpriteLoader.from_image(canvas)
end

function love.draw()
	love.graphics.setCanvas({ canvas, depth = true })
	app:render()
	love.graphics.setCanvas()

	local w, h = love.graphics.getDimensions()
	sprite:draw_ex(w/2, h/2, 'min', w, h, 0.5, 0.5)

      love.graphics.print(love.timer.getFPS(), 10, 10)
end

function love.update(dt)
	app:update(dt)

	if love.keyboard.isDown('escape') then
		love.event.quit()
	end
end