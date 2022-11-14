--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
]]

--[[--
Tree structure that is used when drawing scenes imported from the *gltf format.
(Inherited from menori.Node class)
]]
-- @classmod ModelNodeTree
-- @see Node

local modules = (...):match('(.*%menori.modules.)')

local Node = require (modules .. '.node')
local ModelNode = require (modules .. 'core3d.model_node')
local Mesh = require (modules .. 'core3d.mesh')
local Material = require (modules .. 'core3d.material')

local ml = require (modules .. 'ml')
local mat4 = ml.mat4
local vec3 = ml.vec3
local quat = ml.quat

local NodeTreeBuilder = {}

local function default_callback(node, parent, extras)
      return node
end

local function _create_nodes(builder, nodes, i, callback, parent)
      if not builder.nodes[i] then
            local v = nodes[i]
            local node
            local t = vec3()
            local r = quat(0, 0, 0, 1)
            local s = vec3(1)
            if v.translation or v.rotation or v.scale then
                  t:set(v.translation or {0, 0, 0})
                  r:set(v.rotation or {0, 0, 0, 1})
                  s:set(v.scale or {1, 1, 1})
            elseif v.matrix then
                  mat4(v.matrix):decompose(t, r, s)
            end

            if v.mesh then
                  local mesh = builder.meshes[v.mesh + 1]
                  local material = Material.default
                  local material_index = mesh.primitives[1].material_index
                  if material_index then
                        material = builder.materials[material_index + 1]
                  end
                  node = ModelNode(mesh, material)
            else
                  node = Node()
            end

            node.extras = v.extras

            node:set_position(t)
            node:set_rotation(r)
            node:set_scale(s)
            node = callback(node, parent, v.extras)
            if parent then
                  parent:attach(node)
            end

            node.name = v.name
            builder.nodes[i] = node
            if v.children then
                  for _, child_index in ipairs(v.children) do
                        _create_nodes(builder, nodes, child_index + 1, callback, node)
                  end
            end
      end
end

function NodeTreeBuilder.traverse(gltf, callback)
      callback = callback or default_callback
      local builder = {
            meshes = {}, materials = {}, nodes = {}
      }
      for i, v in ipairs(gltf.meshes) do
            builder.meshes[i] = Mesh(v.primitives)
      end

      for i, v in ipairs(gltf.materials) do
            local material = Material(v.name)
            if v.main_texture then
                  material.main_texture = v.main_texture.source
            end
            for name, uniform in pairs(v.uniforms) do
                  material:set(name, uniform)
            end
            builder.materials[i] = material
      end

      for i, v in ipairs(gltf.nodes) do
            _create_nodes(builder, gltf.nodes, i, callback)
      end

      local scenes = {}
      for i, v in ipairs(gltf.scenes) do
            local scene_node = Node(v.name)
            for _, j in ipairs(v.nodes) do
                  scene_node:attach(builder.nodes[j + 1])
            end
            scenes[i] = scene_node
      end

      return scenes
end

return NodeTreeBuilder