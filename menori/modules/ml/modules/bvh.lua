--[[
-------------------------------------------------------------------------------
	Menori
	@author rozenmad
	2022
-------------------------------------------------------------------------------
	this module based on CPML - Cirno's Perfect Math Library
	-- @author Colby Klein
	-- @author Landon Manning
	-- @copyright 2016
	-- @license MIT/X11
	https://github.com/excessive/cpml/blob/master/modules/bvh.lua
--]]

--- BVH Tree
-- @classmod bvh

local modules   = (...):gsub('%.[^%.]+$', '') .. "."
local intersect = require(modules .. 'intersect')
local vec3      = require(modules .. 'vec3')
local bound3    = require(modules .. 'bound3')
local EPSILON   = 1e-6
local BVH       = {}
local BVHNode   = {}
local Node

BVH.__index     = BVH
BVHNode.__index = BVHNode

local function new(triangles, max_triangles_per_node)
	local tree = setmetatable({}, BVH)
	local triangle_array = {}

	for i, triangle in ipairs(triangles) do
		local p1 = triangle[1]
		local p2 = triangle[2]
		local p3 = triangle[3]

		triangle_array[i] = {
			{p1.x or p1[1], p1.y or p1[2], p1.z or p1[3]},
			{p2.x or p2[1], p2.y or p2[2], p2.z or p2[3]},
			{p3.x or p3[1], p3.y or p3[2], p3.z or p3[3]}
		}
	end

	tree._triangles_array = triangle_array
	tree._max_triangles_per_node = max_triangles_per_node or 10

	local p1x, p1y, p1z
	local p2x, p2y, p2z
	local p3x, p3y, p3z
	local triangle

	tree._bbox_array = {}

	for i = 1, #triangle_array do
		triangle = triangle_array[i]
		p1x = triangle[1][1]
		p1y = triangle[1][2]
		p1z = triangle[1][3]
		p2x = triangle[2][1]
		p2y = triangle[2][2]
		p2z = triangle[2][3]
		p3x = triangle[3][1]
		p3y = triangle[3][2]
		p3z = triangle[3][3]

		tree._bbox_array[i] = {
			bound = bound3(
				vec3(math.min(p1x, p2x, p3x), math.min(p1y, p2y, p3y), math.min(p1z, p2z, p3z)),
				vec3(math.max(p1x, p2x, p3x), math.max(p1y, p2y, p3y), math.max(p1z, p2z, p3z))
			),
			index = i,
		}
	end

	-- clone a helper array
	tree._bbox_helper = {}
	for i = 1, #tree._bbox_array do
		local src = tree._bbox_array[i]
		local dst = {
			bound = src.bound:clone(),
			index = src.index
		}
		tree._bbox_helper[i] = dst
	end

	local count = #triangles
	local extents = tree:calculate_extents(1, count, EPSILON)
	tree.root_node = Node(extents, 1, count, 1)

	tree._nodes_to_split = { tree.root_node }
	while #tree._nodes_to_split > 0 do
		local node = table.remove(tree._nodes_to_split)
		tree:split_node(node)
	end
	return tree
end

