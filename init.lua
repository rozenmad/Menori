--[[
-------------------------------------------------------------------------------
	Menori
	LÖVE library for simple 3D and 2D rendering based on scene graph.
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

local modules = 'menori.modules.'

local menori = {
	PerspectiveCamera = require(modules .. 'core3d.camera'),
	Environment       = require(modules .. 'core3d.environment'),
	glTFLoader        = require(modules .. 'core3d.gltf'),
	Model             = require(modules .. 'core3d.model'),
	ModelNode         = require(modules .. 'core3d.model_node'),
	ModelNodeTree     = require(modules .. 'core3d.model_node_tree'),
	GeometryBuffer    = require(modules .. 'core3d.geometry_buffer'),
	InstancedMesh     = require(modules .. 'core3d.instanced_mesh'),
	AnimationList     = require(modules .. 'animationlist'),
	Camera            = require(modules .. 'camera'),
	ImageLoader       = require(modules .. 'imageloader'),
	Input             = require(modules .. 'input'),
	Node              = require(modules .. 'node'),
	Scene             = require(modules .. 'scene'),
	ShaderObject      = require(modules .. 'shaderobject'),
	Application       = require(modules .. 'application'),
	Sprite            = require(modules .. 'sprite'),
	SpriteLoader      = require(modules .. 'spriteloader'),
	Script            = require(modules .. 'script'),

	class             = require(modules .. 'libs.class'),
	ml                = require(modules .. 'ml'),
}

return menori