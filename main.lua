local menori = require 'menori'
local application = menori.Application

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat

local love_logo_image = love.graphics.newImage('example_assets/love_logo.png')

-- Creating a node for drawing an object.
local SpriteNode = menori.Node:extend('SpriteNode')

function SpriteNode:init(x, y, sx, sy, speed, ox, oy)
	-- Calling the parent's constructor.
	SpriteNode.super.init(self)
	-- Creating a sprite object from an image.
	self.sprite = menori.SpriteLoader.from_image(love_logo_image)
	self.sprite:set_pivot(0.5, 0.5)

	self.x = x
	self.y = y
	self.sx = sx
	self.sy = sy
	self.angle = 0
	self.speed = speed
end

function SpriteNode:render()
	love.graphics.push()
	-- Node contains two matrices.
	-- Local matrix is transformations of the current node.
	-- World matrix is the sum of transformations of the parent nodes.
	-- to_temp_transform_object converts a matrix to LOVE Transform object.
	love.graphics.replaceTransform(self.world_matrix:to_temp_transform_object())

	-- Draw a sprite.
	self.sprite:draw()
	--self.sprite:draw()

	love.graphics.pop()
end
function SpriteNode:update()
	self.angle = self.angle + self.speed

	self:set_position(self.x, self.y, 0)
	self:set_rotation(quat.from_angle_axis(math.rad(self.angle), vec3.unit_z))

	self:set_scale(self.sx, self.sy, self.sx)
end

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

-- Inherit from the scene class and create new scene.
local NewScene = menori.Scene:extend('NewScene')

function NewScene:init()
	-- Calling the parent's constructor.
	NewScene.super.init(self)

	local shader_code = love.filesystem.read('example_assets/lighting.glsl')
	local shader_lighting = love.graphics.newShader(menori.utils.shader_preprocess(shader_code))

	-- An example of creating a mesh.
	local vx = 1
	local vz = 1

	local vertices = {
		{-vx, 0,-vz, 0, 0, 0, 1, 0 },
		{-vx, 0, vz, 0, 1, 0, 1, 0 },
		{ vx, 0,-vz, 1, 0, 0, 1, 0 },
		{ vx, 0, vz, 1, 1, 0, 1, 0 }
	}
	local indices = menori.Mesh.generate_indices(#vertices)

	-- Default mesh format POS3|TEX2|NOR3
	local model_instance = menori.Mesh.from_primitive(vertices, {
		indices = indices, mode = 'triangles'
	})

	-- Creating a material and set it a base texture.
	local material = menori.Material('lighting', shader_lighting)
	material.main_texture = love_logo_image

	-- Now you can use an model instance for every new node.
	-- For each node, its own copy of the material will be created.
	local quadmesh1 = menori.ModelNode(model_instance, material)
	local quadmesh2 = menori.ModelNode(model_instance, material)
	quadmesh1:set_position(5, 0.1,-2)
	quadmesh2:set_position(2, 0.1, 2)

	-- Initializing the perspective camera and environment.
	local aspect = menori.Application.w/menori.Application.h
	self.camera_3d = menori.PerspectiveCamera(35, aspect, 0.5, 1024)
	self.environment_3d = menori.Environment(self.camera_3d)

	-- Adding light sources to the scene.
	self.environment_3d:add_light('point_lights', PointLight(-2, 1,-1, 0.8, 0.2, 0.1))
	self.environment_3d:add_light('point_lights', PointLight( 2, 1,-1, 0.1, 0.6, 0.9))

	self.camera_2d = menori.Camera()
	self.environment_2d = menori.Environment(self.camera_2d)

	-- Creating and attaching nodes to each other.
	local sprite_node = SpriteNode(200, 200, 0.5, 0.5, 0.5)
	self.child1 = sprite_node:attach(SpriteNode(128, 128, 0.5, 0.5, 2))

	-- Load the scene from gltf format, get a table of nodes and scenes contained in the file.
	local gltf = menori.glTFLoader.load('example_assets/players_room_model/scene.gltf')
	for _, v in ipairs(gltf.images) do
		v.source:setFilter('nearest', 'nearest')
	end

	local model_node_tree = menori.ModelNodeTree(gltf, shader_lighting)

	-- Search for a node by name in the hierarchy
	local n = model_node_tree:find('Sketchfab_Scene/Sketchfab_model/fireRed_room.fbx/')
	print(n.name)

	-- Creating a root node and adding the loaded model and other nodes to it.
	self.root_node_3d = menori.Node()
	self.root_node_3d:attach(model_node_tree, quadmesh1, quadmesh2)

	self.root_node_2d = menori.Node()
	self.root_node_2d:attach(sprite_node)

	-- Camera rotation angle.
	self.angle = 0
	self.view_distance = 14
end

-- Turn on the depth buffer, clear the canvases and set the color.
local renderstates = {
	depth = true
}

function NewScene:render()
	love.graphics.clear(0.15, 0.1, 0.1)
	-- Recursively draw all nodes in root_node.
	self:render_nodes(self.root_node_3d, self.environment_3d, renderstates)
	self:render_nodes(self.root_node_2d, self.environment_2d, renderstates)

	love.graphics.setColor(1, 0, 0, 1)
	local v = self.child1:get_world_position()
	love.graphics.rectangle('fill', v.x - 5, v.y - 5, 10, 10)

	local r = self.child1:get_world_rotation()
	local p = r * vec3.unit_x * 100

	love.graphics.rectangle('fill', 200 + p.x - 5, 200 + p.y - 5, 10, 10)
	love.graphics.setColor(1, 1, 1, 1)
end

function NewScene:update_camera()
	-- Rotating the camera around the model.
	self.angle = self.angle + 0.2
	local q = quat.from_euler_angles(0, math.rad(self.angle), math.rad(-35)) * vec3.unit_z * self.view_distance
	self.camera_3d.eye = q
	self.camera_3d.center = vec3(0)
	self.camera_3d:update_view_matrix()

	local uniform_list = self.environment_3d.uniform_list
	uniform_list:set_vector('view_position', self.camera_3d.eye)
end

function NewScene:update()
	self:update_camera()
	-- Recursively update all nodes in root_node.
	self:update_nodes(self.root_node_3d, self.environment_3d)
	self:update_nodes(self.root_node_2d, self.environment_2d)
end

function love.load()
	local w, h = 960, 480
	application:resize_viewport(w*1.5, h*1.5, {filter = 'linear', msaa = 4})

	application:add_scene('new_scene', NewScene())
	application:set_scene('new_scene')
end

function love.draw()
	application:render()
end

function love.update(dt)
	application:update(dt)
end