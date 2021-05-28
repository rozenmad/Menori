--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Description
]]
-- @module menori.Node

local modules = (...):match('(.*%menori.modules.)')

local class = require (modules .. 'libs.class')
local ml    = require (modules .. 'ml')
local mat4  = ml.mat4

local node = class('Node')
node.layer = 0

--- Constructor.
function node:constructor()
	self.children = {}
	self.parent = nil

	self.detach_flag = false
	self.update_flag = true
	self.render_flag = true

	self.local_matrix = mat4()
	self.world_matrix = mat4()
end

function node:update_transform()
	self:update_local_transform()
	for _, v in ipairs(self.children) do
		v:update_local_transform()
	end
end

function node:update_local_transform()
	local local_matrix = self.local_matrix
	local world_matrix = self.world_matrix

	local parent = self.parent
	if parent then
		world_matrix:copy(parent.world_matrix)
		world_matrix:multiply(local_matrix)
	else
		world_matrix:copy(local_matrix)
	end
	local_matrix._changed = false
end

--- Get child node by index.
-- @treturn Node
function node:get_child_by_index(index)
	assert(index <= #self.children and index > 0, 'child index out of range')
	return self.children[index]
end

--- Remove all children from this node.
function node:remove_children()
	for i = #self.children, 1, -1 do
		self.children[i].parent = nil
		self.children[i] = nil
	end
end

--- Attach child to this node.
-- @param node
-- @return Node
function node:attach(node)
	--[[for i, node in ipairs({...}) do
		self.children[#self.children + 1] = node
		node.parent = self
	end
	return ...]]
	self.children[#self.children + 1] = node
	node.parent = self
	return node
end

--- Detach child from this node.
function node:detach(child)
	for i, v in ipairs(self.children) do
		if v == child then
			table.remove(self.children, i)
		end
	end
end

function node:map_recursive(callback)
	for i, v in ipairs(self.children) do
		callback(v, i)
		v:map_recursive(callback)
	end
end

--- Detach this node from parent.
function node:detach_from_parent()
	node.parent = nil
	self.detach_flag = true
end

-- The number of children attached to this node.
function node:children_count()
	return #self.children
end

--- Recursively print all the children attached to this node.
-- @param node (nil) by default
-- @param tabs (nil) by default
function node:debug_print(node, tabs)
	node = node or self
	tabs = tabs or ''
	print(tabs .. '-> ' .. string.format('Node: %s Child count: %i', node, #node.children))
	tabs = tabs .. '\t'
	for i, v in ipairs(node.children) do
		self:debug_print(v, tabs)
	end
end

return node