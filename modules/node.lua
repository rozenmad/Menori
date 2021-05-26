--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2020
-------------------------------------------------------------------------------
--]]

--- Base class of Node.
--- Mixin this class to your game object.
--- Transform class included (see transform).
-- @module Node
local class		= require 'menori.modules.libs.class'
local ml 		= require 'menori.modules.ml'
local mat4		= ml.mat4

local node = class('Node')
node.layer = 0

--- Constructor for mixin.
function node:constructor()
	self.childs = {}
	self.parent = nil

	self.detach_flag = false
	self.update_flag = true
	self.render_flag = true

	self.local_matrix = mat4()
	self.world_matrix = mat4()
end

function node:update_transform()
	self:update_local_transform()
	for _, v in ipairs(self.childs) do
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
	assert(index <= #self.childs and index > 0, 'child index out of range')
	return self.childs[index]
end

--- Remove all childs from this node.
function node:remove_childs()
	for i = #self.childs, 1, -1 do
		self.childs[i].parent = nil
		self.childs[i] = nil
	end
end

--- Attach child to this node.
-- @treturn Node,...
function node:attach(node)
	--[[for i, node in ipairs({...}) do
		self.childs[#self.childs + 1] = node
		node.parent = self
	end
	return ...]]
	self.childs[#self.childs + 1] = node
	node.parent = self
	return node
end

--- Detach child from this node.
function node:detach(child)
	for i, v in ipairs(self.childs) do
		if v == child then
			table.remove(self.childs, i)
		end
	end
end

function node:map_recursive(cb)
	for i, v in ipairs(self.childs) do
		cb(v, i)
		v:map_recursive(cb)
	end
end

--- Detach this node from parent.
function node:detach_from_parent()
	node.parent = nil
	self.detach_flag = true
end

function node:childs_count()
	return #self.childs
end

--- Print all childs of this node.
function node:debug_print(node, tabs)
	node = node or self
	tabs = tabs or ''
	print(tabs .. '-> ' .. string.format('Node: %s Child count: %i', node, #node.childs))
	tabs = tabs .. '\t'
	for i, v in ipairs(node.childs) do
		self:debug_print(v, tabs)
	end
end

return node