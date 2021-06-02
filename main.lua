local menori = require 'menori'
local application = menori.Application

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat

local love_logo = menori.ImageLoader.load('example_assets/love_logo.png')

-- Creating a node for drawing an object.
local SpriteNode = menori.Node:extend('SpriteNode')

function SpriteNode:constructor(x, y, sx, sy, speed)
	-- Calling the parent's constructor.
	SpriteNode.super.constructor(self)
	-- Creating a sprite object from an image.
	self.sprite = menori.SpriteLoader.from_image(love_logo)
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
	-- we can also pass transformations to this function
	-- like this:
	-- self.sprite:draw(0, 0, 0, 1, 1)

	love.graphics.pop()
end
function SpriteNode:update()
	self.angle = self.angle + self.speed

	self.local_matrix:identity()
	self.local_matrix:translate(self.x, self.y, 0)
	self.local_matrix:rotate(math.rad(self.angle), vec3.unit_z)
	self.local_matrix:scale(self.sx, self.sy, 1)
end

local PointLight = menori.UniformList:extend('PointLight')
PointLight.name = 'point_lights'
function PointLight:constructor(x, y, z, r, g, b, sr, sg, sb)
	PointLight.super.constructor(self)

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

function NewScene:constructor()
	-- Calling the parent's constructor.
	NewScene.super.constructor(self)

	local shader_code = love.filesystem.read('example_assets/lighting.glsl')
	local shader_lighting = love.graphics.newShader(menori.utils.shader_preprocess(shader_code))

	-- An example of creating a primitive.
	local vx = 1
	local vz = 1

	local vertices = {
		{-vx, 0,-vz, 0, 0, 0, 1, 0 },
		{-vx, 0, vz, 0, 1, 0, 1, 0 },
		{ vx, 0,-vz, 1, 0, 0, 1, 0 },
		{ vx, 0, vz, 1, 1, 0, 1, 0 }
	}
	local indices = menori.Model.generate_indices(#vertices)

	-- default mesh format POS3|TEX2|NOR3
	local primitive = menori.Model.create_primitive(
		vertices, indices, #vertices, love_logo
	)

	-- Create a model instance from a primitive
	local model_instance = menori.Model(primitive)

	-- Now you can use an model instance for every new node.
	local quadmesh1 = menori.ModelNode(model_instance, nil, shader_lighting)
	local quadmesh2 = menori.ModelNode(model_instance, nil, shader_lighting)
	quadmesh1.local_matrix:translate(5, 0.1,-2)
	quadmesh2.local_matrix:translate(2, 0.1, 2)

	-- Initializing the perspective camera and environment.
	local aspect = menori.Application.w/menori.Application.h
	self.camera_3d = menori.PerspectiveCamera(35, aspect, 0.5, 1024)
	self.environment_3d = menori.Environment(self.camera_3d)

	self.camera_2d = menori.Camera()
	self.environment_2d = menori.Environment(self.camera_2d)

	self.environment_3d:add_light('point_lights', PointLight(-2, 1,-1, 0.8, 0.2, 0.1))
	self.environment_3d:add_light('point_lights', PointLight( 2, 1,-1, 0.1, 0.6, 0.9))

	-- Creating and attaching nodes to each other.
	local sprite_node = SpriteNode(100, 100, 1, 1, 1)
	local child1 = sprite_node:attach(SpriteNode(150, 50, 0.5, 0.5, 3))
	local child2 = child1:attach(SpriteNode(200, 0, 0.5, 0.5, -6))

	-- Load the scene from gltf format, get a table of nodes and scenes contained in the file.
	local nodes, scenes = menori.glTFLoader.load('example_assets/players_room_model/', 'scene')

	local model_node_tree = menori.ModelNodeTree(nodes, scenes, shader_lighting)

	-- Create a root node and add the loaded scene to it.
	self.root_node_3d = menori.Node()
	self.root_node_3d:attach(model_node_tree)
	self.root_node_3d:attach(quadmesh1)
	self.root_node_3d:attach(quadmesh2)

	self.root_node_2d = menori.Node()
	self.root_node_2d:attach(sprite_node)

	-- Camera rotation angle.
	self.angle = -90
end

-- Turn on the depth buffer, clear the canvases and set the color.
local renderstates = {
	depth = true
}

function NewScene:render()
	love.graphics.clear(0.15, 0.1, 0.1)
	love.graphics.setDepthMode('less', true)
	-- Recursively draw all nodes in root_node.
	self:render_nodes(self.root_node_3d, self.environment_3d, renderstates)

	love.graphics.setDepthMode()

	self:render_nodes(self.root_node_2d, self.environment_2d, renderstates)
end

function NewScene:update_camera()
	-- Rotating the camera around the model.
	self.angle = self.angle + 0.2
	local q = quat.from_euler_angles(math.rad(self.angle), math.rad(35), 0)
	local v = vec3(14, 0, 0)
	self.camera_3d.eye = q * v
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