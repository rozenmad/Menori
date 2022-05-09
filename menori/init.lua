--[[
-------------------------------------------------------------------------------
	Menori
	LÖVE library for simple 3D and 2D rendering based on scene graph.
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]
----
-- @module menori

local modules = (...) and (...):gsub('%.init$', '') .. ".modules." or ""

--- Namespace for all modules in library.
-- @table menori
local menori = {
	PerspectiveCamera = require(modules .. 'core3d.camera'),
	Environment       = require(modules .. 'core3d.environment'),
	UniformList       = require(modules .. 'core3d.uniform_list'),
	glTFLoader        = require(modules .. 'core3d.gltf'),
	Material          = require(modules .. 'core3d.material'),
	Mesh              = require(modules .. 'core3d.mesh'),
	ModelNode         = require(modules .. 'core3d.model_node'),
	ModelNodeTree     = require(modules .. 'core3d.model_node_tree'),
	GeometryBuffer    = require(modules .. 'core3d.geometry_buffer'),
	InstancedMesh     = require(modules .. 'core3d.instanced_mesh'),
	AnimationList     = require(modules .. 'animationlist'),
	Camera            = require(modules .. 'camera'),
	Node              = require(modules .. 'node'),
	Scene             = require(modules .. 'scene'),
	Application       = require(modules .. 'application'),
	Sprite            = require(modules .. 'sprite'),
	SpriteLoader      = require(modules .. 'spriteloader'),
	Script            = require(modules .. 'script'),

	utils             = require(modules .. 'libs.utils'),
	class             = require(modules .. 'libs.class'),
	ml                = require(modules .. 'ml'),
}

return menori