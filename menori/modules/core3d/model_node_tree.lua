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
local Model = require (modules .. 'core3d.model')

local ml = require (modules .. 'ml')
local mat4 = ml.mat4
local vec3 = ml.vec3
local quat = ml.quat

local ModelNodeTree = Node:extend('ModelNodeTree')

local function create_transform_matrix(node)
      local m
      if node.translation or node.rotation or node.scale then
            local t = node.translation or {0, 0, 0}
            local r = node.rotation or {0, 0, 0, 1}
            local s = node.scale or {1, 1, 1}
		m = mat4()
		m:set_position_and_rotation(vec3(t), quat(r))
		m:scale(vec3(s))
	else
		m = mat4(node.matrix)
	end
      return m
end

--- Constructor. Takes as arguments a list of nodes and scenes loaded with glTFLoader.
-- @tparam table nodes
-- @tparam table scenes
function ModelNodeTree:constructor(nodes, scenes, shader)
      ModelNodeTree.super.constructor(self)

      for _, v in ipairs(nodes) do
            local node
            if v.primitives then
                  local m = create_transform_matrix(v)
                  node = ModelNode(Model(v.primitives), m, shader)
            else
                  node = Node()
                  local m = create_transform_matrix(v)
                  node.local_matrix:copy(m)
            end
            v.node = node
      end

      for _, v in ipairs(nodes) do
            if v.children then
                  for _, child_index in ipairs(v.children) do
                        local child = nodes[child_index + 1]
                        v.node:attach(child.node)
                  end
            end
      end

      self.scenes = {}
      for i, v in ipairs(scenes) do
            local scene_node = Node()
            scene_node.name = v.name
            self.scenes[i] = scene_node
            for _, node_index in ipairs(v.nodes) do
                  scene_node:attach(nodes[node_index + 1].node)
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

return ModelNodeTree