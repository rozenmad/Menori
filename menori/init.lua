--[[
-------------------------------------------------------------------------------
      Menori
      LÖVE library for simple 3D and 2D rendering based on scene graph.
      @author rozenmad
      2023
-------------------------------------------------------------------------------
--]]
----
-- @module menori

local modules = (...) and (...):gsub('%.init$', '') .. ".modules." or ""

--- Namespace for all modules in library.
-- @table menori
local menori = {
      PerspectiveCamera      = require(modules .. 'core3d.camera'),
      Environment            = require(modules .. 'core3d.environment'),
      UniformList            = require(modules .. 'core3d.uniform_list'),
      glTFAnimations         = require(modules .. 'core3d.gltf_animations'),
      glTFLoader             = require(modules .. 'core3d.gltf'),
      Material               = require(modules .. 'core3d.material'),
      BoxShape               = require(modules .. 'core3d.boxshape'),
      Mesh                   = require(modules .. 'core3d.mesh'),
      ModelNode              = require(modules .. 'core3d.model_node'),
      NodeTreeBuilder        = require(modules .. 'core3d.node_tree_builder'),
      InstancedMesh          = require(modules .. 'core3d.instanced_mesh'),
      Camera                 = require(modules .. 'camera'),
      Node                   = require(modules .. 'node'),
      Scene                  = require(modules .. 'scene'),
      Sprite                 = require(modules .. 'sprite'),
      SpriteUtils            = require(modules .. 'spriteutils'),
      Canvas                 = require(modules .. 'canvas'),

      ShaderUtils            = require(modules .. 'shaders.utils'),

      scenemanager           = require(modules .. 'scenemanager'),
      utils                  = require(modules .. 'libs.utils'),
      class                  = require(modules .. 'libs.class'),
      ml                     = require(modules .. 'ml'),
}

return menori