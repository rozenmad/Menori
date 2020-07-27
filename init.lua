--[[
-------------------------------------------------------------------------------
	Menori
	library for simple 3D rendering in LOVE
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local modules = 'menori.modules.'

local libs = {
	cpml   				= require 'libs.cpml'
}

local menori = {
	PerspectiveCamera	= require(modules .. 'core3d.camera'),
	Environment			= require(modules .. 'core3d.environment'),

	glTFLoader			= require(modules .. 'core3d.gltf'),
	Model				= require(modules .. 'core3d.model'),

	Camera				= require(modules .. 'camera'),
	ImageLoader			= require(modules .. 'imageloader'),
	Input				= require(modules .. 'input'),
	Node				= require(modules .. 'node'),
	Scene				= require(modules .. 'scene'),
	ShaderObject		= require(modules .. 'shaderobject'),
	SceneDispatcher		= require(modules .. 'scenedispatcher'),
	Sprite				= require(modules .. 'sprite'),
	SpriteLoader		= require(modules .. 'spriteloader'),
	Script				= require(modules .. 'script'),

	utils				= require(modules .. 'utils'),
	class				= require(modules .. 'libs.class'),
	matrix4x4			= require(modules .. 'libs.matrix4x4'),

	-- globals --
	libs				= libs,
}

return menori