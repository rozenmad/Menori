--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

local class = require 'menori.modules.libs.class'

local Node = require 'menori.modules.node'
local ModelNode = require 'menori.modules.core3d.model_node'
local Model = require 'menori.modules.core3d.model'

local ml = require 'menori.modules.ml'
local mat4 = ml.mat4
local vec3 = ml.vec3
local quat = ml.quat

local ModelNodeTree = class('ModelNodeTree')

local function create_transform_matrix(node)
      local m
      if node.translation and node.rotation and node.scale then
		m = mat4()
		m:set_position_and_rotation(vec3(node.translation), quat(node.rotation))
		m:scale(vec3(node.scale))
	else
		m = mat4(node.matrix)
	end
      return m
end

function ModelNodeTree:constructor(nodes)
      for i, v in ipairs(nodes) do
            local node
            if v.primitives then
                  node = ModelNode(Model(v))
                  local m = create_transform_matrix(v)
                  node.local_matrix:copy(m)
            else
                  node = Node()
                  local m = create_transform_matrix(v)
                  node.local_matrix:copy(m)
            end
            v.node = node
      end

      for i, v in ipairs(nodes) do
            if v.children then
                  for _, child_index in ipairs(v.children) do
                        local child = nodes[child_index + 1]
                        v.node:attach(child.node)
                  end
            end
      end

      self.root = nodes[1].node
end

return ModelNodeTree