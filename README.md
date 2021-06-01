# Menori

LÖVE library for simple 3D and 2D rendering based on scene graph. Loading of 3D models in .gltf (JSON) format is also supported.

![preview_example](preview.png)

[Documentation](https://rozenmad.github.io)

You can generate documentation using `ldoc -c menori/docs/config.ld -o index .`

# Usage Example

``` lua
local menori = require 'menori'
local application = menori.Application

local ml = menori.ml
local vec3 = ml.vec3
local quat = ml.quat

local NewScene = menori.Scene:extend('NewScene')

function NewScene:constructor()
	NewScene.super.constructor(self)

	local aspect = menori.Application.w/menori.Application.h
	self.camera = menori.PerspectiveCamera(60, aspect, 0.5, 1024)
	self.environment = menori.Environment(self.camera)

	local nodes, scenes = menori.glTFLoader.load('example_assets/players_room_model/', 'scene')
	local model_node_tree = menori.ModelNodeTree(nodes, scenes)

	self.root_node = menori.Node()
	self.root_node:attach(model_node_tree)

	self.y_angle = 0
end

function NewScene:render()
	love.graphics.clear(0.3, 0.25, 0.2)

	love.graphics.setDepthMode('less', true)
	self:render_nodes(self.root_node, self.environment)
	love.graphics.setDepthMode()
end

function NewScene:update_camera()
	self.y_angle = self.y_angle + 0.5
	local q = quat.from_euler_angles(math.rad(self.y_angle), math.rad(25), 0)
	self.camera:set_direction(q * vec3(10, 0, 0))
	self.camera:update_view_matrix()
end

function NewScene:update()
	self:update_camera()
	self:update_nodes(self.root_node, self.environment)
end

function love.load()
	local w, h = 960, 480
	application:resize_viewport(w, h)

	application:add_scene('new_scene', NewScene())
	application:set_scene('new_scene')
end

function love.draw()
	application:render()
end

function love.update(dt)
	application:update(dt)
end
```

See ```main.lua``` for a more complete example.

# License
MIT