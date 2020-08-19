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
local matrix4x4 = require 'menori.modules.libs.matrix4x4'

local node = class('Node')
node.layer = 0

--- Constructor for mixin.
function node:constructor()
	self._childs = {}
	self._parent = nil

	self.detach_flag = false
	self.update_flag = true
	self.render_flag = true

	self.local_matrix = matrix4x4()
	self.world_matrix = matrix4x4()
end

function node:update_transform(_child)
	if self._parent then self._parent:update_transform(self) end
	if self.local_matrix:is_changed() then
		self:update_local_transform()
		if _child then _child.local_matrix._changed = true end
	end
end

function node:update_local_transform()
	local local_matrix = self.local_matrix
	local world_matrix = self.world_matrix

	local parent = self._parent
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
	assert(index <= #self._childs and index > 0, 'child index out of range')
	return self._childs[index]
end

--- Remove all childs from this node.
function node:remove_childs()
	for i = #self._childs, 1, -1 do
		self._childs[i]._parent = nil
		self._childs[i] = nil
	end
end

--- Attach child to this node.
-- @treturn Node,...
function node:attach(node)
	--[[for i, node in ipairs({...}) do
		self._childs[#self._childs + 1] = node
		node._parent = self
	end
	return ...]]
	self._childs[#self._childs + 1] = node
	node._parent = self
	return node
end

--- Detach child from this node.
function node:detach(child)
	for i, v in ipairs(self._childs) do
		if v == child then
			table.remove(self._childs, i)
		end
	end
end

function node:map_recursive(cb)
	for i, v in ipairs(self._childs) do
		cb(v, i)
		v:map_recursive(cb)
	end
end

--- Detach this node from parent.
function node:detach_from_parent()
	node._parent = nil
	self.detach_flag = true
end

function node:childs_count()
	return #self._childs
end

--- Print all childs of this node.
function node:debug_print(node, tabs)
	node = node or self
	tabs = tabs or ''
	print(tabs .. '-> ' .. string.format('Node: %s Child count: %i', node, #node._childs))
	tabs = tabs .. '\t'
	for i, v in ipairs(node._childs) do
		self:debug_print(v, tabs)
	end
end

return node