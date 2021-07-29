--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Tree structure that is used when drawing scenes imported from the *gltf format.
]]
-- @module menori.ModelNodeTree

local modules = (...):match('(.*%menori.modules.)')

local Node = require (modules .. '.node')
local ModelNode = require (modules .. 'core3d.model_node')
local Mesh = require (modules .. 'core3d.mesh')

local ml = require (modules .. 'ml')
local mat4 = ml.mat4
local vec3 = ml.vec3
local quat = ml.quat

local ModelNodeTree = Node:extend('ModelNodeTree')

local function set_transform(node, v)
      if v.translation or v.rotation or v.scale then
            local t = v.translation or {0, 0, 0}
            local r = v.rotation or {0, 0, 0, 1}
            local s = v.scale or {1, 1, 1}
            node:set_position(t[1], t[2], t[3])
            node:set_rotation(quat(r[1], r[2], r[3], r[4]))
            node:set_scale(s[1], s[2], s[3])
	elseif v.matrix then
            local t = vec3()
            local r = quat()
            local s = vec3()
		mat4(v.matrix):decompose(t, r, s)
            node:set_position(t)
            node:set_rotation(r)
            node:set_scale(s)
	end
end

--- init. Takes as arguments a list of nodes and scenes loaded with glTFLoader.
-- @tparam table nodes
-- @tparam table scenes
function ModelNodeTree:init(gltf, shader)
      ModelNodeTree.super.init(self)
      self._nodes = gltf.nodes

      for _, v in ipairs(gltf.nodes) do
            local node
            if v.mesh then
                  local mesh = gltf.meshes[v.mesh + 1]
                  node = ModelNode(Mesh(mesh), shader)
                  set_transform(node, v)
            else
                  node = Node()
                  set_transform(node, v)
            end
            node.name = v.name
            v.node = node
      end

      for _, v in ipairs(gltf.nodes) do
            if v.children then
                  for _, child_index in ipairs(v.children) do
                        local child = gltf.nodes[child_index + 1]
                        v.node:attach(child.node)
                  end
            end
      end

      self.scenes = {}
      for i, v in ipairs(gltf.scenes) do
            local scene_node = Node()
            scene_node.name = v.name
            self.scenes[i] = scene_node
            for _, node_index in ipairs(v.nodes) do
                  scene_node:attach(gltf.nodes[node_index + 1].node)
            end
      end

      local first = self.scenes[1]
      if first then
            first:update_transform()
            self:attach(first)
      end
end

--- Set scene by name.
-- @tparam string name
function ModelNodeTree:set_scene_by_name(name)
      self:remove_childs()
      for _, v in ipairs(self.scenes) do
            if v.name == name then
                  self:attach(v)
            end
      end
end

--- Find a node by name.
-- @tparam string name
function ModelNodeTree:find(name)
      for _, v in ipairs(self._nodes) do
            if v.name == name then
                  return v.node
            end
      end
end

return ModelNodeTree