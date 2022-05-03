--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2021
-------------------------------------------------------------------------------
--]]

--[[--
Node is the base class of all display objects.
Node object can be assigned as a child of another node, resulting in a tree arrangement.
You need to inherit from the Node class to create your own display object.
]]
-- @module menori.Node

local modules = (...):match('(.*%menori.modules.)')

local class  = require (modules .. 'libs.class')
local ml     = require (modules .. 'ml')
local mat4   = ml.mat4
local vec3   = ml.vec3
local quat   = ml.quat
local bound3 = ml.bound3

--- Class members
-- @table Node
-- @field children childen of this node
-- @field parent parent of this node
-- @field detach_flag flag that is used to detach this node from its parent during the next scene update
-- @field update_flag flag that sets whether the node is updated during the scene update pass
-- @field render_flag flag that sets whether the node is rendered during the scene render pass
-- @field local_matrix (read-only) local transformation matrix
-- @field world_matrix (read-only) world transformation matrix based on world (parent) factors.

local node = class('Node')
node.layer = 0

--- init.
function node:init(name)
	self.children = {}
	self.parent = nil
	self.name = name or "node"

	self.detach_flag = false
	self.update_flag = true
	self.render_flag = true
	self.update_transform_flag = true

	self.local_matrix = mat4()
	self.world_matrix = mat4()

	self._transform_flag = true

	self.position = vec3(0)
	self.rotation = quat()
	self.scale    = vec3(1)
end

function node:clone(new_object)
	new_object = new_object or node()
	new_object.parent = self.parent
	new_object.name = self.name

	new_object.detach_flag = self.detach_flag
	new_object.update_flag = self.update_flag
	new_object.render_flag = self.render_flag
	new_object.update_transform_flag = self.update_transform_flag

	new_object.local_matrix:copy(self.local_matrix)
	new_object.world_matrix:copy(self.world_matrix)

	new_object.position:set(self.position)
	new_object.rotation:set(self.rotation)
	new_object.scale:set(self.scale)

	for _, v in ipairs(self.children) do
		local child = v:clone()
		new_object:attach(child)
	end
	return new_object
end

function node:set_position(x, y, z)
	self._transform_flag = true
	self.position:set(x, y, z)
end

function node:set_rotation(q)
	self._transform_flag = true
	self.rotation = q
end

function node:set_scale(sx, sy, sz)
	self._transform_flag = true
	self.scale:set(sx, sy, sz)
end

function node:get_world_position(retvalue)
	self:recursive_update_transform()
	local p = retvalue or vec3()
	self.world_matrix:decompose(p, nil, nil)
	return p
end

function node:get_world_rotation(retvalue)
	self:recursive_update_transform()
	local q = retvalue or quat()
	self.world_matrix:decompose(nil, q, nil)
	return q
end

function node:get_world_scale(retvalue)
	self:recursive_update_transform()
	local s = retvalue or vec3()
	self.world_matrix:decompose(nil, nil, s)
	return s
end

function node:_recursive_get_aabb(t)
	if self.calculate_aabb then
		local a = t
		local b = self:calculate_aabb()

		if a.min.x > b.min.x then a.min.x = b.min.x end
		if a.min.y > b.min.y then a.min.y = b.min.y end
		if a.min.z > b.min.z then a.min.z = b.min.z end

		if a.max.x < b.max.x then a.max.x = b.max.x end
		if a.max.y < b.max.y then a.max.y = b.max.y end
		if a.max.z < b.max.z then a.max.z = b.max.z end
	end

	if #self.children > 0 then
		for i, v in ipairs(self.children) do
			v:_recursive_get_aabb(t)
		end
	end
	return t
end

function node:get_aabb()
	return self:_recursive_get_aabb(bound3(
		vec3(math.huge), vec3(-math.huge)
	))
end

--- Update transformation matrix for current node and its children.
function node:recursive_update_transform()
	if self.parent then self.parent:recursive_update_transform() end
	if self.update_transform_flag and self._transform_flag then
		self:update_transform()
	end
end

--- Update transformation matrix only for current node.
function node:update_transform()
	local local_matrix = self.local_matrix
	local world_matrix = self.world_matrix

	if self.update_transform_flag then
		local_matrix:compose(self.position, self.rotation, self.scale)
	end

	local parent = self.parent
	if parent then
		world_matrix:copy(parent.world_matrix)
		world_matrix:multiply(local_matrix)
	else
		world_matrix:copy(local_matrix)
	end
end

--- Get child node by index.
-- @tparam number index
-- @treturn Node object
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

--- Attach child node to this node.
-- @tparam Node object
-- @treturn Node object
function node:attach(node_object)
	--[[for i, node in ipairs({...}) do
		self.children[#self.children + 1] = node
		node.parent = self
	end
	return ...]]
	self.children[#self.children + 1] = node_object
	node_object:update_transform()
	node_object.parent = self
	return node_object
end

--- Detach child node from this node.
-- @tparam Node object
function node:detach(child)
	for i, v in ipairs(self.children) do
		if v == child then
			table.remove(self.children, i)
		end
	end
end

--- Recursively traverse all nodes.
-- @tparam function callback Function that is called for every child node with params (child, index)
function node:foreach(callback, i)
	i = i or 1
	callback(self, i)
	for i, v in ipairs(self.children) do
		v:foreach(callback, i)
	end
end

--- Detach this node from the parent node.
function node:detach_from_parent()
	local parent = self.parent
	if parent then
		local children = parent.children
		for i = 1, #children do
			if children[i] == self then
				table.remove(children, i)
				break
			end
		end
	end
	self.parent = nil
	self.detach_flag = true
end

function node:get_root_node(upto)
	if self.parent and self.parent ~= upto then
		return self.parent:get_root_node(upto)
	end
	return self
end

-- The number of children attached to this node.
function node:children_count()
	return #self.children
end

--- Recursively print all the children attached to this node.
function node:debug_print(node, tabs)
	node = node or self
	tabs = tabs or ''
	print(tabs .. '-> ' .. string.format('Node: %s Child count: %i', node, #node.children))
	tabs = tabs .. '  '
	for _, v in ipairs(node.children) do
		self:debug_print(v, tabs)
	end
end

return node