function BVH:intersect_aabb(aabb)
	local nodes = self._nodes_to_split
	local intersecting = {}

	nodes[1] = self.root_node
	while #nodes > 0 do
		local node = table.remove(nodes)

		if intersect.aabb_aabb(aabb, node.extents) then
			if node._node0 then
				nodes[#nodes + 1] = node._node0
			end
			if node._node1 then
				nodes[#nodes + 1] = node._node1
			end

			for i = node._start_index, node._end_index do
				local triangle_index = self._bbox_array[i].index
				table.insert(intersecting, {
					triangle = self._triangles_array[triangle_index],
					triangle_index = triangle_index
				})
			end
		end
	end

	return intersecting
end

function BVH:intersect_ray(ray, backfaceCulling)
	local nodes = self._nodes_to_split
	local intersecting = {}

	local inv_ray_direction = 1 / ray.direction

	nodes[1] = self.root_node
	while #nodes > 0 do
		local node = table.remove(nodes)

		if BVH.intersectNodeBox(ray.position, inv_ray_direction, node.extents) then
			if node._node0 then
				nodes[#nodes + 1] = node._node0
			end
			if node._node1 then
				nodes[#nodes + 1] = node._node1
			end

			for i = node._start_index, node._end_index do
				local triangle_index = self._bbox_array[i].index
				local triangle = self._triangles_array[triangle_index]

				local rayhit = intersect.ray_triangle(ray, triangle, backfaceCulling)
				if rayhit then
					rayhit.triangle = triangle
					rayhit.triangle_index = triangle_index
					table.insert(intersecting, rayhit)
				end
			end
		end
	end

	table.sort(intersecting, function (a, b)
		return a.distance < b.distance
	end)

	return intersecting
end

function BVH:calculate_extents(start_index, end_index, expand_by)
	expand_by = expand_by or 0

	if start_index > end_index then
		return bound3()
	end

	local bound = bound3(
		vec3(math.huge), vec3(-math.huge)
	)
	local min = bound.min
	local max = bound.max

	for i= start_index, end_index do
		local src_bound = self._bbox_array[i].bound
		min.x = math.min(src_bound.min.x, min.x)
		min.y = math.min(src_bound.min.y, min.y)
		min.z = math.min(src_bound.min.z, min.z)
		max.x = math.max(src_bound.max.x, max.x)
		max.y = math.max(src_bound.max.y, max.y)
		max.z = math.max(src_bound.max.z, max.z)
	end

	min:sub_scalar(expand_by)
	max:add_scalar(expand_by)
	return bound
end

function BVH:split_node(node)
	local num_elements = node:element_count()
	if (num_elements <= self._max_triangles_per_node) or (num_elements <= 0) then
		return
	end

	local start_index = node._start_index
	local end_index = node._end_index

	local lt_node = { {},{},{} }
	local rt_node = { {},{},{} }
	local extent_centers = { node:center_x(), node:center_y(), node:center_z() }

	local extents_length = {
		node.extents.max.x - node.extents.min.x,
		node.extents.max.y - node.extents.min.y,
		node.extents.max.z - node.extents.min.z
	}

	local object_center = {}
	for i=start_index, end_index do
		local bound = self._bbox_array[i].bound
		object_center[1] = (bound.min.x + bound.max.x) * 0.5 -- center = (min + max) / 2
		object_center[2] = (bound.min.y + bound.max.y) * 0.5 -- center = (min + max) / 2
		object_center[3] = (bound.min.z + bound.max.z) * 0.5 -- center = (min + max) / 2

		for j=1, 3 do
			if object_center[j] < extent_centers[j] then
				table.insert(lt_node[j], i)
			else
				table.insert(rt_node[j], i)
			end
		end
	end

	-- check if we couldn't split the node by any of the axes (x, y or z). halt
	-- here, dont try to split any more (cause it will always fail, and we'll
	-- enter an infinite loop
	local split_failed = {
		#lt_node[1] == 0 or #rt_node[1] == 0,
		#lt_node[2] == 0 or #rt_node[2] == 0,
		#lt_node[3] == 0 or #rt_node[3] == 0
	}

	if split_failed[1] and split_failed[2] and split_failed[3] then
		return
	end

	-- choose the longest split axis. if we can't split by it, choose next best one.
	local split_order = { 1, 2, 3 }
	table.sort(split_order, function(a, b)
		return extents_length[a] > extents_length[b]
	end)

	local lt_elements
	local rt_elements

	for i=1, 3 do
		local candidate_index = split_order[i]
		if not split_failed[candidate_index] then
			lt_elements = lt_node[candidate_index]
			rt_elements = rt_node[candidate_index]
			break
		end
	end

	-- sort the elements in range (start_index, end_index) according to which node they should be at
	local node0_start = start_index
	local node1_start = node0_start + #lt_elements
	local node0_end = node1_start - 1
	local node1_end = end_index
	local current_element

	local helper_pos = node._start_index
	local dst, src

	for i = 1, #rt_elements do
		lt_elements[#lt_elements+1] = rt_elements[i]
	end

	for i = 1, #lt_elements do
		current_element = lt_elements[i]
		dst = self._bbox_helper[helper_pos]
		src = self._bbox_array[current_element]
		dst.bound:set(src.bound)
		dst.index = src.index
		helper_pos = helper_pos + 1
	end

	-- copy results back to main array
	for i = node._start_index, node._end_index do
		dst = self._bbox_array[i]
		src = self._bbox_helper[i]
		dst.bound:set(src.bound)
		dst.index = src.index
	end

	-- create 2 new nodes for the node we just split, and add links to them from the parent node
	local node0_extents = self:calculate_extents(node0_start, node0_end, EPSILON)
	local node1_extents = self:calculate_extents(node1_start, node1_end, EPSILON)

	local node0 = Node(node0_extents, node0_start, node0_end, node._level + 1)
	local node1 = Node(node1_extents, node1_start, node1_end, node._level + 1)

	node._node0 = node0
	node._node1 = node1
	node:clear()

	-- add new nodes to the split queue
	table.insert(self._nodes_to_split, node0)
	table.insert(self._nodes_to_split, node1)
end

function BVH._calcTValues(min_value, max_value, ray_origin_coord, invdir)
	local res = { min = 0, max = 0 }

	if invdir >= 0 then
		res.min = (min_value - ray_origin_coord) * invdir
		res.max = (max_value - ray_origin_coord) * invdir
	else
		res.min = (max_value - ray_origin_coord) * invdir
		res.max = (min_value - ray_origin_coord) * invdir
	end

	return res
end

function BVH.intersectNodeBox(origin, inv_direction, node)
	local t  = BVH._calcTValues(node.min.x, node.max.x, origin.x, inv_direction.x)
	local ty = BVH._calcTValues(node.min.y, node.max.y, origin.y, inv_direction.y)

	if t.min > ty.max or ty.min > t.max then
		return false
	end

	-- These lines also handle the case where tmin or tmax is NaN
	-- (result of 0 * Infinity). x !== x returns true if x is NaN
	if ty.min > t.min or t.min ~= t.min then
		t.min = ty.min
	end

	if ty.max < t.max or t.max ~= t.max then
		t.max = ty.max
	end

	local tz = BVH._calcTValues(node.min.z, node.max.z, origin.z, inv_direction.z)

	if t.min > tz.max or tz.min > t.max then
		return false
	end

	if tz.min > t.min or t.min ~= t.min then
		t.min = tz.min
	end

	if tz.max < t.max or t.max ~= t.max then
		t.max = tz.max
	end

	--return point closest to the ray (positive side)
	if t.max < 0 then
		return false
	end

	return true
end

local function new_node(extents, start_index, end_index, level)
	return setmetatable({
		extents = extents,
		_start_index = start_index,
		_end_index = end_index,
		_level = level
		--_node0    = nil
		--_node1    = nil
	}, BVHNode)
end

function BVHNode:element_count()
	return (self._end_index + 1) - self._start_index
end

function BVHNode:center_x()
	return (self.extents.min.x + self.extents.max.x) * 0.5
end

function BVHNode:center_y()
	return (self.extents.min.y + self.extents.max.y) * 0.5
end

function BVHNode:center_z()
	return (self.extents.min.z + self.extents.max.z) * 0.5
end

function BVHNode:clear()
	self._start_index =  0
	self._end_index   = -1
end

function BVHNode.ngSphereRadius(extentsMin, extentsMax)
	local center_x = (extentsMin.x + extentsMax.x) * 0.5
	local center_y = (extentsMin.y + extentsMax.y) * 0.5
	local center_z = (extentsMin.z + extentsMax.z) * 0.5

	local extentsMinDistSqr =
		(center_x - extentsMin.x) * (center_x - extentsMin.x) +
		(center_y - extentsMin.y) * (center_y - extentsMin.y) +
		(center_z - extentsMin.z) * (center_z - extentsMin.z)

	local extentsMaxDistSqr =
		(center_x - extentsMax.x) * (center_x - extentsMax.x) +
		(center_y - extentsMax.y) * (center_y - extentsMax.y) +
		(center_z - extentsMax.z) * (center_z - extentsMax.z)

	return math.sqrt(math.max(extentsMinDistSqr, extentsMaxDistSqr))
end

Node = setmetatable({}, {
	__call = function(_, ...) return new_node(...) end
})

return setmetatable({}, {
	__call = function(_, ...) return new(...) end
})