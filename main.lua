local menori = require 'menori'
local app = menori.app

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat

-- Class inherited from UniformList for a light source.
local PointLight = menori.UniformList:extend('PointLight')
function PointLight:init(x, y, z, r, g, b)
	PointLight.super.init(self)

	self:set('position', {x, y, z})
	self:set('constant', 1.0)
	self:set('linear', 0.3)
	self:set('quadratic', 0.032)
	self:set('ambient', {r, g, b})
	self:set('diffuse', {r, g, b})
	self:set('specular', {r, g, b})
end

local NewScene = menori.Scene:extend('NewScene')

function NewScene:init()
	NewScene.super.init(self)

	local _, _, w, h = menori.app:get_viewport()
	self.camera = menori.PerspectiveCamera(60, w/h, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	-- Adding light sources.
	self.environment:add_light('point_lights', PointLight(0, 0.2, 2, 0.8, 0.3, 0.1))
	self.environment:add_light('point_lights', PointLight(2,   1,-1, 0.1, 0.3, 0.8))

	self.root_node = menori.Node()
	self.aabb_root = self.root_node:attach(menori.Node())

	-- Loading the fragment shader code for lighting.
	local lighting_frag = menori.utils.shader_preprocess(love.filesystem.read('example_assets/lighting_frag.glsl'))
	local lighting_shader = love.graphics.newShader(menori.ShaderUtils.cache['default_mesh_vert'], lighting_frag)
	local lighting_skinning_shader = love.graphics.newShader(menori.ShaderUtils.cache['default_mesh_skinning_vert'], lighting_frag)

	-- Loading models from a GLTF.
	local gltf1 = menori.glTFLoader.load('example_assets/etrian_odyssey_3_monk/scene.gltf')
	local scenes1 = menori.NodeTreeBuilder.create(gltf1, function (scene, builder)
		-- Callback for each scene in the gltf.

		-- Creating a gltf animation.
		self.animations = menori.glTFAnimations(builder.animations)
		self.animations:set_action(1)

		-- Traverse each node in the scene.
		scene:traverse(function (node)
			if node.mesh then
				if node.joints then
					node.material.shader = lighting_skinning_shader
				else
					node.material.shader = lighting_shader
				end
			end
		end)
      end)

	local gltf2 = menori.glTFLoader.load('example_assets/players_room_model/scene.gltf')
	local scenes2 = menori.NodeTreeBuilder.create(gltf2, function (scene, builder)
		-- Create AABB for each node and add it to the aabb_root node.
		scene:traverse(function (node)
			if node.mesh then
				node.material.shader = lighting_shader

				local bound = node:get_aabb()
				local size = bound:size()
				local boxshape = menori.BoxShape(size.x, size.y, size.z)
				local material = menori.Material()
				material.wireframe = true
				material.mesh_cull_mode = 'none'
				material.alpha_mode = 'BLEND'
				material:set('baseColor', {1.0, 1.0, 0.0, 0.12})
				local t = menori.ModelNode(boxshape, material)
				t:set_position(bound:center())
				self.aabb_root:attach(t)
			end
		end)
      end)

	-- Changing transformations of the first model.
	scenes1[1]:set_scale(2, 2, 2)
	scenes1[1]:set_rotation(quat.from_angle_axis(math.rad(45), vec3.unit_y))
	scenes1[1]:set_position(-2, 0, -0.5)

	-- Adding scenes to the root node for rendering.
	self.root_node:attach(scenes1[1])
	self.root_node:attach(scenes2[1])

	self.x_angle = -30
	self.y_angle = 0
	self.view_scale = 10
end

function NewScene:render()
	love.graphics.clear(0.3, 0.25, 0.2)

	-- Recursively draw all the nodes that were attached to the root node.
	-- Sorting nodes by transparency.
	self:render_nodes(self.root_node, self.environment, {
		node_sort_comp = menori.Scene.alpha_mode_comp
	})
end

function NewScene:update_camera()
	self.y_angle = self.y_angle + 0.0
	local q = quat.from_euler_angles(0, math.rad(self.y_angle), math.rad(self.x_angle)) * vec3.unit_z * self.view_scale
	local v = vec3(0, 0.5, 0)
	self.camera.center = v
	self.camera.eye = q + v
	self.camera:update_view_matrix()

	self.environment:set_vector('view_position', self.camera.eye)
end

-- Camera Control.
function NewScene:mousemoved(x, y, dx, dy)
	if love.mouse.isDown(2) then
		love.mouse.setRelativeMode(true)
      	self.y_angle = self.y_angle - dx * 0.2

		if dy > 0 and self.x_angle < 45 then
                  self.x_angle = self.x_angle + dy * 0.1
            end
            if dy < 0 and self.x_angle >-45 then
                  self.x_angle = self.x_angle + dy * 0.1
            end
	else
		love.mouse.setRelativeMode(false)
	end
end

function NewScene:wheelmoved(x, y)
      self.view_scale = self.view_scale - y * 0.2
end

function NewScene:update()
	self:update_camera()

	-- Recursively update all the nodes that were attached to the root node.
	self:update_nodes(self.root_node, self.environment)

	-- Updating the gltf animation.
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
end

function love.update(dt)
	app:update(dt)

	if love.keyboard.isDown('escape') then
		love.event.quit()
	end
end

function love.mousemoved(...)
      menori.app:handle_event('mousemoved', ...)
end

function love.wheelmoved(...)
      menori.app:handle_event('wheelmoved', ...)
end